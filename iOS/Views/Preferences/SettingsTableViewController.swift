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
            print("API key updated...")
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
}
