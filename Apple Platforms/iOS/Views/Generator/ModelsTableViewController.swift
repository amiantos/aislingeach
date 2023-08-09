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

class ModelsTableViewController: UITableViewController, UISearchResultsUpdating {
    var activeModels: [ActiveModel] = []
    var allModels: [ActiveModel] = []
    var delegate: ModelsTableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(refreshModelList), for: .valueChanged)

        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.hidesNavigationBarDuringPresentation = false
        search.searchBar.placeholder = "Search models by name"
        navigationItem.searchController = search
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let cache = ModelsCache.standard.get() {
            allModels = cache
            activeModels = cache
            tableView.reloadData()
        } else {
            refreshModelList()
        }
    }

    @objc func refreshModelList() {
        navigationItem.searchController?.isActive = false
        tableView.refreshControl?.endRefreshing()
        allModels = []
        activeModels = []
        tableView.reloadData()
        DispatchQueue.global(qos: .userInitiated).async {
            HordeV2API.getModels(clientAgent: hordeClientAgent()) { data, error in
                DispatchQueue.main.async {
                    if var data = data {
                        data.sort { $0.count ?? 0 > $1.count ?? 0 }
                        ModelsCache.standard.cache(models: data)
                        self.allModels = data
                        self.activeModels = data
                        self.tableView.reloadData()
                    } else if let error = error {
                        self.allModels = []
                        self.activeModels = []
                        Log.error("Unable to load active models. \(error)")
                    }
                }
            }
        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        Log.debug("Searched for: \(text)")
        if text.isEmpty {
            activeModels = allModels
        } else {
            activeModels = allModels.filter { $0.name!.lowercased().contains(text.lowercased()) }
        }
        tableView.reloadData()
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
            navigationController?.popViewController(animated: true)
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
