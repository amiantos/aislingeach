//
//  SharedKeysTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 8/26/23.
//

import UIKit

class SharedKeysTableViewController: UITableViewController {

    var sharedKeys: [(SharedKeyDetails, UserDetails)] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    func loadUserData() {
        Task(priority: .userInitiated) {
            sharedKeys = []
            if let data = try? await HordeV2API.getFindUser(apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()),
               let sharedKeyIds = data.sharedkeyIds {
                for sharedKeyId in sharedKeyIds {
                    if let sharedKeyDetails = try? await HordeV2API.getSharedKeySingle(sharedkeyId: sharedKeyId, clientAgent: hordeClientAgent()),
                       let apiKeyDetails = try? await HordeV2API.getFindUser(apikey: sharedKeyId, clientAgent: hordeClientAgent()) {
                        DispatchQueue.main.async {
                            self.sharedKeys.append((sharedKeyDetails, apiKeyDetails))
                            self.tableView.insertRows(at: [IndexPath(row: self.sharedKeys.count-1, section: 0)], with: .automatic)
                        }
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadUserData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return sharedKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "sharedKeyCell", for: indexPath) as? SharedKeyTableViewCell else { fatalError() }

        let sharedKeyData = sharedKeys[indexPath.row]

        cell.sharedKeyIdLabel.text = sharedKeyData.0._id
        cell.nameLabel.text = sharedKeyData.0.name ?? sharedKeyData.1.username?.replacingOccurrences(of: "\(sharedKeyData.0.username!) (Shared Key: ", with: "").replacingOccurrences(of: ")", with: "")
        let sharedKeyKudos = sharedKeyData.0.kudos ?? 0
        cell.kudosLabel.text = sharedKeyKudos < 0 ? "No Limit" : sharedKeyKudos.formatted()
        cell.utilizedLabel.text = sharedKeyData.0.utilized?.formatted() ?? 0.formatted()
        cell.expiryLabel.text = sharedKeyData.0.expiry?.formatted() ?? "Never"
        cell.maxPixelsLabel.text = sharedKeyData.0.maxImagePixels ?? 0 < 0 ? "None" : sharedKeyData.0.maxImagePixels?.formatted()
        cell.maxStepsLabel.text = sharedKeyData.0.maxImageSteps ?? 0 < 0 ? "None" : sharedKeyData.0.maxImageSteps?.formatted()
        cell.maxTextTokensLabel.text = sharedKeyData.0.maxTextTokens ?? 0 < 0 ? "None" : sharedKeyData.0.maxTextTokens?.formatted()

        return cell
    }

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
