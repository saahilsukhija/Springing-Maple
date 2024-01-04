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
    
    @IBOutlet weak var tableview: UITableView!
    
    var locationManager: LocationManager!
    var visits: [Visit] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(userLocationUpdated), name: .locationUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userVisitUpdated(_:)), name: .newVisitDetected, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            Task {
                await self.showSignInToast()
            }
            self.locationManager = LocationManager.shared
            LocationManager.shared.getLocation { location, error in
                if let loc = location {
                    print("initial location: \(loc)")
                }
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        guard User.shared.isLoggedIn() else {
            let vc = UIStoryboard(name: "LoginScreens", bundle: nil).instantiateViewController(withIdentifier: "LoginScreen") as! LoginVC
            self.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
            return
        }
        
        
        Task {
            do {
                let visits = try await FirestoreDatabase.shared.getPrivateVisits()
                self.visits = visits
                tableview.reloadData()
            } catch {
                self.showFailureToast(message: error.localizedDescription)
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
    
//    @IBAction func submitButtonClicked(_ sender: Any) {
//        let spreadsheet = GoogleSheetAssistant.shared
//        //locationManager?.locationManager?.startUpdatingLocation()
//        locationManager.getCurrentReverseGeoCodedLocation { location, placemark, error in
//            if let error = error {
//                print(error.localizedDescription)
//                //spreadsheet.appendToSpreadsheet(["value" : self.moneyTextField.text ?? "(none)"])
//                return
//            }
//            
//            guard let location = location else {
//                print("no location found")
//                //spreadsheet.appendToSpreadsheet(["value" : self.moneyTextField.text ?? "(none)"])
//                
//                return
//            }
//            
//           // let place = placemark?.name ?? "(\(location.coordinate.latitude), \(location.coordinate.longitude))"
//            //spreadsheet.appendToSpreadsheet(["value" : self.moneyTextField.text == "" ? "(none)" : self.moneyTextField.text!, "location" : place])
//        }
//        
//        
//    }
    
    @objc func userLocationUpdated(_ notification: NSNotification) {
        guard let location = notification.userInfo?["location"] else {
            print("no location recieved on location notification")
            return
        }
        print("location: \(location)")
    }
    
    @objc func userVisitUpdated(_ notification: NSNotification)  {
        guard let visit = notification.userInfo?["visit"] as? Visit else {
            print("no visit recieved on visit notification")
            return
        }
        print("retrieved visit: \(visit)")
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    
}

extension HomeVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

