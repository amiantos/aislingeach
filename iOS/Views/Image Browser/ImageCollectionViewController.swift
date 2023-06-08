//
//  ImageCollectionViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/28/23.
//

import CoreData
import UIKit

private let reuseIdentifier = "imageCell"

class ImageCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout {
    var resultsController: NSFetchedResultsController<GeneratedImage>?

    var menuButton: UIBarButtonItem = .init()

    var showHiddenItems: Bool = false

    var viewFolder: String = "main"

    var multiSelectMode: Bool = false

    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = UIEdgeInsets(
        top: 2,
        left: 2,
        bottom: 2,
        right: 2
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true

        // setup menu
        menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: nil)
        navigationItem.rightBarButtonItem = menuButton

        setupDataSource()

        setupMenu()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout _: UICollectionViewLayout,
        sizeForItemAt _: IndexPath
    ) -> CGSize {
        // 2
        let paddingSpace = (sectionInsets.left + collectionView.contentInset.left) * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        return CGSize(width: widthPerItem, height: widthPerItem)
    }

    // 3
    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        insetForSectionAt _: Int
    ) -> UIEdgeInsets {
        return sectionInsets
    }

    // 4
    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        minimumLineSpacingForSectionAt _: Int
    ) -> CGFloat {
        return sectionInsets.left
    }

    var ops: [BlockOperation] = []

    func controller(_: NSFetchedResultsController<NSFetchRequestResult>, didChange _: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            ops.append(BlockOperation(block: { [weak self] in
                self?.collectionView.insertItems(at: [newIndexPath!])
            }))
        case .delete:
            ops.append(BlockOperation(block: { [weak self] in
                self?.collectionView.deleteItems(at: [indexPath!])
            }))
        case .update:
            ops.append(BlockOperation(block: { [weak self] in
                self?.collectionView.reloadItems(at: [indexPath!])
            }))
        case .move:
            ops.append(BlockOperation(block: { [weak self] in
                self?.collectionView.moveItem(at: indexPath!, to: newIndexPath!)
            }))
        @unknown default:
            break
        }
    }

    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({ () in
            for op: BlockOperation in self.ops { op.start() }
        }, completion: { _ in self.ops.removeAll() })
    }

    deinit {
        for o in ops { o.cancel() }
        ops.removeAll()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in _: UICollectionView) -> Int {
        if let frc = resultsController {
            return frc.sections!.count
        }
        return 0
    }

    override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = resultsController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        print(sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
        guard let object = resultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        // Configure the cell
        cell.setup(object: object)
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !multiSelectMode {
            guard let object = resultsController?.object(at: indexPath) else {
                fatalError("Attempt to configure cell without a managed object")
            }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "imageDetailViewController") as! ImageDetailViewController
            controller.generatedImage = object
            navigationController?.pushViewController(controller, animated: true)
        }
    }

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

