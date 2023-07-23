//
//  ModelsTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 6/4/23.
//

import UIKit

protocol ModelsTableViewControllerDelegate {
    func selectedModel(name: String)
}

class ModelsTableViewController: UITableViewController {
    var activeModels: [ActiveModel] = []
    var delegate: ModelsTableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refreshModelList), for: .valueChanged)

        if let cache = ModelsCache.standard.get() {
            activeModels = cache
            tableView.reloadData()
        } else {
            refreshModelList()
        }
    }

    @objc func refreshModelList() {
        tableView.refreshControl?.endRefreshing()
        activeModels = []
        tableView.reloadData()
        DispatchQueue.global(qos: .userInitiated).async {
            HordeV2API.getModels(clientAgent: hordeClientAgent(), minCount: 1) { data, error in
                DispatchQueue.main.async {
                    if var data = data {
                        data.sort { $0.count ?? 0 > $1.count ?? 0 }
                        ModelsCache.standard.cache(models: data)
                        self.activeModels = data
                        self.tableView.reloadData()
                    } else if let error = error {
                        self.activeModels = []
                        Log.error("Unable to load active models. \(error)")
                    }
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return activeModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "modelTableCell", for: indexPath)

        let activeModel = activeModels[indexPath.row]
        cell.textLabel?.text = activeModel.name
        cell.detailTextLabel?.text = "Workers: \(activeModel.count ?? 0) • Queue: \(activeModel.jobs ?? 0) • Wait: \(activeModel.eta ?? 0) seconds"

        return cell
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let activeModel = activeModels[indexPath.row]
        if let name = activeModel.name {
            delegate?.selectedModel(name: name)
            dismiss(animated: true)
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
