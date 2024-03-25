//
//  CreateTeamVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/14/24.
//

import UIKit

class CreateTeamVC: UIViewController {
    
    static let identifier = "CreateTeamScreen"
    
    @IBOutlet weak var teamNameField: UITextField!
    
    var nextButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton = UIBarButtonItem(title: "Next", image: nil, target: self, action: #selector(nextButtonClicked))
        nextButton.tintColor = .systemGray
        self.navigationItem.rightBarButtonItem = nextButton
        
        teamNameField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        
        self.hideKeyboardWhenTappedAround()
        
        teamNameField.becomeFirstResponder()
        teamNameField.delegate = self
    }
    
    
    @objc func nextButtonClicked() {
        
        guard nextButton.tintColor != UIColor.systemGray else {
            return
        }
        
        guard let name = teamNameField.text else {
            return
        }
        
        let vc = storyboard?.instantiateViewController(withIdentifier: CreateSpreadsheetVC.identifier) as! CreateSpreadsheetVC
        vc.teamName = name
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    
    
    
}

extension CreateTeamVC: UITextFieldDelegate {
    
    @objc func editingChanged() {
        
        if teamNameField.text?.count ?? 0 > 0 {
            nextButton.tintColor = .accentColor
        } else {
            nextButton.tintColor = .systemGray
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nextButtonClicked()
        return true
    }

}
