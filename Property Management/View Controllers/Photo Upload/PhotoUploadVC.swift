//
//  PhotoUploadVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/24/24.
//

import UIKit
import CoreLocation
import Photos

class PhotoUploadVC: UIViewController {
    
    static let identifier = "PhotoUploadScreen"
    
    @IBOutlet weak var connectToDropboxButton: UIButton!
    @IBOutlet weak var mainView: UIView!
    
    @IBOutlet weak var propertyField: UITextField!
    @IBOutlet weak var unitButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var propertyFieldTopConstraint: NSLayoutConstraint!
    
    var isUploading = false
    
    var doneButton: UIBarButtonItem!
    var clearAllButton: UIBarButtonItem!
    
    var images: [UIImage] = []
    var videos: [(NSData, UIImage)] = []
    var keys: [Int] = []
    var videoKeys: [Int] = []
    
    var shouldChangePropertyField = true
    var oldProperty: String = ""
    var timer: Timer?
    var isPresentingCamera: Bool = false
    var shouldCancel: Bool = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        propertyField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(textFieldClicked)))
        propertyField.font = UIFont(name: "Montserrat-Medium", size: 16)
        
        unitButton.layer.cornerRadius = 8
        print("CHANGING 2")
        let mutableString = NSMutableAttributedString(string: "Unit #", attributes: [NSAttributedString.Key.font : UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16), .foregroundColor : UIColor.black])
        unitButton.setAttributedTitle(mutableString, for: .normal)
        configureButtonItems()
        
        doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonClicked))
        doneButton.tintColor = .systemGray
        self.navigationItem.rightBarButtonItem = doneButton
        
        clearAllButton = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearAllButtonClicked))
        clearAllButton.tintColor = .systemGray
        self.navigationItem.leftBarButtonItem = clearAllButton
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        progressBar.isHidden = true
        progressBar.progress = 0
        statusLabel.isHidden = true
        statusLabel.text = ""
        isUploading = false
        
        let alignedFlowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
        collectionView.collectionViewLayout = alignedFlowLayout
        
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(autofillTextField), userInfo: nil, repeats: true)
        getCapturesFromDefaults()
        
        NotificationCenter.default.addObserver(self, selector: #selector(autofillTextField), name: .applicationEnteredForeground, object: nil)
    }
    
    deinit {
        timer?.invalidate()
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
        
        progressBar.isHidden = true
        progressBar.progress = 0
        statusLabel.isHidden = true
        statusLabel.text = ""
        isUploading = false

        autofillTextField(disableUnitReset: true)
        
        
    }
    
    @IBAction func refreshButtonClicked(_ sender: Any) {
        self.propertyField.text = "Loading..."
        let mutableString = NSMutableAttributedString(string: "Unit #", attributes: [
            NSAttributedString.Key.font: UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ])
        self.unitButton.setAttributedTitle(mutableString, for: .normal)
        print("WHAT 1")
        autofillTextField()
    }
    
    override func viewDidLayoutSubviews() {
    }
    
    @objc func doneButtonClicked() {
        
        if doneButton.title == "Cancel" {

            DispatchQueue.main.async {
                self.shouldCancel = true
                self.statusLabel.text = "Cancelling Image Uploading..."
            }
            return
        }
        
        guard User.shared.dropbox.isConnected else {
            Alert.showDefaultAlert(title: "No Dropbox account linked!", message: "Please go to the app settings and enable Dropbox", self)
            return
        }
        guard let selectedFolder = User.shared.dropbox.selectedFolder?.path else {
            Alert.showDefaultAlert(title: "No Dropbox folder linked!", message: "Please go to the app settings and link a root folder", self)
            return
        }
        guard images.count + videos.count != 0 else { return }
        
        guard let propertyName = propertyField.text, propertyName.count != 0 else {
            self.showFailureToast(message: "Please enter a property name")
            return
        }
        
        let unit = unitButton.attributedTitle(for: .normal)?.string
        let path = (unit == "Unit #" || unit == nil) ? "\(selectedFolder)/\(propertyName)" : "\(selectedFolder)/\(propertyName)/\(unit ?? "unknown")"
        let name = (unit == "Unit #" || unit == nil) ? "\(propertyName)" : "\(propertyName)_\(unit ?? "unknown")"
        
        progressBar.isHidden = false
        progressBar.progress = 0
        statusLabel.isHidden = false
        animatePropertyFieldTopConstraint(to: 50)
        
        self.view.isUserInteractionEnabled = false
        self.navigationController?.navigationBar.isUserInteractionEnabled = true
        doneButton.title = "Cancel"
        clearAllButton.title = ""
        self.tabBarController?.tabBar.isUserInteractionEnabled = false
        

        var failedImages: [UIImage] = []
        var failedKeys: [Int] = []
        var successfulUploads = 0
        let totalUploads = self.images.count + self.videos.count
        
        self.statusLabel.text = "Uploading image \(successfulUploads + failedImages.count + 1) of \(totalUploads)"
        
        // Start a background task to keep the app running
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            // End the task if time expires
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        DropboxAssistant.shared.uploadImagesToFolder(
            images: self.images,
            keys: self.keys,
            folderPath: path,
            namingConvention: .propertyName,
            property: name
        ) { image, key, success, everythingCompleted in
            
            let currentUpload = successfulUploads + failedImages.count + 1
            if success {
                successfulUploads += 1
                if let index = self.keys.firstIndex(of: key) {
                    self.images.remove(at: index)
                    self.keys.remove(at: index)
                    self.collectionView.reloadData()
                }
                let progress = (Float(currentUpload)) / Float(totalUploads)
                DispatchQueue.main.async {
                    self.progressBar.setProgress(progress, animated: true)
                    if successfulUploads + failedImages.count + 1 <= totalUploads {
                        self.statusLabel.text = "Uploading image \(successfulUploads + failedImages.count + 1) of \(totalUploads)"
                    }
                }
            } else {
                self.statusLabel.text = "Image \(currentUpload) FAILED"
                failedImages.append(image)
                failedKeys.append(key)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.statusLabel.text = "Uploading image \(successfulUploads + failedImages.count + 1) of \(totalUploads)"
                }
            }
            
            if self.shouldCancel {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Image Uploading CANCELLED"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [self] in
                    animatePropertyFieldTopConstraint(to: 0)
                    progressBar.isHidden = true
                    progressBar.progress = 0
                    statusLabel.isHidden = true
                    statusLabel.text = ""
                }
                self.doneButton.title = "Done"
                self.clearAllButton.title = "Clear"
                self.shouldCancel = false
                self.view.isUserInteractionEnabled = true
                self.navigationController?.navigationBar.isUserInteractionEnabled = true
                self.tabBarController?.tabBar.isUserInteractionEnabled = true
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
                
                DispatchQueue.main.async {
                    Alert.showDefaultAlert(title: "Cancelled image uploads", message: "\(successfulUploads) images out of \(totalUploads) have been uploaded. The cancelled images have stayed on this screen, you can try uploading them again.", self)
                }
                return false
            }
            if everythingCompleted {
                var vids: [NSData] = []
                for v in self.videos {
                    vids.append(v.0)
                }
                DropboxAssistant.shared.uploadVideosToFolder(
                    videos: vids,
                    folderPath: path,
                    namingConvention: .propertyName,
                    property: name
                ) { [self] completed2, error2 in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [self] in
                        animatePropertyFieldTopConstraint(to: 0)
                        progressBar.isHidden = true
                        progressBar.progress = 0
                        statusLabel.isHidden = true
                        statusLabel.text = ""
                    }
                    
                    print("COMPLETED UPLOAD OF DROPBOX IMAGES FOR \(name)!")
                    let str = NSMutableAttributedString(string: unit ?? "Unit #", attributes: [
                        NSAttributedString.Key.font: UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16),
                        .foregroundColor: UIColor.black
                    ])
                    self.clearEverything()
                    self.unitButton.setAttributedTitle(str, for: .normal)
                    self.statusLabel.text = "Finished uploading!"
                    
                    self.images = failedImages
                    self.keys = failedKeys
                    
                    if self.images.count > 0 {
                        self.doneButton.tintColor = .accentColor
                        Alert.showDefaultAlert(title: "Some image uploads failed", message: "\(images.count) images out of \(totalUploads) failed. The failed images have stayed on this screen, you can try uploading them again.", self)
                    }
                    
                    doneButton.title = "Done"
                    clearAllButton.title = "Clear"
                    self.shouldCancel = false
                    self.view.isUserInteractionEnabled = true
                    self.navigationController?.navigationBar.isUserInteractionEnabled = true
                    self.tabBarController?.tabBar.isUserInteractionEnabled = true
                    
                    // End the background task
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = .invalid
                }
            }
            return true
            
        }
        
    }

    
    func clearEverything() {
        self.images.removeAll()
        self.keys.removeAll()
        self.videos.removeAll()
        self.videoKeys.removeAll()
        
        // Reset UI components
        let mutableString = NSMutableAttributedString(string: "Unit #", attributes: [
            NSAttributedString.Key.font: UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ])
        self.unitButton.setAttributedTitle(mutableString, for: .normal)
        self.doneButton.tintColor = .systemGray
        self.clearAllButton.tintColor = .systemGray
        self.configureButtonItems()
        print("WHAT 2")
        self.autofillTextField()
        self.collectionView.reloadData()
        
        self.removeCapturesFromDefaults()
    }
    
    //    @objc func photoUploadedSuccess(_ notification: NSNotification) {
    //        guard let info = notification.userInfo else {
    //            print("NO INFO ON PHOTOUPLOADEDSUCCESS")
    //            return
    //        }
    //
    //
    //        guard let image = info["image"], let key = info["key"], let code = info["code"], let imagecount = info["imagecount"] else {
    //            print("INFO EXISTS, BUT NO DATA: \(info)")
    //            return
    //        }
    //
    //
    //    }
    //
    //    @objc func photoUploadedFail(_ notification: NSNotification) {
    //
    //        guard let info = notification.userInfo else {
    //            print("NO INFO ON PHOTOUPLOADEDFAIL")
    //            return
    //        }
    //
    //        guard let image = info["image"], let key = info["key"], let code = info["error_code"], let imagecount = info["imagecount"] else {
    //            print("INFO EXISTS, BUT NO DATA: \(info)")
    //            return
    //        }
    //    }
    
    @objc func clearAllButtonClicked() {
        guard images.count + videos.count != 0 else { return }
        
        let alert = UIAlertController(title: "Are you sure?", message: "This will remove all images that have been taken", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { _ in
            self.images.removeAll()
            self.keys.removeAll()
            self.videos.removeAll()
            self.videoKeys.removeAll()
            let mutableString = NSMutableAttributedString(string: "Unit #", attributes: [NSAttributedString.Key.font : UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16), .foregroundColor : UIColor.black])
            self.unitButton.setAttributedTitle(mutableString, for: .normal)
            self.doneButton.tintColor = .systemGray
            self.clearAllButton.tintColor = .systemGray
            self.configureButtonItems()
            self.autofillTextField()
            self.collectionView.reloadData()
            
            self.removeCapturesFromDefaults()
        }))
        self.present(alert, animated: true)
        
    }
    
    @IBAction func connectToDropboxButtonClicked(_ sender: Any) {
        let vc = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: DropboxConnectVC.identifier)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func newImageAdded(_ image: UIImage, key: Int, fromGallery: Bool = true) {
        if self.keys.contains(key) && key != -1 {
            return
        }
        self.keys.append(key)
        
        self.images.append(image)
        self.collectionView.reloadData()
        
        doneButton.tintColor = .accentColor
        clearAllButton.tintColor = .accentColor
        
        saveCapturesToDefaults()
        if !fromGallery {
            savePhotoToCameraRoll(image)
        }
    }
    
    func newVideoAdded(_ data: NSData, thumbnail: UIImage, key: Int) {
        if self.videoKeys.contains(key) && key != -1 {
            return
        }
        self.videoKeys.append(key)
        
        self.videos.append((data, thumbnail))
        self.collectionView.reloadData()
        
        doneButton.tintColor = .accentColor
        clearAllButton.tintColor = .accentColor
        
        saveCapturesToDefaults()
    }
    
    func imageRemoved(_ image: UIImage, key: Int) {
        guard let index = keys.firstIndex(of: key) else {
            print("ERROR DELETING")
            return
        }
        
        keys.remove(at: index)
        self.images.remove(at: index)
        self.collectionView.reloadData()
        
        if images.count + videos.count == 0 {
            doneButton.tintColor = .systemGray
            clearAllButton.tintColor = .systemGray
        }
        
        saveCapturesToDefaults()
    }
    
    func videoRemoved(_ image: UIImage, key: Int) {
        guard let index = videoKeys.firstIndex(of: key) else {
            print("ERROR DELETING")
            return
        }
        
        videoKeys.remove(at: index)
        self.videos.remove(at: index)
        self.collectionView.reloadData()
        
        if images.count + videos.count == 0 {
            doneButton.tintColor = .systemGray
            clearAllButton.tintColor = .systemGray
        }
        
        saveCapturesToDefaults()
    }
    
    func savePhotoToCameraRoll(_ image: UIImage) {
        
        guard User.shared.settings.autoSavePhotos else { return }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, error in
            if success {
                print("Saved!")
            }
            else if let error = error {
                print(error.localizedDescription)
            }
            else {
                print("unknown error saving photo")
            }
        })
    }
    
    func saveCapturesToDefaults() {
        //        do {
        //            try UserDefaults.standard.set(object: keys, forKey: "images_keys_temp")
        ////            try UserDefaults.standard.set(object: videoKeys, forKey: "videos_keys_temp")
        //            try UserDefaults.standard.saveImages(images, forKey: "images_temp")
        ////            try UserDefaults.standard.saveVideos(videos, forKey: "videos_temp")
        //        } catch {}
    }
    
    func removeCapturesFromDefaults() {
        //        UserDefaults.standard.removeObject(forKey: "images_keys_temp")
        //        UserDefaults.standard.removeObject(forKey: "images_temp")
        //        UserDefaults.standard.removeObject(forKey: "videos_keys_temp")
        //        UserDefaults.standard.removeObject(forKey: "videos_temp")
        //        UserDefaults.standard.removeObject(forKey: "videos_temp" + "_videos")
        //        UserDefaults.standard.removeObject(forKey: "videos_temp" + "_thumbnails")
    }
    
    func getCapturesFromDefaults() {
        //        do {
        //            self.keys = try UserDefaults.standard.get(objectType: [Int].self, forKey: "images_keys_temp") ?? []
        ////            self.videoKeys = try UserDefaults.standard.get(objectType: [Int].self, forKey: "videos_keys_temp") ?? []
        //            self.images = try UserDefaults.standard.getImages(forKey: "images_temp")
        ////            self.videos = try UserDefaults.standard.getVideos(forKey: "videos_temp")
        //        } catch {
        //            print("NO IMAGES SAVED")
        //        }
    }
    
}

