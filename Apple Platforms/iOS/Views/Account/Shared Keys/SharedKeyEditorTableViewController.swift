//
//  SharedKeyEditorTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 8/29/23.
//

import UIKit

enum SharedKeyEditableField {
    case name
    case kudos
    case expiry
    case max_image_pixels
    case max_image_steps
    case max_text_tokens
}

protocol SharedKeyEditorDelegate {
    func deletedSharedKey(indexPath: IndexPath)
}

class SharedKeyEditorTableViewController: UITableViewController, EditTextFieldViewControllerDelegate, EditLimitFieldViewControllerDelegate {
    var sharedKeyData: (SharedKeyDetails, UserDetails)?
    var indexPath: IndexPath?
    var delegate: SharedKeyEditorDelegate?

    var currentlyEditing: SharedKeyEditableField?


    @IBOutlet weak var nameTableViewCell: UITableViewCell!
    @IBOutlet weak var kudosLimitTableViewCell: UITableViewCell!
    @IBOutlet weak var kudosUtilizedTableViewCell: UITableViewCell!
    @IBOutlet weak var expirationDateTableViewCell: UITableViewCell!
    @IBOutlet weak var maxImagePixelsTableViewCell: UITableViewCell!
    @IBOutlet weak var maxImageStepsTableViewCell: UITableViewCell!
    @IBOutlet weak var maxTextTokensTableViewCell: UITableViewCell!

    @IBAction func copySharedKeyAction(_ sender: UIBarButtonItem) {
        UIPasteboard.general.string = sharedKeyData?.0._id
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backButtonTitle = "Cancel"

        if let sharedKeyData = sharedKeyData {
            nameTableViewCell.detailTextLabel?.text = sharedKeyData.0.name ?? sharedKeyData.1.username?.replacingOccurrences(of: "\(sharedKeyData.0.username!) (Shared Key: ", with: "").replacingOccurrences(of: ")", with: "")
            let sharedKeyKudos = sharedKeyData.0.kudos ?? 0
            kudosLimitTableViewCell.detailTextLabel?.text = sharedKeyKudos < 0 ? "No Limit" : sharedKeyKudos.formatted()
            kudosUtilizedTableViewCell.detailTextLabel?.text = sharedKeyData.0.utilized?.formatted() ?? 0.formatted()
            expirationDateTableViewCell.detailTextLabel?.text = sharedKeyData.0.expiry?.formatted() ?? "Never"
            maxImagePixelsTableViewCell.detailTextLabel?.text = sharedKeyData.0.maxImagePixels ?? 0 < 0 ? "No Limit" : sharedKeyData.0.maxImagePixels?.formatted()
            maxImageStepsTableViewCell.detailTextLabel?.text = sharedKeyData.0.maxImageSteps ?? 0 < 0 ? "No Limit" : sharedKeyData.0.maxImageSteps?.formatted()
            maxTextTokensTableViewCell.detailTextLabel?.text = sharedKeyData.0.maxTextTokens ?? 0 < 0 ? "No Limit" : sharedKeyData.0.maxTextTokens?.formatted()
        }
    }

