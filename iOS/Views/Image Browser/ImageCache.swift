//
//  ImageCache.swift
//  Aislingeach
//
//  Created by Brad Root on 6/2/23.
//

import Foundation
import UIKit

class ImageCache {
    let cache = NSCache<NSString, UIImage>()
    static var standard = ImageCache()

    func cacheImage(image: UIImage, key: NSString) {
        cache.setObject(image, forKey: key)
    }

    func getImage(key: NSString) -> UIImage? {
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }
        return nil
    }
}