extension PhotoUploadVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count + videos.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row >= images.count + videos.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddNewImageCell.identifier, for: indexPath) as! AddNewImageCell
            cell.setup(with: self)
            return cell
        }
        if indexPath.row < images.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImagePreviewCell.identifier, for: indexPath) as! ImagePreviewCell
            cell.setup(with: images[indexPath.row], key: keys[indexPath.row], self)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImagePreviewCell.identifier, for: indexPath) as! ImagePreviewCell
        cell.setup(with: videos[indexPath.row - images.count].1, key: videoKeys[indexPath.row - images.count], self, true, data: videos[indexPath.row - images.count].0)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 3 - 10, height: collectionView.frame.size.width / 3 - 10)
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
        let mutableString = NSMutableAttributedString(string: "Unit #", attributes: [
            NSAttributedString.Key.font: UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ])
        self.unitButton.setAttributedTitle(mutableString, for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.shouldChangePropertyField = true
        }
    }
    
    
}

extension PhotoUploadVC {
    
    
    func configureButtonItems() {
        let actionClosure = { (action: UIAction) in
            let mutableString = NSMutableAttributedString(string: "\(action.title)", attributes: [NSAttributedString.Key.font : UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16), .foregroundColor : UIColor.black])
            self.unitButton.setAttributedTitle(mutableString, for: .normal)
        }
        
