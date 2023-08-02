//
//  ImageDetailSource.swift
//  Aislingeach
//
//  Created by Brad Root on 7/18/23.
//

import LinkPresentation
import UIKit

class ItemDetailSource: NSObject {
    let name: String
    let image: UIImage

    init(name: String, image: UIImage) {
        self.name = name
        self.image = image
    }
}

extension ItemDetailSource: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(_: UIActivityViewController, itemForActivityType _: UIActivity.ActivityType?) -> Any? {
        image
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        let metaData = LPLinkMetadata()
        metaData.title = name
        metaData.imageProvider = NSItemProvider(object: image)
        return metaData
    }
}
