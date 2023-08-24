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

    var viewPredicate: NSPredicate?
    var viewTitle: String?

    func setup(predicate: NSPredicate, title: String) {
        cellBackgroundView.layer.cornerRadius = 8
        promptLabel.text = title
        viewPredicate = predicate
        viewTitle = title
        if title == "Favorites" {
            favoriteIcon.isHidden = false
        }
    }

    func loadData() {
        Log.debug("Load data...")
        Task {
            if let predicate = self.viewPredicate {
                let result = await ImageDatabase.standard.getCountAndRecentImageForPredicate(predicate: predicate)
                self.imageCountLabel.text = result.0.formatted()
                if let object = result.1 {
                    if let cachedImage = ImageCache.standard.getImage(key: NSString(string: object.uuid!.uuidString)) {
                        Log.debug("Reloading cached UIImage...")
                        self.imageView.image = cachedImage
                    } else {
                        if let image = UIImage(data: object.image!) {
                            self.imageView.image = image
                            ImageCache.standard.cacheImage(image: image, key: NSString(string: object.uuid!.uuidString))
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.layoutSubviews()
                }
            }
        }
    }
}
