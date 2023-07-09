//
//  AlbumCollectionViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 7/4/23.
//

import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var imageCountLabel: UILabel!
    
    @IBOutlet weak var favoriteIcon: UIImageView!
    @IBOutlet weak var cellBackgroundView: UIView!
    @IBOutlet weak var imageView: UIImageView!

    var viewPredicate: NSPredicate?
    var viewTitle: String?

    func setup(count: String, predicate: NSPredicate, title: String, image: GeneratedImage?) {
        cellBackgroundView.layer.cornerRadius = 8
        promptLabel.text = title
        imageCountLabel.text = count
        self.viewPredicate = predicate
        self.viewTitle = title
        if title == "Favorites" {
            favoriteIcon.isHidden = false
        }
        if let object = image {
            DispatchQueue.main.async { [self] in
                if let cachedImage = ImageCache.standard.getImage(key: NSString(string: object.uuid!.uuidString)) {
                    Log.debug("Reloading cached UIImage...")
                    imageView.image = cachedImage
                } else {
                    if let image = UIImage(data: object.image!) {
                        imageView.image = image
                        ImageCache.standard.cacheImage(image: image, key: NSString(string: object.uuid!.uuidString))
                    }
                }
            }
        }
    }
    
}
