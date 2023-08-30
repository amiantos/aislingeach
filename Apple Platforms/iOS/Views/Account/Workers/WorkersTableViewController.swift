//
//  WorkersTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 8/13/23.
//

import UIKit

class WorkersTableViewController: UITableViewController {

    var workerData: [WorkerDetails] = [] {
        didSet {
            workerData.sort { w1, w2 in
                w1.name! < w2.name!
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 300
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(loadUserData), for: .valueChanged)

        loadUserData()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    @objc func loadUserData() {
        workerData.removeAll()
        HordeV2API.getFindUser(apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { data, _ in
            if let data = data, let workerIds = data.workerIds {
                if workerIds.isEmpty {
                    // TODO: Load empty state
                } else {
                    let count = workerIds.count
                    var i: Int = 0
                    for workerId in workerIds {
                        HordeV2API.getWorkerSingle(workerId: workerId, apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { data, error in
                            if let data = data {
                                self.workerData.append(data)
                                i += 1
                                if i == count {
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                        self.tableView.refreshControl?.endRefreshing()
                                    }
                                }
                            }
                        }
                    }

                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return workerData.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "workerCell", for: indexPath) as! WorkerTableViewCell
        let workerDetails = workerData[indexPath.row]

        cell.setup(details: workerDetails)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? WorkerTableViewCell else { return }
        if let online =  cell.workerDetails?.online, online {
            if cell.maintenanceMode, let workerId = cell.workerDetails?._id {
                let alert = UIAlertController(title: "Maintenace Mode", message: "Do you want to disable Maintenance mode on this worker?", preferredStyle: .alert)
                let noAction = UIAlertAction(title: "No", style: .cancel)
                let yesAction = UIAlertAction(title: "Disable", style: .default) { action in
                    HordeV2API.putWorkerSingle(body: ModifyWorkerInput(maintenance: false), apikey: UserPreferences.standard.apiKey, workerId: workerId, clientAgent: hordeClientAgent()) { data, error in
                        if let data = data {
                            DispatchQueue.main.async {
                                cell.statusLabel.text = "Online"
                                cell.maintenanceMode = false
                            }
                        } else if let error = error {
                            Log.error("Unable to disable maintenance mode: \(error.localizedDescription)")
                        }
                    }
                }
                alert.addAction(noAction)
                alert.addAction(yesAction)
                self.present(alert, animated: true)
            } else if let workerId = cell.workerDetails?._id {
                let alert = UIAlertController(title: "Maintenance Mode", message: "Do you want to enable Maintenance mode on this worker?", preferredStyle: .alert)
                let noAction = UIAlertAction(title: "No", style: .cancel)
                let yesAction = UIAlertAction(title: "Enable", style: .default) { action in
                    HordeV2API.putWorkerSingle(body: ModifyWorkerInput(maintenance: true), apikey: UserPreferences.standard.apiKey, workerId: workerId, clientAgent: hordeClientAgent()) { data, error in
                        if let data = data {
                            DispatchQueue.main.async {
                                cell.statusLabel.text = "Maintenance"
                                cell.maintenanceMode = true
                            }
                        } else if let error = error {
                            Log.error("Unable to enable maintenance mode: \(error.localizedDescription)")
                        }
                    }
                }
                alert.addAction(noAction)
                alert.addAction(yesAction)
                self.present(alert, animated: true)
            }
        }
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
