//
//  ImageDetailCollectionViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 7/3/23.
//

import CoreData
import UIKit

class ImageDetailCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout, ImageDetailCollectionViewCellDelegate {


    var resultsController: NSFetchedResultsController<GeneratedImage>?

    var viewFolder: String = "main"

    var startingIndexPath: IndexPath?

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
        collectionView.isPagingEnabled = true

        navigationController?.navigationBar.prefersLargeTitles = false

        setupDataSource()

        if let startingIndexPath = startingIndexPath {
            collectionView.scrollToItem(at: startingIndexPath, at: .centeredHorizontally, animated: false)
        }

        let favorite = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action:  #selector(favoriteImage))
        let delete = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(deleteImage))
        let hide = UIBarButtonItem(image: UIImage(systemName: "eye.slash"), style: .plain, target: self, action: #selector(hideImage))
        let share = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareSheet))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolbarItems = [delete, spacer, hide, spacer, share, spacer, favorite]

        navigationController?.setToolbarHidden(false, animated: true)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .done, target: self, action: #selector(cancelAction))
        
    }

    func jumpToIndexPath() {
        if let startingIndexPath = startingIndexPath {
            collectionView.isPagingEnabled = false
            collectionView.scrollToItem(at: startingIndexPath, at: .centeredHorizontally, animated: false)
            collectionView.isPagingEnabled = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        jumpToIndexPath()
    }

    func dismissView() {
        self.dismiss(animated: true)
    }

    @objc func cancelAction() {
        dismiss(animated: true)
    }

    @objc func favoriteImage() {
        Log.debug("Favorite button pressed...")
        if let indexPath = collectionView.indexPathsForVisibleItems.first, let image = resultsController?.object(at: indexPath) as? GeneratedImage {
            ImageDatabase.standard.toggleImageFavorite(generatedImage: image) { [self] image in
                // TODO: Update icon...
            }
        }
    }

    @objc func loadSettings() {

    }

    @objc func shareSheet() {
        if let indexPath = collectionView.indexPathsForVisibleItems.first, let image = resultsController?.object(at: indexPath) as? GeneratedImage {
            let ac = UIActivityViewController(activityItems: [image.image, self], applicationActivities: nil)
            ac.popoverPresentationController?.sourceView = navigationController?.toolbar
            present(ac, animated: true)
        }
    }

    @objc func hideImage() {
        if let indexPath = collectionView.indexPathsForVisibleItems.first, let image = resultsController?.object(at: indexPath) as? GeneratedImage {
            ImageDatabase.standard.toggleImageHidden(generatedImage: image) { [self] _ in
//                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    @objc func deleteImage() {
        if let indexPath = collectionView.indexPathsForVisibleItems.first, let image = resultsController?.object(at: indexPath) as? GeneratedImage {
            ImageDatabase.standard.deleteImage(image) { generatedImage in
                if generatedImage == nil {
                    //
                }
            }
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

    private let itemsPerRow: CGFloat = 1
    private let sectionInsets = UIEdgeInsets(
        top: 0,
        left: 0,
        bottom: 0,
        right: 0
    )

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.safeAreaLayoutGuide.layoutFrame.height)
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        return sectionInsets
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return sectionInsets.left
    }

    override func numberOfSections(in _: UICollectionView) -> Int {
        if let frc = resultsController {
            return frc.sections!.count
        }
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ImageDetailCollectionViewCell else { return }
        navigationItem.title = cell.generatedImage?.uuid?.uuidString
    }

    override func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = resultsController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageDetailCollectionCell", for: indexPath) as! ImageDetailCollectionViewCell
        cell.delegate = self
        guard let object = resultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        // Configure the cell
        cell.setup(object: object)
        return cell
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

extension ImageDetailCollectionViewController {
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
}
