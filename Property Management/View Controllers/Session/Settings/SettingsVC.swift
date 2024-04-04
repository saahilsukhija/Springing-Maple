//
//  SettingsVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/28/24.
//

import UIKit

class SettingsVC: UIViewController {

    static let identifier = "SettingsScreen"
    
    @IBOutlet weak var tableView: UITableView!
    
    let settings = ["Notifications", "Profile"]
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
    }
    
    

}

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingCell.identifier) as! SettingCell
        if indexPath.row == 0 {
            cell.setup(title: settings[indexPath.row], status: User.shared.settings.notificationsEnabled ? "Enabled" : "Disabled")
        }
        else if indexPath.row == 1{
            cell.setup(title: settings[indexPath.row], status: User.shared.getUserName())
        }
        //Separator Full Line
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = .zero
        cell.layoutMargins = .zero
        
        return cell
            
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            let vc = storyboard?.instantiateViewController(withIdentifier: NotificationsVC.identifier) as! NotificationsVC
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.row == 1{
            let vc = UIStoryboard(name: "LoginScreens", bundle: nil).instantiateViewController(withIdentifier: ProfileVC.identifier) as! ProfileVC
            self.navigationController?.pushViewController(vc, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    
}
