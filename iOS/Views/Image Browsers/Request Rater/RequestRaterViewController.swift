//
//  RequestRaterViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 7/9/23.
//

import UIKit

class RequestRaterViewController: UIViewController {

    private var requestId: UUID

    private var image1: GeneratedImage?
    private var image2: GeneratedImage?

    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!

    @IBOutlet weak var checkButton1: UIButton!
    @IBOutlet weak var checkButton2: UIButton!

    @IBOutlet weak var submitButton: UIButton!

    @IBAction func checkButtonAction(_ sender: UIButton) {
        Log.debug("Button hit: \(sender.tag)")
        if sender.tag == 1 {
            checkButton2.isSelected = false
        } else {
            checkButton1.isSelected = false
        }

        if checkButton1.isSelected || checkButton2.isSelected {
            submitButton.isEnabled = true
        } else {
            submitButton.isEnabled = false
        }
    }

    @IBAction func tapGestureRecognizer1(_ sender: UITapGestureRecognizer) {
        checkButton1.isSelected = true
        checkButton2.isSelected = false
        submitButton.isEnabled = true
    }

    @IBAction func tapGestureRecognizer2(_ sender: UITapGestureRecognizer) {
        checkButton1.isSelected = false
        checkButton2.isSelected = true
        submitButton.isEnabled = true
    }

    @IBAction func submitButtonAction(_ sender: UIButton) {
        Log.debug("Hit submit button")
        var selectedImageUUID = image1?.uuid
        if checkButton2.isSelected {
            selectedImageUUID = image2?.uuid
        }

        guard let selectedImageUUID = selectedImageUUID else { return }

        submitButton.isEnabled = false
        Log.debug("Selected image UUID \(selectedImageUUID.uuidString) to submit...")

        HordeV2API.postAesthetics(body: AestheticsPayload(best: selectedImageUUID.uuidString.lowercased()), _id: requestId.uuidString.lowercased(), clientAgent: hordeClientAgent()) { data, error in
            if let data = data, let reward = data.reward {
                let alert = UIAlertController(title: "Success!", message: "You received \(reward) kudos.", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Groovy", style: .default)  { _ in
                    self.dismiss(animated: true)
                }
                alert.addAction(alertAction)
                self.present(alert, animated: true)
            } else {
                let alert = UIAlertController(title: "Error", message: "This batch is no longer eligible to be rated, either because you rated it already, or waited too long to rate it.", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Oh well", style: .default)  { _ in
                    self.dismiss(animated: true)
                }
                alert.addAction(alertAction)
                self.present(alert, animated: true)
            }
        }
    }


    init(for requestId: UUID) {
        self.requestId = requestId
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Pick Your Favorite"

        ImageDatabase.standard.fetchImages(for: requestId) { images in
            if let images = images, let image1 = images.first, let image2 = images.last {
                self.image1 = image1
                self.image2 = image2
                DispatchQueue.main.async { [self] in

                    if let cachedImage = ImageCache.standard.getImage(key: NSString(string: image1.uuid!.uuidString)) {
                        Log.debug("Reloading cached UIImage...")
                        imageView1.image = cachedImage
                    } else {
                        if let image = UIImage(data: image1.image!) {
                            imageView1.image = image
                            ImageCache.standard.cacheImage(image: image, key: NSString(string: image1.uuid!.uuidString))
                        }
                    }

                    if let cachedImage = ImageCache.standard.getImage(key: NSString(string: image2.uuid!.uuidString)) {
                        Log.debug("Reloading cached UIImage...")
                        imageView2.image = cachedImage
                    } else {
                        if let image = UIImage(data: image2.image!) {
                            imageView2.image = image
                            ImageCache.standard.cacheImage(image: image, key: NSString(string: image1.uuid!.uuidString))
                        }
                    }
                }
            }
        }

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
