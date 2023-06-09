//
//  ImageCollectionViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 5/28/23.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet var favoriteIcon: UIImageView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var slectionIcon: UIImageView!

    var generatedImage: GeneratedImage?

    func setup(object: GeneratedImage) {
        generatedImage = object
        favoriteIcon.isHidden = !object.isFavorite

        DispatchQueue.main.async { [self] in
            if let cachedImage = ImageCache.standard.getImage(key: NSString(string: "\(object.id)")) {
                Log.debug("Reloading cached UIImage...")
                imageView.image = cachedImage
            } else {
                if let image = UIImage(data: object.image!) {
                    imageView.image = image
                    ImageCache.standard.cacheImage(image: image, key: NSString(string: "\(object.id)"))
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        Log.debug("Unloading image")
        imageView.image = nil
    }

    override var isSelected: Bool {
            didSet {
                if self.isSelected {
                    setSelected()
                }
                else {
                    setUnselected()
                }
            }
        }

        func setSelected(){
            self.slectionIcon.isHidden = false
            self.layer.borderWidth = 2
            self.layer.borderColor = UIColor.white.cgColor
        }

        func setUnselected(){
            self.slectionIcon.isHidden = true
            self.layer.borderWidth = 0
        }
}