extension ImageCollectionViewController {
    func setupMenu() {
        var menuItems: [UIMenuElement] = []

        menuItems.append(UIAction(title: "Toggle Selection Mode", image: UIImage(systemName: "selection.pin.in.out"), handler: { action in
            self.toggleSelectionMode()
        }))


        if viewFolder == "main" && !multiSelectMode {
            let hiddenMenuItemTitle = showHiddenItems ? "Hide Hidden" : "Show Hidden"
            let hiddenMenuItemImage = showHiddenItems ? UIImage(systemName: "eye") : UIImage(systemName: "eye.slash")
            menuItems.append(UIAction(title: hiddenMenuItemTitle, image: hiddenMenuItemImage, handler: { action in
                if self.showHiddenItems == false {
                    let alert = UIAlertController(title: "Show Hidden Items", message: "Are you... sure you want to do this?", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .destructive) { _ in
                        self.toggleHiddenItems()
                    }
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                    alert.addAction(okAction)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true)
                } else {
                    self.toggleHiddenItems()
                }
            }))
            menuItems.append(UIAction(title: "Prune Gallery", image: UIImage(systemName: "trash"), handler: { action in
                let alert = UIAlertController(title: "Prune Image History", message: "This action will delete all images from your library that are not marked as a Favorite nor are Hidden. Are you sure you want to continue?", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .destructive) { _ in
                    ImageDatabase.standard.pruneImages()
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                alert.addAction(okAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true)
            }))
        }

        if multiSelectMode {
            let editActions = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "Favorite", image: UIImage(systemName: "star"), state: .off, handler: { [self] _ in
                    favoriteSelectedImages()
                }),
//                UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up"), state: .off, handler: { [self] _ in
//                    Log.debug("Share button pressed...")
//                }),
                UIAction(title: "Hide", image: UIImage(systemName: "eye.slash"), state: .off, handler: { [self] _ in
                    hideSelectedImages()
                }),
                UIAction(title: "Delete", image: UIImage(systemName: "trash"), state: .off, handler: { [self] _ in
                    deleteSelectedImages()
                })
            ])
            menuItems.append(editActions)
        }

        menuButton.menu = UIMenu(children: menuItems)
    }

    func setupDataSource() {
        let fetchRequest = NSFetchRequest<GeneratedImage>(entityName: "GeneratedImage")
        // Configure the request's entity, and optionally its predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]

        var title = "All Images"
        var predicate = NSPredicate(format: "isHidden = %d", false)
        if viewFolder == "hidden" {
            title = "Hidden Images"
            predicate = NSPredicate(format: "isHidden = %d", true)
        }
        navigationItem.title = title
        fetchRequest.predicate = predicate

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: ImageDatabase.standard.mainManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        resultsController = controller
        controller.delegate = self
        do {
            try controller.performFetch()
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }

    func toggleHiddenItems() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "imageGalleryView") as! ImageCollectionViewController
        controller.viewFolder = "hidden"
        navigationController?.pushViewController(controller, animated: true)
    }

    func deleteSelectedImages() {
        if let selectedCells = collectionView.indexPathsForSelectedItems {
            var images: [GeneratedImage] = []
            selectedCells.forEach { indexPath in
                guard let object = resultsController?.object(at: indexPath) else {
                    fatalError("Attempt to configure cell without a managed object")
                }
                images.append(object)
            }
            ImageDatabase.standard.deleteImages(images)
            toggleSelectionMode()
        }
    }

    func hideSelectedImages() {
        if let selectedCells = collectionView.indexPathsForSelectedItems {
            var images: [GeneratedImage] = []
            selectedCells.forEach { indexPath in
                guard let object = resultsController?.object(at: indexPath) else {
                    fatalError("Attempt to configure cell without a managed object")
                }
                images.append(object)
            }
            // Check hidden status for all items
            var allShowing = true
            for image in images {
                if image.isHidden {
                    allShowing = false
                    break
                }
            }
            if allShowing {
                ImageDatabase.standard.hideImages(images) { _ in
                    self.toggleSelectionMode()
                }
            } else {
                ImageDatabase.standard.unHideImages(images) { _ in
                    self.toggleSelectionMode()
                }
            }
        }
    }

    func favoriteSelectedImages() {
        if let selectedCells = collectionView.indexPathsForSelectedItems {
            var images: [GeneratedImage] = []
            selectedCells.forEach { indexPath in
                guard let object = resultsController?.object(at: indexPath) else {
                    fatalError("Attempt to configure cell without a managed object")
                }
                images.append(object)
            }
            // Check hidden status for all items
            var allFavorites = true
            for image in images {
                if !image.isFavorite {
                    allFavorites = false
                    break
                }
            }
            if allFavorites {
                ImageDatabase.standard.unFavoriteImages(images) { _ in
                    self.toggleSelectionMode()
                }
            } else {
                ImageDatabase.standard.favoriteImages(images) { _ in
                    self.toggleSelectionMode()
                }
            }
        }
    }

    func toggleSelectionMode() {
        multiSelectMode = !multiSelectMode
        collectionView.allowsSelection = false
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = multiSelectMode
        setupMenu()
    }
}
