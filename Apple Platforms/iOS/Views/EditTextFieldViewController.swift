//
//  EditTextFieldViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 9/16/23.
//

import UIKit

protocol EditTextFieldViewControllerDelegate {
    func saveValueChange(newValue: String) async -> (Bool, String?)
}

class EditTextFieldViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var descriptionLabel: UILabel!

    var delegate: EditTextFieldViewControllerDelegate?

    private var fieldName: String?
    private var initialText: String?
    private var descriptionText: String?

    private var saveButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Edit \(fieldName ?? "Field")"
        textField.text = initialText
        descriptionLabel.text = descriptionText

        self.saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem = saveButton
    }

    func setup(fieldName: String, initialText: String, descriptionText: String) {
        self.fieldName = fieldName
        self.initialText = initialText
        self.descriptionText = descriptionText
    }

    @objc func save() {
        guard let delegate = self.delegate else { fatalError("Delegate is not set on editor view.") }

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        Task {
            let result = await delegate.saveValueChange(newValue: self.textField.text ?? "")
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


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
