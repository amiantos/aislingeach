//
//  SharedKeysTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 8/26/23.
//

import UIKit

class SharedKeysTableViewController: UITableViewController {

    var sharedKeys: [(SharedKeyDetails, UserDetails)] = []
    var loading: Bool = false

    @IBAction func addSharedKeyButtonAction(_ sender: UIBarButtonItem) {
        let ac = UIAlertController(title: "Add Shared Key", message: "Enter a name for your new shared key", preferredStyle: .alert)
        ac.addTextField()

        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            if answer.hasText, let name = answer.text, !name.isEmpty {
                Task {
                    do {
                        let result = try await HordeV2API.putSharedKey(
                            body: SharedKeyInput(name: name),
                            apikey: UserPreferences.standard.apiKey,
                            clientAgent: hordeClientAgent()
                        )


                        if let sharedKeyId = result._id, let sharedKeyDetails = try? await HordeV2API.getSharedKeySingle(sharedkeyId: sharedKeyId, clientAgent: hordeClientAgent()),
                           let apiKeyDetails = try? await HordeV2API.getFindUser(apikey: sharedKeyId, clientAgent: hordeClientAgent()) {
                            DispatchQueue.main.async {
                                self.sharedKeys.append((sharedKeyDetails, apiKeyDetails))
                                self.tableView.insertRows(at: [IndexPath(row: self.sharedKeys.count-1, section: 0)], with: .automatic)
                            }
                        }
                    } catch {
                        Log.error(error)
                        let alert = UIAlertController(title: "Error", message: "Unable to create new shared key, try again later?", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Oh, okay...", style: .default)
                        alert.addAction(action)
                        self.present(alert, animated: true)
                    }
                }
            }
        }

        ac.addAction(submitAction)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(ac, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func loadUserData() {
        if loading { return }
        loading = true
        Task(priority: .userInitiated) {
            sharedKeys = []
            tableView.reloadData()
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
                self.loading = false
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sharedKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "sharedKeyCell", for: indexPath) as? SharedKeyTableViewCell else { fatalError() }

        let sharedKeyData = sharedKeys[indexPath.row]

        cell.nameLabel.text = sharedKeyData.0.name ?? sharedKeyData.1.username?.replacingOccurrences(of: "\(sharedKeyData.0.username!) (Shared Key: ", with: "").replacingOccurrences(of: ")", with: "")
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sharedKeySegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let sharedKeyData = sharedKeys[indexPath.row]
                if let view = segue.destination as? SharedKeyEditorTableViewController {
                    view.delegate = self
                    view.setUp(sharedKeyData: sharedKeyData, indexPath: indexPath)
                }
            }
        }
    }

}

extension SharedKeysTableViewController: SharedKeyEditorDelegate {
    func deletedSharedKey(indexPath: IndexPath) {
        sharedKeys.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

}
