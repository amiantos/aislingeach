//
//  SharedKeyEditorTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 8/29/23.
//

import UIKit

protocol SharedKeyEditorDelegate {
    func deletedSharedKey(indexPath: IndexPath)
}

class SharedKeyEditorTableViewController: UITableViewController, EditTextFieldViewControllerDelegate, EditLimitFieldViewControllerDelegate {
    var sharedKeyData: (SharedKeyDetails, UserDetails)? = nil
    var indexPath: IndexPath? = nil
    var delegate: SharedKeyEditorDelegate? = nil


    @IBOutlet weak var nameTableViewCell: UITableViewCell!
    @IBOutlet weak var kudosLimitTableViewCell: UITableViewCell!
    @IBOutlet weak var kudosUtilizedTableViewCell: UITableViewCell!
    @IBOutlet weak var expirationDateTableViewCell: UITableViewCell!
    @IBOutlet weak var maxImagePixelsTableViewCell: UITableViewCell!
    @IBOutlet weak var maxImageStepsTableViewCell: UITableViewCell!
    @IBOutlet weak var maxTextTokensTableViewCell: UITableViewCell!

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
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editFieldViewController") as! EditTextFieldViewController
            view.setup(fieldName: "Name", initialText: nameTableViewCell.detailTextLabel?.text ?? "", descriptionText: "Note: This key name and your horde account name will be visible to the user utilizing your shared key.")
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "kudosLimitTableViewCell":
            Log.debug("kudosLimitTableViewCell")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editLimitFieldViewController") as! EditLimitFieldViewController
            view.setup(fieldName: "Kudos Limit", initialValue: sharedKeyData?.0.kudos ?? 0, descriptionText: "Define a manual amount of kudos to limit the shared key to that amount of usage, or set the key to have no kudos limit.")
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "expirationDateTableViewCell":
            Log.debug("expirationDateTableViewCell")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editLimitFieldViewController") as! EditLimitFieldViewController
            view.setup(fieldName: "Expiration", initialValue: (sharedKeyData?.0.expiry == nil ? -1 : 0), descriptionText: "Enter a number of days until the key should expire, or select No Limit to set the key to never expire.")
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "maxImagePixelsTableViewCell":
            Log.debug("maxImagePixelsTableViewCell")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editLimitFieldViewController") as! EditLimitFieldViewController
            view.setup(fieldName: "Max Image Pixels", initialValue: sharedKeyData?.0.maxImagePixels ?? 0, descriptionText: "Define a maximum pixel limit for generations. Use this to ensure that shared key users do not generate images too large, using too many kudos too quickly.\n\nThis value is measured in total pixel area, for example: to limit the key to 512x512 generations, use the value 262144. Maximum value is 4194304, equivalent to 2048x2048 square pixels.\n\nA value of 0 will disable image generation for this key.")
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "maxImageStepsTableViewCell":
            Log.debug("maxImageStepsTableViewCell")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let view = storyboard.instantiateViewController(withIdentifier: "editLimitFieldViewController") as! EditLimitFieldViewController
            view.setup(fieldName: "Max Image Steps", initialValue: sharedKeyData?.0.maxImageSteps ?? 0, descriptionText: "Define a maximum step limit for generations. This can help prevent shared key users from abusing your shared key for unnecessary high-step generations.\n\nMaximum value is 500. A good rule of thumb is that, with the right sampler selected, as few as 30 steps may be needed for quality generations.")
            view.delegate = self
            navigationController?.pushViewController(view, animated: true)
        case "maxTextTokensTableViewCell":
            Log.debug("maxTextTokensTableViewCell")
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
            return (true, nil)
        } catch {
            return (false, "Unable to save changes. Try again later?")
        }
    }

    func saveValueChange(newValue: Int) async -> (Bool, String?) {
        Log.debug("New value: \(newValue)")
        return (true, nil)
    }

}
