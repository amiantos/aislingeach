//
//  ImageDetailViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/28/23.
//

import LinkPresentation
import UIKit

class ImageDetailViewController: UIViewController {
    var generatedImage: GeneratedImage?

    @IBOutlet var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var promptLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var imageView: UIImageView!

    var menuButton: UIBarButtonItem = .init()

    @IBAction func shareButtonAction(_: UIBarButtonItem) {
        Log.debug("Share button pressed...")
        if let currentImage = imageView.image?.pngData() {
            let ac = UIActivityViewController(activityItems: [currentImage, self], applicationActivities: nil)
            ac.popoverPresentationController?.sourceView = tabBarController?.view
            present(ac, animated: true)
        }
    }

    @IBOutlet var favoriteButton: UIBarButtonItem!
    @IBAction func favoriteButtonAction(_: UIBarButtonItem) {
        Log.debug("Favorite button pressed...")
        if let image = generatedImage {
            ImageDatabase.standard.toggleImageFavorite(generatedImage: image) { [self] image in
                generatedImage = image
                loadImage()
            }
        }
    }

    @IBAction func trashButtonAction(_: UIBarButtonItem) {
        Log.debug("Trash button pressed...")
        guard let generatedImage = generatedImage else { return }

        ImageDatabase.standard.deleteImage(generatedImage) { generatedImage in
            if generatedImage == nil {
                NotificationCenter.default.post(name: .deletedGeneratedImage, object: nil)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadImage()

        menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: nil)
        navigationItem.rightBarButtonItem = menuButton

        menuButton.menu = UIMenu(children: [
            UIAction(title: "Foo", state: .off, handler: { _ in
                Log.debug("foo")
            }),
        ])

        let font = UIFont.monospacedSystemFont(ofSize: 12.0, weight: .regular)
        promptLabel.font = font

        navigationItem.title = "Image Detail"
    }

    func loadImage() {
        if let imageObject = generatedImage, let imageData = imageObject.image, let image = UIImage(data: imageData) {
            let imageWidth = image.size.width
            let imageHeight = image.size.height
            let viewWidth = view.frame.size.width

            let ratio = viewWidth / imageWidth
            let scaledHeight = imageHeight * ratio
            imageHeightConstraint.constant = scaledHeight
            imageView.image = image
            if let fullRequest = imageObject.fullRequest {
                let jsonData = Data(fullRequest.utf8)
                promptLabel.text = jsonData.printJson()
            }
            favoriteButton.image = UIImage(systemName: imageObject.isFavorite ? "heart.fill" : "heart")
            dateLabel.text = imageObject.dateCreated?.formatted(date: .abbreviated, time: .shortened)
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}

extension ImageDetailViewController: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        return ""
    }

    func activityViewController(_: UIActivityViewController, itemForActivityType _: UIActivity.ActivityType?) -> Any? {
        return nil
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        let image = imageView.image!
        let imageProvider = NSItemProvider(object: image)
        let metadata = LPLinkMetadata()
        metadata.imageProvider = imageProvider
        metadata.title = "Share generation"
        return metadata
    }
}
