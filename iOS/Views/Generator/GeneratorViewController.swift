//
//  GeneratorViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/26/23.
//

import UIKit

class GeneratorViewController: UIViewController {
    // MARK: - Variables

    let generationTracker: GenerationTracker = .init()

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
    var saveGenerationSettingsTimer: Timer?
    var generationPollingTimer: Timer?

    // MARK: - IBOutlets

    @IBOutlet var scrollView: UIScrollView!

    @IBOutlet var generationEffectView: UIVisualEffectView!
    @IBOutlet var generationSpinner: UIActivityIndicatorView!

    @IBOutlet var generationWarningImageView: UIImageView!
    @IBOutlet var generationTitleLabel: UILabel!
    @IBOutlet var generationTimeLabel: UILabel!
    @IBOutlet var mainImageView: UIImageView!
    @IBOutlet var mainImageViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet var modelPickButton: UIButton!
    @IBOutlet var upscalerPickButton: UIButton!
    @IBOutlet var samplerPickButton: UIButton!

    @IBOutlet var karrasToggleButton: UIButton!
    @IBOutlet var hiresFixToggleButton: UIButton!
    @IBOutlet var tilingToggleButton: UIButton!
    @IBAction func toggleButtonChanged(_: UIButton) {
        generationSettingsUpdated()
    }

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

    @IBOutlet var stepsSlider: UISlider!
    @IBOutlet var stepsLabel: UILabel!
    @IBAction func stepsSliderChanged(_ sender: UISlider) {
        let intValue = Int(sender.value)
        stepsLabel.text = "\(intValue)"
        generationSettingsUpdated()
    }

    @IBOutlet var guidanceSlider: UISlider!
    @IBOutlet var guidanceLabel: UILabel!
    @IBAction func guidanceSliderChanged(_ sender: UISlider) {
        let intValue = Int(sender.value)
        guidanceLabel.text = "\(intValue)"
        generationSettingsUpdated()
    }

    @IBOutlet var clipSkipSlider: UISlider!
    @IBOutlet var clipSkipLabel: UILabel!
    @IBAction func clipSkipSliderChanged(_ sender: UISlider) {
        let intValue = Int(sender.value)
        clipSkipLabel.text = "\(intValue)"
        generationSettingsUpdated()
    }

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
        generationSettingsUpdated()
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
        generationSettingsUpdated()
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

    @IBOutlet weak var imageQuantitySlider: UISlider!
    @IBOutlet weak var imageQuantitySliderLabel: UILabel!
    @IBAction func imageQuantitySliderChanged(_ sender: UISlider) {
        imageQuantitySliderLabel.text = "\(Int(sender.value))"
        generationSettingsUpdated()
    }

    @IBOutlet var generateButton: UIButton!
    @IBAction func generateButtonPressed(_: UIButton) {
        promptTextView.resignFirstResponder()
        if let generationBody = createGeneratonBodyForCurrentSettings() {
            generationTracker.createNewGenerationRequest(body: generationBody)
        }
    }

    @IBOutlet weak var gfpganToggleButton: UIButton!
    @IBAction func gfpganToggleButonChanged(_ sender: UIButton) {
        if sender.isSelected {
            faceFixerStrengthSlider.isEnabled = true
        } else if !codeFormersToggleButton.isSelected {
            faceFixerStrengthSlider.isEnabled = false
        }
        generationSettingsUpdated()
    }

    @IBOutlet weak var codeFormersToggleButton: UIButton!
    @IBAction func codeFormersToggleButtonChanged(_ sender: UIButton) {
        if sender.isSelected {
            faceFixerStrengthSlider.isEnabled = true
        } else if !gfpganToggleButton.isSelected {
            faceFixerStrengthSlider.isEnabled = false
        }
        generationSettingsUpdated()
    }


    @IBOutlet var faceFixerStrengthSlider: UISlider!
    @IBOutlet var faceFixStrengthLabel: UILabel!
    @IBAction func faceFixStrengthSliderChanged(_ sender: UISlider) {
        faceFixStrengthLabel.text = "\(round(sender.value * 100) / 100.0)"
        generationSettingsUpdated()
    }

    @IBOutlet var slowWorkersButton: UIButton!
    @IBAction func slowWorkersButtonAction(_ sender: UIButton) {
        UserPreferences.standard.set(slowWorkers: sender.isSelected)
        generationSettingsUpdated()
    }

    @IBOutlet var trustedWorkersButton: UIButton!
    @IBAction func trustedWorkersButtonAction(_ sender: UIButton) {
        UserPreferences.standard.set(trustedWorkers: sender.isSelected)
        generationSettingsUpdated()
    }

