//
//  StyleCollectionViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 12/4/24.
//

import UIKit

class StyleCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var styleNameLabel: UILabel!
    @IBOutlet weak var aspectRatioLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        previewImageView.sd_cancelCurrentImageLoad()
        previewImageView.image = nil
    }
}
