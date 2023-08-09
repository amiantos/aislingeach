//
//  GenerationTracker.swift
//  Aislingeach
//
//  Created by Brad Root on 6/9/23.
//

import Foundation
import UIKit

enum TrackerException: Error {
    case NoGenerationsFound
    case ImageSaveFailure
    case FailureToUpdatePendingRequest
    case RequestNotDone
}

enum UpdateType {
    case update
    case error
    case success
}

protocol GenerationTrackerDelegate {
    func showUpdate(type: UpdateType, message: String)
}

class GenerationTracker {
    var timer: Timer?
    var downloadTimer: Timer?
    var delegate: GenerationTrackerDelegate?

    var currentGenerationRequestIdentifier: String?
    var currentGenerationBody: GenerationInputStable?
    var generationsSaved: [String] = []

    var createViewNavigationController: UINavigationController

    var pendingCheckInProcess: Bool = false
    var downloadingInProgress: Bool = false

    init() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "generatorViewController") as! UINavigationController
        controller.modalPresentationStyle = .pageSheet
        controller.isModalInPresentation = true
        createViewNavigationController = controller
        if let generateView = controller.topViewController as? GeneratorViewController {
            generateView.generationTracker = self
        }
        Log.info("GenerationTracker Activated")
        startPolling()
    }

    func startPolling() {
        timer?.invalidate()
        Log.debug("Started polling...")
        timer = Timer(timeInterval: 2, target: self, selector: #selector(checkForPendingGeneration), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)

        downloadTimer = Timer(timeInterval: 1, target: self, selector: #selector(checkForPendingDownloads), userInfo: nil, repeats: true)
        RunLoop.current.add(downloadTimer!, forMode: .common)
    }

    @objc func checkForPendingGeneration() {
        Task {
            if pendingCheckInProcess { return }

            pendingCheckInProcess = true
            let requests = await ImageDatabase.standard.fetchActiveRequests() ?? []

            if requests.count < 5 {
                let unsubmittedRequests = await ImageDatabase.standard.fetchRequestsToSubmit(limit: 5 - requests.count) ?? []
                for request in unsubmittedRequests {
                    Log.info("Submitting new request for \(request.n) images...")
                    guard let jsonString = request.fullRequest,
                          let jsonData = jsonString.data(using: .utf8),
                          let body = try? JSONDecoder().decode(GenerationInputStable.self, from: jsonData) else { continue }

                    do {
                        let result = try await HordeV2API.postImageAsyncGenerate(body: body, apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent())
                        var prunedRequestBody = body
                        prunedRequestBody.sourceImage = "[true]"
                        if let generationIdentifier = result._id {
                            ImageDatabase.standard.updateRequestWithUUID(hordeRequest: request, uuid: UUID(uuidString: generationIdentifier)!) { _ in
                                Log.info("\(generationIdentifier) - Request submitted successfully.")
                            }
                        }
                    } catch {
                        if error.code == 401 {
                            _ = await ImageDatabase.standard.updatePendingRequestErrorState(request: request, message: "401 - Invalid API key")
                        } else if error.code == 403, body.models!.contains("SDXL_beta::stability.ai#6901") {
                            _ = await ImageDatabase.standard.updatePendingRequestErrorState(request: request, message: "403 - Anonymous users cannot use the SDXL beta.")
                        } else if error.code == 403 {
                            _ = await ImageDatabase.standard.updatePendingRequestErrorState(request: request, message: "403 - Generation request was rejected by the server.")
                        } else {
                            // Otherwise we ignore the error
                            Log.error("Unhandled error: \(error.code) \(error.localizedDescription)")
                        }
                    }
                }
            }

            for request in requests {
                guard let requestId = request.uuid?.uuidString.lowercased() else {
                    fatalError("Received a pending request without a UUID, this shouldn't happen.")
                }
                Log.info("\(requestId) - Checking request status")
                do {
                    if request.status == "active" {
                        let data = try await HordeV2API.getImageAsyncCheck(_id: requestId, clientAgent: hordeClientAgent())
                        await sleep(1)

                        guard await ImageDatabase.standard.updatePendingRequest(
                            request: request,
                            check: data
                        ) != nil else {
                            throw TrackerException.FailureToUpdatePendingRequest
                        }

                        guard data.done ?? false else { continue }
                        Log.info("\(requestId) - Horde says done!")
                        await self.saveFinishedGenerations(request: request)
                    } else if request.status == "downloading" {
                        let pendingDownloads = await ImageDatabase.standard.getPendingDownloads(for: request)
                        let images = await ImageDatabase.standard.fetchImages(for: request.uuid!) ?? []
                        if pendingDownloads?.count == 0, !images.isEmpty {
                            ImageDatabase.standard.updatePendingRequestFinishedState(request: request, images: images)
                        }
                    }
                } catch {
                    if error.code == 404 {
                        guard await ImageDatabase.standard.updatePendingRequestErrorState(
                            request: request,
                            message: "This request can no longer be found."
                        ) != nil else {
                            fatalError("Unable to update pending request, this should not happen!")
                        }
                    } else {
                        Log.error("Polling error: \(error.code) : \(error.localizedDescription)")
                    }
                }
            }
            pendingCheckInProcess = false
        }
    }

    @objc func checkForPendingDownloads() {
        Task {
            if downloadingInProgress { return }

            downloadingInProgress = true
            let downloads = await ImageDatabase.standard.fetchPendingDownloads() ?? []
            for download in downloads {
                if let url = download.uri,
                   let requestId = download.requestId,
                   let imageData = try? Data(contentsOf: url),
                   let generatedImage = await ImageDatabase.standard.saveImage(
                       id: download.uuid!,
                       requestId: download.requestId!,
                       image: imageData,
                       fullRequest: download.fullRequest!,
                       fullResponse: download.fullResponse!
                   )
                {
                    Log.info("\(requestId) - Successfully saved image ID \(generatedImage.uuid!)")
                    ImageDatabase.standard.deletePendingDownload(download)
                }
            }
            downloadingInProgress = false
        }
    }

    func saveFinishedGenerations(request: HordeRequest) async {
        guard let requestId = request.uuid?.uuidString.lowercased(), !generationsSaved.contains(requestId) else { return }
        Log.info("\(requestId) - Fetching finished generation...")

        generationsSaved.append(requestId)

        do {
            let data = try await HordeV2API.getImageAsyncStatus(_id: requestId, clientAgent: hordeClientAgent())

            guard data.done ?? false, let generations = data.generations, !generations.isEmpty else {
                throw TrackerException.NoGenerationsFound
            }
            for generation in generations {
                guard let urlString = generation.img,
                      let imageUrl = URL(string: urlString),
                      let pendingDownload = await ImageDatabase.standard.savePendingDownload(
                          id: generation._id!,
                          requestId: requestId,
                          url: imageUrl,
                          request: request,
                          response: generation
                      )
                else {
                    throw TrackerException.ImageSaveFailure
                }

                Log.info("\(requestId) - Saved Pending Download \(pendingDownload.uuid!)")
            }
            ImageDatabase.standard.updatePendingRequestWithKudosCost(request: request, status: data)
        } catch {
            Log.error("\(requestId) - Encountered error trying to fetch images: \(error.localizedDescription)")
            generationsSaved = generationsSaved.filter { $0 != requestId }
        }
    }

    func createNewGenerationRequest(body: GenerationInputStable) {
        Log.info("Submitting a new generation request...")

        delegate?.showUpdate(type: .update, message: "Sending your dream...")
        ImageDatabase.standard.saveNewRequest(request: body) { hordeRequest in
            if hordeRequest != nil {
                self.delegate?.showUpdate(type: .success, message: "Dream was queued successfully!")
            }
        }
    }
}
