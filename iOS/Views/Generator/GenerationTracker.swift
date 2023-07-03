//
//  GenerationTracker.swift
//  Aislingeach
//
//  Created by Brad Root on 6/9/23.
//

import Foundation

protocol GenerationTrackerDelegate {
    func updateProcessingStatus(title: String, message: String)
    func showErrorStatus(title: String, message: String)
    func displayCompletedGeneration(generatedImage: GeneratedImage)
}

class GenerationTracker {
    var timer: Timer?
    var delegate: GenerationTrackerDelegate?

    var currentGenerationRequestIdentifier: String?
    var currentGenerationBody: GenerationInputStable?

    var requestIsProcessing: Bool = false

    init() {
        Log.debug("GenerationTracker Activated")
        startPolling()
    }

    func startPolling() {
        timer?.invalidate()
        Log.debug("Started polling...")
        timer = Timer(timeInterval: 2, target: self, selector: #selector(checkForPendingGeneration), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .common)
    }

    @objc func checkForPendingGeneration() {
        Log.debug("Checking for a pending generation...")
        guard let identifier = currentGenerationRequestIdentifier, !requestIsProcessing else { return }

        Log.info("\(identifier) - Checking request status...")

        requestIsProcessing = true

        HordeV2API.getImageAsyncCheck(_id: identifier, clientAgent: hordeClientAgent()) { data, error in
            if let data = data {
                Log.debug("\(data)")
                if let done = data.done, done {
                    Log.info("\(identifier) - Horde says done!")
                    self.saveFinishedGeneration()
                } else if let waitTime = data.waitTime, let queuePosition = data.queuePosition, let processing = data.processing, let waiting = data.waiting {
                    if queuePosition > 0 {
                        self.delegate?.updateProcessingStatus(title: "Sleeping...", message: "#\(queuePosition) waiting to dream")
                    } else if waitTime > 0 {
                        self.delegate?.updateProcessingStatus(title: "Dreaming...", message: "~\(waitTime) seconds")
                    } else if processing > 0 {
                        self.delegate?.updateProcessingStatus(title: "Waking...", message: "\(processing) image(s) processing")
                    } else if waiting > 0 {
                        self.delegate?.updateProcessingStatus(title: "Sleeping...", message: "Please wait...")
                    } else {
                        self.delegate?.updateProcessingStatus(title: "", message: "")
                    }

                    self.requestIsProcessing = false
                }
            } else if let error = error {
                if error.code == 0 {
                    self.delegate?.showErrorStatus(title: "Connection Error", message: "Connection timed out...\nRetrying...")
                } else {
                    self.delegate?.showErrorStatus(title: "Error", message: error.localizedDescription)
                }
                self.requestIsProcessing = false
            }
        }
    }

    func saveFinishedGeneration() {
        guard let identifier = currentGenerationRequestIdentifier, let body = currentGenerationBody else { return }

        Log.info("\(identifier) - Fetching finished generation...")
        HordeV2API.getImageAsyncStatus(_id: identifier, clientAgent: hordeClientAgent()) { [self] data, error in
            if let data = data {
                Log.debug("\(data)")
                if data.done ?? false {
                    if let generations = data.generations, !generations.isEmpty
                    {
                        generations.forEach { generation in
                            Log.debug("\(generation)")
                            if generation.censored ?? false {
                                self.delegate?.showErrorStatus(title: "Code 42", message: "Unable to generate this image.\nTry again with a different prompt?")
                            } else if let urlString = generation.img,
                                      let imageUrl = URL(string: urlString)
                            {
                                DispatchQueue.global().async {
                                    if let data = try? Data(contentsOf: imageUrl) {
                                        DispatchQueue.main.async {
                                            ImageDatabase.standard.saveImage(id: generation._id!, image: data, request: body, response: generation, completion: { generatedImage in
                                                if let image = generatedImage {
                                                    Log.info("\(identifier) - Saved Image ID \(image.uuid!)")
                                                    self.delegate?.displayCompletedGeneration(generatedImage: image)
                                                    self.currentGenerationBody = nil
                                                    self.currentGenerationRequestIdentifier = nil
                                                    self.requestIsProcessing = false
                                                }
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Log.error("No generations found within the request... this also shouldn't happen, probably.")
                        self.delegate?.showErrorStatus(title: "Error", message: "Task completed, but no generations were found. :(")
                        self.currentGenerationBody = nil
                        self.currentGenerationRequestIdentifier = nil
                        self.requestIsProcessing = false
                    }
                } else {
                    Log.error("Request was not marked as done yet... this shouldn't happen.")
                    self.requestIsProcessing = false
                }
            } else if let error = error {
                Log.error("\(identifier) - Encountered error trying to fetch image: \(error)")
                if error.code == 0 {
                    self.delegate?.showErrorStatus(title: "Connection Error", message: "Connection timed out...\nRetrying...")
                } else {
                    self.delegate?.showErrorStatus(title: "Error", message: error.localizedDescription)
                }
                self.requestIsProcessing = false
            }
        }
    }

    func createNewGenerationRequest(body: GenerationInputStable) {
        Log.info("Submitting a new generation request...")

        delegate?.updateProcessingStatus(title: "Falling asleep...", message: "")

        if requestIsProcessing || currentGenerationRequestIdentifier != nil {
            delegate?.showErrorStatus(title: "Error", message: "A curent request is currently processing. Please wait until it is finished.")
        }

        HordeV2API.postImageAsyncGenerate(body: body, apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { data, error in
            if let data = data, let generationIdentifier = data._id {
                Log.debug("\(data)")
                self.setNewGenerationRequest(generationIdentifier: generationIdentifier, body: body)
            } else if let error = error {
                Log.debug("Error: \(error)")
                if error.code == 401 {
                    self.delegate?.showErrorStatus(title: "401 Error", message: "Invalid API key")
                } else if error.code == 500 {
                    self.delegate?.showErrorStatus(title: "500 Error", message: "Could not connect to server")
                } else {
                    self.delegate?.showErrorStatus(title: "Error", message: error.localizedDescription)
                }
                self.requestIsProcessing = false
            }
        }
    }

    func setNewGenerationRequest(generationIdentifier: String, body: GenerationInputStable) {
        Log.info("\(generationIdentifier) - New request created...")
        currentGenerationRequestIdentifier = generationIdentifier
        currentGenerationBody = body
        requestIsProcessing = false
    }
}
