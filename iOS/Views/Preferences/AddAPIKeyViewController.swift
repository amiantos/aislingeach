//
//  AddAPIKeyViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 7/30/23.
//

import UIKit

class AddAPIKeyViewController: UIViewController {

    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitButtonAction(_ sender: UIButton) {
        if let apiKey = apiKeyTextField.text, !apiKey.isEmpty {
            apiKeyTextField.resignFirstResponder()
            submitButton.isEnabled = false
            HordeV2API.getFindUser(apikey: apiKey, clientAgent: hordeClientAgent()) { data, error in
                if let data = data, let username = data.username {
                    Log.debug("Found user \(username)")
                    let alert = UIAlertController(title: "Verify API Key", message: "This API key is assigned to the user \(username), does that look right?", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "Yes", style: .default) { _ in
                        UserPreferences.standard.set(apiKey: apiKey)
                        NotificationCenter.default.post(name: .newAPIKeySubmitted, object: nil)
                        DispatchQueue.main.async {
                            self.submitButton.isEnabled = true
                            self.dismiss(animated: true)
                        }
                    }
                    let noAction = UIAlertAction(title: "No", style: .cancel) { _ in
                        DispatchQueue.main.async {
                            self.submitButton.isEnabled = true
                        }
                    }
                    alert.addAction(alertAction)
                    alert.addAction(noAction)
                    DispatchQueue.main.async {
                        self.present(alert, animated: true)
                    }
                } else if let error = error {
                    Log.debug("Error: \(error.localizedDescription)")
                    let alert = UIAlertController(title: "Error", message: "We were unable to validate your API key. Try again?", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "Oh, okay...", style: .default)
                    alert.addAction(alertAction)
                    DispatchQueue.main.async {
                        self.submitButton.isEnabled = true
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }

    @IBAction func registerHordeButtonAction(_ sender: UIButton) {
        if let url = URL(string: "https://aihorde.net/register") {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func closeButtonAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
