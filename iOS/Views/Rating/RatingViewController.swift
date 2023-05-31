//
//  RatingViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import UIKit
import Cosmos

class RatingViewController: UIViewController {

    @IBOutlet weak var tenStarsView: CosmosView!
    @IBOutlet weak var sixStarsView: CosmosView!
    @IBOutlet weak var imageContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var imageView: UIImageView!

    @IBOutlet var ratingButton: UIButton!


    @IBOutlet weak var kudosStatsLabel: UILabel!
    @IBOutlet weak var kudosStatsContainer: UIView!
    @IBOutlet weak var imageStatsLabel: UILabel!
    @IBOutlet weak var imageStatsContainer: UIView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var artifactRatingLabel: UILabel!
    @IBAction func ratingButtonAction(_: UIButton) {
        print("Foo")
    }
    @IBAction func touchDownStarButtonAction(_ sender: UIButton) {
        Log.info("Button touched: \(sender.tag)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true

        let starSize = (view.frame.size.width) / 14
        tenStarsView.settings.starSize = starSize
        sixStarsView.settings.starSize = starSize

        kudosStatsContainer.layer.cornerRadius = 5
        imageStatsContainer.layer.cornerRadius = 5

        imageContainerHeightConstraint.constant = view.frame.width
        tenStarsView.didTouchCosmos = { [self] rating in
            switch Int(rating) {
            case 1:
                ratingLabel.text = "Worst"
            case 2:
                ratingLabel.text = "Terrible"
            case 3:
                ratingLabel.text = "Very Bad"
            case 4:
                ratingLabel.text = "Rather Bad"
            case 6:
                ratingLabel.text = "Not Bad"
            case 7:
                ratingLabel.text = "Rather Good"
            case 8:
                ratingLabel.text = "Very Good"
            case 9:
                ratingLabel.text = "Excellent"
            case 10:
                ratingLabel.text = "The Best"
            default:
                ratingLabel.text = "OK"
            }
        }

        sixStarsView.didTouchCosmos = { [self] rating in
            switch Int(rating) {
            case 1:
                artifactRatingLabel.text = "Complete Mess"
            case 2:
                artifactRatingLabel.text = "Serious Issues"
            case 3:
                artifactRatingLabel.text = "Minor Issues"
            case 4:
                artifactRatingLabel.text = "Noticable Flaws"
            case 5:
                artifactRatingLabel.text = "Small Errors"
            default:
                artifactRatingLabel.text = "Flawless"

            }
        }

    }
}
