//
//  GeneratorViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/26/23.
//

import UIKit

class GeneratorViewController: UIViewController {
    // MARK: - Variables

    var currentRatioLock: Int?

    var kudosEstimateTimer: Timer?
    var saveGenerationSettingsTimer: Timer?

    var currentSelectedStyleTitle: String?
    var currentSelectedStyle: Style?

    var firstLaunch: Bool = true

    weak var generationTracker: GenerationTracker? {
        didSet {
            generationTracker?.delegate = self
        }
    }

    let defaultSettings = [
        GenerationInputStable(prompt: "Jane Eyre with headphones, natural skin texture, 24mm, 4k textures, soft cinematic light, adobe lightroom, photolab, hdr, intricate, elegant, highly detailed, sharp focus, (cinematic look:1.2), soothing tones, insane details, intricate details, hyperdetailed, low contrast, soft cinematic light, dim colors, exposure blend, hdr, faded ### (deformed, distorted, disfigured:1.3), poorly drawn, bad anatomy, wrong anatomy, extra limb, missing limb, floating limbs, (mutated hands and fingers:1.4), disconnected limbs, mutation, mutated, ugly, disgusting, blurry, amputation", params: ModelGenerationInputStable(samplerName: .kEuler, cfgScale: 9.0, height: 1024, width: 768, karras: true, hiresFix: true, clipSkip: 1, steps: 20, n: 4), models: ["Deliberate"]),
        GenerationInputStable(prompt: "end of the world, epic realistic, (hdr:1.4), (muted colors:1.4), apocalypse, freezing, abandoned, neutral colors, night, screen space refractions, (intricate details), (intricate details, hyperdetailed:1.2), artstation, cinematic shot, vignette, complex background, buildings, snowy ### poorly drawn", params: ModelGenerationInputStable(samplerName: .kEuler, cfgScale: 9.0, height: 768, width: 1024, karras: true, hiresFix: false, clipSkip: 1, steps: 20, n: 4), models: ["Deliberate"]),
        GenerationInputStable(prompt: "medical mask, victorian era, cinematography, intricately detailed, crafted, meticulous, magnificent, maximum details, extremely hyper aesthetic ### deformed, bad anatomy, disfigured, poorly drawn face, mutation, mutated, extra limb, ugly, disgusting, poorly drawn hands, missing limb, floating limbs, disconnected limbs, malformed hands, blurry, (mutated hands and fingers:1.2), watermark, watermarked, oversaturated, censored, distorted hands, amputation, missing hands, obese, doubled face, double hands, b&w, black and white, sepia, flowers, roses", params: ModelGenerationInputStable(samplerName: .kEuler, cfgScale: 9.0, height: 1024, width: 768, karras: true, hiresFix: false, clipSkip: 1, steps: 20, n: 4), models: ["Deliberate"]),

    ]

    var imageToImageImage: UIImage? {
        didSet {
            Log.debug("Got image...")
            if let image = imageToImageImage {
                imageToImagePreviewImageView.image = image
                imageToImagePreviewImageView.isHidden = false
                pasteImageButton.setTitle("Remove Image", for: .normal)
                controlTypeButton.isEnabled = true
                imageIsControlMapButton.isEnabled = true
                returnControlMapButton.isEnabled = true
                denoisStrengthSlider.isEnabled = true

                let imageWidth: Float = Float(image.size.width / 64)
                let imageHeight: Float = Float(image.size.height / 64)
                Log.debug("Width: \(imageWidth) Height: \(imageHeight)")
                let aspectRatio: Float = imageWidth / imageHeight
                Log.debug("Aspect: \(aspectRatio)")

                var finalWidth: Int = Int(imageWidth)
                var finalHeight: Int = Int(imageHeight)
                if imageWidth > 32 && imageHeight > 32 {
                    if imageWidth > imageHeight {
                        finalWidth = 32
                        finalHeight = Int(Float(32) / aspectRatio)
                    } else {
                        finalHeight = 32
                        finalWidth = Int(Float(32) * aspectRatio)
                    }
                } else if imageWidth > 32 {
                    finalWidth = 32
                    finalHeight = Int(Float(32) / aspectRatio)
                } else if imageHeight > 32 {
                    finalHeight = 32
                    finalWidth = Int(Float(32) * aspectRatio)
                }

                widthSlider.setValue(Float(finalWidth), animated: false)
                heightSlider.setValue(Float(finalHeight), animated: false)
                generationSettingsUpdated()
            } else {
                imageToImagePreviewImageView.isHidden = true
                imageToImagePreviewImageView.image = nil
                pasteImageButton.setTitle("Paste Image or URL", for: .normal)
                controlTypeButton.isEnabled = false
                imageIsControlMapButton.isEnabled = false
                returnControlMapButton.isEnabled = false
                denoisStrengthSlider.isEnabled = false
                generationSettingsUpdated()
            }
        }
    }

