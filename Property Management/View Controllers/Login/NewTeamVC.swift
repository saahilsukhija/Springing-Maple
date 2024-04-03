//
//  NewTeamVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/13/24.
//

import UIKit

class NewTeamVC: UIViewController {

    static let identifier = "NewTeamScreen"
    static let identifierWithoutNavController = "NewTeamScreen_NONAV"
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var teamField: UITextField!
    @IBOutlet weak var createTeamButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        goButton.tintColor = .systemGray
        teamField.addTarget(self, action: #selector(textFieldEdited), for: .editingChanged)
        
        createTeamButton.layer.cornerRadius = 10
        createTeamButton.layer.borderWidth = 1
        createTeamButton.layer.borderColor = UIColor.darkAccent.cgColor
        createTeamButton.tintColor = .darkAccent
        self.hideKeyboardWhenTappedAround()
    }
    

    @IBAction func createGroupButtonClicked(_ sender: Any) {
        
        let vc = storyboard?.instantiateViewController(withIdentifier: CreateTeamVC.identifier) as! CreateTeamVC
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func goButtonClicked(_ sender: Any) {
        
        guard User.shared.isLoggedIn() else {
            print("user not logged in somehow")
            return
        }
        guard teamField.text?.count ?? 0 == Constants.NUMBER_DIGITS_IN_TEAM_ID else {
            goButton.tintColor = .systemGray
            return
        }
        let team = teamField.text!
        let loadingScreen = createLoadingScreen(frame: view.frame)
        view.addSubview(loadingScreen)
        Task {
            do {
                if try await FirestoreDatabase.shared.teamDoesExist(team) == true {
                    User.shared.team = try await FirestoreDatabase.shared.getTeam(from: team)
                    try UserDefaults.standard.set(object: User.shared.team, forKey: "user_team")
                    try await FirestoreDatabase.shared.uploadUserDetails()
                    DispatchQueue.main.async {
                        loadingScreen.removeFromSuperview()
                        self.showSuccessToast(message: "Successfully joined team!")
                        self.dismiss(animated: true)
                        self.navigationController?.popToRootViewController(animated: true)
                        self.navigationController?.dismiss(animated: true)
                        self.dismiss(animated: true)
                    }
                } else {
                    DispatchQueue.main.async {
                        loadingScreen.removeFromSuperview()
                        self.showFailureToast(message: "Team does not exist")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    loadingScreen.removeFromSuperview()
                    self.showFailureToast(message: "Team does not exist")
                }
            }
        }
    }

}

extension NewTeamVC {

    @objc func textFieldEdited() {
        
        if teamField.text?.count ?? 0 >= Constants.NUMBER_DIGITS_IN_TEAM_ID {
            
            goButton.tintColor = .darkAccent
            teamField.resignFirstResponder()
            teamField.text = teamField.text?.substring(to: Constants.NUMBER_DIGITS_IN_TEAM_ID)
            return
        }
        
        goButton.tintColor = .systemGray
    }
}
