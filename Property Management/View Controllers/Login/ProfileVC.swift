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
    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var logOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nameLabel.text = User.shared.getUserName()
        emailLabel.text = User.shared.getUserEmail()
        teamLabel.text = User.shared.team?.id
        
        logOutButton.layer.cornerRadius = 10
        logOutButton.layer.borderWidth = 2
        logOutButton.layer.borderColor = UIColor.systemGray.cgColor
        
        
    }
    
    @IBAction func logOutButtonClicked(_ sender: Any) {
        GIDSignIn.sharedInstance.signOut()
        navigationController?.popViewController(animated: true)
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
