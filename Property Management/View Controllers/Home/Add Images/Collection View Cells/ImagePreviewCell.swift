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
    
    func setup(with image: UIImage) {
        imageView.image = image
    }
}
