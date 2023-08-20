//
//  StylesTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 8/19/23.
//

import UIKit

struct Category {
    let title: String
    let styles: [String]
}

struct Style: Decodable {
    let prompt: String
    let model: String?
    let width: Int?
    let height: Int?
    let steps: Int?
    let cfg_scale: Decimal?
    let samplerName: String?
    let loras: [ModelPayloadLorasStable]?
}

protocol StylesTableViewControllerDelegate {
    func selectedStyle(title: String, style: Style?)
}


class StylesTableViewController: UITableViewController {

    var delegate: StylesTableViewControllerDelegate?

    @IBAction func helpButtonAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "What are styles?", message: "Styles are preset bundles of settings that may add words to your prompt and override some of your generation settings automatically.\n\nThey're meant to help you experiment and make good looking images more easily.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Groovy", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }

    @IBOutlet weak var helpButton: UIBarButtonItem!

    var categories: [Category] = [] {
        didSet {
            categories.sort { c1, c2 in
                c1.title < c2.title
            }
            categories.insert(Category(title: "Default", styles: ["None"]), at: 0)
            tableView.reloadData()
        }
    }

    var styles: [String: Style] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await loadData()
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    func loadData() async {
        // https://raw.githubusercontent.com/Haidra-Org/AI-Horde-Styles/main/categories.json
        let url = URL(string: "https://raw.githubusercontent.com/Haidra-Org/AI-Horde-Styles/main/categories.json")!
        let url2 = URL(string: "https://raw.githubusercontent.com/Haidra-Org/AI-Horde-Styles/main/styles.json")!
        let urlSession = URLSession.shared
        do {
            let (data, _) = try await urlSession.data(from: url)
            let categories = try JSONDecoder().decode([String: [String]].self, from: data)

            let (data2, _) = try await urlSession.data(from: url2)
            Log.debug(String(data: data2, encoding: .utf8))
            self.styles = try JSONDecoder().decode([String: Style].self, from: data2)

            let newCategories = categories.map { key, value in
                return Category(title: key, styles: value.sorted())
            }
            self.categories = newCategories
        } catch {
            Log.error("Unable to grab style categories: \(error.localizedDescription)")
        }


    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return categories[section].styles.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categories[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "styleCell", for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = categories[indexPath.section].styles[indexPath.row]

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath),
              let styleName = cell.textLabel?.text else { return }
        if styleName == "None" {
            delegate?.selectedStyle(title: "None", style: nil)
            navigationController?.popViewController(animated: true)
            return
        }
        guard let style = styles[styleName]  else {
            let alert = UIAlertController(title: "Whoops!", message: "This style could not be loaded, please try another.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Oh, okay...", style: .default)
            alert.addAction(action)
            present(alert, animated: true)
            return
        }
        delegate?.selectedStyle(title: styleName, style: style)
        navigationController?.popViewController(animated: true)
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
