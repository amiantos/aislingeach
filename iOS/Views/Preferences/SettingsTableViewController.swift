//
//  SettingsTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import UIKit

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
            let alert = UIAlertController(title: "Show Hidden Items", message: "Are you... sure you want to do this?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .destructive) { _ in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "imageGalleryView") as! ImageCollectionViewController
                controller.viewFolder = "hidden"
                self.navigationController?.pushViewController(controller, animated: true)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true)
        }
    }
}
