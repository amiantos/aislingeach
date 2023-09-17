//
//  EditLimitFieldViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 9/16/23.
//

import UIKit

protocol EditLimitFieldViewControllerDelegate {
    func saveValueChange(newValue: Int) async -> (Bool, String?)
}

class EditLimitFieldViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var noLimitToggle: UISwitch!
    @IBAction func noLimitToggleChanged(_ sender: UISwitch) {
        if noLimitToggle.isOn {
            textField.isEnabled = false
            textField.text = nil
        } else {
            textField.isEnabled = true
            textField.text = "0"
        }
    }
    
    var delegate: EditLimitFieldViewControllerDelegate?

    private var fieldName: String?
    private var initialValue: Int?
    private var descriptionText: String?

    private var saveButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Edit \(fieldName ?? "Field")"
        descriptionLabel.text = descriptionText

        if let value = initialValue {
            if value < 0 {
                noLimitToggle.isOn = true
                textField.isEnabled = false
                textField.text = nil
            } else {
                textField.text = "\(value)"
                noLimitToggle.isOn = false
            }
        }

        self.saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem = saveButton
    }

    func setup(fieldName: String, initialValue: Int, descriptionText: String) {
        self.fieldName = fieldName
        self.initialValue = initialValue
        self.descriptionText = descriptionText
    }

    @objc func save() {
        guard let delegate = self.delegate else { fatalError("Delegate is not set on editor view.") }

        let newValue: Int = noLimitToggle.isOn ? -1 : Int(self.textField.text ?? "0")!

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        Task {
            let result = await delegate.saveValueChange(newValue: newValue)
            if result.0 {
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                DispatchQueue.main.async {
                    self.navigationItem.rightBarButtonItem = self.saveButton
                    let alert = UIAlertController(title: "Error", message: result.1, preferredStyle: .alert)
                    let okayButton = UIAlertAction(title: "Oh, okay...", style: .default)
                    alert.addAction(okayButton)
                    self.present(alert, animated: true)
                }
            }
        }
    }
}
