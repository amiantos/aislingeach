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

enum AlbumType {
    case normal
    case keyword
}

class Album {
    let predicate: NSPredicate
    let title: String
    var count: Int?
    var generatedImage: GeneratedImage?

    init( predicate: NSPredicate, title: String, count: Int? = nil, generatedImage: GeneratedImage? = nil) {
        self.predicate = predicate
        self.title = title
        self.count = count
        self.generatedImage = generatedImage
    }
}

class AlbumsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var showHidden: Bool = false

    var isLoading: Bool = false

    var presetAlbums: [Album] = []
    var promptAlbums: [Album] = []
    var smartAlbums: [Album] = []

    var menuButton: UIBarButtonItem = .init()

    var infoCache: [String: (Int, GeneratedImage?)] = [:]

    @IBOutlet weak var layout: UICollectionViewFlowLayout!

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
        Task {
            let recentsResult = await ImageDatabase.standard.getCountAndRecentImage(hidden: self.showHidden, favorite: false)
            let favoritesResult = await ImageDatabase.standard.getCountAndRecentImage(hidden: self.showHidden, favorite: true)
            presetAlbums = [
                Album(
                    predicate: NSPredicate(format: "isHidden = %d", self.showHidden),
                    title: "Recents",
                    count: recentsResult.0,
                    generatedImage: recentsResult.1
                ),
                Album(
                    predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "isFavorite = %d", true),
                        NSPredicate(format: "isHidden = %d", self.showHidden)
                    ]),
                    title: "Favorites",
                    count: favoritesResult.0,
                    generatedImage: favoritesResult.1
                )
            ]
            smartAlbums = []
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }

            let result = await ImageDatabase.standard.getPopularPromptKeywords(hidden: self.showHidden)
            let sortedResults = result.sorted { lhs, rhs in
                return lhs.key.replacingOccurrences(of: "(", with: "").lowercased() < rhs.key.replacingOccurrences(of: "(", with: "").lowercased()
            }


            for data in sortedResults {
                smartAlbums.append(
                    Album(
                        predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "promptSimple CONTAINS %@", data.key), NSPredicate(format: "isHidden = %d", self.showHidden)]),
                        title: data.key
                    )
                )
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.isLoading = false
            }
        }

        self.collectionView.reloadData()
        self.isLoading = false
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in _: UICollectionView) -> Int {
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

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "albumSectionTitle", for: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        if let sectionHeader = view as? AlbumSectionTitleCollectionReusableView {
            sectionHeader.sectionLabel.text = indexPath.section != 0 ? "Recent Phrases" : "Collections"
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "albumCell", for: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? AlbumCollectionViewCell {
            var album: Album?
            if indexPath.section == 0 {
                album = presetAlbums[indexPath.row]
            } else {
                album = smartAlbums[indexPath.row]
            }
            guard let foundAlbum = album else { fatalError() }
            cell.setup(album: foundAlbum)
            cell.willDisplay()
        }
    }

    override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "imageGalleryView") as! ThumbnailBrowserViewController
        let data = indexPath.section == 0 ? presetAlbums[indexPath.row] : smartAlbums[indexPath.row]
        controller.setup(title: data.title, predicate: data.predicate)
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentHorizontalSpaces = layout.minimumInteritemSpacing + layout.sectionInset.left + layout.sectionInset.right
        let newCellWidth = (collectionView.bounds.width - contentHorizontalSpaces) / 2
        let data = indexPath.section == 0 ? presetAlbums[indexPath.row] : smartAlbums[indexPath.row]
        let newHeight = AlbumCollectionViewCell.getProductHeightForWidth(props: data, width: newCellWidth)
        Log.debug("returning \(newCellWidth)x\(newHeight)")
        return CGSize(width: newCellWidth, height: newHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 {
            Log.debug("Section 0, returning 0...")
            return CGSize.zero
        }
        return CGSize(
            width: collectionView.bounds.width,
            height: "Recent Phrases".getHeight(font: UIFont.preferredFont(forTextStyle: .title2), width: collectionView.bounds.width) + 28
        )
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
