//
//  ImageDetailViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/28/23.
//

import UIKit

class ImageDetailViewController: UIViewController {
    var generatedImage: GeneratedImage?

    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet var promptLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet var imageView: UIImageView!

    @IBAction func shareButtonAction(_ sender: UIBarButtonItem) {
        Log.debug("Share button pressed...")
        if let currentImage = imageView.image {
            let ac = UIActivityViewController(activityItems: [currentImage], applicationActivities: nil)
            ac.popoverPresentationController?.sourceView = self.tabBarController?.view
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
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadImage()

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
