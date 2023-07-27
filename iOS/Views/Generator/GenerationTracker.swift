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

            Log.debug("Checking for a pending generation...")
            pendingCheckInProcess = true
            let requests = await ImageDatabase.standard.fetchPendingRequests() ?? []
            for request in requests {
                guard let requestId = request.uuid?.uuidString.lowercased() else { return }
                Log.debug("\(requestId) - Checking request status")

                do {
                    if request.status == "active" {
                        let data = try await HordeV2API.getImageAsyncCheck(_id: requestId, clientAgent: hordeClientAgent())
                        Log.debug("\(data)")
                        
                        guard await ImageDatabase.standard.updatePendingRequest(
                            request: request,
                            check: data
                        ) != nil else {
                            throw TrackerException.FailureToUpdatePendingRequest
                        }
                        
                        guard data.done ?? false else { continue }
                        Log.debug("\(requestId) - Horde says done!")
                        await self.saveFinishedGenerations(request: request)
                    } else if request.status == "downloading" {
                        let pendingDownloads = await ImageDatabase.standard.getPendingDownloads(for: request)
                        if pendingDownloads?.count == 0 {
                            let images = await ImageDatabase.standard.fetchImages(for: request.uuid!) ?? []
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

            Log.debug("Checking for a pending downloads...")
            downloadingInProgress = true
            let downloads = await ImageDatabase.standard.fetchPendingDownloads() ?? []
            for download in downloads {
                if let url = download.uri,
                   let imageData = try? Data(contentsOf: url),
                   let generatedImage = await ImageDatabase.standard.saveImage(
                    id: download.uuid!,
                    requestId: download.requestId!,
                      image: imageData,
                      fullRequest: download.fullRequest!,
                      fullResponse: download.fullResponse!
                   ) {
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
            Log.debug("\(data)")

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
                ImageDatabase.standard.updatePendingRequestWithKudosCost(request: request, status: data)
            }
        } catch {
            Log.error("\(requestId) - Encountered error trying to fetch images: \(error.localizedDescription)")
            generationsSaved = generationsSaved.filter { $0 != requestId }
        }
    }

    func createNewGenerationRequest(body: GenerationInputStable) {
        Log.info("Submitting a new generation request...")

        delegate?.showUpdate(type: .update, message: "Sending your dream...")

        HordeV2API.postImageAsyncGenerate(body: body, apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { data, error in
            if let data = data, let generationIdentifier = data._id {
                Log.debug("\(data)")
                ImageDatabase.standard.saveRequest(id: UUID(uuidString: generationIdentifier)!, request: body) { _ in
                    Log.debug("\(generationIdentifier) - Request saved successfully.")
                }
                self.delegate?.showUpdate(type: .success, message: "Dream was sent successfully!")
            } else if let error = error {
                Log.debug("Error: \(error.localizedDescription)")
                if error.code == 401 {
                    self.delegate?.showUpdate(type: .error, message: "401 - Invalid API key")
                } else if error.code == 500 {
                    self.delegate?.showUpdate(type: .error, message: "500 - Could not connect to server, try again?")
                } else if error.code == 403, body.models!.contains("SDXL_beta::stability.ai#6901") {
                    self.delegate?.showUpdate(type: .error, message: "403 - Anonymous users cannot use the SDXL beta.")
                } else if error.code == 403 {
                    self.delegate?.showUpdate(type: .error, message: "403 - Generation request was rejected by the server.")
                } else {
                    self.delegate?.showUpdate(type: .error, message: error.localizedDescription)
                }
            }
        }
    }
}
