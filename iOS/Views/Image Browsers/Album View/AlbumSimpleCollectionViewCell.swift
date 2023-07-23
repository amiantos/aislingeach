//
//  AlbumSimpleCollectionViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 7/5/23.
//

import UIKit

class AlbumSimpleCollectionViewCell: UICollectionViewCell {
    @IBOutlet var promptLabel: UILabel!
    @IBOutlet var countLabel: UILabel!

    var viewPredicate: NSPredicate?
    var viewTitle: String?

    func setup(count: String, predicate: NSPredicate, title: String) {
        promptLabel.text = title
        countLabel.text = count
        viewPredicate = predicate
        viewTitle = title
    }
}
