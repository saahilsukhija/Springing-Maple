//
//  PhotoUploadVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/24/24.
//

import UIKit
import CoreLocation
class PhotoUploadVC: UIViewController {
    
    static let identifier = "PhotoUploadScreen"
    
    @IBOutlet weak var connectToDropboxButton: UIButton!
    @IBOutlet weak var mainView: UIView!
    
    @IBOutlet weak var propertyField: UITextField!
    @IBOutlet weak var unitButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var doneButton: UIBarButtonItem!
    var clearAllButton: UIBarButtonItem!
    
    var images: [UIImage] = []
    var keys: [Int] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        propertyField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(textFieldClicked)))
        propertyField.font = UIFont(name: "Montserrat-Medium", size: 16)
        
        unitButton.layer.cornerRadius = 8
        
        let mutableString = NSMutableAttributedString(string: "Unit #", attributes: [NSAttributedString.Key.font : UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16), .foregroundColor : UIColor.black])
        unitButton.setAttributedTitle(mutableString, for: .normal)
        configureButtonItems()
        
        doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonClicked))
        doneButton.tintColor = .systemGray
        self.navigationItem.rightBarButtonItem = doneButton
        
        clearAllButton = UIBarButtonItem(title: "Clear All", style: .plain, target: self, action: #selector(clearAllButtonClicked))
        clearAllButton.tintColor = .systemGray
        self.navigationItem.leftBarButtonItem = clearAllButton
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let alignedFlowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
        collectionView.collectionViewLayout = alignedFlowLayout
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        connectToDropboxButton.isHidden = DropboxAssistant.shared.isConnected // only show if not connected
        mainView.isHidden = !connectToDropboxButton.isHidden
        
        if !connectToDropboxButton.isHidden {
            let mutableString = NSMutableAttributedString(string: "You are not logged into Dropbox. Connect to Dropbox to upload photos", attributes: [NSAttributedString.Key.font : UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16), .foregroundColor : UIColor.black])
            mutableString.setColor(color: .systemBlue, forText: "Connect to Dropbox")
            connectToDropboxButton.setAttributedTitle(mutableString, for: .normal)
            return
        }
        
        autofillTextField()
        
        
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
        
        guard let propertyName = propertyField.text, propertyName.count != 0 else {
            self.showFailureToast(message: "Please enter a property name")
            return
        }
        
        let unit = unitButton.attributedTitle(for: .normal)?.string
        let path = (unit == "Unit #" || unit == nil) ? "/\(selectedFolder)/\(propertyName)" : "/\(selectedFolder)/\(propertyName)/\(unit ?? "unknown")"
        let name = (unit == "Unit #" || unit == nil) ? "\(propertyName)" : "\(propertyName)_\(unit ?? "unknown")"
        let loadingScreen = createLoadingScreen(frame: view.frame)
        view.addSubview(loadingScreen)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {

            DropboxAssistant.shared.uploadImagesToFolder(images: self.images, folderPath: path, namingConvention: .propertyName, property: name) { completed, error in
                if let error = error {
                    print(error.localizedDescription)
                }
                else {
                    print("COMPLETED UPLOAD OF DROPBOX IMAGES FOR \(propertyName)!")
                    self.showConfirmWorkToast(message: "Uploaded images!")
                    self.images.removeAll()
                    self.keys.removeAll()
                    let mutableString = NSMutableAttributedString(string: "Unit #", attributes: [NSAttributedString.Key.font : UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16), .foregroundColor : UIColor.black])
                    self.unitButton.setAttributedTitle(mutableString, for: .normal)
                    self.doneButton.tintColor = .systemGray
                    self.clearAllButton.tintColor = .systemGray
                    self.configureButtonItems()
                    self.autofillTextField()
                    self.collectionView.reloadData()

                    loadingScreen.removeFromSuperview()
                }
            }
            
        }
    }
    
    @objc func clearAllButtonClicked() {
        guard images.count != 0 else { return }
        
        self.images.removeAll()
        self.keys.removeAll()
        let mutableString = NSMutableAttributedString(string: "Unit #", attributes: [NSAttributedString.Key.font : UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16), .foregroundColor : UIColor.black])
        self.unitButton.setAttributedTitle(mutableString, for: .normal)
        self.doneButton.tintColor = .systemGray
        self.clearAllButton.tintColor = .systemGray
        self.configureButtonItems()
        self.autofillTextField()
        self.collectionView.reloadData()
        
    }
    @IBAction func connectToDropboxButtonClicked(_ sender: Any) {
        let vc = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: DropboxConnectVC.identifier)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func newImageAdded(_ image: UIImage, key: Int) {
        if self.keys.contains(key) && key != -1 {
            return
        }
        self.keys.append(key)
        
        self.images.append(image)
        self.collectionView.reloadData()
        
        doneButton.tintColor = .accentColor
        clearAllButton.tintColor = .accentColor
    }
    
}

extension PhotoUploadVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row >= images.count {
//            plusButtonClicked()
        }
    }
    
    
}


extension PhotoUploadVC: AddressLookupDelegate {
    
    func didChooseAddress(_ address: String, coordinate: CLLocationCoordinate2D) {
        propertyField.text = address
    }
    
    
}

extension PhotoUploadVC {
    
    
    func configureButtonItems() {
        let actionClosure = { (action: UIAction) in
            let mutableString = NSMutableAttributedString(string: "\(action.title)", attributes: [NSAttributedString.Key.font : UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16), .foregroundColor : UIColor.black])
            self.unitButton.setAttributedTitle(mutableString, for: .normal)
        }
        
        var menuChildren: [UIMenuElement] = []
        for unit in 1...Constants.MAX_UNITS {
            menuChildren.append(UIAction(title: "Unit \(unit)", handler: actionClosure))
        }
        
        unitButton.menu = UIMenu(options: .displayInline, children: menuChildren)
        
        unitButton.showsMenuAsPrimaryAction = true
        unitButton.changesSelectionAsPrimaryAction = true
    }
    
    
    func autofillTextField() {
        if !Stopwatch.shared.isRunning {
            LocationManager.shared.startTracking()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (LocationManager.shared.lastLocation == nil ? 1 : 0)) {
            guard let loc = LocationManager.shared.lastLocation else {
                print("NO LOCATION")
                if !Stopwatch.shared.isRunning {
                    LocationManager.shared.stopTracking()
                }
                return
            }
            LocationManager.geocode(coordinate: loc.coordinate) { placemark, error in
                if !Stopwatch.shared.isRunning {
                    LocationManager.shared.stopTracking()
                }
                guard let pl = placemark?[0] else {
                    print("ERROR: \(error?.localizedDescription ?? "error")")
                    return
                }
                self.propertyField.text = pl.name
            }
        }
    }
    
    @objc func textFieldClicked() {
        let vc = storyboard?.instantiateViewController(withIdentifier: AddressLookupVC.identifier) as! AddressLookupVC
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension PhotoUploadVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Get the image from the info dictionary.
        if let editedImage = info[.originalImage] as? UIImage {
            self.newImageAdded(editedImage, key: -1)
        }
        // Dismiss the UIImagePicker after selection
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.isNavigationBarHidden = false
        self.dismiss(animated: true, completion: nil)
    }
}
