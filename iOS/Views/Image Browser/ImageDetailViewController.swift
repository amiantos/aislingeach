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
    @IBOutlet weak var requestDetailsView: UITextView!
    @IBOutlet weak var responseDetailsView: UITextView!

    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var imageView: UIImageView!

    var menuButton: UIBarButtonItem = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: nil)
        navigationItem.rightBarButtonItem = menuButton

        let font = UIFont.monospacedSystemFont(ofSize: 12.0, weight: .regular)
        requestDetailsView.font = font
        responseDetailsView.font = font

        navigationItem.title = "Image Detail"

        loadImage()
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
                requestDetailsView.text = jsonData.printJson()
            }

            if let fullResponse = imageObject.fullResponse {
                let jsonData = Data(fullResponse.utf8)
                responseDetailsView.text = jsonData.printJson()
            } else {
                responseDetailsView.text = "This generation is from an earlier version of Aislingeach and does not have the response details recorded."
            }
            dateLabel.text = imageObject.dateCreated?.formatted(date: .abbreviated, time: .shortened)

            setupMenuItems()
        }
    }

    fileprivate func setupMenuItems() {
        let favoriteMenuImage: UIImage? = generatedImage?.isFavorite ?? false ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")

        let hideMenuImage: UIImage? = generatedImage?.isHidden ?? false ? UIImage(systemName: "eye") : UIImage(systemName: "eye.slash")
        let hideMenuTitle: String = generatedImage?.isHidden ?? false ? "Unhide" : "Hide"

        menuButton.menu = UIMenu(children: [
            UIAction(title: "Favorite", image: favoriteMenuImage, state: .off, handler: { [self] _ in
                Log.debug("Favorite button pressed...")
                if let image = generatedImage {
                    ImageDatabase.standard.toggleImageFavorite(generatedImage: image) { [self] image in
                        generatedImage = image
                        loadImage()
                    }
                }
            }),
            UIAction(title: "Load Settings", image: UIImage(systemName: "arrow.counterclockwise"), state: .off, handler: { _ in
                Log.debug(self.tabBarController?.viewControllers)
                let alert = UIAlertController(title: "Include Seed?", message: "Do you want to include the seed for this image?", preferredStyle: .alert)
                let noAction = UIAlertAction(title: "No", style: .default) { _ in
                    self.loadSettings(includeSeed: false)
                }
                let yesAction = UIAlertAction(title: "Yes", style: .destructive)  { _ in
                    self.loadSettings(includeSeed: true)
                }
                alert.addAction(yesAction)
                alert.addAction(noAction)
                self.present(alert, animated: true)
            }),
            UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up"), state: .off, handler: { [self] _ in
                Log.debug("Share button pressed...")
                if let currentImage = imageView.image?.pngData() {
                    let ac = UIActivityViewController(activityItems: [currentImage, self], applicationActivities: nil)
                    ac.popoverPresentationController?.sourceView = tabBarController?.view
                    present(ac, animated: true)
                }
            }),
            UIAction(title: hideMenuTitle, image: hideMenuImage, state: .off, handler: { [self] _ in
                Log.debug("Hide button pressed...")
                if let image = generatedImage {
                    ImageDatabase.standard.toggleImageHidden(generatedImage: image) { [self] _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                }

            }),
            UIAction(title: "Delete", image: UIImage(systemName: "trash"), state: .off, handler: { [self] _ in
                Log.debug("Trash button pressed...")
                guard let generatedImage = generatedImage else { return }

                ImageDatabase.standard.deleteImage(generatedImage) { generatedImage in
                    if generatedImage == nil {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }),
        ])
    }

    func loadSettings(includeSeed: Bool) {
        if let jsonString = self.generatedImage?.fullRequest,
           let jsonData = jsonString.data(using: .utf8),
           let settings = try? JSONDecoder().decode(GenerationInputStable.self, from: jsonData),
           let navigationController = self.tabBarController?.viewControllers?.first as? UINavigationController,
           let generateView = navigationController.topViewController as? GeneratorViewController {
            Log.info("Loading image settings into Create view...")
            var seed: String? = nil
            if includeSeed {
                if let customSeed = settings.params?.seed {
                    seed = customSeed
                } else if let resJsonString = self.generatedImage?.fullResponse,
                          let resJsonData = resJsonString.data(using: .utf8),
                          let response = try? JSONDecoder().decode(GenerationStable.self, from: resJsonData),
                          let generatedSeed = response.seed {
                    seed = generatedSeed
                }
            }
            generateView.loadSettingsIntoUI(settings: settings, seed: seed)
            self.tabBarController?.selectedIndex = 0
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
