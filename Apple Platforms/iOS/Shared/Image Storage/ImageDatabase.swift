//
//  ImageDatabase.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import CoreData
import Foundation
import UIKit

class ImageDatabase {
    static let standard: ImageDatabase = .init()

    var mainManagedObjectContext: NSManagedObjectContext
    var privateManagedObjectContext: NSManagedObjectContext
    var persistentContainer: NSPersistentContainer

    init() {
        persistentContainer = {
            let container = NSPersistentContainer(name: "ImageModel")
            container.loadPersistentStores(completionHandler: { _, error in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            return container
        }()
        mainManagedObjectContext = persistentContainer.viewContext
        privateManagedObjectContext = persistentContainer.newBackgroundContext()
    }

    deinit {
        self.saveContext()
    }

    func saveContext() {
        if mainManagedObjectContext.hasChanges {
            do {
                try mainManagedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application, although it
                // may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }

        if privateManagedObjectContext.hasChanges {
            do {
                try privateManagedObjectContext.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - Images

    func saveImage(id: UUID, requestId: UUID, image: Data, fullRequest: String, fullResponse: String) async -> GeneratedImage? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform {
                do {
                    let fetchRequest: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "uuid == %@", id as CVarArg)
                    if let image = try? self.mainManagedObjectContext.fetch(fetchRequest).first {
                        Log.debug("Image already found in database, not re-saving.")
                        continuation.resume(returning: image)
                    } else {
                        let generatedImage = GeneratedImage(context: self.mainManagedObjectContext)
                        generatedImage.image = image
                        let imageObject = UIImage(data: image)
                        generatedImage.thumbnail = imageObject?.preparingThumbnail(of: CGSize(width: 512, height: 512))?.pngData()
                        generatedImage.uuid = id
                        generatedImage.requestId = requestId
                        generatedImage.dateCreated = Date()
                        generatedImage.fullRequest = fullRequest
                        if let jsonString = generatedImage.fullRequest,
                           let jsonData = jsonString.data(using: .utf8),
                           let settings = try? JSONDecoder().decode(GenerationInputStable.self, from: jsonData)
                        {
                            generatedImage.promptSimple = settings.prompt
                        }
                        generatedImage.fullResponse = fullResponse
                        generatedImage.backend = "horde"
                        try self.mainManagedObjectContext.save()
                        continuation.resume(returning: generatedImage)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func saveThumbnail(for image: GeneratedImage, thumbnail: UIImage) {
        mainManagedObjectContext.perform {
            image.thumbnail = thumbnail.pngData()
            try? self.mainManagedObjectContext.save()
        }
    }

    func fetchFirstImage(requestId: UUID, completion: @escaping (GeneratedImage?) -> Void) {
        mainManagedObjectContext.perform {
            do {
                let fetchRequest: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "requestId == %@", requestId as CVarArg)
                if let image = try? self.mainManagedObjectContext.fetch(fetchRequest).first {
                    completion(image)
                } else {
                    completion(nil)
                }
            }
        }
    }

    func toggleImageFavorite(generatedImage: GeneratedImage, completion: @escaping (GeneratedImage?) -> Void) {
        mainManagedObjectContext.perform {
            do {
                generatedImage.isFavorite = !generatedImage.isFavorite
                try self.mainManagedObjectContext.save()
                NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
                completion(generatedImage)
            } catch {
                completion(nil)
            }
        }
    }

    func toggleImageHidden(generatedImage: GeneratedImage, completion: @escaping (GeneratedImage?) -> Void) {
        mainManagedObjectContext.perform {
            do {
                generatedImage.isHidden = !generatedImage.isHidden
                try self.mainManagedObjectContext.save()
                NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
                completion(generatedImage)
            } catch {
                completion(nil)
            }
        }
    }

    func hideImages(_ generatedImages: [GeneratedImage], completion: @escaping ([GeneratedImage]?) -> Void) {
        mainManagedObjectContext.perform {
            do {
                for image in generatedImages {
                    image.isHidden = true
                }
                try self.mainManagedObjectContext.save()
                NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
                completion(generatedImages)
            } catch {
                completion(nil)
            }
        }
    }

    func unHideImages(_ generatedImages: [GeneratedImage], completion: @escaping ([GeneratedImage]?) -> Void) {
        mainManagedObjectContext.perform {
            do {
                for image in generatedImages {
                    image.isHidden = false
                }
                try self.mainManagedObjectContext.save()
                NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
                completion(generatedImages)
            } catch {
                completion(nil)
            }
        }
    }

    func favoriteImages(_ generatedImages: [GeneratedImage], completion: @escaping ([GeneratedImage]?) -> Void) {
        mainManagedObjectContext.perform {
            do {
                for image in generatedImages {
                    image.isFavorite = true
                }
                try self.mainManagedObjectContext.save()
                NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
                completion(generatedImages)
            } catch {
                completion(nil)
            }
        }
    }

    func unFavoriteImages(_ generatedImages: [GeneratedImage], completion: @escaping ([GeneratedImage]?) -> Void) {
        mainManagedObjectContext.perform {
            do {
                for image in generatedImages {
                    image.isFavorite = false
                }
                try self.mainManagedObjectContext.save()
                NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
                completion(generatedImages)
            } catch {
                completion(nil)
            }
        }
    }

    func deleteImage(_ generatedImage: GeneratedImage, completion: @escaping (GeneratedImage?) -> Void) {
        mainManagedObjectContext.perform { [self] in
            // TODO: Should trash...
            mainManagedObjectContext.delete(generatedImage)
            try? mainManagedObjectContext.save()
            NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
            completion(nil)
        }
    }

    func deleteImages(_ generatedImages: [GeneratedImage]) {
        mainManagedObjectContext.perform { [self] in
            for image in generatedImages where !image.isFavorite {
                // TODO: Should trash...
                mainManagedObjectContext.delete(image)
            }
            try? mainManagedObjectContext.save()
            NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
        }
    }

//    func pruneImages() {
//        mainManagedObjectContext.perform { [self] in
//            do {
//                let fetchRequest: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
//                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "isFavorite = %d", false), NSPredicate(format: "isHidden = %d", false)])
//                let images = try mainManagedObjectContext.fetch(fetchRequest) as [GeneratedImage]
//                for image in images {
//                    // TODO: Should trash...
//                    mainManagedObjectContext.delete(image)
//                }
//                try mainManagedObjectContext.save()
//                NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
//            } catch {
//                Log.debug("Uh oh...")
//            }
//        }
//    }

    func getCountAndRecentImageForPredicate(predicate: NSPredicate) async -> (Int, GeneratedImage?) {
        return await withCheckedContinuation { continuation in
            privateManagedObjectContext.perform { [self] in
                do {
                    let fetchRequest1: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                    fetchRequest1.predicate = predicate

                    let count1 = try privateManagedObjectContext.count(for: fetchRequest1)
                    if count1 == 0 {
                        continuation.resume(returning: (0, nil))
                    } else {
                        fetchRequest1.fetchLimit = 1
                        fetchRequest1.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
                        let images = try privateManagedObjectContext.fetch(fetchRequest1) as [GeneratedImage]
                        continuation.resume(returning: (count1, images[0]))
                    }
                } catch {
                    continuation.resume(returning: (0, nil))
                }
            }
        }
    }

    func getPopularPromptKeywords(hidden: Bool) async -> [String : (Int, GeneratedImage)] {
        return await withCheckedContinuation { continuation in
            privateManagedObjectContext.perform { [self] in
                do {
                    let fetchRequest1: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                    fetchRequest1.predicate = NSPredicate(format: "isHidden = %d", hidden)
                    fetchRequest1.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
                    let images = try privateManagedObjectContext.fetch(fetchRequest1) as [GeneratedImage]

                    var keywords: [String: (Int, GeneratedImage)] = [:]
                    for obj in images {
                        if var prompt = obj.promptSimple {
                            if let dotRange = prompt.range(of: "###") {
                                prompt.removeSubrange(dotRange.lowerBound ..< prompt.endIndex)
                            }
                            for keyword in prompt.components(separatedBy: ", ") {
                                var cleanedKeyword = keyword.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                                cleanedKeyword = cleanedKeyword.replacing(/:(\d+(?:\.\d+)?)+/, with: "")
                                if let keyword = keywords[cleanedKeyword]  {
                                    keywords[cleanedKeyword] = (keyword.0 + 1, keyword.1)
                                } else {
                                    keywords[cleanedKeyword] = (1, obj)
                                }
                            }
                        }
                    }

                    continuation.resume(returning: keywords)

                } catch {
                    continuation.resume(returning: [:])
                }
            }
        }
    }

    func fetchImages(for requestId: UUID, completion: @escaping ([GeneratedImage]?) -> Void) {
        mainManagedObjectContext.perform { [self] in
            do {
                let fetchRequest: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "requestId = %@", requestId as CVarArg)
                let images = try mainManagedObjectContext.fetch(fetchRequest) as [GeneratedImage]
                completion(images)
            } catch {
                completion(nil)
            }
        }
    }

    func fetchImages(for requestId: UUID) async -> [GeneratedImage]? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform { [self] in
                do {
                    let fetchRequest1: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                    fetchRequest1.predicate = NSPredicate(format: "requestId = %@", requestId as CVarArg)
                    let images = try mainManagedObjectContext.fetch(fetchRequest1) as [GeneratedImage]
                    continuation.resume(returning: images)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Requests

    func saveNewRequest(request: GenerationInputStable, completion: @escaping (HordeRequest?) -> Void) {
        mainManagedObjectContext.perform {
            do {
                let hordeRequest = HordeRequest(context: self.mainManagedObjectContext)
                hordeRequest.prompt = request.prompt
                hordeRequest.dateCreated = Date()
                hordeRequest.fullRequest = request.toJSONString()
                hordeRequest.n = Int16(request.params?.n ?? 0)
                hordeRequest.message = "Dream queued for submission..."
                hordeRequest.status = "active"
                try self.mainManagedObjectContext.save()
                completion(hordeRequest)
            } catch {
                completion(nil)
            }
        }
    }

    func updateRequestWithUUID(hordeRequest: HordeRequest, uuid: UUID, completion: @escaping (HordeRequest?) -> Void) {
        mainManagedObjectContext.perform {
            do {
                hordeRequest.uuid = uuid
                hordeRequest.status = "active"
                hordeRequest.message = "Dream submitted successfully..."
                try self.mainManagedObjectContext.save()
                completion(hordeRequest)
            } catch {
                completion(nil)
            }
        }
    }

    func deleteRequest(_ hordeRequest: HordeRequest, pruneImages: Bool, completion: @escaping (HordeRequest?) -> Void) {
        mainManagedObjectContext.perform { [self] in
            do {
                if pruneImages {
                    let fetchRequest: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                    fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "isFavorite = %d", false),
                        NSPredicate(format: "isHidden = %d", false),
                        NSPredicate(format: "requestId = %@", hordeRequest.uuid! as CVarArg),
                    ])
                    let images = try mainManagedObjectContext.fetch(fetchRequest) as [GeneratedImage]
                    for image in images {
                        // TODO: Should trash...
                        mainManagedObjectContext.delete(image)
                    }
                }
                mainManagedObjectContext.delete(hordeRequest)
                try mainManagedObjectContext.save()
                NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
                completion(nil)
            } catch {
                completion(nil)
            }
        }
    }

    func deleteRequests(pruneImages: Bool) {
        mainManagedObjectContext.perform { [self] in
            do {
                let requestsFetchRequest: NSFetchRequest<HordeRequest> = HordeRequest.fetchRequest()
                requestsFetchRequest.predicate = NSPredicate(format: "status = %@", "finished")
                requestsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
                let requests = try mainManagedObjectContext.fetch(requestsFetchRequest) as [HordeRequest]
                for request in requests {
                    if pruneImages {
                        let fetchRequest: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                            NSPredicate(format: "isFavorite = %d", false),
                            NSPredicate(format: "isHidden = %d", false),
                            NSPredicate(format: "requestId = %@", request.uuid! as CVarArg),
                        ])
                        let images = try mainManagedObjectContext.fetch(fetchRequest) as [GeneratedImage]
                        for image in images {
                            mainManagedObjectContext.delete(image)
                        }
                    }
                    mainManagedObjectContext.delete(request)
                }
                try mainManagedObjectContext.save()
                NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
            } catch {
                Log.error("Encountered error trying to batch delete requests: \(error.localizedDescription)")
            }
        }
    }

    func fetchActiveRequests() async -> [HordeRequest]? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform { [self] in
                do {
                    let fetchRequest1: NSFetchRequest<HordeRequest> = HordeRequest.fetchRequest()
                    fetchRequest1.predicate = NSCompoundPredicate(
                        andPredicateWithSubpredicates: [
                            NSCompoundPredicate(
                                orPredicateWithSubpredicates: [
                                    NSPredicate(format: "status = %@", "active"),
                                    NSPredicate(format: "status = %@", "downloading")
                                ]
                            ),
                            NSPredicate(format: "uuid != nil")
                        ]
                    )
                    fetchRequest1.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]
                    let requests = try mainManagedObjectContext.fetch(fetchRequest1) as [HordeRequest]
                    continuation.resume(returning: requests)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func fetchRequestsToSubmit(limit: Int = 5) async -> [HordeRequest]? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform { [self] in
                do {
                    let fetchRequest1: NSFetchRequest<HordeRequest> = HordeRequest.fetchRequest()
                    fetchRequest1.predicate = NSPredicate(format: "uuid = nil")
                    fetchRequest1.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
                    fetchRequest1.fetchLimit = limit
                    let requests = try mainManagedObjectContext.fetch(fetchRequest1) as [HordeRequest]
                    continuation.resume(returning: requests)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func fetchPendingDownloads() async -> [HordePendingDownload]? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform { [self] in
                do {
                    let fetchRequest1: NSFetchRequest<HordePendingDownload> = HordePendingDownload.fetchRequest()
                    let downloads = try mainManagedObjectContext.fetch(fetchRequest1) as [HordePendingDownload]
                    continuation.resume(returning: downloads)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func getPendingDownloads(for request: HordeRequest) async -> [HordePendingDownload]? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform { [self] in
                do {
                    let fetchRequest1: NSFetchRequest<HordePendingDownload> = HordePendingDownload.fetchRequest()
                    fetchRequest1.predicate = NSPredicate(format: "requestId = %@", request.uuid! as CVarArg)
                    let pendingDownloads = try mainManagedObjectContext.fetch(fetchRequest1) as [HordePendingDownload]
                    continuation.resume(returning: pendingDownloads)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func updatePendingRequest(request: HordeRequest, check: RequestStatusCheck) async -> HordeRequest? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform { [self] in
                do {
                    if request.status != "active" {
                        continuation.resume(returning: request)
                    } else {
                        if let waitTime = check.waitTime,
                           let queuePosition = check.queuePosition,
                           let processing = check.processing,
                           let waiting = check.waiting,
                           let finished = check.finished,
                           let done = check.done
                        {
                            request.waitTime = Int16(waitTime)
                            request.queuePosition = Int16(queuePosition)
                            request.status = done ? "downloading" : "active"
                            request.message = "\(waiting) queued, \(processing) processing, \(finished) finished"
                            if request.status == "downloading" {
                                request.message = "Downloading \(finished) images..."
                            }
                            try mainManagedObjectContext.save()
                        }
                        continuation.resume(returning: request)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func updatePendingRequestErrorState(request: HordeRequest, message: String) async -> HordeRequest? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform {
                do {
                    request.message = message
                    request.status = "error"
                    request.waitTime = 0
                    request.queuePosition = 0
                    try self.mainManagedObjectContext.save()
                    continuation.resume(returning: request)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func updatePendingRequestWithKudosCost(request: HordeRequest, status: RequestStatusStable) {
        mainManagedObjectContext.perform {
            if let kudosCost = (status.kudos as? NSDecimalNumber)?.intValue {
                request.totalKudosCost = Int16(kudosCost)
                try? self.mainManagedObjectContext.save()
            }
        }
    }

    func updatePendingRequestFinishedState(request: HordeRequest, images: [GeneratedImage]) {
        mainManagedObjectContext.perform {
            request.n = Int16(images.count)
            let kudosCost = Int(request.totalKudosCost)
            request.message = "Kudos cost: \(kudosCost) total, ~\(kudosCost / images.count) per image"
            request.status = "finished"

            let mutableItems = request.images?.mutableCopy() as? NSMutableOrderedSet ?? []
            mutableItems.addObjects(from: images)
            request.images = mutableItems.copy() as? NSOrderedSet

            try? self.mainManagedObjectContext.save()

            NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
        }
    }

    func savePendingDownload(id: String, requestId: String, url: URL, request: HordeRequest, response: GenerationStable) async -> HordePendingDownload? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform {
                do {
                    let fetchRequest: NSFetchRequest<HordePendingDownload> = HordePendingDownload.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "uuid == %@", UUID(uuidString: id)! as CVarArg)
                    if let pendingDownload = try? self.mainManagedObjectContext.fetch(fetchRequest).first {
                        Log.debug("Download already found in database, not re-saving.")
                        continuation.resume(returning: pendingDownload)
                    } else {
                        let pendingDownload = HordePendingDownload(context: self.mainManagedObjectContext)
                        pendingDownload.uri = url
                        pendingDownload.uuid = UUID(uuidString: id)!
                        pendingDownload.requestId = UUID(uuidString: requestId)!
                        pendingDownload.fullRequest = request.fullRequest
                        var prunedResponse = response
                        prunedResponse.img = nil
                        pendingDownload.fullResponse = prunedResponse.toJSONString()
                        try self.mainManagedObjectContext.save()
                        continuation.resume(returning: pendingDownload)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    func deletePendingDownload(_ pendingDownload: HordePendingDownload) {
        mainManagedObjectContext.perform {
            self.mainManagedObjectContext.delete(pendingDownload)
            try? self.mainManagedObjectContext.save()
        }
    }
}
