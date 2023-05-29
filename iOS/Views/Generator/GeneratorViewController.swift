//
//  GeneratorViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/26/23.
//

import UIKit

class GeneratorViewController: UIViewController {
    @IBOutlet var scrollView: UIScrollView!

    @IBOutlet var generationEffectView: UIVisualEffectView!
    @IBOutlet var generationSpinner: UIActivityIndicatorView!

    @IBOutlet var generationTitleLabel: UILabel!
    @IBOutlet var generationTimeLabel: UILabel!
    @IBOutlet var mainImageView: UIImageView!
    @IBOutlet weak var mainImageViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet var promptTextView: UITextView!

    @IBOutlet weak var widthSlider: UISlider!
    @IBOutlet weak var widthSliderSizeLabel: UILabel!
    @IBAction func widthSliderChanged(_ sender: UISlider) {
        if currentRatioLock {
            // TODO: This isn't quite right
            let difference = Int(currentGenerationWidth - Int(sender.value))
            var newHeight = currentGenerationHeight-difference
            heightSlider.setValue(Float(currentGenerationHeight-difference), animated: true)
            currentGenerationHeight = currentGenerationHeight-difference
        }
        currentGenerationWidth = Int(sender.value)
        updateSliderLabels()
    }

    @IBOutlet weak var heightSlider: UISlider!
    @IBOutlet weak var heightSliderSizeLabel: UILabel!
    @IBAction func heightSliderChanged(_ sender: UISlider) {
        if currentRatioLock {
            // TODO: This isn't quite right
            let difference = Int(currentGenerationHeight - Int(sender.value))
            var newWidth = currentGenerationWidth-difference
            widthSlider.setValue(Float(currentGenerationWidth-difference), animated: true)
            currentGenerationWidth = currentGenerationWidth-difference
        }

        currentGenerationHeight = Int(sender.value)
        updateSliderLabels()
    }

    @IBOutlet weak var sizingButtonsStackView: UIStackView!
    @IBOutlet weak var aspectRatioButton: UIButton!
    @IBAction func swapDimensionsButtonAction(_ sender: UIButton) {
        let currW = currentGenerationWidth
        let currH = currentGenerationHeight
        currentGenerationWidth = currH
        currentGenerationHeight = currW
        widthSlider.setValue(Float(currentGenerationWidth), animated: false)
        heightSlider.setValue(Float(currentGenerationHeight), animated: false)

        updateSliderLabels()
    }

    @IBOutlet weak var lockRatioButton: UIButton!
    @IBAction func lockRatioButtonAction(_ sender: UIButton) {
        if currentRatioLock {
            currentRatioLock = false
            lockRatioButton.setImage(UIImage(systemName: "lock.open"), for: .normal)
            lockRatioButton.setPreferredSymbolConfiguration(.init(scale: .default), forImageIn: .normal)
        } else {
            currentRatioLock = true
            lockRatioButton.setImage(UIImage(systemName: "lock"), for: .normal)
            lockRatioButton.setPreferredSymbolConfiguration(.init(scale: .default), forImageIn: .normal)
        }
    }

