//
//  ImageDetailCollectionViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 7/3/23.
//

import UIKit

class ImageDetailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!

    var generatedImage: GeneratedImage?

    func setup(object: GeneratedImage) {
        generatedImage = object

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
}
