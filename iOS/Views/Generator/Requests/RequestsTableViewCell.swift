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
        timeLabel.text = ""
        queuePositionLabel.text = ""
        if request.waitTime > 0 {
            timeLabel.text = "\(request.waitTime)s"
        }
        if request.queuePosition > 0 {
            queuePositionLabel.text = "#\(request.queuePosition) in queue"
        }
        if request.status == "finished" {
            activityIndicator.stopAnimating()
            if var images = request.images?.array as? [GeneratedImage], !images.isEmpty {
                images = images.sorted(by: { i1, i2 in
                   i1.dateCreated! < i2.dateCreated!
                })
                if let image = images.last {
                    self.loadImage(generatedImage: image)
                }
            }
        } else if !activityIndicator.isAnimating {
            activityIndicator.startAnimating()
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
        imagePreviewView.image = nil
        queuePositionLabel.text = ""
        timeLabel.text = ""
    }
}
