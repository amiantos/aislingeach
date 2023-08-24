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
    let predicate: NSPredicate
    let title: String

    init(predicate: NSPredicate, title: String) {
        self.predicate = predicate
        self.title = title
    }
}

class AlbumsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var showHidden: Bool = false

    var isLoading: Bool = false

    var albums: [AlbumStruct] = []

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
            let addAlbumButton = UIBarButtonItem(image: UIImage(systemName: "rectangle.stack.fill.badge.plus"), style: .plain, target: self, action: nil)
            navigationItem.rightBarButtonItems = [addAlbumButton, menuButton]
            menuButton.menu = UIMenu(children: [
                UIAction(
                    title: "Show hidden gallery",
                    image: UIImage(systemName: "eye.slash"),
                    state: .off,
                    handler: { [self] _ in
                        showHiddenGallery()
                    }
                )
            ])
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

        albums = [
            AlbumStruct(
                predicate: NSPredicate(format: "isHidden = %d", self.showHidden),
                title: "Recents"
            ),
            AlbumStruct(
                predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "isFavorite = %d", true),
                    NSPredicate(format: "isHidden = %d", self.showHidden)
                ]),
                title: "Favorites"
            ),
            AlbumStruct(
                predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "promptSimple CONTAINS %@", "Eyre"),
                    NSPredicate(format: "isHidden = %d", self.showHidden)
                ]),
                title: "Eyre"
            ),
            AlbumStruct(
                predicate:  NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "promptSimple CONTAINS %@", "end of the world"),
                    NSPredicate(format: "isHidden = %d", self.showHidden)
                ]),
                title: "end of the world"
            ),
            AlbumStruct(
                predicate:  NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "promptSimple CONTAINS %@", "Keith Haring"),
                    NSPredicate(format: "isHidden = %d", self.showHidden)
                ]),
                title: "Keith Haring"
            ),
            AlbumStruct(
                predicate:  NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "promptSimple CONTAINS %@", "Christina Ricci"),
                    NSPredicate(format: "isHidden = %d", self.showHidden)
                ]),
                title: "Christina Ricci"
            ),
            AlbumStruct(
                predicate:  NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "promptSimple CONTAINS %@", "bread"),
                    NSPredicate(format: "isHidden = %d", self.showHidden)
                ]),
                title: "bread"
            )
        ]

        self.collectionView.reloadData()
        self.isLoading = false

    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in _: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albums.count
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 0, height: 0)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "albumCell", for: indexPath) as! AlbumCollectionViewCell

        let foundAlbum = albums[indexPath.row]
        cell.setup(predicate: foundAlbum.predicate, title: foundAlbum.title)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? AlbumCollectionViewCell else { return }
        cell.loadData()
    }

    override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "imageGalleryView") as! ThumbnailBrowserViewController
        let data = albums[indexPath.row]
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