    func setUp(sharedKeyData: (SharedKeyDetails, UserDetails), indexPath: IndexPath) {
        self.sharedKeyData = sharedKeyData
        self.indexPath = indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        switch cell.reuseIdentifier {
        case "nameTableViewCell":
            Log.debug("nameTableViewCell")
            currentlyEditing = .name
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editFieldViewController") as! EditTextFieldViewController
            view.setup(fieldName: "Name", initialText: nameTableViewCell.detailTextLabel?.text ?? "", descriptionText: "Note: This key name and your horde account name will be visible to the user utilizing your shared key.")
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "kudosLimitTableViewCell":
            Log.debug("kudosLimitTableViewCell")
            currentlyEditing = .kudos
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editLimitFieldViewController") as! EditLimitFieldViewController
            view.setup(fieldName: "Kudos Limit", initialValue: sharedKeyData?.0.kudos ?? 0, descriptionText: "Define a manual amount of kudos to limit the shared key to that amount of usage, or set the key to have no kudos limit.")
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "expirationDateTableViewCell":
            Log.debug("expirationDateTableViewCell")
            currentlyEditing = .expiry
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editLimitFieldViewController") as! EditLimitFieldViewController
            if let expiry = sharedKeyData?.0.expiry, let day = Calendar.current.dateComponents([.day], from: Date.now, to: expiry).day {
                view.setup(fieldName: "Expiration", initialValue: day, descriptionText: "Enter a number of days until the key should expire, or select No Limit to set the key to never expire.")
            } else {
                view.setup(fieldName: "Expiration", initialValue: -1, descriptionText: "Enter a number of days until the key should expire, or select No Limit to set the key to never expire.")
            }
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "maxImagePixelsTableViewCell":
            Log.debug("maxImagePixelsTableViewCell")
            currentlyEditing = .max_image_pixels
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editLimitFieldViewController") as! EditLimitFieldViewController
            view.setup(fieldName: "Max Image Pixels", initialValue: sharedKeyData?.0.maxImagePixels ?? 0, descriptionText: "Define a maximum pixel limit for generations. Use this to ensure that shared key users do not generate images too large, using too many kudos too quickly.\n\nThis value is measured in total pixel area, for example: to limit the key to 512x512 generations, use the value 262144. Maximum value is 4194304, equivalent to 2048x2048 square pixels.\n\nA value of 0 will disable image generation for this key.")
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "maxImageStepsTableViewCell":
            Log.debug("maxImageStepsTableViewCell")
            currentlyEditing = .max_image_steps
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editLimitFieldViewController") as! EditLimitFieldViewController
            view.setup(fieldName: "Max Image Steps", initialValue: sharedKeyData?.0.maxImageSteps ?? 0, descriptionText: "Define a maximum step limit for generations. This can help prevent shared key users from abusing your shared key for unnecessary high-step generations.\n\nMaximum value is 500. A good rule of thumb is that, with the right sampler selected, as few as 30 steps may be needed for quality generations.")
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "maxTextTokensTableViewCell":
            Log.debug("maxTextTokensTableViewCell")
            currentlyEditing = .max_text_tokens
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editLimitFieldViewController") as! EditLimitFieldViewController
            view.setup(fieldName: "Max Text Tokens", initialValue: sharedKeyData?.0.maxTextTokens ?? 0, descriptionText: "Define a maximum number of text tokens that can be generated per request. The maximum value is 500.")
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "deleteKeyCell":
            if let sharedKeyId = sharedKeyData?.0._id, let indexPath = self.indexPath {
                HordeV2API.deleteSharedKeySingle(sharedkeyId:sharedKeyId, apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { data, error in
                    if let data = data {
                        Log.debug(data)
                        self.delegate?.deletedSharedKey(indexPath: indexPath)
                        self.navigationController?.popViewController(animated: true)
                    } else if let error = error {
                        Log.debug(error)
                    }
                }
            }
        default:
            Log.debug("No match")
        }
        cell.setSelected(false, animated: true)
    }

    func saveValueChange(newValue: String) async -> (Bool, String?) {
        guard let sharedKeyId = sharedKeyData?.0._id else { fatalError("Unable to find shared key to modify")}
        do {
            try await HordeV2API.patchSharedKeySingle(
                body: SharedKeyInput(name: newValue),
                apikey: UserPreferences.standard.apiKey,
                sharedkeyId: sharedKeyId,
                clientAgent: hordeClientAgent()
            )
            nameTableViewCell.detailTextLabel?.text = newValue
            sharedKeyData?.0.name = newValue
            return (true, nil)
        } catch {
            return (false, "Unable to save changes. Try again later?")
        }
    }

    func saveValueChange(newValue: Int) async -> (Bool, String?) {
        guard let sharedKeyId = sharedKeyData?.0._id else { fatalError("Unable to find shared key to modify")}
        var sharedKeyDetails = SharedKeyInput()
        switch currentlyEditing {
        case .kudos:
            sharedKeyDetails.kudos = newValue
            kudosLimitTableViewCell.detailTextLabel?.text = newValue < 0 ? "No Limit" : newValue.formatted()
            sharedKeyData?.0.kudos = newValue
        case .expiry:
            sharedKeyDetails.expiry = newValue
            if newValue > -1 {
                expirationDateTableViewCell.detailTextLabel?.text = Calendar.current.date(byAdding: .day, value: newValue, to: Date.now)!.formatted()
                sharedKeyData?.0.expiry = Calendar.current.date(byAdding: .day, value: newValue, to: Date.now)!
            } else {
                expirationDateTableViewCell.detailTextLabel?.text = "Never"
                sharedKeyData?.0.expiry = nil
            }
        case .max_image_pixels:
            sharedKeyDetails.max_image_pixels = newValue
            maxImagePixelsTableViewCell.detailTextLabel?.text = newValue < 0 ? "No Limit" : newValue.formatted()
        case .max_image_steps:
            sharedKeyDetails.max_image_steps = newValue
            maxImageStepsTableViewCell.detailTextLabel?.text = newValue < 0 ? "No Limit" : newValue.formatted()
        case .max_text_tokens:
            sharedKeyDetails.max_text_tokens = newValue
            maxTextTokensTableViewCell.detailTextLabel?.text = newValue < 0 ? "No Limit" : newValue.formatted()
        default:
            return (false, "Unknown field being edited, this shouldn't happen.")
        }
        Log.debug(sharedKeyDetails)
        do {
            try await HordeV2API.patchSharedKeySingle(
                body: sharedKeyDetails,
                apikey: UserPreferences.standard.apiKey,
                sharedkeyId: sharedKeyId,
                clientAgent: hordeClientAgent()
            )
            return (true, nil)
        } catch {
            return (false, "Unable to save changes. Try again later?")
        }
    }

}
