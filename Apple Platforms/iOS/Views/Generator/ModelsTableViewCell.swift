//
//  ModelsTableViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 1/11/24.
//

import UIKit

protocol ModelsTableViewCellDelegate {
    func addFavorite(modelName: String, sender: ModelsTableViewCell)
    func removeFavorite(modelName: String, sender: ModelsTableViewCell)
}

class ModelsTableViewCell: UITableViewCell {

    @IBOutlet weak var modelNameLabel: UILabel!
    @IBOutlet weak var modelStatusLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!

    var delegate: ModelsTableViewCellDelegate?

    public var isFavorite: Bool = false {
        didSet {
            updateButtonDisplay()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func favoriteButtonPressed(_ sender: UIButton) {
        self.isFavorite = !self.isFavorite
        updateFavoriteStatus()
    }

    func updateButtonDisplay() {
        if isFavorite {
            favoriteButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
        } else {
            favoriteButton.setImage(UIImage(systemName: "star"), for: .normal)
        }
    }

    func updateFavoriteStatus() {
        guard let modelName = modelNameLabel.text else { return }
        if isFavorite {
            delegate?.addFavorite(modelName: modelName, sender: self)
        } else {
            delegate?.removeFavorite(modelName: modelName, sender: self)
        }
    }
}
