//
//  AlbumsCollectionViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 7/4/23.
//

import LocalAuthentication
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
    var smartAlbums: [AlbumStruct] = []

    var menuButton: UIBarButtonItem = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        if showHidden {
            navigationItem.title = "Hidden Gallery"
        } else {
            // setup menu
            menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: nil)
            navigationItem.rightBarButtonItems = [menuButton]
            menuButton.menu = UIMenu(children: [UIAction(title: "Show hidden gallery", image: UIImage(systemName: "eye.slash"), state: .off, handler: { [self] _ in
                showHiddenGallery()
            })])
        }

        NotificationCenter.default.addObserver(self, selector: #selector(loadDataSource), name: .imageDatabaseUpdated, object: nil)

        loadDataSource()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func showHiddenGallery() {
        let context = LAContext()
        let reason = "Get access to your hidden gallery"
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { success, _ in
            if success {
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let controller = storyboard.instantiateViewController(withIdentifier: "albumGalleryView") as! AlbumsCollectionViewController
                    controller.showHidden = true
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            }
        }
    }

    @objc fileprivate func loadDataSource() {
        if isLoading { return }

        isLoading = true

        presetAlbums = []
        promptAlbums = []

        Task {
            let recentImagesPredicate = NSPredicate(format: "isHidden = %d", self.showHidden)
            let recentImagesResult = await ImageDatabase.standard.getCountAndRecentImageForPredicate(predicate: recentImagesPredicate)
            presetAlbums.append(
                AlbumStruct(
                    count: recentImagesResult.0.formatted(),
                    predicate: recentImagesPredicate,
                    title: "Recents",
                    image: recentImagesResult.1
                )
            )

            let favoriteImagesPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "isFavorite = %d", true),
                NSPredicate(format: "isHidden = %d", self.showHidden)
            ])
            let favoriteImagesResult = await ImageDatabase.standard.getCountAndRecentImageForPredicate(predicate: favoriteImagesPredicate)
            presetAlbums.append(
                AlbumStruct(
                    count: favoriteImagesResult.0.formatted(),
                    predicate: favoriteImagesPredicate,
                    title: "Favorites",
                    image: favoriteImagesResult.1
                )
            )

            let smartAlbumPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "promptSimple CONTAINS %@", "Eyre"),
                NSPredicate(format: "isHidden = %d", self.showHidden)
            ])
            let smartAlbumResult = await ImageDatabase.standard.getCountAndRecentImageForPredicate(predicate: smartAlbumPredicate)
            smartAlbums.append(AlbumStruct(count: smartAlbumResult.0.formatted(), predicate: smartAlbumPredicate, title: "Eyre", image: smartAlbumResult.1))

            let smartAlbumPredicate2 = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "promptSimple CONTAINS %@", "end of the world"),
                NSPredicate(format: "isHidden = %d", self.showHidden)
            ])
            let smartAlbumResult2 = await ImageDatabase.standard.getCountAndRecentImageForPredicate(predicate: smartAlbumPredicate2)
            smartAlbums.append(AlbumStruct(count: smartAlbumResult2.0.formatted(), predicate: smartAlbumPredicate2, title: "end of the world", image: smartAlbumResult2.1))

            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.isLoading = false
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
            return smartAlbums.count
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
                sectionHeader.sectionLabel.text = smartAlbums.count > 0 ? "Your Albums" : ""
            default:
                sectionHeader.sectionLabel.text = "Section \(indexPath.section)"
            }

            return sectionHeader
        }
        return UICollectionReusableView()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "albumCell", for: indexPath) as! AlbumCollectionViewCell

        var album: AlbumStruct?
        if indexPath.section == 0 {
            album = presetAlbums[indexPath.row]
        } else {
            album = smartAlbums[indexPath.row]
        }
        guard let foundAlbum = album else { fatalError() }
        cell.setup(count: foundAlbum.count, predicate: foundAlbum.predicate, title: foundAlbum.title, image: foundAlbum.image)
        return cell
    }

    override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "imageGalleryView") as! ThumbnailBrowserViewController
        let data = indexPath.section == 0 ? presetAlbums[indexPath.row] : smartAlbums[indexPath.row]
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

        let itemsPerRow: CGFloat = 2
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
