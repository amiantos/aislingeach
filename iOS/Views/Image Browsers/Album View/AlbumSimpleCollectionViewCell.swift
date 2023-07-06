//
//  AlbumSimpleCollectionViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 7/5/23.
//

import UIKit

class AlbumSimpleCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!

    var viewPredicate: NSPredicate?
    var viewTitle: String?

    func setup(prompt: String, count: String, predicate: NSPredicate, title: String) {
        promptLabel.text = prompt
        countLabel.text = count
        self.viewPredicate = predicate
        self.viewTitle = title
    }

}
