//
//  AlbumCollectionViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 7/4/23.
//

import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet var promptLabel: UILabel!
    @IBOutlet var imageCountLabel: UILabel!

    @IBOutlet var favoriteIcon: UIImageView!
    @IBOutlet var cellBackgroundView: UIView!
    @IBOutlet var imageView: UIImageView!

    func setup(album: Album) {
        cellBackgroundView.layer.cornerRadius = 8
        promptLabel.text = album.title
        if album.title == "Favorites" {
            favoriteIcon.isHidden = false
        } else {
            favoriteIcon.isHidden = true
        }

        Task(priority: .userInitiated) {
            var foundCount: Int?
            var foundGeneratedImage: GeneratedImage?

            if let count = album.count, let generatedImage = album.generatedImage {
                foundCount = count
                foundGeneratedImage = generatedImage
            } else {
                let result = await ImageDatabase.standard.getCountAndRecentImageForPredicate(predicate: album.predicate)
                foundCount = result.0
                foundGeneratedImage = result.1
                album.count = foundCount
                album.generatedImage = foundGeneratedImage
            }

            if let object = foundGeneratedImage, let count = foundCount {
                self.imageCountLabel.text = count.formatted()
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
            } else {
                imageCountLabel.text = "0"
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageCountLabel.text = "Loading..."
        promptLabel.text = ""
        favoriteIcon.isHidden = true
    }
}
