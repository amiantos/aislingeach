//
//  RequestsTableViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 7/19/23.
//

import UIKit

class RequestsTableViewCell: UITableViewCell {
    @IBOutlet var imagePreviewView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var promptLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var imageCountLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var queuePositionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setup(request: HordeRequest) {
        promptLabel.text = request.prompt
        imageCountLabel.text = "\(request.n) Images"
        messageLabel.text = request.message
        dateLabel.text = request.dateCreated?.formatted()
        if request.waitTime > 0 {
            timeLabel.text = "\(request.waitTime)s"
        } else {
            timeLabel.text = ""
        }
        if request.queuePosition > 0 {
            queuePositionLabel.text = "#\(request.queuePosition) waiting"
        } else {
            queuePositionLabel.text = ""
        }
        if request.status == "active" {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            if let requestId = request.uuid {
                ImageDatabase.standard.fetchFirstImage(requestId: requestId) { image in
                    guard let generatedImage = image else { return }
                    self.loadImage(generatedImage: generatedImage)
                }
            }
        }
    }

    func loadImage(generatedImage: GeneratedImage) {
        DispatchQueue.main.async { [self] in
            if let cachedImage = ImageCache.standard.getImage(key: NSString(string: generatedImage.uuid!.uuidString)) {
                Log.debug("Reloading cached UIImage...")
                imagePreviewView.image = cachedImage
            } else {
                if let image = UIImage(data: generatedImage.image!) {
                    imagePreviewView.image = image
                    ImageCache.standard.cacheImage(image: image, key: NSString(string: generatedImage.uuid!.uuidString))
                }
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        Log.debug("Unloading image")
        imagePreviewView.image = nil
    }
}