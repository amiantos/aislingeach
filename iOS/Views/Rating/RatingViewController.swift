//
//  RatingViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import UIKit
import Cosmos

class RatingViewController: UIViewController {

    var currentImageIdentifier: String?

    @IBOutlet weak var startMessageView: UIStackView!
    @IBOutlet weak var tenStarsView: CosmosView!
    @IBOutlet weak var sixStarsView: CosmosView!
    @IBOutlet weak var imageContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var ratingButton: UIButton!
    @IBOutlet weak var loadingMessageTitleLabel: UILabel!
    @IBOutlet weak var loadingMessageActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingMessageSubtitleLabel: UILabel!
    @IBOutlet weak var loadingMessageContainer: UIVisualEffectView!
    @IBOutlet weak var kudosStatsLabel: UILabel!
    @IBOutlet weak var kudosStatsContainer: UIView!
    @IBOutlet weak var imageStatsLabel: UILabel!
    @IBOutlet weak var imageStatsContainer: UIView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var artifactRatingLabel: UILabel!
    @IBAction func ratingButtonAction(_: UIButton) {
        grabImageToRate()
    }
    @IBAction func touchDownStarButtonAction(_ sender: UIButton) {
        Log.info("Button touched: \(sender.tag)")
    }
    @IBOutlet weak var submitRatingButton: UIButton!
    @IBAction func submitRatingButtonAction(_ sender: UIButton) {
        submitRating()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let starSize = (view.frame.size.width) / 14
        tenStarsView.settings.starSize = starSize
        sixStarsView.settings.starSize = starSize

        kudosStatsContainer.layer.cornerRadius = 5
        imageStatsContainer.layer.cornerRadius = 5

        updateStatLabels()
        
        loadingMessageSubtitleLabel.text = ""

        imageContainerHeightConstraint.constant = view.frame.width
        tenStarsView.didTouchCosmos = { [self] rating in
            setRatingLabel(rating: Int(rating))
            checkIfEnableRatingButton()
        }
        sixStarsView.didTouchCosmos = { [self] rating in
            setArtifactLabel(rating: Int(rating))
            checkIfEnableRatingButton()
        }
        sixStarsView.didFinishTouchingCosmos = { [self] rating in
            setArtifactLabel(rating: Int(rating))
            checkIfEnableRatingButton()
        }
        tenStarsView.didFinishTouchingCosmos = { [self] rating in
            setRatingLabel(rating: Int(rating))
            checkIfEnableRatingButton()
        }

    }
}

extension RatingViewController {
    func setRatingLabel(rating: Int) {
        switch Int(rating) {
        case 1:
            ratingLabel.text = "1 - Worst"
        case 2:
            ratingLabel.text = "2 - Terrible"
        case 3:
            ratingLabel.text = "3 - Very Bad"
        case 4:
            ratingLabel.text = "4 - Rather Bad"
        case 5:
            ratingLabel.text = "5 - OK"
        case 6:
            ratingLabel.text = "6 - Not Bad"
        case 7:
            ratingLabel.text = "7 - Rather Good"
        case 8:
            ratingLabel.text = "8 - Very Good"
        case 9:
            ratingLabel.text = "9 - Excellent"
        case 10:
            ratingLabel.text = "10 - The Best"
        default:
            ratingLabel.text = " "
        }
    }
    func setArtifactLabel(rating: Int) {
        switch Int(rating) {
        case 1:
            artifactRatingLabel.text = "1 - Complete Mess"
        case 2:
            artifactRatingLabel.text = "2 - Serious Issues"
        case 3:
            artifactRatingLabel.text = "3 - Minor Issues"
        case 4:
            artifactRatingLabel.text = "4 - Noticable Flaws"
        case 5:
            artifactRatingLabel.text = "5 - Small Errors"
        case 6:
            artifactRatingLabel.text = "6 - Flawless"
        default:
            artifactRatingLabel.text = " "
        }
    }
    func grabImageToRate() {
        startLoadingSpinner()
        RatingsV1API.getDefaultDatasetImagePop(apikey: UserPreferences.standard.apiKey) { data, error in
            if let data = data {
                Log.debug("\(data)")
                self.setNewImageToRate(imageResponse: data)
            } else if let error = error {
                if error.code == 403 {
                    self.setErrorState(message: "Unauthorized - Check your API key!")
                }
                self.setErrorState(message: "\(error)")
            }
        }
    }

