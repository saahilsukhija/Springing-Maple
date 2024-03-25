//
//  ProfileVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/3/24.
//

import UIKit
import GoogleSignIn

class ProfileVC: UIViewController {
    
    static let identifier = "ProfileScreen"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var teamNameLabel: UILabel!
    @IBOutlet weak var teamIDLabel: UILabel!
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var leaveTeamButton: UIButton!
    
    @IBOutlet weak var spreadsheetLabel: UILabel!
    
    @IBOutlet weak var spreadsheetView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        nameLabel.text = User.shared.getUserName()
        emailLabel.text = User.shared.getUserEmail()
        teamNameLabel.text = User.shared.team?.name
        teamIDLabel.text = "ID: \(User.shared.team?.id ?? "")"
        
        logOutButton.layer.cornerRadius = 10
        
        leaveTeamButton.layer.cornerRadius = 8
        
        if User.shared.team?.spreadsheetID == "" {
            spreadsheetLabel.text = "Create spreadsheet"
        } else {
            spreadsheetLabel.text = "View spreadsheet"
        }
        
        spreadsheetView.isUserInteractionEnabled = true
        spreadsheetView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(spreadsheetClicked(_:))))
        
    }
    
    @IBAction func logOutButtonClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure?", message: "You will be able to login later.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { action in
            GIDSignIn.sharedInstance.signOut()
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true)
    }
    
    @IBAction func leaveTeamButtonClicked(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure?", message: "You will be able to join a team later.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { action in
            Task {
                do {
                    try await FirestoreDatabase.shared.leaveCurrentTeam()
                    DispatchQueue.main.async {
                        self.showSuccessToast(message: "Successfully left team")
                        self.dismiss(animated: true)
                        self.navigationController?.popViewController(animated: true)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showFailureToast(message: "Error leaving team, please try again")
                    }
                }
            }
        }))
        self.present(alert, animated: true)
    }
    
    @IBAction func deleteAccountButtonClicked(_ sender: Any) {
        
    }
    
    @IBAction func membersButtonClicked(_ sender: Any) {
        
    }
    
    @objc func spreadsheetClicked(_ sender: Any) {
        guard let team = User.shared.team, let name = User.shared.team?.name else {
            self.showFailureToast(message: "Some error occured")
            return
        }
        
        if !(User.shared.team?.hasSpreadsheet() ?? false) {
            let vc = storyboard?.instantiateViewController(withIdentifier: CreateSpreadsheetVC.identifier) as! CreateSpreadsheetVC
            vc.teamName = name
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            guard let id = team.spreadsheetID else {
                self.showFailureToast(message: "Some error occured")
                return
            }
            let url = "https://docs.google.com/spreadsheets/d/\(id)"
            let ur = URL(string : "googlesheets://\(url)")!
            UIApplication.shared.open(URL(string: "\(ur)")!)
        }
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