    @IBAction func generateButtonPressed(_: UIButton) {
        guard let generationText = promptTextView.text, generationText != "" else { return }
        promptTextView.resignFirstResponder()

        startGenerationSpinner()
        let modelParams = ModelGenerationInputStable(
            samplerName: .kEulerA,
            cfgScale: 7.5,
            denoisingStrength: 0.75,
            height: 64*currentGenerationHeight,
            width: 64*currentGenerationWidth,
            karras: true,
            hiresFix: true,
            clipSkip: 2,
            steps: 30,
            n: 1
        )
        let generationBody = GenerationInputStable(
            prompt: generationText,
            params: modelParams,
            nsfw: false,
            trustedWorkers: true,
            slowWorkers: true,
            censorNsfw: true,
            models: ["stable_diffusion"],
            r2: true,
            shared: true,
            replacementFilter: true,
            dryRun: false
        )
        V2API.postImageAsyncGenerate(body: generationBody, apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { data, error in
            if let data = data, let generationIdentifier = data._id {
                Log.debug("\(data)")
                self.setNewGenerationRequest(generationIdentifier: generationIdentifier, generationBody: generationBody)
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
    var currentGenerationBody: GenerationInputStable?
    var currentGenerationHeight: Int = 8
    var currentGenerationWidth: Int = 8
    var currentRatioLock: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        print(hordeClientAgent())
        navigationController?.navigationBar.prefersLargeTitles = true
        mainImageViewHeightConstraint.constant = view.frame.width

        widthSlider.setValue(Float(currentGenerationWidth), animated: false)
        heightSlider.setValue(Float(currentGenerationHeight), animated: false)
        updateSliderLabels()

        self.hideKeyboardWhenTappedAround() 
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    func updateSliderLabels() {
        widthSliderSizeLabel.text = "\(currentGenerationWidth*64)"
        heightSliderSizeLabel.text = "\(currentGenerationHeight*64)"

        let gcd = gcdBinaryRecursiveStein(currentGenerationWidth, currentGenerationHeight)
        aspectRatioButton.titleLabel?.text = "Aspect Ratio: \(currentGenerationWidth/gcd):\(currentGenerationHeight/gcd)"
        self.aspectRatioButton.sizeToFit()
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size

        // TODO: This should check if the text entry point will be off screen when the keyboard appears and only scroll if needed

        let tabbarHeight = tabBarController?.tabBar.frame.size.height ?? 0
        let toolbarHeight = navigationController?.toolbar.frame.size.height ?? 0
        let bottomInset = keyboardSize.height - tabbarHeight - toolbarHeight

        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y + bottomInset), animated: true)
        print("Shown")
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
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

extension GeneratorViewController {
    func setNewGenerationRequest(generationIdentifier: String, generationBody: GenerationInputStable) {
        Log.info("\(generationIdentifier) - New request received...")
        currentGenerationIdentifier = generationIdentifier
        currentGenerationBody = generationBody
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
        guard let generationIdentifier = currentGenerationIdentifier else { return }
        Log.info("\(generationIdentifier) - Checking request status...")
        V2API.getImageAsyncCheck(_id: generationIdentifier, clientAgent: hordeClientAgent()) { data, _ in
            if let data = data {
                Log.debug("\(data)")
                if let done = data.done, let restarted = data.restarted, done, restarted <= 0 {
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
        guard let generationIdentifier = currentGenerationIdentifier else { return }
        guard var generationBody = currentGenerationBody else { return }
        Log.info("\(generationIdentifier) - Fetching finished generation...")
        V2API.getImageAsyncStatus(_id: generationIdentifier, clientAgent: hordeClientAgent()) { [self] data, _ in
            if let data = data {
                Log.debug("\(data)")
                if data.finished == 1 {
                    if let generations = data.generations, let generation = generations.first, let urlString = generation.img, let imageUrl = URL(string: urlString) {
                        DispatchQueue.global().async {
                            if let data = try? Data(contentsOf: imageUrl), let image = UIImage(data: data) {
                                DispatchQueue.main.async { [self] in
                                    let imageWidth = image.size.width
                                    let imageHeight = image.size.height
                                    let viewWidth = view.frame.size.width

                                    let ratio = viewWidth/imageWidth
                                    let scaledHeight = imageHeight * ratio
                                    mainImageViewHeightConstraint.constant = scaledHeight
                                    UIView.animate(withDuration: 0.3) {
                                        self.view.layoutIfNeeded()
                                        self.mainImageView.image = image
                                        self.hideGenerationDisplay()
                                    }
                                    if !(generation.censored ?? false) {
                                        generationBody.params?.seed = generation.seed!
                                        ImageDatabase.standard.saveImage(id: generationIdentifier, image: data, body: generationBody, completion: { _ in
                                            DispatchQueue.main.async {
                                                Log.info("\(generationIdentifier) - Saved to image database...")
                                            }
                                        })
                                    }
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
