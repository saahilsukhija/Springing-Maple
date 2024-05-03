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
    var activities: [Activity] = []
    var userEnteredValues: [Date : (String, Double?, String)] = [:] //Key is INITIAL DATE
    
    var shouldDeleteFromList = true
    var isPresentingCamera = false
    var isLoading = false
    
    
    
    var loadingScreen: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load")
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(userLocationUpdated), name: .locationUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userDriveUpdated(_:)), name: .newDriveFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(driveMarkedAsRegistered(_:)), name: .driveMarkedAsRegistered, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(driveMarkedAsDeleted(_:)), name: .driveMarkedAsDeleted, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(workMarkedAsRegistered(_:)), name: .workMarkedAsRegistered, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(workMarkedAsDeleted(_:)), name: .workMarkedAsDeleted, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(cloudDriveDetected(_:)), name: .cloudDriveDetected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(cloudWorkDetected(_:)), name: .cloudWorkDetected, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(shouldUpdateTableView), name: .shouldUpdateTableView, object: nil)
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
    
    @objc func shouldUpdateTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.isLoading = false
        loadingScreen?.removeFromSuperview()
    }
    override func viewDidAppear(_ animated: Bool) {
        
        guard !isPresentingCamera else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
            guard User.shared.isLoggedIn() else {
                let vc = UIStoryboard(name: "LoginScreens", bundle: nil).instantiateViewController(withIdentifier: LoginVC.identifier)
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
                try? FirestoreDatabase.shared.addNotificationForPrivateDrives()
                try? FirestoreDatabase.shared.addNotificationForPrivateWorks()
                return
            }
            
            Task {
                do {
                    let team = try await FirestoreDatabase.shared.getUserTeam()
                    DispatchQueue.main.async {
                        if team == nil {
                        
                            let vc = UIStoryboard(name: "LoginScreens", bundle: nil).instantiateViewController(withIdentifier: NewTeamVC.identifier)
                            vc.modalPresentationStyle = .fullScreen
                            self.present(vc, animated: true)
                            return
                        }
                        else {
                            User.shared.team = team
                        }
                    }
                }
            }
            
            try? FirestoreDatabase.shared.addNotificationForPrivateDrives()
            try? FirestoreDatabase.shared.addNotificationForPrivateWorks()
            
            
            self.loadingScreen = self.createLoadingScreen(frame: self.view.frame)

            self.isLoading = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.isLoading {
                    self.view.addSubview(self.loadingScreen!)
                }
            }
            Task {
//                let d1 = Drive(initialCoordinates: CLLocationCoordinate2D(latitude: -122.034679, longitude: 37.322557), finalCoordinates: CLLocationCoordinate2D(latitude: -122.0562, longitude: 37.3150), initialDate: Date().getDate(byAdding: .minute, value: 12), finalDate: Date().getDate(byAdding: .minute, value: 18), initPlace: "Home Depot", finPlace: "Dolores Dr.", milesDriven: 1.7)
//                let d2 = Drive(initialCoordinates: CLLocationCoordinate2D(latitude: -122.0562, longitude: 37.3150), finalCoordinates: CLLocationCoordinate2D(latitude: -122.034679, longitude: 37.322557), initialDate: Date().getDate(byAdding: .minute, value: 32), finalDate: Date().getDate(byAdding: .minute, value: 40), initPlace: "Dolores Dr.", finPlace: "Walmart", milesDriven: 1.7)
//                let work = Work(initialCoordinates: CLLocationCoordinate2D(latitude: -122.0562, longitude: 37.3150), finalCoordinates: CLLocationCoordinate2D(latitude: -122.0562, longitude: 37.3150), initialDate: Date().getDate(byAdding: .minute, value: 18), finalDate: Date().getDate(byAdding: .minute, value: 32), initPlace: "Dolores Dr.", finPlace: "Dolores Dr.")
//                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//                    Task {
//                        try? await FirestoreDatabase.shared.uploadPrivateDrive(d1)
//                        try? await FirestoreDatabase.shared.uploadPrivateWork(work)
//                        try? await FirestoreDatabase.shared.uploadPrivateDrive(d2)
//                    }
//                }
////                try? await FirestoreDatabase.shared.uploadPrivateDrive(Drive(initialCoordinates: CLLocationCoordinate2D(latitude: -122.055925, longitude: 37.323040), finalCoordinates: CLLocationCoordinate2D(latitude: -122.054925, longitude: 37.323040), initialDate: Date(), finalDate: Date(), initPlace: "Home", finPlace: "Home Depot"))
////                try? await FirestoreDatabase.shared.uploadPrivateDrive(Drive(initialCoordinates: CLLocationCoordinate2D(latitude: -122.054925, longitude: 37.323040), finalCoordinates: CLLocationCoordinate2D(latitude: -122.054925, longitude: 37.323040), initialDate: Date(), finalDate: Date(), initPlace: "Home Depot", finPlace: "Home"))
////                try? await FirestoreDatabase.shared.uploadPrivateWork(Work(initialCoordinates: CLLocationCoordinate2D(latitude: -122.054925, longitude: 37.323040), finalCoordinates: CLLocationCoordinate2D(latitude: -122.054925, longitude: 37.323040), initialDate: Date(), finalDate: Date(), initPlace: "Home Depot", finPlace: "Home Depot"))
                do {
                    GoogleSheetAssistant.shared.addUserSheet()
                    var drives: [Drive] = []
                    var works: [Work] = []
                    do {
                        drives = try await FirestoreDatabase.shared.getPrivateDrives()
                    } catch {}
                    do {
                        works = try await FirestoreDatabase.shared.getPrivateWorks()
                    } catch {}
                    self.activities = drives
                    self.activities.replaceWorks(with: works)
                    
                    for (i, a) in self.activities.enumerated() {
                        if a.initialPlace == nil || a.initialPlace == "" || a.initialPlace == "(error)" {
                            print("BRUH")
//                            LocationManager().getReverseGeoCodedLocation(location: CLLocation(latitude: a.initialCoordinate.latitude, longitude: a.initialCoordinate.longitude)) { location, placemark, error in
//                                var text = ""
//                                if let error = error {
//                                    text = ""
//                                    print(error.localizedDescription)
//                                } else {
//                                    text = placemark?.name ?? "(error 2)"
//                                }
//                                
//                                DispatchQueue.main.async {
//                                    self.activities[i].setInitPlace(text)
//                                    self.tableView.reloadData()
//                                }
//                            }
                            
                        }
                        if a.finalPlace == nil || a.finalPlace == "" || a.finalPlace == "(error)" {
                            print("BRUH2")
//                            LocationManager().getReverseGeoCodedLocation(location: CLLocation(latitude: a.finalCoordinate.latitude, longitude: a.finalCoordinate.longitude)) { location, placemark, error in
//                                var text = ""
//                                if let error = error {
//                                    text = ""
//                                    print(error.localizedDescription)
//                                } else {
//                                    text = placemark?.name ?? "(error 2)"
//                                }
//                                
//                                DispatchQueue.main.async {
//                                    self.activities[i].setFinalPlace(text)
//                                    self.tableView.reloadData()
//                                    
//                                }
//                            }
                            
                        }
                    }
                    print("got drives: \(drives)")
                    print("got works: \(works)")
                    for work in works {
                        print("initial: \(work.initialCoordinate) at \(work.initialDate) \n final: \(work.finalCoordinate) at \(work.finalDate)")
                        print(work.finalDate.secondsSince(work.initialDate))
                    }
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.tableView.reloadData()
                        self.loadingScreen?.removeFromSuperview()
                    }
                    
                    

                    
                }

            }
        }
    }
    
    
    func showSignInToast() async {
        
        if(User.shared.isLoggedIn()) {
            //showAnimationToast(animationName: "LoginSuccess", message: "Welcome, \(GIDSignIn.sharedInstance.currentUser!.profile!.givenName!)")
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
        if !User.shared.isLoggedIn() {
            let vc = UIStoryboard(name: "LoginScreens", bundle: nil).instantiateViewController(withIdentifier: "LoginScreen") as! LoginVC
            self.modalPresentationStyle = .fullScreen
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = UIStoryboard(name: "LoginScreens", bundle: nil).instantiateViewController(withIdentifier: ProfileVC.identifier) as! ProfileVC
            self.modalPresentationStyle = .fullScreen
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func presentAddActivityVC() {
        let vc = storyboard?.instantiateViewController(withIdentifier: ChooseActivityVC.identifier) as! ChooseActivityVC
        navigationController?.pushViewController(vc, animated: true)
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
        if arr.count > activities.getDrives().count {
            activities.replaceDrives(with: arr)
            tableView.reloadData()
        }
    }
    
    @objc func cloudWorkDetected(_ notification: NSNotification) {
        guard let arr = notification.userInfo?["works"] as? [Work] else {
            print("no works recieved on cloud work notification")
            return
        }
        if arr.count > activities.getWorks().count {
            activities.replaceWorks(with: arr)
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
        
        if registeredDrive.ticketNumber == "" {
            askToSubmitDrive(drive, registeredDrive)
        } else {
            submitDrive(drive, registeredDrive)
        }
        
        
    }
    
    @objc func workMarkedAsRegistered(_ notification: NSNotification) {
        guard let work = notification.userInfo?["work"] as? Work else {
            print("no work recieved on work notification")
            return
        }
        guard let registeredWork = notification.userInfo?["registered_work"] as? RegisteredWork else {
            print("no registered work recieved on work notification")
            return
        }
        
        let receipt = notification.userInfo?["receipt_image"] as? UIImage
        
        if registeredWork.ticketNumber == "" {
            askToSubmitWork(work, registeredWork, receipt)
        } else {
            submitWork(work, registeredWork, receipt)
        }
        
        
    }
    
    func askToSubmitDrive(_ drive: Drive, _ registeredDrive: RegisteredDrive) {
        let alert = UIAlertController(title: "No Ticket Number Given!", message: "No ticket number was provided, are you sure you want to continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { action in
            self.submitDrive(drive, registeredDrive)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    
    func submitDrive(_ drive: Drive, _ registeredDrive: RegisteredDrive) {
        Task {
            
            let index = activities.firstIndex { d in
                return d == drive
            }
            
            guard let index = index else {
                print("no index")
                return
            }
            
            self.showConfirmDriveToast()
            activities.remove(at: index)
            if activities.count != 0 {
                tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .right)
            } else {
                tableView.reloadData()
            }
            
            do {
                try await FirestoreDatabase.shared.registerDrive(from: activities.getDrives(), drive: drive, to: registeredDrive)
                    GoogleSheetAssistant.shared.appendRegisteredDriveToSpreadsheet(registeredDrive)

            } catch {
                DispatchQueue.main.async {
                    self.showFailureToast(message: error.localizedDescription)
                }
            }


        }
    }
    
    func askToSubmitWork(_ work: Work, _ registeredWork: RegisteredWork, _ receipt: UIImage?) {
        let alert = UIAlertController(title: "No Ticket Number Given!", message: "No ticket number was provided, are you sure you want to continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { action in
            self.submitWork(work, registeredWork, receipt)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func submitWork(_ work: Work, _ registeredWork: RegisteredWork, _ receipt: UIImage?) {
        Task {
            
            let index = activities.firstIndex { d in
                return d == work
            }
            
            let isOngoing = (work.finalDate == .ongoingDate)
            
            if index == nil  {
                work.setFinalDate(Date())
                registeredWork.setFinalDate(Date())
                LocationManager.shared.removeLastDrive()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.showConfirmWorkToast();
            }
            else {
                self.showConfirmWorkToast();
                
                if let index = index {
                    activities.remove(at: index)
                }
                if activities.count != 0 {
                    if let index = index {
                        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .right)
                    } else {
                        LocationManager.shared.removeLastDrive()
                        tableView.deleteRows(at: [IndexPath(row: activities.count + 1, section: 0)], with: .right)
                    }
                } else {
                    tableView.reloadData()
                }
            }
            
            do {
                if let receipt = receipt {
                    try FirebaseStorage.shared.uploadWorkReciept(registeredWork, image: receipt) { completion in
                        print("did upload reciept: \(completion)")
                        Task {
                            try await FirestoreDatabase.shared.registerWork(from: self.activities.getWorks(), work: work, to: registeredWork)
                            GoogleSheetAssistant.shared.appendRegisteredWorkToSpreadsheet(registeredWork)
                        }
                    }
                } else {
                    try await FirestoreDatabase.shared.registerWork(from: activities.getWorks(), work: work, to: registeredWork)
                    GoogleSheetAssistant.shared.appendRegisteredWorkToSpreadsheet(registeredWork)
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
            
            let index = activities.firstIndex { d in
                return d == drive
            }
            
            guard let index = index else {
                print("no index")
                return
            }
            
            self.showDeleteDriveToast()
            activities.remove(at: index)
            
            if activities.count != 0 {
                tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
            }
            else {
                tableView.reloadData()
            }
            
            do {
                try await FirestoreDatabase.shared.removePrivateDrive(drive, from: activities.getDrives())
            } catch {
                DispatchQueue.main.async {
                    self.showFailureToast(message: error.localizedDescription)
                }
            }
            


        }
    }
    
    @objc func workMarkedAsDeleted(_ notification: NSNotification) {
        guard let work = notification.userInfo?["work"] as? Work else {
            print("no work recieved on work notification")
            return
        }
        
        Task {
            
            let index = activities.firstIndex { w in
                return w == work
            }
            
            let isOngoing = (work.finalDate == .ongoingDate)
            
            if isOngoing {
                LocationManager.shared.removeLastDrive()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                self.showDeleteWorkToast();
                return
            }
            
            guard index != nil else {
                print("no index")
                return
            }
            
            self.showDeleteWorkToast()
            if let index = index {
                activities.remove(at: index)
            }
            
            if activities.count != 0 && !isOngoing {
                if let index = index {
                    tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .left)
                } else {
                    LocationManager.shared.removeLastDrive()
                    tableView.deleteRows(at: [IndexPath(row: activities.count + 1, section: 0)], with: .left)
                }
            } else {
                tableView.reloadData()
            }
            
            do {
                try await FirestoreDatabase.shared.removePrivateWork(work, from: activities.getWorks())
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
        if activities.count + (LocationManager.shared.lastDriveCreated == nil ? 0 : 1) == 0 {
            return 1
        }
        return activities.count + (LocationManager.shared.lastDriveCreated == nil ? 0 : 1)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if activities.count + (LocationManager.shared.lastDriveCreated == nil ? 0 : 1) == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: NoActivityCell.identifier) as! NoActivityCell
            cell.setup(vc: self)
            return cell
        }
        if indexPath.row < activities.count {
            if activities[indexPath.row] is Work {
                let cell = tableView.dequeueReusableCell(withIdentifier: WorkCell.identifier) as! WorkCell
                cell.setup(with: activities[indexPath.row] as! Work, fields: userEnteredValues[activities[indexPath.row].initialDate])
                cell.parentVC = self
                
                //Separator Full Line
                cell.preservesSuperviewLayoutMargins = false
                cell.separatorInset = .zero
                cell.layoutMargins = .zero
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: DriveCell.identifier) as! DriveCell
                cell.setup(with: activities[indexPath.row] as! Drive, fields: userEnteredValues[activities[indexPath.row].initialDate])
                cell.parentVC = self
                
                //Separator Full Line
                cell.preservesSuperviewLayoutMargins = false
                cell.separatorInset = .zero
                cell.layoutMargins = .zero
                return cell
            }
        }
        else {
            print("pending work!!!")
            //pending work
            let cell = tableView.dequeueReusableCell(withIdentifier: WorkCell.identifier) as! WorkCell
            let drive = LocationManager.shared.lastDriveCreated!
            let work = Work(initialCoordinates: drive.initialCoordinate, finalCoordinates: drive.finalCoordinate, initialDate: drive.finalDate, finalDate: Date.ongoingDate, initPlace: drive.finalPlace, finPlace: drive.finalPlace)
            cell.setup(with: work, fields: userEnteredValues[work.initialDate])
            cell.parentVC = self
            
            //Separator Full Line
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = .zero
            cell.layoutMargins = .zero
            return cell
        }
        
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 40))
        view.backgroundColor = .clear
        
        let label = UILabel(frame: CGRect(x: view.frame.size.width/2 - 80, y: 0, width: 160, height: 40))
        label.textAlignment = .center
        label.text = "Swipe to log activity"
        label.font = UIFont(name: "Montserrat-SemiBold", size: 13)
        label.textColor = .systemGray
        label.backgroundColor = .clear
        view.addSubview(label)
        
        let lineViewLeft = UIView(frame: CGRect(x: 45, y: view.frame.size.height / 2, width: label.frame.minX - 50, height: 1))
        lineViewLeft.backgroundColor = .systemGray

        view.addSubview(lineViewLeft)
        
        let lineViewRight = UIView(frame: CGRect(x: label.frame.maxX + 5, y: view.frame.size.height / 2, width: lineViewLeft.frame.size.width, height: 1))
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
        if activities.count == 0 {
            return nil
        }
        let completeAction = UIContextualAction(style: .normal, title: "Complete") { (action, view, completion) in
            if let cell = tableView.cellForRow(at: indexPath) as? WorkCell {
                cell.checkMarkClicked(self)
            } else {
                (tableView.cellForRow(at: indexPath) as! DriveCell).checkMarkClicked(self)
            }
            completion(false)
        }
        completeAction.image = UIImage(systemName: "checkmark")
        completeAction.backgroundColor = .accentColor
        
        return UISwipeActionsConfiguration(actions: [completeAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if activities.count == 0 {
            return nil
        }
        let completeAction = UIContextualAction(style: .normal, title: "Delete") { (action, view, completion) in
            if let cell = tableView.cellForRow(at: indexPath) as? WorkCell {
                cell.trashButtonClicked(self)
            } else {
                (tableView.cellForRow(at: indexPath) as! DriveCell).trashButtonClicked(self)
            }
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

