//
//  AddNewImageCell.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/9/24.
//

import UIKit
import BSImagePicker
import Photos

class AddNewImageCell: UICollectionViewCell {
    
    static let identifier = "NewImageCell"
    var imagePicker: UIImagePickerController!
    
    var parentVC: UIViewController!
    
    func setup(with vc: AddPropertyImagesVC) {
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(plusButtonClicked)))
        self.parentVC = vc
        imagePicker = UIImagePickerController()
        imagePicker.delegate = vc
    }
    
    func setup(with vc: PhotoUploadVC) {
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(plusButtonClicked)))
        self.parentVC = vc
        imagePicker = UIImagePickerController()
        imagePicker.delegate = vc
    }
    
    @objc func plusButtonClicked() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Take photo", style: .default, handler: { action in
            self.openCamera()
        }))
        sheet.addAction(UIAlertAction(title: "Choose from library", style: .default, handler: { action in
            self.openGallery()
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.parentVC.present(sheet, animated: true)
    
    }
    
    func openCamera() {
        
        if parentVC is AddPropertyImagesVC {
            if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera)){
                imagePicker.sourceType = UIImagePickerController.SourceType.camera
                //If you dont want to edit the photo then you can set allowsEditing to false
                imagePicker.allowsEditing = false
                imagePicker.delegate = parentVC as? any UIImagePickerControllerDelegate & UINavigationControllerDelegate
                
                self.parentVC.present(imagePicker, animated: true, completion: nil)
            }
            else{
                let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.parentVC.present(alert, animated: true, completion: nil)
            }
            return
        }
        
        let vc = CameraViewController()
        vc.parentVC = self.parentVC
        self.parentVC.present(vc, animated: true)

    }

    /// Choose image from camera roll
    func openGallery() {
        let multiSelectImagePicker = ImagePickerController()
        parentVC.presentImagePicker(multiSelectImagePicker, select: { (asset) in
            // User selected an asset. Do something with it. Perhaps begin processing/upload?
        }, deselect: { (asset) in
            // User deselected an asset. Cancel whatever you did when asset was selected.
        }, cancel: { (assets) in
            // User canceled selection.
        }, finish: { (assets) in
            for asset in assets {
                var completedImages: [UIImage] = []
                PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { [self] (image, info) in
                    if let image = image {
                        if completedImages.contains(image) {
                            print("SKIPPING")
                            return
                        }
                        if let vc = parentVC as? AddPropertyImagesVC {
                            
                            vc.newImageAdded(image, key: info?["PHImageResultRequestIDKey"] as? Int ?? 0)
                            completedImages.append(image)
                        }
                        if let vc = parentVC as? PhotoUploadVC {
                            vc.newImageAdded(image, key: info?["PHImageResultRequestIDKey"] as? Int ?? 0)
                            completedImages.append(image)
                        }
                    } else {
                        print("FAIL")
                    }
                }
                //(parentVC as? AddPropertyImagesVC)?.newImageAdded(asset.)
            }
        })
    }
    
}
    
