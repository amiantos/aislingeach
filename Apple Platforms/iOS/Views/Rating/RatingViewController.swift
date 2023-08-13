//
//  RatingViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/27/23.
//

import Cosmos
import UIKit

class RatingViewController: UIViewController, UIScrollViewDelegate {
    var currentImageIdentifier: String?
    var currentImageIdentifierAssociatedApiKey: String?

    @IBAction func addAPIKeyButtonAction(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "addAPIKeyNavController") as! UINavigationController
        controller.modalPresentationStyle = .pageSheet
        controller.isModalInPresentation = true
        present(controller, animated: true)
    }

    @IBOutlet weak var loggedOutContentView: UIView!
    @IBOutlet var startMessageView: UIStackView!
    @IBOutlet var tenStarsView: CosmosView!
    @IBOutlet var sixStarsView: CosmosView!
    @IBOutlet var imageContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var imageScrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var ratingButton: UIButton!
    @IBOutlet var loadingMessageTitleLabel: UILabel!
    @IBOutlet var loadingMessageActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var loadingMessageSubtitleLabel: UILabel!
    @IBOutlet var loadingMessageContainer: UIVisualEffectView!
    @IBOutlet var kudosStatsLabel: UILabel!
    @IBOutlet var kudosStatsContainer: UIView!
    @IBOutlet var imageStatsLabel: UILabel!
    @IBOutlet var imageStatsContainer: UIView!
    @IBOutlet var ratingLabel: UILabel!
    @IBOutlet var artifactRatingLabel: UILabel!
    @IBAction func ratingButtonAction(_: UIButton) {
        grabImageToRate()
    }

    @IBAction func touchDownStarButtonAction(_ sender: UIButton) {
        Log.info("Button touched: \(sender.tag)")
    }

    @IBOutlet var submitRatingButton: UIButton!
    @IBAction func submitRatingButtonAction(_: UIButton) {
        submitRating()
    }

    var defaultScale = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()

        let starSize = (view.frame.size.width) / 14
        tenStarsView.settings.starSize = starSize
        sixStarsView.settings.starSize = starSize

        kudosStatsContainer.layer.cornerRadius = 5
        imageStatsContainer.layer.cornerRadius = 5

        updateStatLabels()

        imageScrollView.minimumZoomScale = 0.01
        imageScrollView.maximumZoomScale = 6.0

        loadingMessageSubtitleLabel.text = ""

        imageContainerHeightConstraint.constant = view.frame.width
        tenStarsView.didTouchCosmos = { [self] rating in
            checkIfEnableRatingButton()
        }
        sixStarsView.didTouchCosmos = { [self] rating in
            checkIfEnableRatingButton()
        }
        sixStarsView.didFinishTouchingCosmos = { [self] rating in
            checkIfEnableRatingButton()
        }
        tenStarsView.didFinishTouchingCosmos = { [self] rating in
            checkIfEnableRatingButton()
        }

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction))
        doubleTapGesture.numberOfTapsRequired = 2
        imageScrollView.addGestureRecognizer(doubleTapGesture)

        NotificationCenter.default.addObserver(self, selector: #selector(setup), name: .newAPIKeySubmitted, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setup()
    }

    @objc func setup() {
        if UserPreferences.standard.apiKey == "0000000000" {
            loggedOutContentView.isHidden = false
        } else {
            loggedOutContentView.isHidden = true
        }
    }

    @objc func doubleTapAction(gesture: UITapGestureRecognizer) {
        // TODO: Would be awesome if this recongized tap location on image and zoomed to into that area
        if gesture.state == UIGestureRecognizer.State.ended {
            if imageScrollView.zoomScale != defaultScale {
                imageScrollView.setZoomScale(defaultScale, animated: true)
            } else {
                imageScrollView.setZoomScale(1.0, animated: true)
            }
        }
    }

    func resetZoom() {
        setScale()
        imageScrollView.setZoomScale(defaultScale, animated: true)
    }

    func setScale() {
        if imageView.intrinsicContentSize.width != 0 {
            let scaleWidth = imageScrollView.bounds.width / imageView.intrinsicContentSize.width
            let scaleHeight = imageScrollView.safeAreaLayoutGuide.layoutFrame.height / imageView.intrinsicContentSize.height
            let scale = min(scaleWidth, scaleHeight)

            imageScrollView.minimumZoomScale = scale
            imageScrollView.zoomScale = scale
            defaultScale = scale

            setContentOffset()
        }
    }

    func setContentOffset() {
        let scaledHeight = imageView.intrinsicContentSize.height * imageScrollView.zoomScale
        let scaledWidth = imageView.intrinsicContentSize.width * imageScrollView.zoomScale
        var offsetY = 0.0
        var offsetX = 0.0
        if scaledHeight < imageScrollView.safeAreaLayoutGuide.layoutFrame.height {
            offsetY = max((imageScrollView.safeAreaLayoutGuide.layoutFrame.height - scaledHeight) * 0.5, 0)
        }
        if scaledWidth < imageScrollView.safeAreaLayoutGuide.layoutFrame.width {
            offsetX = max((imageScrollView.safeAreaLayoutGuide.layoutFrame.width - scaledWidth) * 0.5, 0)
        }
        imageScrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }

    func viewForZooming(in _: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_: UIScrollView) {
        setContentOffset()
    }
}

