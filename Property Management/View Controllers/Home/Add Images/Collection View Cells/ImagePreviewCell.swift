//
//  ImagePreviewCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/9/24.
//

import UIKit

class ImagePreviewCell: UICollectionViewCell {
    
    static let identifier = "ImagePreviewCell"
    
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage!
    var key: Int!
    var parentVC: UIViewController!
    
    func setup(with image: UIImage, key: Int, _ vc: UIViewController) {
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageClicked)))
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        self.image = image
        self.key = key
        self.parentVC = vc
    }
    
    @objc func imageClicked() {
        let vc = parentVC.storyboard?.instantiateViewController(withIdentifier: ImagePreviewVC.identifier) as! ImagePreviewVC
        self.parentVC.present(vc, animated: true)
        vc.setup(with: self.image, key: key, parentVC)
    }
}