    @IBOutlet weak var shareButton: UIButton!
    @IBAction func shareButtonAction(_ sender: UIButton) {
        UserPreferences.standard.set(shareWithLaion: sender.isSelected)
        generationSettingsUpdated()
    }

    @IBOutlet var debugModeButton: UIButton!
    @IBAction func debugModeButtonAction(_ sender: UIButton) {
        UserPreferences.standard.set(debugMode: sender.isSelected)
        generationSettingsUpdated()
    }

    @IBOutlet weak var seedTextField: UITextField!
    @IBOutlet weak var randomSeedButton: UIButton!
    @IBAction func randomSeedButtonAction(_ sender: UIButton) {
        if sender.isSelected {
            seedTextField.text = nil
        }
    }
    @IBAction func seedTextFieldEditingDidBegin(_ sender: UITextField) {
        randomSeedButton.isSelected = false
    }

    @IBAction func seedTextFieldEditingDidEnd(_ sender: UITextField) {
        if !sender.hasText {
            randomSeedButton.isSelected = true
        }
    }
    @IBOutlet weak var repeatSeedButton: UIButton!
    @IBAction func repeatSeedButtonAction(_ sender: UIButton) {
        guard let image = lastGeneratedImage, let jsonString = image.fullRequest, let jsonData = jsonString.data(using: .utf8), let settings = try? JSONDecoder().decode(
            GenerationInputStable.self,
            from: jsonData
        ) else { return }
        seedTextField.text = settings.params?.seed
        randomSeedButton.isSelected = false
        generationSettingsUpdated()
    }


    // MARK: - View Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true
        mainImageViewHeightConstraint.constant = view.frame.width

        let recentSettings = UserPreferences.standard.recentSettings

        hideKeyboardWhenTappedAround()

        NotificationCenter.default.addObserver(self, selector: #selector(checkIfCurrentGenerationWasDeleted), name: .imageDatabaseUpdated, object: nil)

        upscalerPickButton.showsMenuAsPrimaryAction = true
        upscalerPickButton.changesSelectionAsPrimaryAction = true

        samplerPickButton.showsMenuAsPrimaryAction = true
        samplerPickButton.changesSelectionAsPrimaryAction = true

        slowWorkersButton.isSelected = UserPreferences.standard.slowWorkers
        trustedWorkersButton.isSelected = UserPreferences.standard.trustedWorkers
        debugModeButton.isSelected = UserPreferences.standard.debugMode
        shareButton.isSelected = UserPreferences.standard.shareWithLaion

        loadSettingsIntoUI(settings: recentSettings, seed: nil)

        updateSliderLabels()

        generationTracker.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
        updateSliderLabels()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tearDownKeyboardNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkIfCurrentGenerationWasDeleted()
        generationSettingsUpdated()
        updateSliderLabels()
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "openModelsViewSegue", let destinationView = segue.destination as? ModelsTableViewController {
            destinationView.delegate = self
        }
    }
}

// MARK: - Generator Tracker Delegate

extension GeneratorViewController: GenerationTrackerDelegate {
    func updateProcessingStatus(title: String, message: String) {
        generationTitleLabel.text = title
        generationTimeLabel.text = message
        generationEffectView.isHidden = false
        generationWarningImageView.isHidden = true
        generationSpinner.startAnimating()
        generateButton.isEnabled = false
        deleteButton.isEnabled = false
        favoriteButton.isEnabled = false
    }

    func showErrorStatus(title: String, message: String) {
        generationSpinner.stopAnimating()
        generationWarningImageView.isHidden = false
        generationTitleLabel.text = title
        generationTimeLabel.text = message
        generateButton.isEnabled = true
    }

    func displayCompletedGeneration(generatedImage: GeneratedImage) {
        if let data = generatedImage.image, let image = UIImage(data: data) {
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
                    self.lastGeneratedImage = generatedImage
                    self.updateImageActionButtons()
                }
            }
        }
    }
}

// MARK: - Everything Else

