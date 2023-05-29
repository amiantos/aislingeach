//
//  RatingViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import UIKit

class RatingViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var ratingButton: UIButton!

    @IBAction func ratingButtonAction(_ sender: UIButton) {
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
