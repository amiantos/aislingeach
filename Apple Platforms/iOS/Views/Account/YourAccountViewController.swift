//
//  YourAccountViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 7/31/23.
//

import UIKit

class YourAccountViewController: UIViewController {

    @IBOutlet weak var loggedInContentView: UIView!
    @IBOutlet weak var loggedOutUserContentView: UIView!
    @IBOutlet weak var loadingUserDataContentView: UIView!

    @IBAction func addAPIKeyButtonAction(_ sender: UIButton) {
        showLoginView()
    }
    @IBAction func logOutButtonAction(_ sender: UIButton) {
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

    @IBOutlet weak var manageWorkersButton: UIButton!
    @IBOutlet weak var manageSharedKeysButton: UIButton!
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var totalKudosLabel: UILabel!
    @IBOutlet weak var totalImagesRequestedLabel: UILabel!
    @IBOutlet weak var kudosGiftedToYouLabel: UILabel!
    @IBOutlet weak var kudosGiftedToOthersLabel: UILabel!
    @IBOutlet weak var workerImagesGeneratedLabel: UILabel!
    @IBOutlet weak var recurringKudosLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(setup), name: .newAPIKeySubmitted, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
    }

    func showLoginView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "addAPIKeyNavController") as! UINavigationController
        controller.modalPresentationStyle = .pageSheet
        controller.isModalInPresentation = true
        present(controller, animated: true)
    }

    @objc func setup() {
        if UserPreferences.standard.apiKey == "0000000000" {
            loggedOutUserContentView.isHidden = false
        } else {
            loggedOutUserContentView.isHidden = true
            loadingUserDataContentView.isHidden = false
            loadUserData()
        }
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
                let workerCount = data.workerCount ?? 0
                let imagesGenerated = data.contributions?.fulfillments ?? data.records?.fulfillment?.image ?? 0
                let recurringKudos = data.kudosDetails?.recurring ?? 0
                DispatchQueue.main.async { [self] in
                    usernameLabel.text = username
                    totalKudosLabel.text = totalKudos.formatted()
                    totalImagesRequestedLabel.text = totalImages.formatted()
                    kudosGiftedToYouLabel.text = receivedKudos.formatted()
                    kudosGiftedToOthersLabel.text = giftedKudos.formatted()
                    workerImagesGeneratedLabel.text = imagesGenerated.formatted()
                    loadingUserDataContentView.isHidden = true
                    loggedInContentView.isHidden = false
                    recurringKudosLabel.text = recurringKudos.formatted()

                    if workerCount > 0 {
                        manageWorkersButton.isEnabled = true
                    }
                }
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
