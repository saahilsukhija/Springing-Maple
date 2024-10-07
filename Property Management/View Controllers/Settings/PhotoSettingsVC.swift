//
//  PhotoSettingsVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 10/2/24.
//

import UIKit

class PhotoSettingsVC: UIViewController {

    static let identifier = "PhotoSettingsScreen"
    
    @IBOutlet weak var autoSavePhotosEnabledSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if User.shared.settings.autoSavePhotos {
            autoSavePhotosEnabledSwitch.isOn = true
        } else {
            autoSavePhotosEnabledSwitch.isOn = false
        }

    }
    
    @IBAction func driveNotificationSwitchButtonClicked() {
        autoSavePhotosEnabledSwitch.isOn = !autoSavePhotosEnabledSwitch.isOn
        
        if autoSavePhotosEnabledSwitch.isOn {
            autoSavePhotosEnabledSwitch.isOn = false
            User.shared.settings.enableAutoSavePhotos(false)
            updateAllViews()
            return
        }
        else {
            autoSavePhotosEnabledSwitch.isOn = true
            User.shared.settings.enableAutoSavePhotos(true)
            updateAllViews()
            return
        }
        
    }

}

extension PhotoSettingsVC {
    
    func updateAllViews() {
        
        updateSwitches()
        
    }
    
    func updateSwitches() {
        
        if let settings = User.shared.settings {
            
            autoSavePhotosEnabledSwitch.isOn = settings.autoSavePhotos
            
        }
        
    }
    
}
