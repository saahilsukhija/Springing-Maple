//
//  AddNewImageCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/9/24.
//

import UIKit
import FDTake

class AddNewImageCell: UICollectionViewCell {
    
    static let identifier = "NewImageCell"
    var camera: FDTakeController!
    
    var parentVC: AddPropertyImagesVC!
    
    func setup(with vc: AddPropertyImagesVC) {
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(plusButtonClicked)))
        self.parentVC = vc
        camera = FDTakeController()
        camera.allowsVideo = false
    }
    
    @objc func plusButtonClicked() {
        camera.present()
        camera.didGetPhoto = {
            (_ photo: UIImage, _ info: [AnyHashable : Any]) in
            self.parentVC.newImageAdded(photo)
            //self.camera.dismiss()
        }
    }
    
}
