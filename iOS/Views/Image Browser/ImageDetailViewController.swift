//
//  ImageDetailViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/28/23.
//

import UIKit

class ImageDetailViewController: UIViewController {

    var generatedImage: GeneratedImage?

    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    @IBAction func shareButtonAction(_ sender: UIBarButtonItem) {
        Log.debug("Share button pressed...")
    }

    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBAction func favoriteButtonAction(_ sender: UIBarButtonItem) {
        Log.debug("Favorite button pressed...")
        if let image = generatedImage {
            ImageDatabase.standard.toggleImageFavorite(generatedImage: image) { [self] image in
                generatedImage = image
                loadImage()
            }
        }
    }

    @IBAction func trashButtonAction(_ sender: UIBarButtonItem) {
        Log.debug("Trash button pressed...")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loadImage()
    }

    func loadImage() {
        if let image = generatedImage {
            imageView.image = UIImage(data: image.image!)
            navigationItem.title = "\(image.uuid!)"
            promptLabel.text = image.promptSimple
            favoriteButton.image = UIImage(systemName: image.isFavorite ? "heart.fill" : "heart")
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
