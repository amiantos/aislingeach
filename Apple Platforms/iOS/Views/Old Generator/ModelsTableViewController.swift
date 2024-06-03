//
//  ModelsTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 6/4/23.
//

import UIKit
import Algorithms

protocol ModelsTableViewControllerDelegate {
    func selectedModel(name: String)
}

class ModelsTableViewController: UITableViewController, UISearchResultsUpdating {
    var activeModels: [ActiveModel] = [] {
        didSet {
            var favoriteModels = activeModels.filter { model in
                favoritesArray.contains { $0 == model.name }
            }
            favoriteModels.sort { $0.count ?? 0 > $1.count ?? 0 }

            var notFavoriteModels = activeModels.filter { model in
                !favoritesArray.contains { $0 == model.name }
            }
            notFavoriteModels.sort { $0.count ?? 0 > $1.count ?? 0 }

            activeModels = Array(chain(favoriteModels, notFavoriteModels))
        }
    }
    var allModels: [ActiveModel] = []
    var delegate: ModelsTableViewControllerDelegate?

    var favoritesArray: [String] = [] {
        didSet {
            favoritesArray = Array(favoritesArray.uniqued())
            UserPreferences.standard.set(favoriteModels: favoritesArray)
            Log.debug(favoritesArray)
        }
    }

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

        favoritesArray = UserPreferences.standard.favoriteModels
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let cache = ModelsCache.standard.getModels() {
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
                    if let data = data {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "modelTableCell", for: indexPath) as! ModelsTableViewCell

        let activeModel = activeModels[indexPath.row]
        cell.modelNameLabel.text = activeModel.name
        cell.modelStatusLabel.text = "Workers: \(activeModel.count ?? 0) • Queue: \(activeModel.jobs ?? 0) • Wait: \(activeModel.eta ?? 0) seconds"
        cell.delegate = self

        if favoritesArray.contains(where: { $0 == activeModel.name}) {
            cell.isFavorite = true
        } else {
            cell.isFavorite = false
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? ModelsTableViewCell
        if let name = cell?.modelNameLabel.text {
            delegate?.selectedModel(name: name)
            navigationController?.popViewController(animated: true)
        }
    }
}

extension ModelsTableViewController: ModelsTableViewCellDelegate {
    func addFavorite(modelName: String, sender: ModelsTableViewCell) {
        favoritesArray.append(modelName)
        guard let indexPath = tableView.indexPath(for: sender) else { return }
        tableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: 0))
    }
    
    func removeFavorite(modelName: String, sender: ModelsTableViewCell) {
        favoritesArray.removeAll { $0 == modelName }
    }

}