    func setNewImageToRate(imageResponse: DatasetImagePopResponse) {
        currentImageIdentifier = imageResponse._id
        Log.info("\(String(describing: currentImageIdentifier)) - New image to rate received, downloading image...")
        if let urlString = imageResponse.url, let imageUrl = URL(string: urlString) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: imageUrl), let image = UIImage(data: data) {
                    DispatchQueue.main.async { [self] in
//                        let imageWidth = image.size.width
//                        let imageHeight = image.size.height
//                        let viewWidth = view.frame.size.width
//
//                        let ratio = viewWidth / imageWidth
//                        let scaledHeight = imageHeight * ratio
//                        imageContainerHeightConstraint.constant = scaledHeight
                        UIView.animate(withDuration: 0.3) {
                            self.view.layoutIfNeeded()
                            self.imageView.image = image
                            self.imageView.isHidden = false
                            self.sixStarsView.rating = 0
                            self.tenStarsView.rating = 0
                            self.ratingLabel.text = " "
                            self.artifactRatingLabel.text = " "
                            self.submitRatingButton.isEnabled = false
                            self.hideLoadingDisplay()
                            Log.info("\(String(describing: self.currentImageIdentifier)) - Image loaded.")
                        }
                    }
                }
            }
        } else {
            setErrorState(message: "Unable to load image URL.")
        }
    }

    func submitRating() {
        if tenStarsView.rating == 0 || sixStarsView.rating == 0 { return }
        guard let currentImageIdentifier = currentImageIdentifier else { return }

        let rating = Int(tenStarsView.rating)
        let artifacts = Int(-((sixStarsView.rating-1)-5))
        startLoadingSpinner()
        let postBody = RatePostInput(rating: rating, artifacts: artifacts)
        Log.info("\(currentImageIdentifier) - Submitting... Rating: \(rating), Artifacts: \(artifacts)")
        RatingsV1API.postRate(body: postBody, apikey: UserPreferences.standard.apiKey, imageId: currentImageIdentifier) { data, error in
            if let data = data {
                Log.info("\(currentImageIdentifier) - Rating submitted successfully. \(String(describing: data.reward)) kudos rewarded.")
                UserPreferences.standard.add(ratingKudos: data.reward ?? 0)
                UserPreferences.standard.add(ratingImages: 1)
                self.updateStatLabels()
                self.grabImageToRate()
            } else if let error = error {
                self.setErrorState(message: "\(error)")
            }
        }
    }

    func startLoadingSpinner() {
        startMessageView.isHidden = true
        loadingMessageContainer.isHidden = false
        loadingMessageTitleLabel.text = ""
        loadingMessageActivityIndicator.startAnimating()
        loadingMessageSubtitleLabel.text = ""
    }

    func hideLoadingDisplay() {
        loadingMessageContainer.isHidden = true
    }

    func setErrorState(message: String) {
        loadingMessageContainer.isHidden = false
        loadingMessageTitleLabel.text = "Error"
        loadingMessageActivityIndicator.stopAnimating()
        loadingMessageSubtitleLabel.text = message
    }

    func checkIfEnableRatingButton() {
        if tenStarsView.rating > 0 && sixStarsView.rating > 0 {
            submitRatingButton.isEnabled = true
        }
    }

    func updateStatLabels() {
        imageStatsLabel.text = "\(UserPreferences.standard.ratingImages)"
        kudosStatsLabel.text = "\(UserPreferences.standard.ratingKudos)"
    }
}
