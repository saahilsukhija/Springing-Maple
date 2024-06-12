//
//  DriveSettingsVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/11/24.
//

import UIKit

class DriveSettingsVC: UIViewController {

    static let identifier = "DriveSettingsScreen"
    
    @IBOutlet weak var autoUploadDrivesEnabledSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if User.shared.settings.autoUploadDrives {
            autoUploadDrivesEnabledSwitch.isOn = true
        } else {
            autoUploadDrivesEnabledSwitch.isOn = false
        }

    }
    
    @IBAction func driveNotificationSwitchButtonClicked() {
        autoUploadDrivesEnabledSwitch.isOn = !autoUploadDrivesEnabledSwitch.isOn
        
        if autoUploadDrivesEnabledSwitch.isOn {
            autoUploadDrivesEnabledSwitch.isOn = false
            User.shared.settings.enableAutoUploadDrives(false)
            updateAllViews()
            return
        }
        else {
            autoUploadDrivesEnabledSwitch.isOn = true
            User.shared.settings.enableAutoUploadDrives(true)
            updateAllViews()
            return
        }
        
    }

}

extension DriveSettingsVC {
    
    func updateAllViews() {
        
        updateSwitches()
        
    }
    
    func updateSwitches() {
        
        if let settings = User.shared.settings {
            
            autoUploadDrivesEnabledSwitch.isOn = settings.autoUploadDrives
            
        }
        
    }
    
}
