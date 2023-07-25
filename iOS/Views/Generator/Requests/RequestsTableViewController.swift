//
//  RequestsTableViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 7/19/23.
//

import CoreData
import UIKit

class RequestsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    @IBOutlet var headerView: UIView!
    @IBOutlet var createNewRequestButton: UIButton!
    @IBAction func createNewRequestButtonAction(_: UIButton) {
        present(appDelegate.generationTracker.createViewNavigationController, animated: true)
    }

    var resultsController: NSFetchedResultsController<HordeRequest>?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

        setupDataSource()
        tableView.tableHeaderView = headerView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        super.viewWillDisappear(animated)
    }

    private func setupDataSource() {
        let fetchRequest = NSFetchRequest<HordeRequest>(entityName: "HordeRequest")
        // Configure the request's entity, and optionally its predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: ImageDatabase.standard.mainManagedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        resultsController = controller
        controller.delegate = self

        do {
            try controller.performFetch()
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        if let frc = resultsController {
            return frc.sections!.count
        }
        return 0
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = resultsController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "requestCell", for: indexPath) as! RequestsTableViewCell

        guard let object = resultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        cell.setup(request: object)

        return cell
    }

    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 124
    }

    // MARK: - NSFetchedResultsControllerDelegate

    var ops: [BlockOperation] = []

    func controller(_: NSFetchedResultsController<NSFetchRequestResult>, didChange _: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            ops.append(BlockOperation(block: { [weak self] in
                self?.tableView.insertRows(at: [newIndexPath!], with: .automatic)
            }))
        case .delete:
            ops.append(BlockOperation(block: { [weak self] in
                self?.tableView.deleteRows(at: [indexPath!], with: .automatic)
            }))
        case .update:
            ops.append(BlockOperation(block: { [weak self] in
                self?.tableView.reloadRows(at: [indexPath!], with: .none)
            }))
        case .move:
            ops.append(BlockOperation(block: { [weak self] in
                self?.tableView.moveRow(at: indexPath!, to: newIndexPath!)
            }))
        @unknown default:
            break
        }
    }

    func controllerDidChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.performBatchUpdates({ () in
            for op: BlockOperation in self.ops { op.start() }
        }, completion: { _ in self.ops.removeAll() })
    }

    deinit {
        for o in ops { o.cancel() }
        ops.removeAll()
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
         // Return false if you do not want the specified item to be editable.
         return true
     }
     */

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let request = resultsController?.object(at: indexPath) else { fatalError("Attempt to delete a row without an object") }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "imageGalleryView") as! ThumbnailBrowserViewController
        controller.setup(title: request.prompt ?? request.uuid?.uuidString ?? "", predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "requestId = %@", request.uuid! as CVarArg), NSPredicate(format: "isHidden = %d", false)]))
        navigationController?.pushViewController(controller, animated: true)
    }

    // Override to support editing the table view.
    override func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let request = resultsController?.object(at: indexPath) else { fatalError("Attempt to delete a row without an object") }

            if request.status == "error" || request.status == "done" {
                ImageDatabase.standard.deleteRequest(request, pruneImages: false) { request in
                    if request != nil { fatalError("Deleting request did not work?") }
                }
            } else if request.status != "finished" {
                let alert = UIAlertController(title: "Delete Refused", message: "This request is still processing, you can't delete it yet, sorry.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Oh... weird, okay", style: .cancel)
                alert.addAction(cancelAction)
                present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: "Delete Request", message: "Would you like to prune the unmarked images from this request?", preferredStyle: .alert)
                let deleteImagesAction = UIAlertAction(title: "Prune images", style: .destructive) { _ in
                    ImageDatabase.standard.deleteRequest(request, pruneImages: true) { request in
                        if request != nil { fatalError("Deleting request did not work?") }
                    }
                }
                let deleteRequestAction = UIAlertAction(title: "Keep all images", style: .default) { _ in
                    ImageDatabase.standard.deleteRequest(request, pruneImages: false) { request in
                        if request != nil { fatalError("Deleting request did not work?") }
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                alert.addAction(deleteImagesAction)
                alert.addAction(deleteRequestAction)
                alert.addAction(cancelAction)
                present(alert, animated: true)
            }
        }
    }

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
