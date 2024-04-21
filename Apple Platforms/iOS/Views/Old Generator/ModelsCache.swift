//
//  ModelsCache.swift
//  Aislingeach
//
//  Created by Brad Root on 6/2/23.
//

import Foundation
import UIKit

class ModelsCache {
    let cache = NSCache<NSString, NSArray>()
    static var standard = ModelsCache()

    func cache(models: [ActiveModel]) {
        cache.setObject(models as NSArray, forKey: "default")
    }

    func getModels() -> [ActiveModel]? {
        if let cached = cache.object(forKey: "default") as? [ActiveModel] {
            return cached
        }
        return nil
    }
}
