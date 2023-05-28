//
//  ViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/26/23.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var generationEffectView: UIVisualEffectView!
    @IBOutlet weak var generationSpinner: UIActivityIndicatorView!

    @IBOutlet weak var generationTitleLabel: UILabel!
    @IBOutlet weak var generationTimeLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!

    @IBOutlet weak var promptTextView: UITextView!

    @IBAction func generateButtonPressed(_ sender: UIButton) {
        let generationText = promptTextView.text!
        if generationText == "" { return }

        startGenerationSpinner()
        V2API.postImageAsyncGenerate(body: GenerationInputStable(prompt: generationText), apikey: Preferences.standard.apiKey, clientAgent: appNameAndVersion()) { data, error in
            if let data = data, let generationIdentifier = data._id {
                Log.debug("\(data)")
                self.setNewGenerationRequest(generationIdentifier: generationIdentifier)
            } else if let error = error {
                if error.code == 401 {
                    self.showGenerationError(message: "401: Invalid API Key?")
                } else {
                    self.showGenerationError(message: error.localizedDescription)
                }
            }
        }
    }

    var currentGenerationIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size

        let tabbarHeight = tabBarController?.tabBar.frame.size.height ?? 0
        let toolbarHeight = navigationController?.toolbar.frame.size.height ?? 0
        let bottomInset = keyboardSize.height - tabbarHeight - toolbarHeight

        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        scrollView.setContentOffset(CGPoint(x: 0,y: scrollView.contentOffset.y+bottomInset), animated: true)
        print("Shown")
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
        print("Hidden")
    }

    func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillShow(notification:)),
                                             name: UIResponder.keyboardWillShowNotification,
                                             object: nil)
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillHide(notification:)),
                                             name: UIResponder.keyboardWillHideNotification,
                                             object: nil)
    }


}

extension ViewController {
    func setNewGenerationRequest(generationIdentifier: String) {
        Log.info("\(generationIdentifier) - New request received...")
        currentGenerationIdentifier = generationIdentifier
        checkCurrentGenerationStatus()
    }

    func startGenerationSpinner() {
        Log.info("New generation started...")
        generationTitleLabel.text = ""
        generationTimeLabel.text = "Falling asleep..."
        generationEffectView.isHidden = false
        generationSpinner.startAnimating()
    }

    func hideGenerationDisplay() {
        Log.info("Hiding generation progress display.")
        generationSpinner.stopAnimating()
        generationEffectView.isHidden = true
    }

    func showGenerationError(message: String) {
        Log.info("Showing error...")
        generationSpinner.stopAnimating()
        generationTitleLabel.text = "Error!"
        generationTimeLabel.text = message
    }

    @objc func checkCurrentGenerationStatus() {
        guard let generationIdentifier = self.currentGenerationIdentifier else { return }
        Log.info("\(generationIdentifier) - Checking request status...")
        V2API.getImageAsyncCheck(_id: generationIdentifier, clientAgent: appNameAndVersion()) { data, error in
            if let data = data {
                Log.debug("\(data)")
                if let done = data.done, done {
                    Log.info("\(generationIdentifier) - Done!")
                    self.getFinishedImageAndDisplay()
                } else if let waitTime = data.waitTime {
                    if waitTime > 0 {
                        self.generationTitleLabel.text = "Dreaming..."
                        self.generationTimeLabel.text = "~\(waitTime) seconds"
                    } else {
                        self.generationTimeLabel.text = "Waking up..."
                    }
                    self.perform(#selector(self.checkCurrentGenerationStatus), with: nil, afterDelay: TimeInterval(1))
                }
            }
        }
    }

    func getFinishedImageAndDisplay() {
        guard let generationIdentifier = self.currentGenerationIdentifier else { return }
        Log.info("\(generationIdentifier) - Fetching finished generation...")
        V2API.getImageAsyncStatus(_id: generationIdentifier, clientAgent: appNameAndVersion()) { [self] data, error in
            if let data = data {
                Log.debug("\(data)")
                if data.finished == 1 {
                    if let generations = data.generations, let generation = generations.first, let urlString = generation.img, let imageUrl = URL(string: urlString) {
                        DispatchQueue.global().async {
                            if let data = try? Data(contentsOf: imageUrl) {
                                DispatchQueue.main.async { [self] in
                                    hideGenerationDisplay()
                                    mainImageView.image = UIImage(data: data)
                                    ImageDatabase.standard.saveImage(id: generationIdentifier, image: data, completion: { _ in
                                        DispatchQueue.main.async {
                                            Log.info("\(generationIdentifier) - Saved to image database...")
                                        }
                                    })
                                }
                            }
                        }
                    }
                } else {
                    print("Not finished...?!")
                }
            }
        }
    }

}

