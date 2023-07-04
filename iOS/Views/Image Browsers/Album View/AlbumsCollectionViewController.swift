//
//  AlbumsCollectionViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 7/4/23.
//

import UIKit
import LocalAuthentication
import CoreData

private let reuseIdentifier = "albumCell"

struct AlbumStruct {
    var prompt: String
    var count: String
    var predicate: NSPredicate
    var title: String
    var protected: Bool
}

class AlbumsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var presetAlbums: [AlbumStruct] = [
        AlbumStruct(prompt: "All Images", count: "200 Images", predicate: NSPredicate(format: "isHidden = %d", false), title: "All Images", protected: false),
        AlbumStruct(prompt: "Favorites", count: "200 Images", predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "isFavorite = %d", true), NSPredicate(format: "isHidden = %d", false)]), title: "Favorites", protected: false),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "GeneratedImage")
        let keypathExp = NSExpression(forKeyPath: "promptSimple")
        let expression = NSExpression(forFunction: "count:", arguments: [keypathExp])

        let expression2 = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "dateCreated")])

        let maxDate = NSExpressionDescription()
        maxDate.expression = expression2
        maxDate.name = "date"
        maxDate.expressionResultType = .dateAttributeType

        let countDesc = NSExpressionDescription()
        countDesc.expression = expression
        countDesc.name = "count"
        countDesc.expressionResultType = .integer64AttributeType

        fetchRequest.predicate = NSPredicate(format: "isHidden = %d", false)
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.propertiesToGroupBy = ["promptSimple"]
        fetchRequest.propertiesToFetch = ["promptSimple", countDesc, maxDate]
        fetchRequest.resultType = .dictionaryResultType

        do {
            let results = try ImageDatabase.standard.mainManagedObjectContext.fetch(fetchRequest) as? [AnyObject]

            let sortedResults = (results as! NSArray).sortedArray(using: [NSSortDescriptor(key: "date", ascending: false)]) as! [[String:AnyObject]]
            for data in sortedResults {
                if let prompt = data["promptSimple"] as? String, let count = data["count"] as? Int {
                    presetAlbums.append(
                        AlbumStruct(
                            prompt: prompt,
                            count: "\(count) Images",
                            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "promptSimple = %@", prompt), NSPredicate(format: "isHidden = %d", false)]),
                            title: prompt,
                            protected: false
                        )
                    )
                }
            }
            presetAlbums.append(contentsOf: [AlbumStruct(prompt: "Hidden Images", count: "200 Images", predicate: NSPredicate(format: "isHidden = %d", true), title: "Hidden Images", protected: true), AlbumStruct(prompt: "Hidden Favorites", count: "200 Images", predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "isFavorite = %d", true), NSPredicate(format: "isHidden = %d", true)]), title: "Hidden Favorites", protected: true)])
        } catch {
            print("Error fetching grouped and counted records: \(error.localizedDescription)")
        }


    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return presetAlbums.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumCollectionViewCell
    
        let data = presetAlbums[indexPath.row]
        cell.setup(prompt: data.prompt, count: data.count, predicate: data.predicate, title: data.title)
    
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "imageGalleryView") as! ThumbnailBrowserViewController
        let data = presetAlbums[indexPath.row]
        if data.protected {
            let context = LAContext()
            let reason = "Get access to Hidden Content"
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            ) { success, error in
                if success {
                    DispatchQueue.main.async {
                        controller.setup(title: data.title, predicate: data.predicate)
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                }
            }
        } else {
            controller.setup(title: data.title, predicate: data.predicate)
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    // MARK: UICollectionViewDelegateFlowLayout

    private let itemsPerRow: CGFloat = 2
    private let sectionInsets = UIEdgeInsets(
        top: 2,
        left: 2,
        bottom: 2,
        right: 2
    )

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let paddingSpace = (sectionInsets.left + collectionView.contentInset.left) * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return sectionInsets.left
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