extension GeneratorViewController {
    func loadSettingsIntoUI(settings: GenerationInputStable?, seed: String?) {
        let initialWidth = ((settings?.params?.width) != nil) ? (settings?.params?.width)! / 64 : 8
        let initialHeight = ((settings?.params?.height) != nil) ? (settings?.params?.height)! / 64 : 8
        widthSlider.setValue(Float(initialWidth), animated: false)
        heightSlider.setValue(Float(initialHeight), animated: false)

        let selectedModel = settings?.models?.first ?? "stable_diffusion"
        modelPickButton.setTitle(selectedModel, for: .normal)

        // setup button?
        let upscalerOptions: [String] = [
            "No Upscaler",
            "RealESRGAN_x4plus",
            "RealESRGAN_x2plus",
            "RealESRGAN_x4plus_anime_6B",
            "NMKD_Siax",
            "4x_AnimeSharp",
        ]
        let menuChildren: [UIAction] = {
            var actions: [UIAction] = []
            upscalerOptions.forEach { option in
                var state: UIMenuElement.State = .off
                if let postProcessing = settings?.params?.postProcessing {
                    Log.debug(postProcessing)
                    state = postProcessing.contains(where: { opt in
                        opt == ModelGenerationInputStable.PostProcessing(rawValue: option)
                    }) ? .on : .off
                }
                actions.append(UIAction(title: option, state: state, handler: { _ in
                    self.generationSettingsUpdated()
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
                let state: UIMenuElement.State = settings?.params?.samplerName?.rawValue == option ? .on : .off
                actions.append(UIAction(title: option, state: state, handler: { _ in
                    self.generationSettingsUpdated()
                }))
            }
            return actions
        }()
        samplerPickButton.menu = UIMenu(children: samplerMenuChildren)

        if let recentGuidance = settings?.params?.cfgScale {
            let floatScale = Float(truncating: recentGuidance as NSNumber)
            guidanceSlider.setValue(floatScale, animated: false)
            guidanceLabel.text = "\(recentGuidance)"
        }

        if let recentSteps = settings?.params?.steps {
            let floatScale = Float(truncating: recentSteps as NSNumber)
            stepsSlider.setValue(floatScale, animated: false)
            stepsLabel.text = "\(recentSteps)"
        }

        if let recentClipSkip = settings?.params?.clipSkip {
            let floatScale = Float(truncating: recentClipSkip as NSNumber)
            clipSkipSlider.setValue(floatScale, animated: false)
            clipSkipLabel.text = "\(recentClipSkip)"
        }

        karrasToggleButton.isSelected = settings?.params?.karras ?? true
        hiresFixToggleButton.isSelected = settings?.params?.hiresFix ?? true
        tilingToggleButton.isSelected = settings?.params?.tiling ?? false

        gfpganToggleButton.isSelected = false
        codeFormersToggleButton.isSelected = false
        if let postProcessing = settings?.params?.postProcessing {
            postProcessing.forEach { processor in
                switch processor {
                case .gfpgan:
                    gfpganToggleButton.isSelected = true
                case .codeFormers:
                    codeFormersToggleButton.isSelected = true
                default:
                    break
                }
            }
        }

        if gfpganToggleButton.isSelected || codeFormersToggleButton.isSelected {
            faceFixerStrengthSlider.isEnabled = true
            let faceFixStrength = settings?.params?.facefixerStrength ?? 0.75
            let float = Float(truncating: faceFixStrength as NSNumber)
            faceFixStrengthLabel.text = "\(faceFixStrength)"
            faceFixerStrengthSlider.setValue(float, animated: false)

        }
        promptTextView.text = settings?.prompt ?? "temple in ruins, forest, stairs, columns, cinematic, detailed, atmospheric, epic, concept art, Matte painting, background, mist, photo-realistic, concept art, volumetric light, cinematic epic + rule of thirds octane render, 8k, corona render, movie concept art, octane render, cinematic, trending on artstation, movie concept art, cinematic composition, ultra-detailed, realistic, hyper-realistic, volumetric lighting, 8k"

        imageQuantitySlider.setValue(1.0, animated: false)
        if selectedModel == "SDXL_beta::stability.ai#6901" {
            imageQuantitySlider.setValue(2.0, animated: false)
        }

        if let seed = seed {
            seedTextField.text = seed
            randomSeedButton.isSelected = false
        }
    }

    func generationSettingsUpdated() {
        saveGenerationSettingsTimer?.invalidate()
        saveGenerationSettingsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { timer in
            self.saveGenerationSettings()
            timer.invalidate()
        })

        kudosEstimateTimer?.invalidate()
        kudosEstimateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { timer in
            self.fetchAndDisplayKudosEstimate()
            timer.invalidate()
        })
    }

    func saveGenerationSettings() {
        guard let settings = createGeneratonBodyForCurrentSettings() else { return }
        UserPreferences.standard.set(recentSettings: settings)
    }

    func fetchAndDisplayKudosEstimate() {
        guard let currentGen = createGeneratonBodyForCurrentSettings(dryRun: true) else { return }
        DispatchQueue.global().async {
            HordeV2API.postImageAsyncGenerate(body: currentGen, apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { data, error in
                if let data = data, let kudosEstimate = data.kudos {
                    Log.debug(data)
                    DispatchQueue.main.async {
                        self.generateButton.configuration?.subtitle = "\(kudosEstimate) Kudos"
                    }
                } else if let error = error {
                    Log.error(error)
                }
            }
        }
    }

    func createGeneratonBodyForCurrentSettings(dryRun: Bool = false) -> GenerationInputStable? {
        guard let generationText = promptTextView.text, generationText != "" else { return nil }
        let currentDimensions = getCurrentWidthAndHeight()
        let samplerString = samplerPickButton.menu?.selectedElements[0].title ?? "k_euler_a"
        let samplerName = ModelGenerationInputStable.SamplerName(rawValue: samplerString)

        var postprocessing: [ModelGenerationInputStable.PostProcessing]? = []

        if let menuItem = upscalerPickButton.menu?.selectedElements.first, let upscaler = ModelGenerationInputStable.PostProcessing(rawValue: menuItem.title) {
            postprocessing?.append(upscaler)
        }

        if gfpganToggleButton.isSelected {
            postprocessing?.append(.gfpgan)
        }
        if codeFormersToggleButton.isSelected {
            postprocessing?.append(.codeFormers)
        }

        if let pp = postprocessing, pp.isEmpty {
            postprocessing = nil
        }

        var seed: String?  = seedTextField.text ?? ""
        if let seedCheck = seed, seedCheck.isEmpty { seed = nil }

        let modelParams = ModelGenerationInputStable(
            samplerName: samplerName,
            cfgScale: Decimal(Int(guidanceSlider.value)),
            denoisingStrength: 0.75,
            seed: seed,
            height: 64 * currentDimensions.1,
            width: 64 * currentDimensions.0,
            seedVariation: nil,
            postProcessing: postprocessing,
            karras: karrasToggleButton.isSelected,
            tiling: tilingToggleButton.isSelected,
            hiresFix: hiresFixToggleButton.isSelected,
            clipSkip: Int(clipSkipSlider.value),
            controlType: nil,
            imageIsControl: false,
            returnControlMap: nil,
            facefixerStrength: Decimal(round(Double(faceFixerStrengthSlider.value) * 100.0) / 100.0),
            loras: nil,
            steps: Int(stepsSlider.value),
            n: Int(imageQuantitySlider.value)
        )
        let input = GenerationInputStable(
            prompt: generationText,
            params: modelParams,
            nsfw: UserPreferences.standard.debugMode,
            trustedWorkers: UserPreferences.standard.trustedWorkers,
            slowWorkers: UserPreferences.standard.slowWorkers,
            censorNsfw: !UserPreferences.standard.debugMode,
            workers: nil,
            workerBlacklist: nil,
            models: [modelPickButton.titleLabel?.text ?? "stable_diffusion"],
            sourceImage: nil,
            sourceProcessing: nil,
            sourceMask: nil,
            r2: true,
            shared: UserPreferences.standard.shareWithLaion,
            replacementFilter: !UserPreferences.standard.debugMode,
            dryRun: dryRun
        )
        return input
    }

    func getCurrentWidthAndHeight() -> (Int, Int) {
        return (Int(widthSlider.value), Int(heightSlider.value))
    }

    @objc func checkIfCurrentGenerationWasDeleted() {
        if let generatedImage = lastGeneratedImage {
            if generatedImage.managedObjectContext == nil {
                lastGeneratedImage = nil
                mainImageView.image = nil
                repeatSeedButton.isEnabled = false
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
        repeatSeedButton.isEnabled = true
    }

    func updateSliderLabels() {
        let currentDimensions = getCurrentWidthAndHeight()
        widthSliderSizeLabel.text = "\(currentDimensions.0 * 64)"
        heightSliderSizeLabel.text = "\(currentDimensions.1 * 64)"

        let gcd = gcdBinaryRecursiveStein(currentDimensions.0, currentDimensions.1)
        aspectRatioButton.titleLabel?.text = "\(currentDimensions.0 / gcd):\(currentDimensions.1 / gcd)"
        aspectRatioButton.sizeToFit()

        imageQuantitySliderLabel.text = "\(Int(imageQuantitySlider.value))"
    }

    func hideGenerationDisplay() {
        Log.info("Hiding generation progress display.")
        generationSpinner.stopAnimating()
        generationEffectView.isHidden = true
        generateButton.isEnabled = true
    }
}

// Let us know the prompt was changed

extension GeneratorViewController: UITextViewDelegate {
    func textViewDidEndEditing(_: UITextView) {
        generationSettingsUpdated()
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
    }

    @objc func keyboardWillHide(notification _: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
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
        if name == "SDXL_beta::stability.ai#6901" {
            imageQuantitySlider.setValue(2, animated: true)
            imageQuantitySlider.isEnabled = false
            if widthSlider.value < 16 && heightSlider.value < 16{
                widthSlider.setValue(16, animated: true)
                heightSlider.setValue(16, animated: true)
            }
        } else {
            imageQuantitySlider.isEnabled = true
        }
    }
}
