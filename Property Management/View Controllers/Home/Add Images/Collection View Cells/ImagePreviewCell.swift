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
    @IBOutlet weak var playButton: UIImageView!
    var image: UIImage!
    var key: Int!
    var parentVC: UIViewController!
    var isVideo: Bool!
    var data: NSData?
    func setup(with image: UIImage, key: Int, _ vc: UIViewController, _ isVid: Bool = false, data: NSData? = nil) {
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageClicked)))
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        self.image = image
        self.key = key
        self.parentVC = vc
        self.isVideo = isVid
        self.data = data
        playButton.isHidden = !isVideo
    }
    
    @objc func imageClicked() {
        if !self.isVideo {
            let vc = parentVC.storyboard?.instantiateViewController(withIdentifier: ImagePreviewVC.identifier) as! ImagePreviewVC
            self.parentVC.present(vc, animated: true)
            vc.setup(with: self.image, key: key, parentVC)
        } else {
            if let data = data {
                let vc = parentVC.storyboard?.instantiateViewController(withIdentifier: VideoPreviewVC.identifier) as! VideoPreviewVC
                self.parentVC.present(vc, animated: true)
                vc.setup(with: self.image, data: data, key: key, parentVC)
            } else {
                print("wtf")
            }
        }
    }
}
