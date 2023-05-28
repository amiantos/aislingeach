//
//  ImageDetailViewController.swift
//  Aislingeach
//
//  Created by Brad Root on 5/28/23.
//

import UIKit

class ImageDetailViewController: UIViewController {

    var generatedImage: GeneratedImage?

    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        loadImage()
    }

    func loadImage() {
        if let image = generatedImage {
            imageView.image = UIImage(data: image.image!)
            navigationItem.title = "\(image.uuid!)"
            promptLabel.text = image.promptSimple
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
