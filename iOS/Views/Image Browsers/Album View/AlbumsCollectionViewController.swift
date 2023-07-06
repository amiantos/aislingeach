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

    var showHidden: Bool = false

    var presetAlbums: [AlbumStruct] = []
    var promptAlbums: [AlbumStruct] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        if showHidden {
            navigationItem.title = "Hidden Gallery"
        }

        presetAlbums = [
            AlbumStruct(prompt: "All Images", count: "200 Images", predicate: NSPredicate(format: "isHidden = %d", showHidden), title: "All Images", protected: false),
            AlbumStruct(prompt: "Favorites", count: "200 Images", predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "isFavorite = %d", true), NSPredicate(format: "isHidden = %d", showHidden)]), title: "Favorites", protected: false)
        ]

        // Do any additional setup after loading the view.
        ImageDatabase.standard.getPopularPromptKeywords(hidden: showHidden) { [self] keywords in
            let sortedResults = keywords.sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.lowercased() < rhs.key.lowercased()
                }
                return lhs.value > rhs.value
            }

            for data in sortedResults {
                promptAlbums.append(
                    AlbumStruct(
                        prompt: data.key,
                        count: "\(data.value) Images",
                        predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "promptSimple CONTAINS %@", data.key), NSPredicate(format: "isHidden = %d", showHidden)]),
                        title: data.key,
                        protected: false
                    )
                )
            }
            collectionView.reloadData()
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
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return presetAlbums.count
        case 1:
            return promptAlbums.count
        default:
            return 0
        }

    }

   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
       if section == 0 {
           return CGSize(width: 0, height: 0)
       } else {
           let indexPath = IndexPath(row: 0, section: section)
           let headerView = self.collectionView(collectionView, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath)

           // Use this view to calculate the optimal size based on the collection view's width
           return headerView.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width, height: UIView.layoutFittingExpandedSize.height),
                                                     withHorizontalFittingPriority: .required, // Width is fixed
                                                     verticalFittingPriority: .fittingSizeLevel) // Height can be as large as needed
       }
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "albumSectionTitle", for: indexPath) as? AlbumSectionTitleCollectionReusableView {
            switch (indexPath.section) {
            case 1:
                sectionHeader.sectionLabel.text = "Prompt Keywords"
            default:
                sectionHeader.sectionLabel.text = "Section \(indexPath.section)"
            }

                return sectionHeader
            }
            return UICollectionReusableView()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "albumCell", for: indexPath) as! AlbumCollectionViewCell

            let data = presetAlbums[indexPath.row]
            cell.setup(prompt: data.prompt, count: data.count, predicate: data.predicate, title: data.title)

            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "simpleAlbumCell", for: indexPath) as! AlbumSimpleCollectionViewCell

        let data = promptAlbums[indexPath.row]
        cell.setup(prompt: data.prompt, count: data.count, predicate: data.predicate, title: data.title)

        return cell

    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "imageGalleryView") as! ThumbnailBrowserViewController
        let data = indexPath.section == 0 ? presetAlbums[indexPath.row] : promptAlbums[indexPath.row]
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

    private let sectionInsets = UIEdgeInsets(
        top: 8,
        left: 8,
        bottom: 8,
        right: 8
    )

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            let itemsPerRow: CGFloat = indexPath.section == 0 ? 2 : 1
            let paddingSpace = (sectionInsets.left + collectionView.contentInset.left) * (itemsPerRow + 1)
            let availableWidth = view.frame.width - paddingSpace
            let widthPerItem = availableWidth / itemsPerRow
            let heightPerItem: CGFloat = indexPath.section == 0 ? widthPerItem : 60
            return CGSize(width: widthPerItem, height: heightPerItem)
        } else {
            let cell = self.collectionView(collectionView, cellForItemAt: indexPath)

            // Use this view to calculate the optimal size based on the collection view's width
            return cell.systemLayoutSizeFitting(CGSize(width: collectionView.frame.width - ((sectionInsets.left + collectionView.contentInset.left)*2), height: UIView.layoutFittingExpandedSize.height),
                                                withHorizontalFittingPriority: .required, // Width is fixed
                                                verticalFittingPriority: .fittingSizeLevel) // Height can be as large as needed
        }
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
