//
//  RatingViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import UIKit

class RatingViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!

    @IBOutlet var ratingButton: UIButton!

    @IBAction func ratingButtonAction(_: UIButton) {}

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true
    }
}
