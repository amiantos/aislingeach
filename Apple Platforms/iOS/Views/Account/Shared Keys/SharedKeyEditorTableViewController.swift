//
//  SharedKeyEditorTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 8/29/23.
//

import UIKit

class SharedKeyEditorTableViewController: UITableViewController {

    var sharedKeyData: (SharedKeyDetails, UserDetails)? = nil


    @IBOutlet weak var nameTableViewCell: UITableViewCell!
    @IBOutlet weak var kudosLimitTableViewCell: UITableViewCell!
    @IBOutlet weak var kudosUtilizedTableViewCell: UITableViewCell!
    @IBOutlet weak var expirationDateTableViewCell: UITableViewCell!
    @IBOutlet weak var maxImagePixelsTableViewCell: UITableViewCell!
    @IBOutlet weak var maxImageStepsTableViewCell: UITableViewCell!
    @IBOutlet weak var maxTextTokensTableViewCell: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()

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

    func setUp(sharedKeyData: (SharedKeyDetails, UserDetails)) {
        self.sharedKeyData = sharedKeyData
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        switch cell.reuseIdentifier {
        case "nameTableViewCell":
            Log.debug("nameTableViewCell")
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
            Log.debug("deleteKeyCell")
        default:
            Log.debug("No match")
        }
        cell.setSelected(false, animated: true)
    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
