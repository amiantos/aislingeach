//
//  RequestsTableViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 7/19/23.
//

import UIKit

class RequestsTableViewCell: UITableViewCell {

    @IBOutlet weak var imagePreviewView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageCountLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setup(request: HordeRequest) {
        promptLabel.text = request.prompt
        imageCountLabel.text = "\(request.n) Images"
        messageLabel.text = "Waiting..."
        dateLabel.text = request.dateCreated?.formatted()
        if request.status == "active" {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