    // MARK: - IBOutlets

    @IBAction func doneButtonAction(_: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @IBOutlet var scrollView: UIScrollView!

    @IBOutlet var modelPickButton: UIButton!
    @IBOutlet var upscalerPickButton: UIButton!
    @IBOutlet var samplerPickButton: UIButton!

    @IBOutlet var karrasToggleButton: UIButton!
    @IBOutlet var hiresFixToggleButton: UIButton!
    @IBOutlet var tilingToggleButton: UIButton!
    @IBAction func toggleButtonChanged(_: UIButton) {
        generationSettingsUpdated()
    }

    @IBOutlet var promptTextViewContainerView: UIView!
    @IBOutlet var promptTextView: UITextView!

    @IBOutlet weak var negativePromptContainerView: UIView!
    @IBOutlet weak var negativePromptTextView: UITextView!

    @IBOutlet weak var styleButton: UIButton!

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

    @IBOutlet var imageQuantitySlider: UISlider!
    @IBOutlet var imageQuantitySliderLabel: UILabel!
    @IBAction func imageQuantitySliderChanged(_ sender: UISlider) {
        imageQuantitySliderLabel.text = "\(Int(sender.value))"
        generationSettingsUpdated()
    }
    @IBOutlet weak var requestQuantitySlider: UISlider!
    @IBOutlet weak var requestQuantitySliderLabel: UILabel!
    @IBAction func requestQuantitySliderChanged(_ sender: UISlider) {
        requestQuantitySliderLabel.text = "\(Int(sender.value))"
        generationSettingsUpdated()
    }

    @IBOutlet var generateButton: UIButton!
    @IBAction func generateButtonPressed(_: UIButton) {
        promptTextView.resignFirstResponder()
        negativePromptTextView.resignFirstResponder()
        if let generationBody = createGeneratonBodyForCurrentSettings() {
            generateButton.isEnabled = false
            for _ in 1...Int(requestQuantitySlider.value) {
                generationTracker?.createNewGenerationRequest(body: generationBody)
            }
            generateButton.isEnabled = true
            if UserPreferences.standard.autoCloseCreatePanel {
                navigationController?.dismiss(animated: true)
            }
        }
    }

    @IBOutlet var generateButtonLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var gfpganToggleButton: UIButton!
    @IBAction func gfpganToggleButonChanged(_ sender: UIButton) {
        if sender.isSelected {
            faceFixerStrengthSlider.isEnabled = true
        } else if !codeFormersToggleButton.isSelected {
            faceFixerStrengthSlider.isEnabled = false
        }
        generationSettingsUpdated()
    }

    @IBOutlet var codeFormersToggleButton: UIButton!
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
        UserPreferences.standard.set(trustedWorkers: !sender.isSelected)
        generationSettingsUpdated()
    }

    @IBOutlet var shareButton: UIButton!
    @IBAction func shareButtonAction(_ sender: UIButton) {
        UserPreferences.standard.set(shareWithLaion: sender.isSelected)
        generationSettingsUpdated()
    }

    @IBOutlet var seedTextField: UITextField!
    @IBOutlet var randomSeedButton: UIButton!
    @IBAction func randomSeedButtonAction(_ sender: UIButton) {
        if sender.isSelected {
            seedTextField.text = nil
        }
    }

