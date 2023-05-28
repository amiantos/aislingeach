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

    @IBOutlet weak var generationTimeLabel: UILabel!
    @IBOutlet weak var mainImageView: UIImageView!

    @IBOutlet weak var promptTextView: UITextView!

    @IBAction func generateButtonPressed(_ sender: UIButton) {
        let generationText = promptTextView.text!
        if generationText == "" { return }

        startGenerationSpinner()
        V2API.postImageAsyncGenerate(body: GenerationInputStable(prompt: generationText), apikey: Preferences.standard.apiKey) { data, error in
            if let data = data, let generationIdentifier = data._id {
                Log.debug("\(data)")
                self.setNewGenerationRequest(generationIdentifier: generationIdentifier)
            } else {
                Log.error("New generaiton error: \(error)")
            }
        }
    }

    var currentGenerationIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
        generationEffectView.isHidden = false
        generationSpinner.startAnimating()
    }

    func stopGenerationDisplay() {
        Log.info("New generation complete.")
        generationSpinner.stopAnimating()
        generationEffectView.isHidden = true
    }

    @objc func checkCurrentGenerationStatus() {
        guard let generationIdentifier = self.currentGenerationIdentifier else { return }
        Log.info("\(generationIdentifier) - Checking request status...")
        V2API.getImageAsyncCheck(_id: generationIdentifier) { data, error in
            if let data = data {
                Log.debug("\(data)")
                if let done = data.done, done {
                    Log.info("\(generationIdentifier) - Done!")
                    self.getFinishedImageAndDisplay()
                } else if let waitTime = data.waitTime {
                    if waitTime > 0 {
                        self.generationTimeLabel.text = "~\(waitTime) seconds"
                    } else {
                        self.generationTimeLabel.text = "Loading..."
                    }
                    self.perform(#selector(self.checkCurrentGenerationStatus), with: nil, afterDelay: TimeInterval(1))
                }
            }
        }
    }

    func getFinishedImageAndDisplay() {
        guard let generationIdentifier = self.currentGenerationIdentifier else { return }
        Log.info("\(generationIdentifier) - Fetching finished generation...")
        V2API.getImageAsyncStatus(_id: generationIdentifier, clientAgent: "Aislingeach (Alpha)") { [self] data, error in
            if let data = data {
                Log.debug("\(data)")
                if data.finished == 1 {
                    if let generations = data.generations, let generation = generations.first, let urlString = generation.img, let imageUrl = URL(string: urlString) {
                        DispatchQueue.global().async {
                            let data = try? Data(contentsOf: imageUrl)
                            DispatchQueue.main.async { [self] in
                                stopGenerationDisplay()
                                mainImageView.image = UIImage(data: data!)
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

