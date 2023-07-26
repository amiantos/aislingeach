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

    func delete(_ object: NSManagedObject) {
        mainManagedObjectContext.delete(object)
    }

    // MARK: - Images

    func saveImage(id: String, requestId: String, image: Data, request: HordeRequest, response: GenerationStable) async -> GeneratedImage? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform {
                do {
                    let fetchRequest: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "uuid == %@", UUID(uuidString: id)! as CVarArg)
                    if let image = try? self.mainManagedObjectContext.fetch(fetchRequest).first {
                        Log.debug("Image already found in database, not re-saving.")
                        continuation.resume(returning: image)
                    }

                    let generatedImage = GeneratedImage(context: self.mainManagedObjectContext)
                    generatedImage.image = image
                    generatedImage.uuid = UUID(uuidString: id)!
                    generatedImage.requestId = UUID(uuidString: requestId)!
                    generatedImage.dateCreated = Date()
                    generatedImage.fullRequest = request.fullRequest
                    generatedImage.promptSimple = request.prompt
                    var prunedResponse = response
                    prunedResponse.img = nil
                    generatedImage.fullResponse = prunedResponse.toJSONString()
                    generatedImage.backend = "horde"
                    try self.mainManagedObjectContext.save()
                    continuation.resume(returning: generatedImage)
                } catch {
                    continuation.resume(returning: nil)
                }
            }
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
        // TODO: Should trash...
        mainManagedObjectContext.delete(generatedImage)
        saveContext()
        NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
        completion(nil)
    }

    func deleteImages(_ generatedImages: [GeneratedImage]) {
        for image in generatedImages where !image.isFavorite {
            mainManagedObjectContext.delete(image)
        }
        saveContext()
        NotificationCenter.default.post(name: .imageDatabaseUpdated, object: nil)
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

    func getCountAndRecentImageForPredicate(predicate: NSPredicate, completion: @escaping ((Int, GeneratedImage?)) -> Void) {
        privateManagedObjectContext.perform { [self] in
            do {
                let fetchRequest: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                fetchRequest.predicate = predicate
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]

                let count = try privateManagedObjectContext.count(for: fetchRequest)
                if count == 0 {
                    completion((0, nil))
                } else {
                    fetchRequest.fetchLimit = 1
                    let images = try privateManagedObjectContext.fetch(fetchRequest) as [GeneratedImage]
                    completion((count, images[0]))
                }
            } catch {
                completion((0, nil))
            }
        }
    }

    func getPopularPromptKeywords(hidden: Bool, completion: @escaping ([String: Int]) -> Void) {
        privateManagedObjectContext.perform { [self] in
            do {
                let fetchRequest: NSFetchRequest<GeneratedImage> = GeneratedImage.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "isHidden = %d", hidden)
                fetchRequest.propertiesToFetch = ["promptSimple"]
                fetchRequest.resultType = .dictionaryResultType
                let prompts = try privateManagedObjectContext.fetch(fetchRequest) as [AnyObject]

                var keywords: [String: Int] = [:]
                for obj in prompts {
                    if var prompt = obj["promptSimple"] as? String {
                        if let dotRange = prompt.range(of: " ### ") {
                            prompt.removeSubrange(dotRange.lowerBound ..< prompt.endIndex)
                        }
                        for keyword in prompt.components(separatedBy: ", ") {
                            var cleanedKeyword = keyword.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                            cleanedKeyword = cleanedKeyword.replacing(/:(\d+(?:\.\d+)?)+/, with: "")
                            if var data = keywords[cleanedKeyword] {
                                data += 1
                                keywords[cleanedKeyword] = data
                            } else {
                                keywords[cleanedKeyword] = 1
                            }
                        }
                    }
                }

                completion(keywords)

            } catch {
                completion([:])
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

    // MARK: - Requests

    func saveRequest(id: UUID, request: GenerationInputStable, completion: @escaping (HordeRequest?) -> Void) {
        mainManagedObjectContext.perform {
            do {
                let hordeRequest = HordeRequest(context: self.mainManagedObjectContext)
                hordeRequest.uuid = id
                hordeRequest.prompt = request.prompt
                hordeRequest.dateCreated = Date()
                hordeRequest.fullRequest = request.toJSONString()
                hordeRequest.n = Int16(request.params?.n ?? 0)
                hordeRequest.message = "Falling asleep..."
                hordeRequest.status = "active"
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

    func fetchPendingRequests() async -> [HordeRequest]? {
        return await withCheckedContinuation { continuation in
            mainManagedObjectContext.perform { [self] in
                do {
                    let fetchRequest1: NSFetchRequest<HordeRequest> = HordeRequest.fetchRequest()
                    fetchRequest1.predicate = NSPredicate(format: "status = %@", "active")
                    fetchRequest1.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]
                    let requests = try mainManagedObjectContext.fetch(fetchRequest1) as [HordeRequest]
                    continuation.resume(returning: requests)
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
                            request.status = done ? "done" : "active"
                            request.message = "\(waiting) sleeping, \(processing) dreaming, \(finished) waking"
                            if request.status == "done" {
                                request.message = "Deciphering \(finished) images..."
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

    func updatePendingRequestFinishedState(request: HordeRequest, status: RequestStatusStable, images: [GeneratedImage]) {
        let imageCount = images.count
        request.n = Int16(imageCount)
        request.message = "Finished!"
        if let kudosCost = (status.kudos as? NSDecimalNumber)?.intValue {
            request.totalKudosCost = Int16(kudosCost)
            request.message = "Kudos cost: \(kudosCost) total, ~\((kudosCost/imageCount)) per image"
        }
        request.status = "finished"

        let mutableItems = request.images?.mutableCopy() as? NSMutableOrderedSet ?? []
        mutableItems.addObjects(from: images)
        request.images = mutableItems.copy() as? NSOrderedSet

        saveContext()
    }

//    func fetchGames(completion: @escaping ([Game]?) -> Void) {
//        mainManagedObjectContext.perform {
//            do {
//                let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
//                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))]
//                let managedGames = try self.mainManagedObjectContext.fetch(fetchRequest) as [Game]
//                completion(managedGames)
//            } catch {
//                completion(nil)
//            }
//        }
//    }

//    func createGame(from gameStruct: GameStruct, completion: @escaping (Game?) -> Void) {
//        mainManagedObjectContext.perform {
//            do {
//                let game = Game(context: self.mainManagedObjectContext)
//                game.name = gameStruct.name
//                game.uuid = gameStruct.uuid
//                game.author = gameStruct.author ?? "Anonymous"
//                game.website = gameStruct.website
//                game.license = gameStruct.license
//                game.about = gameStruct.about
//                game.font = GameFont(jsonDescription: gameStruct.font) ?? .normal
//                try self.mainManagedObjectContext.save()
//
//                // Create Attributes
//                var attributesDict: [UUID: Attribute] = [:]
//                for attributeStruct in gameStruct.attributes {
//                    let attribute = Attribute(context: self.mainManagedObjectContext)
//                    attribute.uuid = attributeStruct.uuid
//                    attribute.name = attributeStruct.name
//                    attribute.game = game
//                    attributesDict[attributeStruct.uuid] = attribute
//                    try self.mainManagedObjectContext.save()
//                }
//
//                // Create Pages
//                var pagesDict: [UUID: Page] = [:]
//                for pageStruct in gameStruct.pages {
//                    let page = Page(context: self.mainManagedObjectContext)
//                    page.uuid = pageStruct.uuid
//                    page.content = pageStruct.content
//                    page.type = PageType(jsonDescription: pageStruct.type) ?? .none
//                    page.game = game
//                    pagesDict[pageStruct.uuid] = page
//                    try self.mainManagedObjectContext.save()
//                }
//
//                // Create Decisions
//                for pageStruct in gameStruct.pages {
//                    if let decisionStructs = pageStruct.decisions, !decisionStructs.isEmpty {
//                        for decisionStruct in decisionStructs {
//                            let decision = Decision(context: self.mainManagedObjectContext)
//                            decision.uuid = decisionStruct.uuid
//                            decision.content = decisionStruct.content
//                            decision.page = pagesDict[pageStruct.uuid]!
//                            if let destinationUUID = decisionStruct.destinationUuid {
//                                decision.destination = pagesDict[destinationUUID]!
//                            }
//                            try self.mainManagedObjectContext.save()
//
//                            // Create Rules
//                            if let ruleStructs = decisionStruct.rules, !ruleStructs.isEmpty {
//                                for ruleStruct in ruleStructs {
//                                    let rule = Rule(context: self.mainManagedObjectContext)
//                                    rule.uuid = ruleStruct.uuid
//                                    rule.value = ruleStruct.value
//                                    rule.type = RuleType(jsonDescription: ruleStruct.type) ?? .isEqualTo
//                                    if let attributeUUID = ruleStruct.attributeUuid {
//                                        rule.attribute = attributesDict[attributeUUID]!
//                                    }
//                                    rule.decision = decision
//                                    try self.mainManagedObjectContext.save()
//                                }
//                            }
//                        }
//                    }
//
//                    // Create Consequences
//                    if let consequenceStructs = pageStruct.consequences, !consequenceStructs.isEmpty {
//                        for consequenceStruct in consequenceStructs {
//                            let consequence = Consequence(context: self.mainManagedObjectContext)
//                            consequence.uuid = consequenceStruct.uuid
//                            consequence.amount = consequenceStruct.amount
//                            consequence.type = ConsequenceType(jsonDescription: consequenceStruct.type) ?? .set
//                            if let attributeUUID = consequenceStruct.attributeUuid {
//                                consequence.attribute = attributesDict[attributeUUID]
//                            }
//                            consequence.page = pagesDict[pageStruct.uuid]!
//                            try self.mainManagedObjectContext.save()
//                        }
//                    }
//                }
//
//                self.saveContext()
//                NotificationCenter.default.post(name: .didAddNewBook, object: nil)
//                completion(game)
//            } catch {
//                completion(nil)
//            }
//        }
//    }
//
//    func createGame(name: String, completion: @escaping (Game?) -> Void) {
//        mainManagedObjectContext.perform {
//            do {
//                let managedGame = Game(context: self.mainManagedObjectContext)
//                managedGame.name = name
//                managedGame.uuid = UUID()
//                try self.mainManagedObjectContext.save()
//                self.saveContext()
//                NotificationCenter.default.post(name: .didAddNewBook, object: nil)
//                completion(managedGame)
//            } catch {
//                completion(nil)
//            }
//        }
//    }
//
//    func fetchGames(completion: @escaping ([Game]?) -> Void) {
//        mainManagedObjectContext.perform {
//            do {
//                let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
//                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))]
//                let managedGames = try self.mainManagedObjectContext.fetch(fetchRequest) as [Game]
//                completion(managedGames)
//            } catch {
//                completion(nil)
//            }
//        }
//    }
//
//    func deleteGame(_ game: Game, completion: @escaping (Game?) -> Void) {
//        mainManagedObjectContext.delete(game)
//        saveContext()
//        completion(nil)
//    }
//
//    // MARK: - Pages
//
//    func fetchPage(by uuid: String, completion: @escaping (Page?) -> Void) {
//        mainManagedObjectContext.perform {
//            do {
//                let fetchRequest: NSFetchRequest<Page> = Page.fetchRequest()
//                fetchRequest.predicate = NSPredicate(format: "uuid == %@", uuid)
//                if let page = try? self.mainManagedObjectContext.fetch(fetchRequest).first {
//                    completion(page)
//                } else {
//                    completion(nil)
//                }
//            }
//        }
//    }
//
//    func fetchFirstPage(for game: Game, completion: @escaping (Page?) -> Void) {
//        mainManagedObjectContext.perform {
//            do {
//                let fetchRequest: NSFetchRequest<Page> = Page.fetchRequest()
//                fetchRequest.predicate = NSPredicate(format: "type == %@ && game == %@", NSNumber(value: PageType.first.rawValue), game)
//                if let managedPage = try self.mainManagedObjectContext.fetch(fetchRequest).first {
//                    completion(managedPage)
//                } else {
//                    self.createPage(
//                        for: game,
//                        content: "This first page has been automatically generated for you. Replace it with your own content!",
//                        type: .first,
//                        completion: { page in
//                            completion(page)
//                        }
//                    )
//                }
//            } catch {
//                completion(nil)
//            }
//        }
//    }
//
//    func fetchAllPages(for game: Game, completion: @escaping ([Page]?) -> Void) {
//        mainManagedObjectContext.perform {
//            do {
//                let fetchRequest: NSFetchRequest<Page> = Page.fetchRequest()
//                fetchRequest.predicate = NSPredicate(format: "game == %@ AND (origins.@count > 0 OR type == 1)", game)
//                let managedPages = try self.mainManagedObjectContext.fetch(fetchRequest) as [Page]
//                completion(managedPages)
//            } catch {
//                completion(nil)
//            }
//        }
//    }
//
//    func createPage(for game: Game, content: String, type: PageType, completion: @escaping (Page?) -> Void) {
//        mainManagedObjectContext.perform {
//            do {
//                let managedPage = Page(context: self.mainManagedObjectContext)
//                let savedContent = content
//                managedPage.content = savedContent
//                managedPage.type = type
//                managedPage.uuid = UUID()
//                managedPage.game = game
//                try self.mainManagedObjectContext.save()
//                self.saveContext()
//                completion(managedPage)
//            } catch {
//                completion(nil)
//            }
//        }
//    }
//
//    func deletePage(_ page: Page, completion: @escaping (Page?) -> Void) {
//        mainManagedObjectContext.delete(page)
//        saveContext()
//        completion(nil)
//    }
//
//    func searchPages(for game: Game, terms: String, completion: @escaping ([Page]) -> Void) {
//        fetchAllPages(for: game) { pages in
//            guard let pages = pages else { return completion([]) }
//            var filteredPages = [Page]()
//
//            for page in pages where page.content.lowercased().contains(terms.lowercased()) {
//                filteredPages.append(page)
//            }
//
//            completion(filteredPages)
//        }
//    }
//
//    // MARK: - Decisions
//
//    func createDecision(
//        for page: Page,
//        content: String,
//        destination: Page,
//        completion: @escaping (Decision?) -> Void
//    ) {
//        if page.type != .ending {
//            mainManagedObjectContext.perform {
//                do {
//                    let managedDecision = Decision(context: self.mainManagedObjectContext)
//                    managedDecision.content = content
//                    managedDecision.uuid = UUID()
//                    managedDecision.page = page
//                    managedDecision.destination = destination
//                    try self.mainManagedObjectContext.save()
//                    self.saveContext()
//                    completion(managedDecision)
//                } catch {
//                    completion(nil)
//                }
//            }
//        } else {
//            completion(nil)
//        }
//    }
//
//    func deleteDecision(_ decision: Decision, completion: @escaping (Decision?) -> Void) {
//        mainManagedObjectContext.delete(decision)
//        saveContext()
//        completion(nil)
//    }
//
//    // MARK: - Rules
//
//    func createRule(for decision: Decision, attribute _: Attribute?, type: RuleType?, value: Float?, completion: @escaping (Rule?) -> Void) {
//        mainManagedObjectContext.perform {
//            do {
//                let managedRule = Rule(context: self.mainManagedObjectContext)
//                managedRule.uuid = UUID()
//                managedRule.decision = decision
//                managedRule.value = value ?? 0
//                managedRule.type = type ?? .isEqualTo
//                try self.mainManagedObjectContext.save()
//                self.saveContext()
//                completion(managedRule)
//            } catch {
//                completion(nil)
//            }
//        }
//    }
//
//    func deleteRule(_ rule: Rule, completion: @escaping (Rule?) -> Void) {
//        mainManagedObjectContext.delete(rule)
//        saveContext()
//        completion(nil)
//    }
//
//    // MARK: - Consequences
//
//    func createConsequence(
//        for page: Page,
//        attribute: Attribute?,
//        type: ConsequenceType?,
//        amount: Float,
//        completion: @escaping (Consequence?) -> Void
//    ) {
//        if page.type != .ending {
//            mainManagedObjectContext.perform {
//                do {
//                    let managedConsequence = Consequence(context: self.mainManagedObjectContext)
//                    managedConsequence.uuid = UUID()
//                    managedConsequence.page = page
//                    managedConsequence.type = type ?? .add
//                    managedConsequence.amount = amount
//                    managedConsequence.attribute = attribute
//                    try self.mainManagedObjectContext.save()
//                    self.saveContext()
//                    completion(managedConsequence)
//                } catch {
//                    completion(nil)
//                }
//            }
//        } else {
//            completion(nil)
//        }
//    }
//
//    func deleteConsequence(_ consequence: Consequence, completion: @escaping (Consequence?) -> Void) {
//        mainManagedObjectContext.delete(consequence)
//        saveContext()
//        completion(nil)
//    }
//
//    // MARK: - Attributes
//
//    func createAttribute(for game: Game, name: String, completion: @escaping (Attribute?) -> Void) {
//        mainManagedObjectContext.perform {
//            do {
//                let managedAttribute = Attribute(context: self.mainManagedObjectContext)
//                managedAttribute.name = name
//                managedAttribute.uuid = UUID()
//                managedAttribute.game = game
//                try self.mainManagedObjectContext.save()
//                self.saveContext()
//                completion(managedAttribute)
//            } catch {
//                completion(nil)
//            }
//        }
//    }
//
//    func fetchAllAttributes(for game: Game, completion: @escaping ([Attribute]?) -> Void) {
//        do {
//            let fetchRequest: NSFetchRequest<Attribute> = Attribute.fetchRequest()
//            fetchRequest.predicate = NSPredicate(format: "game == %@", game)
//            let managedAttributes = try mainManagedObjectContext.fetch(fetchRequest) as [Attribute]
//            completion(managedAttributes)
//        } catch {
//            completion(nil)
//        }
//    }
//
//    func deleteAttribute(_ attribute: Attribute, completion: @escaping (Attribute?) -> Void) {
//        mainManagedObjectContext.delete(attribute)
//        saveContext()
//        completion(nil)
//    }
}
