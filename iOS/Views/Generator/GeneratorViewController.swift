//
//  GeneratorViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/26/23.
//

import UIKit



class GeneratorViewController: UIViewController {
    // MARK: - Variables

    var currentGenerationIdentifier: String?
    var currentGenerationBody: GenerationInputStable?
    var currentRatioLock: Int?

    var lastGeneratedImage: GeneratedImage? {
        didSet {
            if lastGeneratedImage != nil {
                favoriteButton.isEnabled = true
                deleteButton.isEnabled = true
            } else {
                favoriteButton.isEnabled = false
                deleteButton.isEnabled = false
            }
        }
    }

    var kudosEstimateTimer: Timer?

    // MARK: - IBOutlets

    @IBOutlet var scrollView: UIScrollView!

    @IBOutlet var generationEffectView: UIVisualEffectView!
    @IBOutlet var generationSpinner: UIActivityIndicatorView!

    @IBOutlet var generationWarningImageView: UIImageView!
    @IBOutlet var generationTitleLabel: UILabel!
    @IBOutlet var generationTimeLabel: UILabel!
    @IBOutlet var mainImageView: UIImageView!
    @IBOutlet var mainImageViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var modelPickButton: UIButton!
    @IBOutlet var upscalerPickButton: UIButton!
    @IBOutlet var samplerPickButton: UIButton!

    @IBOutlet var deleteButton: UIButton!
    @IBAction func deleteButtonAction(_: UIButton) {
        if let generatedImage = lastGeneratedImage {
            ImageDatabase.standard.deleteImage(generatedImage) { [self] image in
                if image == nil {
                    lastGeneratedImage = nil
                    mainImageView.image = nil
                }
            }
        }
    }

    @IBOutlet var favoriteButton: UIButton!
    @IBAction func favoriteButtonAction(_: UIButton) {
        if let generatedImage = lastGeneratedImage {
            ImageDatabase.standard.toggleImageFavorite(generatedImage: generatedImage) { gImage in
                if let gImage = gImage {
                    self.lastGeneratedImage = gImage
                    self.updateImageActionButtons()
                }
            }
        }
    }

    @IBOutlet var promptTextView: UITextView!

    @IBOutlet var widthSlider: UISlider!
    @IBOutlet var widthSliderSizeLabel: UILabel!
    @IBAction func widthSliderChanged(_: UISlider) {
        if let ratioLock = currentRatioLock {
            let newHeightValue = widthSlider.value - Float(ratioLock)
            if newHeightValue < heightSlider.minimumValue {
                widthSlider.value = heightSlider.minimumValue + Float(ratioLock)
            } else if newHeightValue > heightSlider.maximumValue {
                widthSlider.value = heightSlider.maximumValue + Float(ratioLock)
            } else {
                heightSlider.value = newHeightValue
            }
        }
        updateSliderLabels()
    }

    @IBOutlet var heightSlider: UISlider!
    @IBOutlet var heightSliderSizeLabel: UILabel!
    @IBAction func heightSliderChanged(_: UISlider) {
        if let ratioLock = currentRatioLock {
            let newWidthValue = heightSlider.value + Float(ratioLock)
            if newWidthValue > widthSlider.maximumValue {
                heightSlider.value = heightSlider.maximumValue - Float(ratioLock)
            } else if newWidthValue < widthSlider.minimumValue {
                heightSlider.value = heightSlider.minimumValue - Float(ratioLock)
            } else {
                widthSlider.value = newWidthValue
            }
        }
        updateSliderLabels()
    }

    @IBOutlet var sizingButtonsStackView: UIStackView!
    @IBOutlet var aspectRatioButton: UIButton!
    @IBAction func swapDimensionsButtonAction(_: UIButton) {
        let currentDimensions = getCurrentWidthAndHeight()
        let currW = currentDimensions.0
        let currH = currentDimensions.1
        if let ratioLock = currentRatioLock {
            currentRatioLock = -ratioLock
        }
        widthSlider.setValue(Float(currH), animated: false)
        heightSlider.setValue(Float(currW), animated: false)
        updateSliderLabels()
    }

    @IBOutlet var lockRatioButton: UIButton!
    @IBAction func lockRatioButtonAction(_: UIButton) {
        if currentRatioLock == nil {
            currentRatioLock = Int(widthSlider.value) - Int(heightSlider.value)
            lockRatioButton.setImage(UIImage(systemName: "lock"), for: .normal)
        } else {
            currentRatioLock = nil
            lockRatioButton.setImage(UIImage(systemName: "lock.open"), for: .normal)
        }
        lockRatioButton.setPreferredSymbolConfiguration(.init(scale: .default), forImageIn: .normal)
        Log.info("Ratio locked to: \(String(describing: currentRatioLock))")
    }

