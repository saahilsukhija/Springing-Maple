//
//  CreateSpreadsheetVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/23/24.
//

import UIKit

class CreateSpreadsheetVC: UIViewController {

    static let identifier = "CreateSpreadsheetScreen"
    
    @IBOutlet weak var spreadsheetNameField: UITextField!
    
    var createButton: UIBarButtonItem!
    var teamName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        createButton = UIBarButtonItem(title: "Create", image: nil, target: self, action: #selector(createButtonClicked))
        createButton.tintColor = .systemGray
        self.navigationItem.rightBarButtonItem = createButton
        
        spreadsheetNameField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        
        self.hideKeyboardWhenTappedAround()
        
        spreadsheetNameField.becomeFirstResponder()
        spreadsheetNameField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.spreadsheetNameField.text = teamName
        editingChanged()
    }
    
    @objc func createButtonClicked() {
        guard createButton.tintColor != UIColor.systemGray else {
            return
        }
        createWithSpreadsheet()
    }
    
    func createWithSpreadsheet() {
        
        guard createButton.tintColor != UIColor.systemGray else {
            return
        }
        
        guard let spreadsheetName = spreadsheetNameField.text else {
            return
        }
        
        spreadsheetNameField.resignFirstResponder()
        let loadingScreen = createLoadingScreen(frame: view.frame)
        view.addSubview(loadingScreen)
        
        Task {
            var team: Team!
            if let t = User.shared.team {
                team = t
            } else {
                team = await Team(name: teamName)
            }
            GoogleSheetAssistant.shared.createNewSpreadsheet(from: team, spreadsheetName: spreadsheetName) { id in
                Task {
                    team.spreadsheetID = id
                    User.shared.team = team
                    
                    do {
                        try await FirestoreDatabase.shared.uploadUserDetails()
                        try await FirestoreDatabase.shared.uploadTeamDetails(team)
                        try UserDefaults.standard.set(object: team, forKey: "user_team")
                    } catch {
                        print("error uploading details")
                    }
                    DispatchQueue.main.async {
                        loadingScreen.removeFromSuperview()
                        self.showSuccessToast(message: "Created team with id: \(team.id ?? "error")")
                        
                        self.navigationController?.popToRootViewController(animated: true)
                        self.navigationController?.dismiss(animated: true)
                    }
                }
            }
        }
        
    }
    
    @IBAction func noSpreadsheetButtonClicked(_ sender: Any) {
        
        let alert = UIAlertController(title: "Are you sure?", message: "You will be able to create a spreadsheet later.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { action in
            self.createWithoutSpreadsheet()
        }))
        self.present(alert, animated: true)

    }
    func createWithoutSpreadsheet() {
        
        guard createButton.tintColor != UIColor.systemGray else {
            return
        }
        
        
        self.resignFirstResponder()
        let loadingScreen = createLoadingScreen(frame: view.frame)
        view.addSubview(loadingScreen)
        
        Task {
            var team: Team!
            if let t = User.shared.team {
                team = t
            } else {
                team = await Team(name: teamName)
            }
            User.shared.team = team
            
            do {
                try await FirestoreDatabase.shared.uploadUserDetails()
                try await FirestoreDatabase.shared.uploadTeamDetails(team)
                try UserDefaults.standard.set(object: team, forKey: "user_team")
            } catch {
                print("error uploading details")
            }
            DispatchQueue.main.async {
                loadingScreen.removeFromSuperview()
                self.showSuccessToast(message: "Created team with id: \(team.id ?? "error")")
                
                self.navigationController?.popToRootViewController(animated: true)
                self.navigationController?.dismiss(animated: true)
                self.dismiss(animated: true)
            }
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

extension CreateSpreadsheetVC: UITextFieldDelegate {
    
    @objc func editingChanged() {
        
        if spreadsheetNameField.text?.count ?? 0 > 0 {
            createButton.tintColor = .accentColor
        } else {
            createButton.tintColor = .systemGray
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        createButtonClicked()
        return true
    }
}
