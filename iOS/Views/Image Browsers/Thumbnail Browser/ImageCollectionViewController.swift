//
//  ThumbnailBrowserViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/28/23.
//

import CoreData
import UIKit

private let reuseIdentifier = "imageCell"

class ThumbnailBrowserViewController: UICollectionViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout {
    var resultsController: NSFetchedResultsController<GeneratedImage>?

    var menuButton: UIBarButtonItem = .init()
    var editButton: UIBarButtonItem = .init()

    var viewPredicate: NSPredicate?

    var showHiddenItems: Bool = false
    var multiSelectMode: Bool = false

    var imageDetailNavigationController: UINavigationController?
    var imageDetailViewController: ImageDetailCollectionViewController?

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
        navigationController?.setToolbarHidden(true, animated: false)
    }

    func setup(title: String, predicate: NSPredicate) {
        viewPredicate = predicate
        navigationItem.title = title
        setupDataSource()
        setupMenu()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
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
            guard let cell = collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell else { fatalError("No cell found, weird!") }
            cell.setUnselected()

            if imageDetailViewController == nil {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                imageDetailNavigationController = storyboard.instantiateViewController(withIdentifier: "navControllerImageDetail") as? UINavigationController
                imageDetailViewController = imageDetailNavigationController?.topViewController as? ImageDetailCollectionViewController
                imageDetailViewController?.predicate = resultsController?.fetchRequest.predicate
            }

            if let nav = imageDetailNavigationController, let controller = imageDetailViewController {
                controller.startingIndexPath = indexPath
                nav.modalPresentationStyle = .overFullScreen
                present(nav, animated: true)
            }
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
}

extension ThumbnailBrowserViewController {
    func setupMenu() {
        editButton.title = isEditing ? "Done" : "Select"

        var menuItems: [UIMenuElement] = []

        if isEditing {
            let editActions = UIMenu(title: "", options: .displayInline, children: [
                UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up"), state: .off, handler: { [self] _ in
                    shareSelectedImages()
                }),
                UIAction(title: "Favorite", image: UIImage(systemName: "star"), state: .off, handler: { [self] _ in
                    favoriteSelectedImages()
                }),
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

        fetchRequest.predicate = viewPredicate

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: ImageDatabase.standard.mainManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        resultsController = controller
        controller.delegate = self

        do {
            try controller.performFetch()
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
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
            if images.count > 0 {
                let alert = UIAlertController(title: "Confirm", message: "Are you sure you want to delete these \(images.count) images? This cannot be reverted.", preferredStyle: .alert)
                let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
                    ImageDatabase.standard.deleteImages(images)
                    self.toggleEditing()
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                alert.addAction(deleteAction)
                alert.addAction(cancelAction)
                present(alert, animated: true)
            }
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

    func shareSelectedImages() {
        if let selectedCells = collectionView.indexPathsForSelectedItems {
            var images: [ItemDetailSource] = []

            selectedCells.forEach { indexPath in
                guard let object = resultsController?.object(at: indexPath) else {
                    fatalError("Attempt to share a cell without a managed object")
                }
                var image: UIImage?
                if let cachedImage = ImageCache.standard.getImage(key: NSString(string: "\(object.id)")) {
                    image = cachedImage
                } else if let freshImage = UIImage(data: object.image!) {
                    image = freshImage
                }

                if let image = image,
                   let imageData = image.pngData(),
                   let pngImage = UIImage(data: imageData)
                {
                    let prompt = object.promptSimple ?? object.id.debugDescription
                    images.append(ItemDetailSource(name: "\(prompt)", image: pngImage))
                }
            }

            let ac = UIActivityViewController(activityItems: images, applicationActivities: nil)
            ac.popoverPresentationController?.sourceView = navigationController?.toolbar
            present(ac, animated: true)
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
