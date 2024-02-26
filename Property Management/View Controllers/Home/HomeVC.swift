//
//  ViewController.swift
//  Property Management
//
//  Created by Saahil Sukhija on 10/31/23.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import CoreLocation

class HomeVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var locationManager: LocationManager!
    var drives: [Drive] = []
    
    
    var shouldDeleteFromList = true
    
    var isPresentingCamera = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(userLocationUpdated), name: .locationUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userDriveUpdated(_:)), name: .newDriveFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(driveMarkedAsRegistered(_:)), name: .driveMarkedAsRegistered, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(driveMarkedAsDeleted(_:)), name: .driveMarkedAsDeleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cloudDriveDetected(_:)), name: .cloudDriveDetected, object: nil)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                await self.showSignInToast()
            }
            if Stopwatch.shared.shouldTrackLocation() {
                self.locationManager = LocationManager.shared
                LocationManager.shared.getLocation { location, error in
                    if let loc = location {
                        print("initial location: \(loc)")
                    }
                }
            }
        }
        

        
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        guard !isPresentingCamera else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard User.shared.isLoggedIn() else {
                let vc = UIStoryboard(name: "LoginScreens", bundle: nil).instantiateViewController(withIdentifier: LoginVC.identifier) as! LoginVC
                self.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
                try? FirestoreDatabase.shared.addNotificationForPrivateDrives()
                return
            }
            
            try? FirestoreDatabase.shared.addNotificationForPrivateDrives()
            
            let loadingScreen = self.createLoadingScreen(frame: self.view.frame)
            self.view.addSubview(loadingScreen)
            Task {
                do {
                    let drives = try await FirestoreDatabase.shared.getPrivateDrives()
                    self.drives = drives
                    print("got drives: \(drives)")
                    for drive in drives {
                        print("initial: \(drive.initialCoordinate) at \(drive.initialDate) \n final: \(drive.finalCoordinate) at \(drive.finalDate)")
                        print(drive.finalDate.secondsSince(drive.initialDate))
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        loadingScreen.removeFromSuperview()
                    }
                    
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//                        Task {
//                            try? await FirestoreDatabase.shared.uploadPrivateDrive(Drive(initialCoordinates: CLLocationCoordinate2DMake(37.3150, -122.0562), finalCoordinates: CLLocationCoordinate2DMake(37.32, -122.001), initialDate: Date(), finalDate: Date()))
//                            try? await FirestoreDatabase.shared.uploadPrivateDrive(Drive(initialCoordinates: CLLocationCoordinate2DMake(37.3346, -122.009), finalCoordinates: CLLocationCoordinate2DMake(37.348, -122.03), initialDate: Date(), finalDate: Date()))
//                            try? await FirestoreDatabase.shared.uploadPrivateDrive(Drive(initialCoordinates: CLLocationCoordinate2DMake(37.35, -122.25), finalCoordinates: CLLocationCoordinate2DMake(37.243, -122.256), initialDate: Date(), finalDate: Date()))
//                        }
////                    }
                    
                    
                    
                } catch {
                    print(error.localizedDescription)
                }
                DispatchQueue.main.async {
                    loadingScreen.removeFromSuperview()
                }

            }
        }
    }
    
    
    func showSignInToast() async {
        
        if(User.shared.isLoggedIn()) {
            showAnimationToast(animationName: "LoginSuccess", message: "Welcome, \(GIDSignIn.sharedInstance.currentUser!.profile!.givenName!)")
            do {
                try await FirestoreDatabase.shared.uploadUserDetails()
                
            } catch {
                print(error.localizedDescription)
            }
        }
        else {
            print("not signed in")
        }
    }
    
    
    @IBAction func profileButtonClicked(_ sender: Any) {
        let vc = UIStoryboard(name: "LoginScreens", bundle: nil).instantiateViewController(withIdentifier: "LoginScreen") as! LoginVC
        self.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @objc func userLocationUpdated(_ notification: NSNotification) {
        guard let location = notification.userInfo?["location"] else {
            print("no location recieved on location notification")
            return
        }
        print("location: \(location)")
    }
    
    @objc func userDriveUpdated(_ notification: NSNotification)  {
        guard let drive = notification.userInfo?["drive"] as? Drive else {
            print("no drive recieved on drive notification")
            return
        }
        print("retrieved drive: \(drive)")
    }
    
    @objc func cloudDriveDetected(_ notification: NSNotification) {
        guard let arr = notification.userInfo?["drives"] as? [Drive] else {
            print("no drives recieved on cloud drive notification")
            return
        }
        if arr.count > drives.count {
            drives = arr
            tableView.reloadData()
        }
    }
    @objc func driveMarkedAsRegistered(_ notification: NSNotification) {
        guard let drive = notification.userInfo?["drive"] as? Drive else {
            print("no drive recieved on drive notification")
            return
        }
        guard let registeredDrive = notification.userInfo?["registered_drive"] as? RegisteredDrive else {
            print("no registered recieved on drive notification")
            return
        }
        
        let receipt = notification.userInfo?["receipt_image"] as? UIImage
        
        if registeredDrive.ticketNumber == "" {
            askToSubmitDrive(drive, registeredDrive, receipt)
        } else {
            submitDrive(drive, registeredDrive, receipt)
        }
        
        
    }
    
    func askToSubmitDrive(_ drive: Drive, _ registeredDrive: RegisteredDrive, _ receipt: UIImage?) {
        let alert = UIAlertController(title: "No Ticket Number Given!", message: "No ticket number was provided, are you sure you want to continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { action in
            self.submitDrive(drive, registeredDrive, receipt)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func submitDrive(_ drive: Drive, _ registeredDrive: RegisteredDrive, _ receipt: UIImage?) {
        
        Task {
            
            let index = drives.firstIndex { d in
                return d == drive
            }
            
            guard let index = index else {
                print("no index")
                return
            }
            
            self.showConfirmDriveToast()
            drives.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .right)
            
            do {
                if let receipt = receipt {
                    try FirebaseStorage.shared.uploadDriveReciept(registeredDrive, image: receipt) { completion in
                        print("did upload reciept: \(completion)")
                        Task {
                            try await FirestoreDatabase.shared.registerDrive(from: self.drives, drive: drive, to: registeredDrive)
                            GoogleSheetAssistant.shared.appendRegisteredDriveToSpreadsheet(registeredDrive)
                        }
                    }
                } else {
                    try await FirestoreDatabase.shared.registerDrive(from: drives, drive: drive, to: registeredDrive)
                    GoogleSheetAssistant.shared.appendRegisteredDriveToSpreadsheet(registeredDrive)
                }

            } catch {
                DispatchQueue.main.async {
                    self.showFailureToast(message: error.localizedDescription)
                }
            }


        }
        
        
    }
    
    @objc func driveMarkedAsDeleted(_ notification: NSNotification) {
        guard let drive = notification.userInfo?["drive"] as? Drive else {
            print("no drive recieved on drive notification")
            return
        }
        
        Task {
            
            let index = drives.firstIndex { d in
                return d == drive
            }
            
            guard let index = index else {
                print("no index")
                return
            }
            
            self.showDeleteDriveToast()
            drives.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
            
            do {
                try await FirestoreDatabase.shared.removePrivateDrive(drive, from: drives)
            } catch {
                DispatchQueue.main.async {
                    self.showFailureToast(message: error.localizedDescription)
                }
            }
            


        }
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drives.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DriveCell.identifer) as! DriveCell
        cell.setup(with: drives[indexPath.row])
        cell.parentVC = self
        
        //Separator Full Line
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 40))
        view.backgroundColor = .clear
        
        let label = UILabel(frame: CGRect(x: view.frame.size.width/2 - 65, y: 0, width: 130, height: 40))
        label.textAlignment = .center
        label.text = "Swipe to log drive"
        label.font = UIFont(name: "Montserrat-SemiBold", size: 13)
        label.textColor = .systemGray
        view.addSubview(label)
        
        let lineViewLeft = UIView(frame: CGRect(x: 45, y: view.frame.size.height / 2, width: label.frame.minX - 55, height: 1))
        lineViewLeft.backgroundColor = .systemGray
        view.addSubview(lineViewLeft)
        
        let lineViewRight = UIView(frame: CGRect(x: label.frame.maxX + 10, y: view.frame.size.height / 2, width: lineViewLeft.frame.size.width, height: 1))
        lineViewRight.backgroundColor = .systemGray
        view.addSubview(lineViewRight)
        
        let trashImageLeft = UIImageView(frame: CGRect(x: 20, y: 12, width: 15, height: 15))
        trashImageLeft.tintColor = .systemGray
        trashImageLeft.image = UIImage(systemName: "trash")
        view.addSubview(trashImageLeft)
        
        let checkImageRight = UIImageView(frame: CGRect(x: view.frame.size.width - 37, y: 12, width: 15, height: 15))
        checkImageRight.tintColor = .systemGray
        checkImageRight.image = UIImage(systemName: "checkmark")
        view.addSubview(checkImageRight)
        
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let completeAction = UIContextualAction(style: .normal, title: "Complete") { (action, view, completion) in
            (tableView.cellForRow(at: indexPath) as! DriveCell).checkMarkClicked(self)
            completion(false)
        }
        completeAction.image = UIImage(systemName: "checkmark")
        completeAction.backgroundColor = .accentColor
        
        return UISwipeActionsConfiguration(actions: [completeAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let completeAction = UIContextualAction(style: .normal, title: "Delete") { (action, view, completion) in
            (tableView.cellForRow(at: indexPath) as! DriveCell).trashButtonClicked(self)
            completion(false)
        }
        completeAction.image = UIImage(systemName: "trash")
        completeAction.backgroundColor = .systemRed
        
        return UISwipeActionsConfiguration(actions: [completeAction])
        
    }
}

extension HomeVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        UIView.animate(withDuration: 0.2, animations: {
            // For some reason adding inset in keyboardWillShow is animated by itself but removing is not, that's why we have to use animateWithDuration here
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        })
    }
}

