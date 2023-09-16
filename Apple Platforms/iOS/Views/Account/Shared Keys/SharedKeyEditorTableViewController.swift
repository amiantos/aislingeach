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

class SharedKeyEditorTableViewController: UITableViewController, EditTextFieldViewControllerDelegate {
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
            maxImagePixelsTableViewCell.detailTextLabel?.text = sharedKeyData.0.maxImagePixels ?? 0 < 0 ? "None" : sharedKeyData.0.maxImagePixels?.formatted()
            maxImageStepsTableViewCell.detailTextLabel?.text = sharedKeyData.0.maxImageSteps ?? 0 < 0 ? "None" : sharedKeyData.0.maxImageSteps?.formatted()
            maxTextTokensTableViewCell.detailTextLabel?.text = sharedKeyData.0.maxTextTokens ?? 0 < 0 ? "None" : sharedKeyData.0.maxTextTokens?.formatted()
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
        case "expirationDateTableViewCell":
            Log.debug("expirationDateTableViewCell")
        case "maxImagePixelsTableViewCell":
            Log.debug("maxImagePixelsTableViewCell")
        case "maxImageStepsTableViewCell":
            Log.debug("maxImageStepsTableViewCell")
        case "maxTextTokensTableViewCell":
            Log.debug("maxTextTokensTableViewCell")
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
}
