//
//  ViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/26/23.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var generationSpinner: UIActivityIndicatorView!

    @IBOutlet weak var mainImageView: UIImageView!

    @IBOutlet weak var promptTextView: UITextView!

    @IBAction func generateButtonPressed(_ sender: UIButton) {
        generationSpinner.startAnimating()
        V2API.postImageAsyncGenerate(body: GenerationInputStable(prompt: "fantastic scenery landscape from the top of the mountain, pine trees, green valleys, magic fog and lightning, epic composition, fibonacci ratio, golden ratio, fancy, incredible detailed game artwork, sharpen and ultra quality, trending, artstation, behance, wikiart, 8 k"), apikey: "") { data, error in
            if let data = data, let generationIdentifier = data._id {
                self.setNewGenerationRequest(generationIdentifier: generationIdentifier)
            } else {
                print(error)
            }
        }
    }

    var currentGenerationIdentifier: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

}

extension ViewController {
    func setNewGenerationRequest(generationIdentifier: String) {
        print("Got new request \(generationIdentifier)")
        currentGenerationIdentifier = generationIdentifier
        checkCurrentGenerationStatus()
    }

    @objc func checkCurrentGenerationStatus() {
        guard let generationIdentifier = self.currentGenerationIdentifier else { return }
        print("Checking generation status...")
        V2API.getImageAsyncCheck(_id: generationIdentifier) { data, error in
            if let data = data {
                if data.finished == 1 {
                    print("Generation done ")
                    self.getFinishedImageAndDisplay()
                } else if var waitTime = data.waitTime {
                    if waitTime < 1 { waitTime = 1 }
                    print("Wait time... \(waitTime) seconds")
                    self.perform(#selector(self.checkCurrentGenerationStatus), with: nil, afterDelay: TimeInterval(waitTime))
                }
            }
        }
    }

    func getFinishedImageAndDisplay() {
        guard let generationIdentifier = self.currentGenerationIdentifier else { return }
        print("Fetching finished generation")
        V2API.getImageAsyncStatus(_id: generationIdentifier, clientAgent: "Aislingeach (Alpha)") { [self] data, error in
            if let data = data {
                if data.finished == 1 {
                    if let generations = data.generations, let generation = generations.first, let urlString = generation.img, let imageUrl = URL(string: urlString) {
                        DispatchQueue.global().async {
                            let data = try? Data(contentsOf: imageUrl)
                            DispatchQueue.main.async { [self] in
                                generationSpinner.stopAnimating()
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

