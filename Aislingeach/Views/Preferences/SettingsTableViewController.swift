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
        if let newKey = sender.text, newKey != Preferences.standard.apiKey {
            print("API key updated...")
            Preferences.standard.set(apiKey: sender.text ?? "")
        }
        apiKeyTextField.resignFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        apiKeyTextField.delegate = self
        apiKeyTextField.text = Preferences.standard.apiKey
    }
}
