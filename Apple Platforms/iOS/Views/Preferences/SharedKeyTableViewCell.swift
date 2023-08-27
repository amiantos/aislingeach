//
//  SharedKeyTableViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 8/26/23.
//

import UIKit

class SharedKeyTableViewCell: UITableViewCell {

    @IBOutlet weak var sharedKeyIdLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var kudosLabel: UILabel!
    @IBOutlet weak var utilizedLabel: UILabel!
    @IBOutlet weak var expiryLabel: UILabel!
    @IBOutlet weak var maxPixelsLabel: UILabel!
    @IBOutlet weak var maxStepsLabel: UILabel!
    @IBOutlet weak var maxTextTokensLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
