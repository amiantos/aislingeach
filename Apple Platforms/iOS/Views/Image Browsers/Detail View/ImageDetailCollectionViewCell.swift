//
//  ImageDetailCollectionViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 7/3/23.
//

import UIKit

protocol ImageDetailCollectionViewCellDelegate {
    func dismissView()
    func showRatingView(for requestId: UUID)
    func loadSettings(includeSeed: Bool)
    func toggleMetadataView(isHidden: Bool)
}

class ImageDetailCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var scrollView: UIScrollView!

    @IBOutlet var requestDetailsTextView: UITextView!
    @IBOutlet var responseDetailsTextView: UITextView!
    var delegate: ImageDetailCollectionViewCellDelegate?

    var generatedImage: GeneratedImage?
    var requestSettings: GenerationInputStable?
    var requestResponse: GenerationStable?

    @IBOutlet var metaDataView: UIView!
    @IBOutlet var metaDataViewCenterYConstraint: NSLayoutConstraint!

    var defaultScale = 1.0

    @IBOutlet var sdxlRateButton: UIButton!
    @IBAction func sdxlRateButtonAction(_: UIButton) {
        if let settings = requestSettings,
           let requestId = generatedImage?.requestId,
           settings.models!.contains("SDXL_beta::stability.ai#6901")
        {
            delegate?.showRatingView(for: requestId)
        }
    }

    @IBAction func loadSettingsButtonAction(_: UIButton) {
        delegate?.loadSettings(includeSeed: false)
    }

    @IBAction func loadSettingsAndSeedButtonAction(_: UIButton) {
        delegate?.loadSettings(includeSeed: true)
    }

    @IBAction func copyPromptOnlyAction(_: UIButton) {
        if let prompt = generatedImage?.promptSimple {
            UIPasteboard.general.string = prompt
        }
    }

    @IBAction func copyAllSettingsAction(_: UIButton) {
        if let request = requestSettings,
           let response = requestResponse,
           let requestParams = request.params,
           let seed: String = requestParams.seed != nil ? requestParams.seed : response.seed,
           let width = requestParams.width,
           let height = requestParams.height,
           let steps = requestParams.steps,
           let model = response.model,
           let sampler = requestParams.samplerName,
           let cfgScale = requestParams.cfgScale,
           let clipSkip = requestParams.clipSkip
        {
            UIPasteboard.general.string = """
            \(request.prompt)
            Steps: \(steps), Size: \(width)x\(height), Seed: \(seed), Model: \(model), Sampler: \(sampler), CFG scale: \(cfgScale), Clip skip: \(clipSkip)
            """
        }
    }

    @IBAction func copyRequestAction(_: UIButton) {
        if let fullRequest = generatedImage?.fullRequest {
            let jsonData = Data(fullRequest.utf8)
            UIPasteboard.general.string = jsonData.printJson()
        }
    }

    @IBAction func copyResponseAction(_: UIButton) {
        if let fullResponse = generatedImage?.fullResponse {
            let jsonData = Data(fullResponse.utf8)
            UIPasteboard.general.string = jsonData.printJson()
        }
    }

    // MARK: - View Setup

    func setup(object: GeneratedImage, metaDataViewIsHidden: Bool) {
        generatedImage = object

        DispatchQueue.main.async { [self] in
            if let cachedImage = ImageCache.standard.getImage(key: NSString(string: "\(object.id)")) {
                Log.debug("Reloading cached UIImage...")
                imageView.image = cachedImage
            } else if let objImage = object.image, let image = UIImage(data: objImage) {
                imageView.image = image
                ImageCache.standard.cacheImage(image: image, key: NSString(string: "\(object.id)"))
            }
            setScale()
        }

        scrollView.minimumZoomScale = 0.01
        scrollView.maximumZoomScale = 6.0

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapAction))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)

        let downSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(downSwipeAction))
        downSwipeGesture.direction = UISwipeGestureRecognizer.Direction.down
        scrollView.addGestureRecognizer(downSwipeGesture)

        let upSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(upSwipeAction))
        upSwipeGesture.direction = UISwipeGestureRecognizer.Direction.up
        scrollView.addGestureRecognizer(upSwipeGesture)

        let downSwipeGestureForMetadataView = UISwipeGestureRecognizer(target: self, action: #selector(downSwipeActionForMetadataView))
        downSwipeGestureForMetadataView.direction = UISwipeGestureRecognizer.Direction.down
        metaDataView.addGestureRecognizer(downSwipeGestureForMetadataView)

        if metaDataViewIsHidden {
            metaDataView.layer.opacity = 0
            metaDataViewCenterYConstraint.constant = 50
        } else {
            metaDataView.layer.opacity = 1
            metaDataViewCenterYConstraint.constant = 0
        }
        layoutIfNeeded()

        if let image = generatedImage,
           let jsonString = image.fullRequest,
           let jsonData = jsonString.data(using: .utf8),
           let settings = try? JSONDecoder().decode(GenerationInputStable.self, from: jsonData)
        {
            requestSettings = settings
        }

        if let image = generatedImage,
           let jsonString = image.fullResponse,
           let jsonData = jsonString.data(using: .utf8),
           let response = try? JSONDecoder().decode(GenerationStable.self, from: jsonData)
        {
            requestResponse = response
        }

        if let fullRequest = generatedImage?.fullRequest {
            let jsonData = Data(fullRequest.utf8)
            requestDetailsTextView.text = jsonData.printJson()
        }

        if let fullResponse = generatedImage?.fullResponse {
            let jsonData = Data(fullResponse.utf8)
            responseDetailsTextView.text = jsonData.printJson()
        } else {
            responseDetailsTextView.text = "This generation is from an earlier version of Aislingeach and does not have the response details recorded."
        }
//         dateLabel.text = imageObject.dateCreated?.formatted(date: .abbreviated, time: .shortened)

        if let requestSettings = requestSettings,
           let _ = generatedImage?.requestId,
           requestSettings.models!.contains("SDXL_beta::stability.ai#6901"),
           let genDate = generatedImage?.dateCreated,
           genDate.timeIntervalSinceNow > -(60 * 20)
        {
            sdxlRateButton.isEnabled = true
        } else {
            sdxlRateButton.isEnabled = false
        }
    }

    @objc func doubleTapAction(gesture: UITapGestureRecognizer) {
        // TODO: Would be awesome if this recongized tap location on image and zoomed to into that area
        if gesture.state == UIGestureRecognizer.State.ended {
            if scrollView.zoomScale != defaultScale {
                scrollView.setZoomScale(defaultScale, animated: true)
            } else {
                scrollView.setZoomScale(1.0, animated: true)
            }
        }
    }

    @objc func downSwipeAction(gesture: UITapGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.ended {
            delegate?.dismissView()
        }
    }

    @objc func upSwipeAction(gesture: UITapGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.ended {
            delegate?.toggleMetadataView(isHidden: false)
            layoutIfNeeded()
            metaDataViewCenterYConstraint.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.metaDataView.layer.opacity = 1
                self.layoutIfNeeded()
            }
        }
    }

    func toggleMetadataView(isHidden: Bool, animated: Bool) {
        if (metaDataView.layer.opacity == 0 && isHidden) || (metaDataView.layer.opacity == 1 && !isHidden) { return }
//        layoutIfNeeded()
        if isHidden {
            metaDataViewCenterYConstraint.constant = 50
        } else {
            metaDataViewCenterYConstraint.constant = 0
        }
        UIView.animate(withDuration: animated ? 0.3 : 0.0) { [self] in
            if isHidden {
                metaDataView.layer.opacity = 0
            } else {
                metaDataView.layer.opacity = 1
            }
            self.layoutIfNeeded()
        }
    }

    @objc func downSwipeActionForMetadataView(gesture: UITapGestureRecognizer) {
        if gesture.state == UIGestureRecognizer.State.ended {
            layoutIfNeeded()
            delegate?.toggleMetadataView(isHidden: true)
            metaDataViewCenterYConstraint.constant = 50
            UIView.animate(withDuration: 0.3) {
                self.metaDataView.layer.opacity = 0
                self.layoutIfNeeded()
            }
        }
    }

    func resetZoom() {
        setScale()
        scrollView.setZoomScale(defaultScale, animated: true)
    }

    func setScale() {
        if imageView.intrinsicContentSize.width != 0 {
            let scaleWidth = scrollView.bounds.width / imageView.intrinsicContentSize.width
            let scaleHeight = scrollView.safeAreaLayoutGuide.layoutFrame.height / imageView.intrinsicContentSize.height
            let scale = min(scaleWidth, scaleHeight)

            Log.debug("Scale: \(scale)")
            scrollView.minimumZoomScale = scale
            scrollView.zoomScale = scale
            defaultScale = scale

            setContentOffset()
        }
    }

    func setContentOffset() {
        let scaledHeight = imageView.intrinsicContentSize.height * scrollView.zoomScale
        let scaledWidth = imageView.intrinsicContentSize.width * scrollView.zoomScale
        var offsetY = 0.0
        var offsetX = 0.0
        if scaledHeight < scrollView.safeAreaLayoutGuide.layoutFrame.height {
            offsetY = max((scrollView.safeAreaLayoutGuide.layoutFrame.height - scaledHeight) * 0.5, 0)
        }
        if scaledWidth < scrollView.safeAreaLayoutGuide.layoutFrame.width {
            offsetX = max((scrollView.safeAreaLayoutGuide.layoutFrame.width - scaledWidth) * 0.5, 0)
        }
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
    }

    func viewForZooming(in _: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_: UIScrollView) {
        setContentOffset()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        Log.debug("Unloading image")
        imageView.image = nil
        scrollView.contentInset = .zero
        scrollView.contentOffset = .zero
    }
}
