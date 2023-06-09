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
    @IBOutlet var slectionIcon: UIImageView!

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
            if isSelected {
                setSelected()
            } else {
                setUnselected()
            }
        }
    }

    func setSelected() {
        slectionIcon.isHidden = false
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
    }

    func setUnselected() {
        slectionIcon.isHidden = true
        layer.borderWidth = 0
    }
}
