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
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var onlineStatusLight: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setup(details: WorkerDetails) {
        workerDetails = details
        
        workerNameLabel.text = details.name ?? "No worker name found"
        idLabel.text = details._id ?? "No worker id found"
        if let maintenanceMode = details.maintenanceMode,
           let online = details.online {
            if !online {
                onlineStatusLight.tintColor = .systemRed
                self.maintenanceMode = false
            } else if maintenanceMode {
                onlineStatusLight.tintColor = .systemYellow
                self.maintenanceMode = true
            } else {
                onlineStatusLight.tintColor = .systemGreen
                self.maintenanceMode = false
            }
        }

    }

}
