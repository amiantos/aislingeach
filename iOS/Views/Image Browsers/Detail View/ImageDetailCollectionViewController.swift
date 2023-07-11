//
//  ImageDetailCollectionViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 7/3/23.
//

import LinkPresentation
import CoreData
import UIKit

class ImageDetailCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout, ImageDetailCollectionViewCellDelegate {
  
    var resultsController: NSFetchedResultsController<GeneratedImage>?
    var predicate: NSPredicate?
    var startingIndexPath: IndexPath?

    var favoriteButton: UIBarButtonItem?
    var deleteButton: UIBarButtonItem?
    var hideButton: UIBarButtonItem?
    var shareButton: UIBarButtonItem?
    var infoButton: UIBarButtonItem?

    var metaDataViewIsHidden: Bool = true {
        didSet {
            guard let infoButton = infoButton else { return }
            if metaDataViewIsHidden {
                infoButton.image = UIImage(systemName: "info.circle")
            } else {
                infoButton.image = UIImage(systemName: "info.circle.fill")
            }
        }
    }

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

        favoriteButton = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action:  #selector(favoriteImage))
        deleteButton = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(deleteImage))
        hideButton = UIBarButtonItem(image: UIImage(systemName: "eye.slash"), style: .plain, target: self, action: #selector(hideImage))
        shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareSheet))
        infoButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(pressedInfoButton))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        toolbarItems = [shareButton!, spacer, favoriteButton!, spacer, infoButton!, spacer, hideButton!, spacer, deleteButton!]

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
        if metaDataViewIsHidden, let indexPath = collectionView.indexPathsForVisibleItems.first, let cell = collectionView.cellForItem(at: indexPath) as? ImageDetailCollectionViewCell {
            cell.toggleMetadataView(isHidden: true, animated: false)
        }
        jumpToIndexPath()
    }

    override func viewWillDisappear(_ animated: Bool) {
        metaDataViewIsHidden = true
        super.viewWillDisappear(animated)
    }

    func showRatingView(for requestId: UUID) {
        let requestRatingView = RequestRaterViewController(for: requestId)
        self.present(requestRatingView, animated: true)
    }

    func dismissView() {
        metaDataViewIsHidden = true
        self.dismiss(animated: true)
    }

    @objc func cancelAction() {
        dismiss(animated: true)
    }

    func toggleMetadataView(isHidden: Bool) {
        Log.debug("Setting metadata view to hidden: \(isHidden)")
        metaDataViewIsHidden = isHidden
    }

    func setupToolbarItems(image: GeneratedImage) {
        let favoriteMenuImage: UIImage? = image.isFavorite ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
        let hideMenuImage: UIImage? = image.isHidden ? UIImage(systemName: "eye.slash.fill") : UIImage(systemName: "eye.slash")

        favoriteButton?.image = favoriteMenuImage
        hideButton?.image = hideMenuImage
    }

    @objc func favoriteImage() {
        Log.debug("Favorite button pressed...")
        if let indexPath = collectionView.indexPathsForVisibleItems.first, let image = resultsController?.object(at: indexPath) as? GeneratedImage {
            ImageDatabase.standard.toggleImageFavorite(generatedImage: image) { [self] image in
                if let image = image {
                    self.setupToolbarItems(image: image)
                }
            }
        }
    }

    @objc func reuseSettings() {
        let alert = UIAlertController(title: "Include Seed?", message: "Do you want to include the seed for this image?", preferredStyle: .alert)
        let noAction = UIAlertAction(title: "No", style: .default) { _ in
            self.loadSettings(includeSeed: false)
        }
        let yesAction = UIAlertAction(title: "Yes", style: .destructive)  { _ in
            self.loadSettings(includeSeed: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(yesAction)
        alert.addAction(noAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }

    @objc func shareSheet() {
        if let indexPath = collectionView.indexPathsForVisibleItems.first, let cell = collectionView.cellForItem(at: indexPath) as? ImageDetailCollectionViewCell, let image = cell.imageView.image {
            let ac = UIActivityViewController(activityItems: [image.pngData() as Any, self], applicationActivities: nil)
            ac.popoverPresentationController?.sourceView = navigationController?.toolbar
            present(ac, animated: true)
        }
    }

    @objc func hideImage() {
        if let indexPath = collectionView.indexPathsForVisibleItems.first, let image = resultsController?.object(at: indexPath) as? GeneratedImage {
            ImageDatabase.standard.toggleImageHidden(generatedImage: image) { [self] image in
//                if let image = image {
//                    self.setupToolbarItems(image: image)
//                }
            }
        }
    }

    @objc func pressedInfoButton() {
        if let indexPath = collectionView.indexPathsForVisibleItems.first, let cell = collectionView.cellForItem(at: indexPath) as? ImageDetailCollectionViewCell {
            if metaDataViewIsHidden {
                cell.toggleMetadataView(isHidden: false, animated: true)
                metaDataViewIsHidden = false
            } else {
                cell.toggleMetadataView(isHidden: true, animated: true)
                metaDataViewIsHidden = true
            }
        }
    }

    @objc func deleteImage() {
        if let indexPath = collectionView.indexPathsForVisibleItems.first,
           let image = resultsController?.object(at: indexPath) as? GeneratedImage {

            let alert = UIAlertController(title: "Confirm", message: "Do you sure you want to delete the image? This cannot be reverted.", preferredStyle: .alert)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive)  { _ in
                ImageDatabase.standard.deleteImage(image) { generatedImage in
                    if generatedImage == nil {
                        Log.debug("Image successfully deleted.")
                    }
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
        }
    }

    func loadSettings(includeSeed: Bool) {
        Log.debug(presentingViewController)
        if let indexPath = collectionView.indexPathsForVisibleItems.first,
           let image = resultsController?.object(at: indexPath) as? GeneratedImage,
           let jsonString = image.fullRequest,
           let jsonData = jsonString.data(using: .utf8),
           let settings = try? JSONDecoder().decode(GenerationInputStable.self, from: jsonData),
           let tabBarController = presentingViewController as? UITabBarController,
           let navigationController = tabBarController.viewControllers?.first as? UINavigationController,
           let generateView = navigationController.topViewController as? GeneratorViewController {
            Log.info("Loading image settings into Create view...")
            var seed: String? = nil
            if includeSeed {
                if let customSeed = settings.params?.seed {
                    seed = customSeed
                } else if let resJsonString = image.fullResponse,
                          let resJsonData = resJsonString.data(using: .utf8),
                          let response = try? JSONDecoder().decode(GenerationStable.self, from: resJsonData),
                          let generatedSeed = response.seed {
                    seed = generatedSeed
                }
            }
            generateView.loadSettingsIntoUI(settings: settings, seed: seed)
            self.dismissView()
            tabBarController.selectedIndex = 0
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
        guard let cell = cell as? ImageDetailCollectionViewCell, let image = cell.generatedImage else { return }
        navigationItem.title = image.promptSimple
        setupToolbarItems(image: image)
        Log.debug("Wiill display cell \(metaDataViewIsHidden)")
        cell.toggleMetadataView(isHidden: metaDataViewIsHidden, animated: false)
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
        Log.debug("Configuring cell \(metaDataViewIsHidden)")
        cell.setup(object: object, metaDataViewIsHidden: metaDataViewIsHidden)
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

        fetchRequest.predicate = self.predicate

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


extension ImageDetailCollectionViewController: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        return ""
    }

    func activityViewController(_: UIActivityViewController, itemForActivityType _: UIActivity.ActivityType?) -> Any? {
        return nil
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        guard let indexPath = collectionView.indexPathsForVisibleItems.first, let cell = collectionView.cellForItem(at: indexPath) as? ImageDetailCollectionViewCell, let image = cell.imageView.image else { return nil }

        let imageProvider = NSItemProvider(object: image)
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        metadata.title = "Share generation"
        return metadata
    }
}
