//
//  SettingsTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import UIKit
import LocalAuthentication

class SettingsTableViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet var apiKeyTextField: UITextField!

    @IBAction func apiKeySaveAction(_ sender: UITextField) {
        if var newKey = sender.text, newKey != UserPreferences.standard.apiKey {
            if newKey == "" { newKey = "0000000000" }
            Log.info("API key updated...")
            UserPreferences.standard.set(apiKey: newKey)
            apiKeyTextField.text = UserPreferences.standard.apiKey
        }
        apiKeyTextField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        apiKeyTextField.delegate = self
        apiKeyTextField.text = UserPreferences.standard.apiKey
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        if cell.reuseIdentifier == "hiddenContentCell" {
            let context = LAContext()
            let reason = "Get access to Hidden Content"
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            ) { success, error in
                if success {
                    DispatchQueue.main.async {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let controller = storyboard.instantiateViewController(withIdentifier: "albumGalleryView") as! AlbumsCollectionViewController
                        controller.showHidden = true
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                }
            }
        }
    }
}