    @IBOutlet weak var allowNSFWButton: UIButton!
    @IBAction func allowNSFWButtonAction(_ sender: UIButton) {
        UserPreferences.standard.set(allowNSFW: sender.isSelected)
        generationSettingsUpdated()
    }

    @IBAction func seedTextFieldEditingDidBegin(_: UITextField) {
        randomSeedButton.isSelected = false
    }

    @IBAction func seedTextFieldEditingDidEnd(_ sender: UITextField) {
        if !sender.hasText {
            randomSeedButton.isSelected = true
        }
    }

    @IBOutlet var closeCreatePanelAutomaticallyButton: UIButton!
    @IBAction func closeCreatePanelAutomaticallyButtonAction(_ sender: UIButton) {
        UserPreferences.standard.set(autoCloseCreatePanel: sender.isSelected)
    }

    @IBOutlet weak var controlTypeButton: UIButton!

    @IBOutlet weak var denoisStrengthSlider: UISlider!
    @IBOutlet weak var denoiseStrengthSliderLabelLabel: UILabel!
    @IBOutlet weak var denoiseStrengthSliderLabel: UILabel!
    @IBAction func denoisStrengthSliderChanged(_ sender: UISlider) {
        denoiseStrengthSliderLabel.text = "\(round(sender.value * 100) / 100.0)"
        generationSettingsUpdated()
    }

    @IBOutlet weak var imageToImagePreviewImageView: UIImageView!
    @IBOutlet weak var pasteImageStackView: UIStackView!
    @IBOutlet weak var pasteImageButton: UIButton!
    @IBAction func pasteImageButtonAction(_ sender: UIButton) {
        if imageToImageImage != nil {
            let alert = UIAlertController(title: "Clear Image?", message: "Are you sure you want to clear this image?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "No", style: .cancel)
            let confirmAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
                self.imageToImageImage = nil
            }
            alert.addAction(cancelAction)
            alert.addAction(confirmAction)
            self.present(alert, animated: true)
        } else {
            pasteImageButton.isEnabled = false
            pasteImageButton.setTitle("Please wait...", for: .disabled)
            DispatchQueue.global().async {
                if let string = UIPasteboard.general.string,
                   let url = URL(string: string),
                   let imageData = try? Data(contentsOf: url),
                   let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.imageToImageImage = image
                        self.pasteImageButton.isEnabled = true
                    }
                } else if let image = UIPasteboard.general.image {
                    Log.debug("Got image from clipboard")
                    DispatchQueue.main.async {
                        self.imageToImageImage = image
                        self.pasteImageButton.isEnabled = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self.pasteImageButton.isEnabled = true
                        let alert = UIAlertController(title: "Paste Error", message: "Did not find any content in the clipboard suitable for pasting.", preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "Oh, okay...", style: .cancel)
                        alert.addAction(alertAction)
                        self.present(alert, animated: true)
                        self.pasteImageButton.setTitle("Paste Image or URL", for: .normal)
                    }
                }
            }
        }
    }
    @IBOutlet weak var returnControlMapButton: UIButton!
    @IBOutlet weak var imageIsControlMapButton: UIButton!

    @IBAction func resetButtonAction(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Reset to Default?", message: "Reset all generation settings to their defaults? A randomized prompt will also be supplied.", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { _ in
            self.loadSettingsIntoUI(settings: self.defaultSettings.randomElement()!, seed: nil)
        }
        let noAction = UIAlertAction(title: "No", style: .default)
        alert.addAction(noAction)
        alert.addAction(yesAction)
        present(alert, animated: true)
    }

    // MARK: - View Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true

        var recentSettings = UserPreferences.standard.recentSettings
        if recentSettings == nil {
            recentSettings = self.defaultSettings[0]
        }

        hideKeyboardWhenTappedAround()

        upscalerPickButton.showsMenuAsPrimaryAction = true
        upscalerPickButton.changesSelectionAsPrimaryAction = true

        samplerPickButton.showsMenuAsPrimaryAction = true
        samplerPickButton.changesSelectionAsPrimaryAction = true

        slowWorkersButton.isSelected = UserPreferences.standard.slowWorkers
        trustedWorkersButton.isSelected = !UserPreferences.standard.trustedWorkers
        allowNSFWButton.isSelected = UserPreferences.standard.allowNSFW
        shareButton.isSelected = UserPreferences.standard.shareWithLaion
        closeCreatePanelAutomaticallyButton.isSelected = UserPreferences.standard.autoCloseCreatePanel

        loadSettingsIntoUI(settings: recentSettings, seed: nil)

        promptTextView.layer.cornerRadius = 5
        promptTextViewContainerView.layer.cornerRadius = 5

        negativePromptTextView.layer.cornerRadius = 5
        negativePromptContainerView.layer.cornerRadius = 5
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSliderLabels()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstLaunch {
            generationSettingsUpdated()
            firstLaunch = false
        } else {
            updateSliderLabels()
        }
        loadUserKudos()
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == "openModelsViewSegue", let destinationView = segue.destination as? ModelsTableViewController {
            destinationView.delegate = self
        } else if segue.identifier == "openStylesViewSegue", let destinationView = segue.destination as? StylesTableViewController {
            destinationView.delegate = self
        }
    }
}

