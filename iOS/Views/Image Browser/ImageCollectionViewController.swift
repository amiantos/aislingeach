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
    var editButton: UIBarButtonItem = .init()

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
        editButton = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(toggleEditing))

        navigationItem.rightBarButtonItems = [menuButton, editButton]

        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.allowsMultipleSelectionDuringEditing = true
        setEditing(false, animated: false)
        menuButton.isEnabled = false

        setupDataSource()

        setupMenu()
    }

    @objc func toggleEditing() {
        setEditing(!isEditing, animated: true)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        if isEditing != editing {
            super.setEditing(editing, animated: animated)
            collectionView.isEditing = editing

            if !editing {
                // Clear selection if leaving edit mode.
                collectionView.indexPathsForSelectedItems?.forEach { indexPath in
                    collectionView.deselectItem(at: indexPath, animated: animated)
                }
            }
            setupMenu()
        }
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
        if isEditing {
            menuButton.isEnabled = isEditing
        } else {
            guard let object = resultsController?.object(at: indexPath) else {
                fatalError("Attempt to configure cell without a managed object")
            }

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "imageDetailViewController") as! ImageDetailViewController
            controller.generatedImage = object
            navigationController?.pushViewController(controller, animated: true)

            guard let cell = collectionView.cellForItem(at: indexPath) else { fatalError("No cell found, weird!") }
            cell.isSelected = false
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt _: IndexPath) {
        if let items = collectionView.indexPathsForSelectedItems, items.isEmpty {
            menuButton.isEnabled = false
        }

        if collectionView.indexPathsForSelectedItems == nil {
            menuButton.isEnabled = false
        }
    }

    override func collectionView(_: UICollectionView, shouldBeginMultipleSelectionInteractionAt _: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_: UICollectionView, didBeginMultipleSelectionInteractionAt _: IndexPath) {
        // Replace the Select button with Done, and put the
        // collection view into editing mode.
        setEditing(true, animated: true)
    }

//    override func collectionViewDidEndMultipleSelectionInteraction(_: UICollectionView) {
//        print("\(#function)")
//    }

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
        editButton.title = isEditing ? "Done" : "Select"

        var menuItems: [UIMenuElement] = []

        if viewFolder == "main", !isEditing {
            let hiddenMenuItemTitle = showHiddenItems ? "Hide Hidden" : "Show Hidden"
            let hiddenMenuItemImage = showHiddenItems ? UIImage(systemName: "eye") : UIImage(systemName: "eye.slash")
            menuItems.append(UIAction(title: hiddenMenuItemTitle, image: hiddenMenuItemImage, handler: { _ in
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
        }

        if isEditing {
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
                }),
            ])
            menuItems.append(editActions)
        }

        menuButton.menu = UIMenu(children: menuItems)

        if !isEditing { menuButton.isEnabled = false }
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
            self.toggleEditing()
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
                    self.toggleEditing()
                }
            } else {
                ImageDatabase.standard.unHideImages(images) { _ in
                    self.toggleEditing()
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
                    self.toggleEditing()
                }
            } else {
                ImageDatabase.standard.favoriteImages(images) { _ in
                    self.toggleEditing()
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
