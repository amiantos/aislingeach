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
    @IBOutlet weak var recurringKudosLabel: UILabel!
    @IBOutlet weak var accumulatedKudosLabel: UILabel!
    @IBOutlet weak var kudosRewardsLabel: UILabel!
    @IBOutlet weak var workerGenerationsLabel: UILabel!
    
    @IBOutlet weak var logOutButtonLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backButtonTitle = "Account"
        NotificationCenter.default.addObserver(self, selector: #selector(loadUserData), name: .newAPIKeySubmitted, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadUserData()
    }

    @objc func loadUserData() {
        HordeV2API.getFindUser(apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { [self] data, error in
            Log.debug(data)
            if let data = data,
               let username = data.username {
                let totalKudos = data.kudos ?? 0
                let totalImages = data.usage?.requests ?? data.records?.request?.image ?? 0
                let giftedKudos = -(data.kudosDetails?.gifted ?? 0)
                let receivedKudos = data.kudosDetails?.received ?? 0
                let recurringKudos = data.kudosDetails?.recurring ?? 0
                let accumulatedKudos = data.kudosDetails?.accumulated ?? 0
                let rewardedKudos = data.kudosDetails?.awarded
                let generatedImages = data.contributions?.fulfillments ?? data.records?.fulfillment?.image ?? 0

                DispatchQueue.main.async { [self] in
                    navigationItem.title = username
                    totalKudosLabel.text = totalKudos.formatted()
                    totalImagesRequestedLabel.text = totalImages.formatted()
                    kudosGiftedToYouLabel.text = receivedKudos.formatted()
                    kudosGiftedToOthersLabel.text = giftedKudos.formatted()
                    recurringKudosLabel.text = recurringKudos.formatted()
                    accumulatedKudosLabel.text = accumulatedKudos.formatted()
                    kudosRewardsLabel.text = rewardedKudos?.formatted()
                    workerGenerationsLabel.text = generatedImages.formatted()
                }
            }
        }

        if UserPreferences.standard.apiKey == "0000000000" {
            logOutButtonLabel.text = "Log In"
        } else {
            logOutButtonLabel.text = "Log Out"
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 1 {
            if UserPreferences.standard.apiKey == "0000000000" {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "addAPIKeyNavController") as! UINavigationController
                controller.modalPresentationStyle = .pageSheet
                controller.isModalInPresentation = true
                present(controller, animated: true)
            } else {
                let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out? Be sure you've backed up your API key somewhere, as it cannot be recovered from Aislingeach once you log out.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                let yesAction = UIAlertAction(title: "Log Out", style: .destructive) { _ in
                    UserPreferences.standard.set(apiKey: "0000000000")
                    NotificationCenter.default.post(name: .newAPIKeySubmitted, object: nil)
                }
                alert.addAction(yesAction)
                alert.addAction(cancelAction)
                present(alert, animated: true)
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
