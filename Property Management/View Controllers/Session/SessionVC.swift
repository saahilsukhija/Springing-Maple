//
//  SessionVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/13/24.
//

import UIKit
import GoogleSignIn

class SessionVC: UIViewController {
    
    @IBOutlet weak var clockInButton: UIButton!
    @IBOutlet weak var breakButton: UIButton!
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var breakMinLabel: UILabel!
    @IBOutlet weak var breakSecLabel: UILabel!
    @IBOutlet weak var clockInLabel: UILabel!
    @IBOutlet weak var startBreakLabel: UILabel!
    
    @IBOutlet var bottomViews: [UIView]!
    
    @IBOutlet weak var driveCounterLabel: UILabel!
    @IBOutlet weak var workCounterLabel: UILabel!
    @IBOutlet weak var driveCaptionLabel: UILabel!
    @IBOutlet weak var workCaptionLabel: UILabel!
    
    var timer: Timer!
    
    var openingSettings: Bool! = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        breakButton.layer.cornerRadius = 10
        clockInButton.layer.cornerRadius = 10
        
        updateButtons()
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateLabels), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(userClockedIn), name: .userClockedIn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userClockedOut), name: .userClockedOut, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                await self.showSignInToast()
            }
        }
        
        for view in bottomViews {
            view.layer.cornerRadius = view.frame.size.height / 2 - 5
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor.systemGray5.cgColor
            view.dropShadow()
        }
    }
    
    deinit {
        timer.invalidate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        openingSettings = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if !User.shared.isLoggedIn()  {
                let vc = UIStoryboard(name: "LoginScreens", bundle: nil).instantiateViewController(withIdentifier: LoginVC.identifier)
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
            else {
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
                                //self.dismiss(animated: true, completion: nil)
                                if !self.openingSettings {
                                    self.navigationController?.popViewController(animated: true)
                                }
                            }
                        }
                    }
                    
                    do {
                        let d = try await FirestoreDatabase.shared.getDailyCounter(.drive)
                        let w = try await FirestoreDatabase.shared.getDailyCounter(.work)
                        
                        DispatchQueue.main.async {
                            self.driveCounterLabel.text = "\(d)"
                            self.workCounterLabel.text = "\(w)"
                            
                            self.driveCaptionLabel.text = (d != 1 ? "drives" : "drive")
                            self.workCaptionLabel.text = (w != 1 ? "visits" : "visit")
                        }
                    } catch {
                        self.driveCounterLabel.text = "0"
                        self.workCounterLabel.text = "0"
                        
                        self.driveCaptionLabel.text = "drives"
                        self.workCaptionLabel.text = "visits"
                    }
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
    
    func updateButtons() {
        if Stopwatch.shared.isRunning {
            clockInLabel.text = "Clock Out"
            clockInButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            
            clockInLabel.textColor = .systemRed
            clockInButton.tintColor = .systemRed
        }
        else {
            clockInLabel.text = "Clock In"
            clockInButton.setImage(UIImage(systemName: "handbag"), for: .normal)
            
            clockInLabel.textColor = .accentColor
            clockInButton.tintColor = .accentColor
        }
        
        if Stopwatch.shared.isOnBreak {
            startBreakLabel.text = "End Break"
            breakButton.setImage(UIImage(systemName: "play"), for: .normal)
            
            startBreakLabel.textColor = .systemRed
            breakButton.tintColor = .systemRed
        }
        else {
            startBreakLabel.text = "Start Break"
            breakButton.setImage(UIImage(systemName: "pause"), for: .normal)
            
            startBreakLabel.textColor = UIColor.break
            breakButton.tintColor = UIColor.break
        }
    }
    
    @objc func updateLabels() {
        let times = Stopwatch.shared.getCurrentTimes()
        hourLabel.text = times.0
        minuteLabel.text = times.1
        secondLabel.text = times.2
        let t = Stopwatch.shared.getCurrentBreakTimes()
        breakMinLabel.text = "\(t.0)"
        breakSecLabel.text = "\(t.1)"
    }
    
    @IBAction func clockInButtonClicked(_ sender: Any) {
        if Stopwatch.shared.isRunning {
            let alert = UIAlertController(title: "Are you sure?", message: "Clocking out will end your session and stop tracking of visits and drives.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { action in
                let _ = Stopwatch.shared.end()
                self.updateButtons()
                GoogleSheetAssistant.shared.appendSummaryToSpreadsheet(date: Date())
                LocationManager.shared.endPendingWork()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    Task {
                        try? await FirestoreDatabase.shared.resetDailyCounters()
                    }
                    self.driveCounterLabel.text = "0"
                    self.workCounterLabel.text = "0"
                    
                    self.driveCaptionLabel.text = "drives"
                    self.workCaptionLabel.text = "visits"
                }
                NotificationCenter.default.removeObserver(self, name: .locationAuthorized, object: nil)
            }))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(locationAuthorizationGranted), name: .locationAuthorized, object: nil)
            Stopwatch.shared.start()
        }
        
        updateButtons()
        
        do {
            try UserDefaults.standard.set(object: Stopwatch.shared, forKey: "stopwatch")
        } catch {
            print("error while storing stopwatch in UserDefaults")
        }
    }
    
    @IBAction func breakButtonClicked(_ sender: Any) {
        if Stopwatch.shared.isOnBreak {
            let (startDate, endDate) = Stopwatch.shared.endBreak()
            GoogleSheetAssistant.shared.appendBreakToSpreadsheet(start: startDate, end: endDate)
            NotificationCenter.default.addObserver(self, selector: #selector(locationAuthorizationGranted), name: .locationAuthorized, object: nil)
            
        } else {
            if Stopwatch.shared.isRunning {
                Stopwatch.shared.startBreak()
                NotificationCenter.default.removeObserver(self, name: .locationAuthorized, object: nil)
            } else {
                Alert.showDefaultAlert(title: "Unable to start a break", message: "Check in before you start a break!", self)
            }
        }
        updateButtons()
    }
    
    
    @objc func userClockedIn() {
        LocationManager.shared.startTracking()
        addLastDriveAtCurrentLocation()
    }
    
    @objc func userClockedOut() {
        LocationManager.shared.stopTracking()
    }
    
    @IBAction func settingsButtonClicked(_ sender: Any) {
        openingSettings = true
        let vc = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: SettingsVC.identifier) as! SettingsVC
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func addLastDriveAtCurrentLocation() {
        if LocationManager.shared.lastActivity == nil || LocationManager.shared.lastActivity?.automotive == false {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if let location = LocationManager.shared.lastLocation {
                    LocationManager.geocode(coordinate: location.coordinate) { placemark, error in
                        LocationManager.shared.lastDriveCreated = Drive(initialCoordinates: location.coordinate, finalCoordinates: location.coordinate, initialDate: Date(), finalDate: Date(), initPlace: placemark?[0].name ?? "error", finPlace: placemark?[0].name ?? "error")
                        AppDelegate.saveVariables()
                        NotificationCenter.default.post(name: .shouldUpdateTableView, object: nil)
                    }
                }
            }
        }

    }
    
    @objc func locationAuthorizationGranted() {
        print("granted")
        addLastDriveAtCurrentLocation()
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}


