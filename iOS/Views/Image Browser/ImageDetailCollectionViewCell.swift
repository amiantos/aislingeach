//
//  ImageDetailCollectionViewCell.swift
//  Aislingeach
//
//  Created by Brad Root on 7/3/23.
//

import UIKit

class ImageDetailCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!

    var generatedImage: GeneratedImage?

    var defaultScale = 1.0

    func setup(object: GeneratedImage) {
        generatedImage = object

        DispatchQueue.main.async { [self] in
            if let cachedImage = ImageCache.standard.getImage(key: NSString(string: "\(object.id)")) {
                Log.debug("Reloading cached UIImage...")
                imageView.image = cachedImage
                setScale()
            } else {
                if let image = UIImage(data: object.image!) {
                    imageView.image = image
                    ImageCache.standard.cacheImage(image: image, key: NSString(string: "\(object.id)"))
                    setScale()
                }
            }
        }

        scrollView.minimumZoomScale = 0.01
        scrollView.maximumZoomScale = 6.0

        let doubleTapGesture = UITapGestureRecognizer(target: self, action:#selector(self.doubleTapAction))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
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

    func setScale() {
        if imageView.intrinsicContentSize.width != 0 {
            let scale = scrollView.bounds.width / imageView.intrinsicContentSize.width
            Log.debug("Scale: \(scale)")
            scrollView.minimumZoomScale = scale
            scrollView.zoomScale = scale
            defaultScale = scale

            Log.debug("Image size: \(imageView.intrinsicContentSize.width) x \(imageView.intrinsicContentSize.height)")
            Log.debug("\(imageView.intrinsicContentSize.height*scale) - \(scrollView.safeAreaLayoutGuide.layoutFrame.height)")

            let scaledHeight = imageView.intrinsicContentSize.height * scale
            if scaledHeight < scrollView.safeAreaLayoutGuide.layoutFrame.height {
                let offsetY = max((scrollView.safeAreaLayoutGuide.layoutFrame.height - scaledHeight) * 0.5, 0)
                scrollView.contentInset = UIEdgeInsets(top: offsetY, left: 0, bottom: 0, right: 0)
            }
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return imageView
        }

    override func prepareForReuse() {
        super.prepareForReuse()
        Log.debug("Unloading image")
        imageView.image = nil
    }
}