    @IBOutlet weak var generateButton: UIButton!
    @IBAction func generateButtonPressed(_: UIButton) {
        promptTextView.resignFirstResponder()
        if let generationBody = getCurrentGenerationBody() {
            startGenerationSpinner()
            HordeV2API.postImageAsyncGenerate(body: generationBody, apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { data, error in
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
    }

    // MARK: - View Setup

    override func viewDidLoad() {
        super.viewDidLoad()
        print(hordeClientAgent())
        navigationController?.navigationBar.prefersLargeTitles = true
        mainImageViewHeightConstraint.constant = view.frame.width

        widthSlider.setValue(Float(8), animated: false)
        heightSlider.setValue(Float(8), animated: false)
        updateSliderLabels()

        hideKeyboardWhenTappedAround()

        NotificationCenter.default.addObserver(self, selector: #selector(checkIfCurrentGenerationWasDeleted), name: .deletedGeneratedImage, object: nil)

        // setup button?
        let upscalerOptions: [String] = ["No Upscaler", "RealESRGAN_x4plus", "RealESRGAN_x4plus_anime_6B", "RealESRGAN_x4plus_anime_6B", "NMKD_Siax", "4x_AnimeSharp"]
        let menuChildren: [UIAction] = {
            var actions: [UIAction] = []
            upscalerOptions.forEach { option in
                actions.append(UIAction(title: option, state: .on, handler: { foo in
                    print(foo)
                }))
            }
            return actions
        }()
        upscalerPickButton.menu = UIMenu(children: menuChildren)
        upscalerPickButton.showsMenuAsPrimaryAction = true
        upscalerPickButton.changesSelectionAsPrimaryAction = true

        let samplerOptions: [String] = [
            "k_euler_a",
            "k_euler",
            "k_heun",
            "k_lms",
            "k_dpm_fast",
            "k_dpm_adaptive",
            "k_dpm_2_a",
            "k_dpm_2",
            "k_dpmpp_2m",
            "k_dpmpp_2s_a",
            "k_dpmpp_sde",
        ]
        let samplerMenuChildren: [UIAction] = {
            var actions: [UIAction] = []
            samplerOptions.forEach { option in
                actions.append(UIAction(title: option, state: .on, handler: { _ in
                    self.flagKudosEstimatorForUpdate()
                }))
            }
            return actions
        }()
        samplerPickButton.menu = UIMenu(children: samplerMenuChildren)
        samplerPickButton.showsMenuAsPrimaryAction = true
        samplerPickButton.changesSelectionAsPrimaryAction = true

        flagKudosEstimatorForUpdate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
        updateSliderLabels()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tearDownKeyboardNotifications()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openModelsViewSegue", let destinationView = segue.destination as? ModelsTableViewController {
            destinationView.delegate = self
        }
    }
}

// MARK: - Everything Else

extension GeneratorViewController {
    func flagKudosEstimatorForUpdate() {
        guard getCurrentGenerationBody(dryRun: true) != nil else { return }
        self.kudosEstimateTimer?.invalidate()
        kudosEstimateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
            self.fetchAndDisplayKudosEstimate()
        })

    }
    func fetchAndDisplayKudosEstimate() {
        guard let currentGen = getCurrentGenerationBody(dryRun: true) else { return }
        DispatchQueue.main.async {
            HordeV2API.postImageAsyncGenerate(body: currentGen, apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { data, error in
                if let data = data, let kudosEstimate = data.kudos {
                    Log.debug(data)
                    self.generateButton.configuration?.subtitle = "\(kudosEstimate) Kudos"
                } else if let error = error {
                    Log.error(error)
                }
            }
        }
    }
    func getCurrentGenerationBody(dryRun: Bool = false) -> GenerationInputStable? {
        guard let generationText = promptTextView.text, generationText != "" else { return nil }
        let currentDimensions = getCurrentWidthAndHeight()
        let samplerString = samplerPickButton.menu?.selectedElements[0].title ?? "k_euler_a"
        let samplerName = ModelGenerationInputStable.SamplerName(rawValue: samplerString)
        let modelParams = ModelGenerationInputStable(
            samplerName: samplerName,
            cfgScale: 9,
            denoisingStrength: 0.75,
            height: 64 * currentDimensions.1,
            width: 64 * currentDimensions.0,
            seedVariation: nil,
            postProcessing: nil,
            karras: true,
            tiling: false,
            hiresFix: true,
            clipSkip: 2,
            controlType: nil,
            imageIsControl: false,
            returnControlMap: nil,
            facefixerStrength: 0.75,
            loras: nil,
            steps: 20,
            n: 1
        )
        return GenerationInputStable(
            prompt: generationText,
            params: modelParams,
            nsfw: false,
            trustedWorkers: true,
            slowWorkers: true,
            censorNsfw: true,
            workers: nil,
            workerBlacklist: nil,
            models: [modelPickButton.titleLabel?.text ?? "stable_diffusion"],
            sourceImage: nil,
            sourceProcessing: nil,
            sourceMask: nil,
            r2: true,
            shared: true,
            replacementFilter: true,
            dryRun: dryRun
        )
    }

    func getCurrentWidthAndHeight() -> (Int, Int) {
        return (Int(widthSlider.value), Int(heightSlider.value))
    }

    @objc func checkIfCurrentGenerationWasDeleted() {
        if let generatedImage = lastGeneratedImage {
            if generatedImage.managedObjectContext == nil {
                lastGeneratedImage = nil
                mainImageView.image = nil
            }
        }
    }

    func updateImageActionButtons() {
        if let lastGeneratedImage = lastGeneratedImage, lastGeneratedImage.isFavorite {
            favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        } else {
            favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        }
        favoriteButton.setPreferredSymbolConfiguration(.init(scale: .default), forImageIn: .normal)
    }

    func updateSliderLabels() {
        let currentDimensions = getCurrentWidthAndHeight()
        widthSliderSizeLabel.text = "\(currentDimensions.0 * 64)"
        heightSliderSizeLabel.text = "\(currentDimensions.1 * 64)"

        let gcd = gcdBinaryRecursiveStein(currentDimensions.0, currentDimensions.1)
        aspectRatioButton.titleLabel?.text = "\(currentDimensions.0 / gcd):\(currentDimensions.1 / gcd)"
        aspectRatioButton.sizeToFit()

        flagKudosEstimatorForUpdate()
    }

    func setNewGenerationRequest(generationIdentifier: String, generationBody: GenerationInputStable) {
        Log.info("\(generationIdentifier) - New request received...")
        favoriteButton.isEnabled = false
        deleteButton.isEnabled = false
        currentGenerationIdentifier = generationIdentifier
        currentGenerationBody = generationBody
        checkCurrentGenerationStatus()
    }

    func startGenerationSpinner() {
        Log.info("New generation started...")
        generationTitleLabel.text = ""
        generationTimeLabel.text = "Falling asleep..."
        generationEffectView.isHidden = false
        generationWarningImageView.isHidden = true
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
        generationWarningImageView.isHidden = false
        generationTitleLabel.text = "Error!"
        generationTimeLabel.text = message
    }

    @objc func checkCurrentGenerationStatus() {
        guard let generationIdentifier = currentGenerationIdentifier else { return }
        Log.info("\(generationIdentifier) - Checking request status...")
        HordeV2API.getImageAsyncCheck(_id: generationIdentifier, clientAgent: hordeClientAgent()) { data, _ in
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
        HordeV2API.getImageAsyncStatus(_id: generationIdentifier, clientAgent: hordeClientAgent()) { [self] data, _ in
            if let data = data {
                Log.debug("\(data)")
                if data.finished == 1 {
                    if let generations = data.generations,
                       let generation = generations.first
                    {
                        if generation.censored ?? false {
                            showGenerationError(message: "Unable to generate this image.\nTry again with a different prompt?\n(Code 42)")
                        } else if let urlString = generation.img,
                                  let imageUrl = URL(string: urlString)
                        {
                            DispatchQueue.global().async {
                                if let data = try? Data(contentsOf: imageUrl), let image = UIImage(data: data) {
                                    DispatchQueue.main.async { [self] in
                                        let imageWidth = image.size.width
                                        let imageHeight = image.size.height
                                        let viewWidth = view.frame.size.width

                                        let ratio = viewWidth / imageWidth
                                        let scaledHeight = imageHeight * ratio
                                        mainImageViewHeightConstraint.constant = scaledHeight
                                        UIView.animate(withDuration: 0.3) {
                                            self.view.layoutIfNeeded()
                                            self.mainImageView.image = image
                                            self.hideGenerationDisplay()
                                        }
                                        if !(generation.censored ?? false) {
                                            generationBody.params?.seed = generation.seed!
                                            ImageDatabase.standard.saveImage(id: generationIdentifier, image: data, body: generationBody, completion: { generatedImage in
                                                guard let generatedImage = generatedImage else { return }
                                                self.lastGeneratedImage = generatedImage
                                                self.updateImageActionButtons()
                                            })
                                        }
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

// MARK: - Keyboard Stuff

extension GeneratorViewController {
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

    func tearDownKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension GeneratorViewController: ModelsTableViewControllerDelegate {
    func selectedModel(name: String) {
        modelPickButton.setTitle(name, for: .normal)
        flagKudosEstimatorForUpdate()
    }
}