extension RatingViewController {
    func grabImageToRate() {
        startLoadingSpinner()
        RatingsV1API.getDefaultDatasetImagePop(apikey: UserPreferences.standard.apiKey) { data, error in
            if let data = data {
                Log.debug("\(data)")
                self.setNewImageToRate(imageResponse: data)
            } else if let error = error {
                if error.code == 403 {
                    self.setErrorState(message: "Invalid API key, please check your API key and try again.")
                } else {
                    self.setErrorState(message: "\(error.localizedDescription)")
                }
            } else {
                self.setErrorState(message: "This shouldn't happen...")
            }
        }
    }

    func setNewImageToRate(imageResponse: DatasetImagePopResponse) {
        currentImageIdentifier = imageResponse._id
        currentImageIdentifierAssociatedApiKey = UserPreferences.standard.apiKey
        Log.info("\(String(describing: currentImageIdentifier)) - New image to rate received, downloading image...")
        if let urlString = imageResponse.url, let imageUrl = URL(string: urlString) {
            Task {
                let request = URLRequest(url: imageUrl)
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200, let image = UIImage(data: data) else {
                    setErrorState(message: "Unable to load image from URL.")
                    return
                }
                DispatchQueue.main.async { [self] in
                    self.view.layoutIfNeeded()
                    self.imageView.image = image
                    self.setScale()
                    self.imageView.isHidden = false
                    self.imageScrollView.isHidden = false
                    self.sixStarsView.rating = 0
                    self.tenStarsView.rating = 0
                    self.submitRatingButton.isEnabled = false
                    submitRatingButton.setTitle("Submit", for: .normal)
                    submitRatingButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
                    self.hideLoadingDisplay()
                    Log.info("\(String(describing: self.currentImageIdentifier)) - Image loaded.")
                }
            }
        }
    }

    func submitRating() {
        if tenStarsView.rating == 0 || sixStarsView.rating == 0 { return }
        guard let currentImageIdentifier = currentImageIdentifier else { return }

        let rating = Int(tenStarsView.rating)
        let artifacts = Int(-((sixStarsView.rating - 1) - 5))
        startLoadingSpinner()
        let postBody = RatePostInput(rating: rating, artifacts: artifacts)
        Log.info("\(currentImageIdentifier) - Submitting... Rating: \(rating), Artifacts: \(artifacts)")
        if UserPreferences.standard.apiKey != currentImageIdentifierAssociatedApiKey {
            Log.info("User changed API key between image fetches... grabbing new image to rate.")
            grabImageToRate()
        } else {
            RatingsV1API.postRate(body: postBody, apikey: UserPreferences.standard.apiKey, imageId: currentImageIdentifier) { data, error in
                if let data = data {
                    Log.info("\(currentImageIdentifier) - Rating submitted successfully. \(String(describing: data.reward)) kudos rewarded.")
                    if UserPreferences.standard.apiKey != "0000000000" {
                        UserPreferences.standard.add(ratingKudos: data.reward ?? 0)
                    }
                    UserPreferences.standard.add(ratingImages: 1)
                    self.updateStatLabels()
                    self.grabImageToRate()
                } else if let error = error {
                    if error.code == 401 {
                        self.setErrorState(message: "Invalid API key, please check your API key and try again.")
                    } else {
                        self.setErrorState(message: "Unable to grab the image, please retry? (\(error.localizedDescription))")
                    }
                }
            }
        }
    }

    func startLoadingSpinner() {
        submitRatingButton.isEnabled = false
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

        submitRatingButton.setTitle("Retry", for: .normal)
        submitRatingButton.setImage(UIImage(systemName: "arrow.uturn.backward"), for: .normal)
        submitRatingButton.isEnabled = true
    }

    func checkIfEnableRatingButton() {
        if tenStarsView.rating > 0, sixStarsView.rating > 0 {
            submitRatingButton.isEnabled = true
        }
    }

    func updateStatLabels() {
        imageStatsLabel.text = "\(UserPreferences.standard.ratingImages)"
        kudosStatsLabel.text = "\(UserPreferences.standard.ratingKudos)"
    }
}
