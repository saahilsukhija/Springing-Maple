//
//  AddPropertyImagesVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/9/24.
//

import UIKit

class AddPropertyImagesVC: UIViewController {
    
    static let identifier = "AddPropertyImagesScreen"
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var images: [UIImage] = []
    var propertyName: String?
    
    var doneButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let name = propertyName {
            self.navigationItem.title = "Add Images for \(name)"
        } else {
            self.navigationItem.title = "Add Images"
        }
        
        doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonClicked))
        doneButton.tintColor = .systemGray
        self.navigationItem.rightBarButtonItem = doneButton
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let alignedFlowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
        collectionView.collectionViewLayout = alignedFlowLayout
        
    }
    
    @objc func doneButtonClicked() {
        guard User.shared.dropbox.isConnected else {
            Alert.showDefaultAlert(title: "No Dropbox account linked!", message: "Please go to the app settings and enable Dropbox", self)
            return
        }
        guard let selectedFolder = User.shared.dropbox.selectedFolder?.name else {
            Alert.showDefaultAlert(title: "No Dropbox folder linked!", message: "Please go to the app settings and link a root folder", self)
            return
        }
        guard images.count != 0 else { return }
        guard let propertyName = propertyName else {
            self.showFailureToast(message: "Error finding the property name. Please try again")
            return
        }
        
        let loadingScreen = createLoadingScreen(frame: view.frame)
        view.addSubview(loadingScreen)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            loadingScreen.removeFromSuperview()
            self.navigationController?.popViewController(animated: true)
            DropboxAssistant.shared.uploadImagesToFolder(images: self.images, folderPath: "/\(selectedFolder)/\(propertyName)") { completed, error in
                if let error = error {
                    print(error.localizedDescription)
                }
                else {
                    print("COMPLETED UPLOAD OF DROPBOX IMAGES FOR \(propertyName)!")
                }
            }
            self.showConfirmWorkToast(message: "Uploading images...")
        }
        
        
    }
    
    func setupImages(with images: [UIImage]) {
        self.images = images
        if images.count > 0 {
            doneButton.tintColor = .accentColor
        } else {
            doneButton.tintColor = .systemGray
        }
    }
    
    func newImageAdded(_ image: UIImage) {
        self.images.append(image)
        self.collectionView.reloadData()
        
        doneButton.tintColor = .accentColor
    }
    
}

extension AddPropertyImagesVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row >= images.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddNewImageCell.identifier, for: indexPath) as! AddNewImageCell
            cell.setup(with: self)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImagePreviewCell.identifier, for: indexPath) as! ImagePreviewCell
        cell.setup(with: images[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 3 - 20, height: collectionView.frame.size.width / 3 - 20)
    }
    
    
    
    
}
