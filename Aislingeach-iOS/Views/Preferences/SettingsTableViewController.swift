//
//  SettingsTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import UIKit

class SettingsTableViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet weak var apiKeyTextField: UITextField!

    @IBAction func apiKeySaveAction(_ sender: UITextField) {
        if var newKey = sender.text, newKey != Preferences.standard.apiKey {
            if newKey == "" { newKey = "0000000000" }
            print("API key updated...")
            Preferences.standard.set(apiKey: newKey)
            apiKeyTextField.text = Preferences.standard.apiKey
        }
        apiKeyTextField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        apiKeyTextField.delegate = self
        apiKeyTextField.text = Preferences.standard.apiKey
    }
}
