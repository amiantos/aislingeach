//
//  YourAccountTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 9/16/23.
//

import UIKit

class YourAccountTableViewController: UITableViewController {

    @IBOutlet weak var totalKudosLabel: UILabel!
    @IBOutlet weak var totalImagesRequestedLabel: UILabel!
    @IBOutlet weak var kudosGiftedToYouLabel: UILabel!
    @IBOutlet weak var kudosGiftedToOthersLabel: UILabel!
    @IBOutlet weak var workerImagesGeneratedLabel: UILabel!
    @IBOutlet weak var recurringKudosLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        loadUserData()

        navigationItem.backButtonTitle = "Account"
    }

    func loadUserData() {
        HordeV2API.getFindUser(apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { [self] data, error in
            Log.debug(data)
            if let data = data,
               let username = data.username {
                let totalKudos = data.kudos ?? 0
                let totalImages = data.usage?.requests ?? data.records?.request?.image ?? 0
                let giftedKudos = -(data.kudosDetails?.gifted ?? 0)
                let receivedKudos = data.kudosDetails?.received ?? 0
                let imagesGenerated = data.contributions?.fulfillments ?? data.records?.fulfillment?.image ?? 0
                let recurringKudos = data.kudosDetails?.recurring ?? 0
                DispatchQueue.main.async { [self] in
                    navigationItem.title = username
                    totalKudosLabel.text = totalKudos.formatted()
                    totalImagesRequestedLabel.text = totalImages.formatted()
                    kudosGiftedToYouLabel.text = receivedKudos.formatted()
                    kudosGiftedToOthersLabel.text = giftedKudos.formatted()
                    workerImagesGeneratedLabel.text = imagesGenerated.formatted()
                    recurringKudosLabel.text = recurringKudos.formatted()
                }
            }
        }
    }
}