// MARK: - Everything Else

extension GeneratorViewController {
    func loadSettingsIntoUI(settings: GenerationInputStable?, seed: String?) {
        if let imageString = settings?.sourceImage {
            let image = convertBase64StringToImage(imageBase64String: imageString)
            imageToImageImage = image
        } else {
            imageToImageImage = nil
        }

        selectedStyle(title: "None", style: nil)

        let denoiseStrength = settings?.params?.denoisingStrength ?? 0.75
        let denoiseFloat = Float(truncating: denoiseStrength as NSNumber)
        denoiseStrengthSliderLabel.text = "\(denoiseStrength)"
        denoisStrengthSlider.setValue(denoiseFloat, animated: false)

        let initialWidth = ((settings?.params?.width) != nil) ? (settings?.params?.width)! / 64 : 8
        let initialHeight = ((settings?.params?.height) != nil) ? (settings?.params?.height)! / 64 : 8
        widthSlider.setValue(Float(initialWidth), animated: false)
        heightSlider.setValue(Float(initialHeight), animated: false)

        let selectedModel = settings?.models?.first ?? "stable_diffusion"
        modelPickButton.setTitle(selectedModel, for: .normal)

        // setup button?
        let controlTypeOptions: [String] = [
            "None",
            "canny",
            "hed",
            "depth",
            "normal",
            "openpose",
            "seg",
            "scribble",
            "fakescribbles",
            "hough",
        ]
        let controlTypeMenuChildren: [UIAction] = {
            var actions: [UIAction] = []
            controlTypeOptions.forEach { option in
                let state: UIMenuElement.State = settings?.params?.controlType?.rawValue == option ? .on : .off
                actions.append(UIAction(title: option, state: state, handler: { _ in
                    self.generationSettingsUpdated()
                }))
            }

            return actions
        }()
        controlTypeButton.menu = UIMenu(children: controlTypeMenuChildren)
        controlTypeButton.showsMenuAsPrimaryAction = true
        controlTypeButton.changesSelectionAsPrimaryAction = true


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
        samplerPickButton.showsMenuAsPrimaryAction = true
        samplerPickButton.changesSelectionAsPrimaryAction = true

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

        if let prompt = settings?.prompt {
            let splitPrompt = prompt.components(separatedBy: "###")
            if let positivePrompt = splitPrompt.first {
                promptTextView.text = positivePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if splitPrompt.first != splitPrompt.last, let negativePrompt = splitPrompt.last {
                negativePromptTextView.text = negativePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                negativePromptTextView.text = ""
            }
        } else {
            promptTextView.text = "temple in ruins, forest, stairs, columns, cinematic, detailed, atmospheric, epic, concept art, Matte painting, background, mist, photo-realistic, concept art, volumetric light, cinematic epic + rule of thirds octane render, 8k, corona render, movie concept art, octane render, cinematic, trending on artstation, movie concept art, cinematic composition, ultra-detailed, realistic, hyper-realistic, volumetric lighting, 8k"
            negativePromptTextView.text = "bad quality, worst quality"
        }

        if selectedModel == "SDXL_beta::stability.ai#6901" {
            imageQuantitySlider.setValue(2.0, animated: false)
            requestQuantitySlider.setValue(1.0, animated: false)
        } else if let seed = seed {
            seedTextField.text = seed
            randomSeedButton.isSelected = false
            imageQuantitySlider.setValue(1.0, animated: false)
            requestQuantitySlider.setValue(1.0, animated: false)
        } else {
            imageQuantitySlider.setValue(Float(settings?.params?.n ?? 1), animated: false)
            requestQuantitySlider.setValue(1.0, animated: false)
        }

        let returnControlMap = settings?.params?.returnControlMap ?? false
        returnControlMapButton.isSelected = returnControlMap

        let imageIsControlMap = settings?.params?.imageIsControl ?? false
        imageIsControlMapButton.isSelected = imageIsControlMap

        generationSettingsUpdated()
    }

    func generationSettingsUpdated(customWait: TimeInterval = 1) {
        saveGenerationSettingsTimer?.invalidate()
        saveGenerationSettingsTimer = Timer.scheduledTimer(withTimeInterval: customWait, repeats: false, block: { timer in
            self.saveGenerationSettings()
            timer.invalidate()
        })

        kudosEstimateTimer?.invalidate()
        self.generateButton.isEnabled = false
        if customWait == 1 {
            generateButtonLabel.text = "Updating Kudos Estimate..."
            statusLabel.text = "Loading your total Kudos..."
        }
        kudosEstimateTimer = Timer.scheduledTimer(withTimeInterval: customWait, repeats: false, block: { timer in
            self.fetchAndDisplayKudosEstimate()
            self.loadUserKudos()
            timer.invalidate()
        })

        updateSliderLabels()
    }

    func saveGenerationSettings() {
        guard let settings = createGeneratonBodyForCurrentSettings(ignoreStyle: true) else { return }
        UserPreferences.standard.set(recentSettings: settings)
    }

    func fetchAndDisplayKudosEstimate() {
        guard let currentGen = createGeneratonBodyForCurrentSettings(dryRun: true) else { return }
        Task(priority: .userInitiated) {
            do {
                let result = try await HordeV2API.postImageAsyncGenerate(body: currentGen, apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent())
                Log.debug("Kudos estimate result: \(result)")
                let kudosEstimate = result.kudos ?? 0
                DispatchQueue.main.async {
                    self.generateButton.isEnabled = true
                    let requestCount = Int(self.requestQuantitySlider.value)
                    let adjustedKudosEstimate = Int(kudosEstimate) * requestCount
                    let adjustedImageCount = (currentGen.params?.n ?? 1) * requestCount
                    self.generateButtonLabel.text = "Kudos Cost: ~\(adjustedKudosEstimate) for \(adjustedImageCount) images, ~\(adjustedKudosEstimate / adjustedImageCount) per image"
                }
            } catch ErrorResponse.error(_, _, let knownError) {
                self.generateButton.isEnabled = false
                self.generateButtonLabel.text = "Error: \(knownError.message)"
            } catch {
                self.generateButton.isEnabled = false
                self.generateButtonLabel.text = error.localizedDescription
            }
        }
    }

    func createGeneratonBodyForCurrentSettings(dryRun: Bool = false, ignoreStyle: Bool = false) -> GenerationInputStable? {
        let promptText = promptTextView.text ?? ""
        let negativePrompt = negativePromptTextView.text ?? ""

        var generationText = negativePrompt.isEmpty ? promptText : "\(promptText) ### \(negativePrompt)"

        var currentDimensions = getCurrentWidthAndHeight()

        var samplerString = samplerPickButton.menu?.selectedElements[0].title ?? "k_euler_a"

        let samplerName = ModelGenerationInputStable.SamplerName(rawValue: samplerString)

        var postprocessing: [ModelGenerationInputStable.PostProcessing]? = []

        if gfpganToggleButton.isSelected {
            postprocessing?.append(.gfpgan)
        }

        if codeFormersToggleButton.isSelected {
            postprocessing?.append(.codeFormers)
        }

        if let menuItem = upscalerPickButton.menu?.selectedElements.first, let upscaler = ModelGenerationInputStable.PostProcessing(rawValue: menuItem.title) {
            postprocessing?.append(upscaler)
        }

        if let pp = postprocessing, pp.isEmpty {
            postprocessing = nil
        }

        var seed: String? = seedTextField.text ?? ""
        if let seedCheck = seed, seedCheck.isEmpty { seed = nil }

        var modelName = modelPickButton.titleLabel?.text ?? "stable_diffusion"

        var sourceImage: String? = nil
        var controlType: ModelGenerationInputStable.ControlType? = nil
        let denoisingStrength: Decimal = Decimal(round(Double(denoisStrengthSlider.value) * 100.0) / 100.0)
        var sourceProcessing: GenerationInputStable.SourceProcessing? = nil
        if let image = imageToImageImage?.resized(toWidth: CGFloat(64 * currentDimensions.0)) {
            sourceImage = image.jpegData(compressionQuality: 1)?.base64EncodedString()
            sourceProcessing = .img2img
            if let controlTypeString = controlTypeButton.menu?.selectedElements[0].title {
                controlType = ModelGenerationInputStable.ControlType(rawValue: controlTypeString)
            }
        }

        let imageIsControl = imageIsControlMapButton.isEnabled ? imageIsControlMapButton.isSelected : false
        let returnControlMap = returnControlMapButton.isEnabled ? returnControlMapButton.isSelected : false

        var steps = Int(stepsSlider.value)
        var cfgScale = Decimal(Int(guidanceSlider.value))

        var loras: [ModelPayloadLorasStable]? = nil

        var numberOfImages = Int(imageQuantitySlider.value)

        if !ignoreStyle, let style = currentSelectedStyle {
            if let styleSteps = style.steps {
                Log.debug("Set steps from style \(styleSteps)")
                steps = styleSteps
            }

            if let styleCfg = style.cfg_scale {
                Log.debug("Set cfg from style \(styleCfg)")
                cfgScale = styleCfg
            }

            generationText = style.prompt.replacingOccurrences(of: "{p}", with: promptText)
            if negativePrompt.isEmpty {
                generationText = generationText.replacingOccurrences(of: "{np},", with: "")
                generationText = generationText.replacingOccurrences(of: "{np}", with: "")
            } else if generationText.contains("###") {
                generationText = generationText.replacingOccurrences(of: "{np}", with: negativePrompt)
            } else {
                generationText = generationText.replacingOccurrences(of: "{np}", with: " ### \(negativePrompt)")
            }

            if let model = style.model {
                Log.debug("Set model from style: \(model)")
                modelName = model
            }

            if let string = style.samplerName {
                Log.debug("Set sampler from style: \(string)")
                samplerString = string
            }

            if let width = style.width, let height = style.height {
                Log.debug("Set dimensions from style: \(width/64) x \(height/64)")
                currentDimensions = (width/64, height/64)
            }

            if let styleLoras = style.loras {
                Log.debug("Set loras from style: \(styleLoras)")
                loras = styleLoras
            }

        }

        let modelParams = ModelGenerationInputStable(
            samplerName: samplerName,
            cfgScale: cfgScale,
            denoisingStrength: denoisingStrength,
            seed: seed,
            height: 64 * currentDimensions.1,
            width: 64 * currentDimensions.0,
            seedVariation: nil,
            postProcessing: postprocessing,
            karras: karrasToggleButton.isSelected,
            tiling: tilingToggleButton.isSelected,
            hiresFix: hiresFixToggleButton.isSelected,
            clipSkip: Int(clipSkipSlider.value),
            controlType: controlType,
            imageIsControl: imageIsControl,
            returnControlMap: returnControlMap,
            facefixerStrength: Decimal(round(Double(faceFixerStrengthSlider.value) * 100.0) / 100.0),
            loras: loras,
            steps: steps,
            n: numberOfImages
        )

        let input = GenerationInputStable(
            prompt: generationText,
            params: modelParams,
            nsfw: UserPreferences.standard.allowNSFW,
            trustedWorkers: UserPreferences.standard.trustedWorkers,
            slowWorkers: UserPreferences.standard.slowWorkers,
            censorNsfw: !UserPreferences.standard.allowNSFW,
            workers: nil,
            workerBlacklist: nil,
            models: [modelName],
            sourceImage: sourceImage,
            sourceProcessing: sourceProcessing,
            sourceMask: nil,
            r2: true,
            shared: UserPreferences.standard.shareWithLaion,
            replacementFilter: true,
            dryRun: dryRun
        )
        return input
    }

    func getCurrentWidthAndHeight() -> (Int, Int) {
        return (Int(widthSlider.value), Int(heightSlider.value))
    }

    func updateSliderLabels() {
        let currentDimensions = getCurrentWidthAndHeight()
        widthSliderSizeLabel.text = "\(currentDimensions.0 * 64)"
        heightSliderSizeLabel.text = "\(currentDimensions.1 * 64)"

        let gcd = gcdBinaryRecursiveStein(currentDimensions.0, currentDimensions.1)
        aspectRatioButton.titleLabel?.text = "\(currentDimensions.0 / gcd):\(currentDimensions.1 / gcd)"
        aspectRatioButton.sizeToFit()

        imageQuantitySliderLabel.text = "\(Int(imageQuantitySlider.value))"
        requestQuantitySliderLabel.text = "\(Int(requestQuantitySlider.value))"
    }

    func loadUserKudos() {
        if UserPreferences.standard.apiKey == "0000000000" {
            self.statusLabel.text = "Your kudos: ∞"
        } else {
            DispatchQueue.global(qos: .background).async {
                HordeV2API.getFindUser(apikey: UserPreferences.standard.apiKey, clientAgent: hordeClientAgent()) { data, error in
                    if let data = data, let kudos = data.kudos {
                        DispatchQueue.main.async {
                            self.statusLabel.text = "Your Kudos: \(kudos.formatted())"
                        }
                    } else if let error = error {
                        Log.debug(error.localizedDescription)
                    }
                }
            }
        }
    }
}

// MARK: - Text View Delegate

extension GeneratorViewController: UITextViewDelegate {
    func textViewDidEndEditing(_: UITextView) {
        generationSettingsUpdated()
    }
}

// MARK: - Generation Tracker Delegate

extension GeneratorViewController: GenerationTrackerDelegate {
    func showUpdate(type: UpdateType, message: String) {
        statusLabel.text = message
        if type == .success || type == .error {
            generateButton.isEnabled = true
            generationSettingsUpdated(customWait: 2)
        }
    }
}

// MARK: - Model Picker

extension GeneratorViewController: ModelsTableViewControllerDelegate {
    func selectedModel(name: String) {
        modelPickButton.setTitle(name, for: .normal)
        if name == "SDXL_beta::stability.ai#6901" {
            imageQuantitySlider.setValue(2, animated: true)
            imageQuantitySlider.isEnabled = false
            if widthSlider.value < 16 && heightSlider.value < 16 {
                widthSlider.setValue(16, animated: true)
                heightSlider.setValue(16, animated: true)
            }
        } else {
            imageQuantitySlider.isEnabled = true
        }
        generationSettingsUpdated()
    }
}

// MARK: - Style Picker

extension GeneratorViewController: StylesTableViewControllerDelegate {
    func selectedStyle(title: String, style: Style?) {
        styleButton.setTitle(title, for: .normal)
        currentSelectedStyleTitle = title
        currentSelectedStyle = style
        generationSettingsUpdated()
    }
}
