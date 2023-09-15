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
            let recentsResult = await ImageDatabase.standard.getCountAndRecentImageForPredicate(predicate: NSPredicate(format: "isHidden = %d", self.showHidden))
            let favoritesResult = await ImageDatabase.standard.getCountAndRecentImageForPredicate(predicate:NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "isFavorite = %d", true),
                NSPredicate(format: "isHidden = %d", self.showHidden)
            ]))
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
                sectionHeader.sectionLabel.text = smartAlbums.count > 0 ? "Recent Phrases" : ""
            default:
                sectionHeader.sectionLabel.text = "Section \(indexPath.section)"
            }

            return sectionHeader
        }
        return UICollectionReusableView()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "albumCell", for: indexPath) as! AlbumCollectionViewCell

        var album: Album?
        if indexPath.section == 0 {
            album = presetAlbums[indexPath.row]
        } else {
            album = smartAlbums[indexPath.row]
        }
        guard let foundAlbum = album else { fatalError() }
        cell.setup(album: foundAlbum)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let albumCell = cell as? AlbumCollectionViewCell else { return }
        albumCell.willDisplay()
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
