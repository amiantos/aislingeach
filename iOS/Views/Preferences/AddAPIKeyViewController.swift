//
//  AddAPIKeyViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 7/30/23.
//

import UIKit

class AddAPIKeyViewController: UIViewController {

    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBAction func submitButtonAction(_ sender: UIButton) {
    }

    @IBAction func registerHordeButtonAction(_ sender: UIButton) {
    }
    
    @IBAction func closeButtonAction(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
