//
//  ImagePreviewVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 8/6/24.
//

import UIKit

class ImagePreviewVC: UIViewController {

    static let identifier = "ImagePreviewScreen"
    
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage!
    var key: Int!
    var parentVC: UIViewController!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //navigationItem.title = "Preview"
    }
    
    func setup(with image: UIImage, key: Int, _ vc: UIViewController) {
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        
        self.image = image
        self.key = key
        self.parentVC = vc
    }

    @IBAction func doneButtonClicked(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func deleteButtonClicked(_ sender: Any) {
        if let vc = parentVC as? PhotoUploadVC {
            vc.imageRemoved(image, key: key)
        }
        if let vc = parentVC as? AddPropertyImagesVC {
            vc.imageRemoved(image, key: key)
        }
        self.dismiss(animated: true)
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
