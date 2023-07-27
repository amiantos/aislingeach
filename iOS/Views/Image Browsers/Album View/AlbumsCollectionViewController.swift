//
//  AlbumsCollectionViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 7/4/23.
//

import CoreData
import UIKit

private let reuseIdentifier = "albumCell"

class AlbumStruct {
    let count: String
    let predicate: NSPredicate
    let title: String
    let image: GeneratedImage?

    init(count: String, predicate: NSPredicate, title: String, image: GeneratedImage?) {
        self.count = count
        self.predicate = predicate
        self.title = title
        self.image = image
    }
}

class AlbumsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var showHidden: Bool = false

    var isLoading: Bool = false

    var presetAlbums: [AlbumStruct] = []
    var promptAlbums: [AlbumStruct] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        if showHidden {
            navigationItem.title = "Hidden Gallery"
        }

        loadDataSource()
    }

    @objc fileprivate func loadDataSource() {
        if isLoading { return }

        isLoading = true

        presetAlbums = []
        promptAlbums = []

        ImageDatabase.standard.getCountAndRecentImageForPredicate(predicate: NSPredicate(format: "isHidden = %d", showHidden)) { result in
            self.presetAlbums.append(AlbumStruct(count: "\((result.0).formatted())", predicate: NSPredicate(format: "isHidden = %d", self.showHidden), title: "Recents", image: result.1))
        }

        ImageDatabase.standard.getCountAndRecentImageForPredicate(predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "isFavorite = %d", true), NSPredicate(format: "isHidden = %d", showHidden)])) { result in
            self.presetAlbums.append(AlbumStruct(count: "\((result.0).formatted())", predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "isFavorite = %d", true), NSPredicate(format: "isHidden = %d", self.showHidden)]), title: "Favorites", image: result.1))
        }

        // Do any additional setup after loading the view.
        DispatchQueue.global().async { [self] in
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
                            count: "\(data.value.formatted())",
                            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "promptSimple CONTAINS %@", data.key), NSPredicate(format: "isHidden = %d", showHidden)]),
                            title: data.key,
                            image: nil
                        )
                    )
                }
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.isLoading = false
                }
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in _: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return presetAlbums.count
        case 1:
            return promptAlbums.count
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
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
            if indexPath.section == 0 {
                return UICollectionReusableView()
            }
            switch indexPath.section {
            case 1:
                sectionHeader.sectionLabel.text = promptAlbums.count > 0 ? "Prompt Keywords" : ""
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
            cell.setup(count: data.count, predicate: data.predicate, title: data.title, image: data.image)

            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "simpleAlbumCell", for: indexPath) as! AlbumSimpleCollectionViewCell

        let data = promptAlbums[indexPath.row]
        cell.setup(count: data.count, predicate: data.predicate, title: data.title)

        return cell
    }

    override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "imageGalleryView") as! ThumbnailBrowserViewController
        let data = indexPath.section == 0 ? presetAlbums[indexPath.row] : promptAlbums[indexPath.row]
        controller.setup(title: data.title, predicate: data.predicate)
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: UICollectionViewDelegateFlowLayout

    private let sectionInsets = UIEdgeInsets(
        top: 0,
        left: 0,
        bottom: 0,
        right: 0
    )

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = self.collectionView(collectionView, cellForItemAt: indexPath)

        let itemsPerRow: CGFloat = indexPath.section == 0 ? 2 : 1
        let widthPerItem = (collectionView.safeAreaLayoutGuide.layoutFrame.width - 1) / itemsPerRow
        return cell.systemLayoutSizeFitting(CGSize(width: widthPerItem, height: UIView.layoutFittingExpandedSize.height),
                                            withHorizontalFittingPriority: .required, // Width is fixed
                                            verticalFittingPriority: .fittingSizeLevel) // Height can be as large as needed
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
