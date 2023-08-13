//
//  WorkerTableViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 8/13/23.
//

import UIKit

class WorkerTableViewCell: UITableViewCell {

    var maintenanceMode: Bool = false
    var workerDetails: WorkerDetails?

    @IBOutlet weak var workerNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var uptimeLabel: UILabel!
    @IBOutlet weak var maxResolutionLabel: UILabel!
    @IBOutlet weak var modelsServedLabel: UILabel!
    @IBOutlet weak var kudosEarnedLabel: UILabel!
    @IBOutlet weak var requestsCompletedLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setup(details: WorkerDetails) {
        workerDetails = details
        
        workerNameLabel.text = details.name ?? "No worker name found"
        descriptionLabel.text = details.info ?? "No worker description"
        idLabel.text = details._id ?? "No worker id found"
        modelsServedLabel.text = "\((details.models ?? [])!.count)"
        kudosEarnedLabel.text = details.kudosRewards?.formatted()
        requestsCompletedLabel.text = details.requestsFulfilled?.formatted()
        if let seconds = details.uptime {
            uptimeLabel.text = "\(seconds/86400)d \((seconds % 86400)/3600)h \((seconds % 3600) / 60)m \((seconds % 3600) % 60)s"
        } else {
            uptimeLabel.text = "N/A"
        }

        if let maintenanceMode = details.maintenanceMode,
           let online = details.online {
            if !online {
                statusLabel.text = "Offline"
                self.maintenanceMode = false
            } else if maintenanceMode {
                statusLabel.text = "Maintenance"
                self.maintenanceMode = true
            } else {
                statusLabel.text = "Online"
                self.maintenanceMode = false
            }
        }

        if let power = details.maxPixels {
            maxResolutionLabel.text = "\(Int(Float(power).squareRoot())) x \(Int(Float(power).squareRoot()))"
        } else {
            maxResolutionLabel.text = "N/A"
        }

    }

}