        let customClosure = { (action: UIAction) in
            let alertController = UIAlertController(title: "Custom Unit Number", message: "", preferredStyle: UIAlertController.Style.alert)
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Enter Unit"
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let saveAction = UIAlertAction(title: "Save", style: .default) { action in
                let txt = (alertController.textFields![0] as UITextField).text ?? ""
                let mutableString = NSMutableAttributedString(string: "\(txt)", attributes: [NSAttributedString.Key.font : UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16), .foregroundColor : UIColor.black])
                self.unitButton.setAttributedTitle(mutableString, for: .normal)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(saveAction)
            self.present(alertController, animated: true)
        }
        
        var menuChildren: [UIMenuElement] = []
        menuChildren.append(UIAction(title: "Unit #", handler: customClosure))
        menuChildren.append(UIAction(title: "Custom", handler: customClosure))
        for unit in 1...Constants.MAX_UNITS {
            menuChildren.append(UIAction(title: "Unit \(unit)", handler: actionClosure))
        }
        
        for unit in "abcdefghijklmno".uppercased() {
            menuChildren.append(UIAction(title: "Unit \(unit)", handler: actionClosure))
        }
        
        
        
        unitButton.menu = UIMenu(options: .displayInline, children: menuChildren)
        
        unitButton.showsMenuAsPrimaryAction = true
        unitButton.changesSelectionAsPrimaryAction = true
    }
    
    
    @objc func autofillTextField(_ count: Int = 0, disableUnitReset val: Bool = false) {
        print("resetting text field: \(count)")
        oldProperty = self.propertyField.text ?? ""
        print(self.propertyField.text?.count ?? 0)
        guard self.propertyField.text == "Loading..." || self.propertyField.text == "" else { return }
        guard shouldChangePropertyField else { return }
        guard count != 10 else { return }
        guard LocationManager.shared.locationManager?.authorizationStatus != .denied else { return }
        LocationManager.shared.lastLocation = nil
        LocationManager.shared.startTrackingTempLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard let loc = LocationManager.shared.lastLocation else {
                print("NO LOCATION")
                if !Stopwatch.shared.isRunning {
                    LocationManager.shared.stopTracking()
                }
                self.autofillTextField(count + 1, disableUnitReset: val)
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
                
                if self.oldProperty != pl.name {
                    print(self.oldProperty)
                    print(pl.name)
                    self.propertyField.text = pl.name
                    if val {
                        print("CHANGING 1")
                        let mutableString = NSMutableAttributedString(string: "Unit #", attributes: [
                            NSAttributedString.Key.font: UIFont(name: "Montserrat-Medium", size: 16) ?? .systemFont(ofSize: 16),
                            .foregroundColor: UIColor.black
                        ])
                        self.unitButton.setAttributedTitle(mutableString, for: .normal)
                    }
                }
            }
        }
    }
    
    @objc func textFieldClicked() {
        let vc = storyboard?.instantiateViewController(withIdentifier: AddressLookupVC.identifier) as! AddressLookupVC
        vc.delegate = self
        shouldChangePropertyField = false
        oldProperty = propertyField.text ?? ""
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func animatePropertyFieldTopConstraint(to amount: CGFloat) {
        // Update the constraint constant to the desired value
        propertyFieldTopConstraint.constant = amount
        
        // Animate the layout update
        UIView.animate(withDuration: 0.3, delay: 0.02, options: [.curveEaseInOut], animations: {
            // Trigger the layout update
            self.view.layoutIfNeeded()
        }, completion: nil)
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
