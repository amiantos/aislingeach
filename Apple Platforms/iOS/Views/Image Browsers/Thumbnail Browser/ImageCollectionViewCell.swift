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
    @IBOutlet var selectionTint: UIView!

    var generatedImage: GeneratedImage?

    func setup(object: GeneratedImage) {
        generatedImage = object
        favoriteIcon.isHidden = !object.isFavorite

        DispatchQueue.global(qos: .background).async { [self] in
            if let objUuid = object.uuid {
                let objectIdentifier = "thumb-\(objUuid.uuidString)"
                if let cachedImage = ImageCache.standard.getImage(key: NSString(string: objectIdentifier)) {
                    Log.debug("Reloading cached UIImage...")
                    DispatchQueue.main.async {
                        self.imageView.image = cachedImage
                    }
                } else if let imageData = object.thumbnail, let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.imageView.image = image
                        ImageCache.standard.cacheImage(image: image, key: NSString(string: objectIdentifier))
                    }
                } else if let imageData = object.image, let image = UIImage(data: imageData) {
                    image.prepareThumbnail(of: CGSize(width: 512, height: 512)) { thumbnail in
                        if let thumbnail = thumbnail {
                            DispatchQueue.main.async {
                                self.imageView.image = thumbnail
                                ImageCache.standard.cacheImage(image: thumbnail, key: NSString(string: objectIdentifier))
                                ImageDatabase.standard.saveThumbnail(for: object, thumbnail: thumbnail)
                            }
                        }
                    }
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        Log.debug("Unloading image")
        imageView.image = nil
        generatedImage = nil
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
        selectionTint.isHidden = false
        slectionIcon.image = UIImage(systemName: "checkmark.circle.fill")?.stroked(with: .white)
    }

    func setUnselected() {
        slectionIcon.isHidden = true
        selectionTint.isHidden = true
    }
}
