//
//  NotificationsVC.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/29/24.
//

import UIKit

class NotificationsVC: UIViewController {
    
    static let identifier = "NotificationsScreen"
    @IBOutlet weak var enabledSwitch: UISwitch!
    @IBOutlet weak var clockInOutTimesView: UIView!
    
    @IBOutlet weak var clockInTimePicker: UIDatePicker!
    @IBOutlet weak var clockOutTimePicker: UIDatePicker!
    
    @IBOutlet weak var removeClockInButton: UIButton!
    @IBOutlet weak var removeClockOutButton: UIButton!
    
    @IBOutlet weak var clockInCover: UIView!
    @IBOutlet weak var clockOutCover: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        if User.shared.settings.notificationsEnabled {
            enabledSwitch.isOn = true
            
        } else {
            enabledSwitch.isOn = false
        }
        
        clockInTimePicker.tag = 0
        clockOutTimePicker.tag = 1
        
        clockInTimePicker.addTarget(self, action: #selector(timePickerClicked(_:)), for: .valueChanged)
        clockOutTimePicker.addTarget(self, action: #selector(timePickerClicked(_:)), for: .valueChanged)
        
        updateAllViews()
        
        
    }
    
    @IBAction func clockInRemoveButtonClicked(_ sender: Any) {
        clockInTimePicker.date = .distantPast
        User.shared.settings.removeNotificationTimes(type: .clockIn)
        updateCoversAndButtons()
    }
    
    @IBAction func clockOutRemoveButtonClicked(_ sender: Any) {
        clockOutTimePicker.date = .distantPast
        User.shared.settings.removeNotificationTimes(type: .clockOut)
        updateCoversAndButtons()
    }
    
    @objc func timePickerClicked(_ picker: UIDatePicker) {
        let date = picker.date
        let group = date.get(.hour, .minute)

        guard let hour = group.hour, let min = group.minute else {
            self.showFailureToast(message: "Error saving date")
            return
        }
        
        if picker.tag == 0 {
            User.shared.settings.setNotificationTimes(type: .clockIn, hour: hour, min: min)
        } else {
            User.shared.settings.setNotificationTimes(type: .clockOut, hour: hour, min: min)
        }
        updateAllViews()
        
    }
    @IBAction func switchButtonClicked() {
        
        enabledSwitch.isOn = !enabledSwitch.isOn
        if enabledSwitch.isOn {
            enabledSwitch.isOn = false
            User.shared.enableNotifications(false)
            updateAllViews()
            return
        }
        
        NotificationManager.shared.requestAuthorization { enabled in
            
            DispatchQueue.main.async {
                if enabled {
                    self.enabledSwitch.isOn = true
                    User.shared.enableNotifications()
                    self.updateAllViews()
                    return
                } else {
                    User.shared.enableNotifications(false)
                    Alert.showDefaultAlert(title: "Notifications not enabled!", message: "Go to settings and enable notifications for this app.", self); #warning("Should have option for settings app")
                }
            }
        }
        
    }
    
    
    
    
    
}

//MARK: UI Stuff
extension NotificationsVC {
    
    func updateAllViews() {
        
        updateDatePickers()
        updateCoversAndButtons()
        
        
    }
    
    func updateDatePickers() {
        if let settings = User.shared.settings {
            
            if let clockInTime = settings.clockInTime {
                let calendar = Calendar.current
                let date = calendar.date(from: clockInTime)!
                clockInTimePicker.date = date
            } else {
                clockInTimePicker.date = .distantPast
            }
            
            if let clockOutTime = settings.clockOutTime {
                let calendar = Calendar.current
                let date = calendar.date(from: clockOutTime)!
                clockOutTimePicker.date = date
            } else {
                clockOutTimePicker.date = .distantPast
            }
        }
    }
    
    func updateCoversAndButtons() {
        
        if enabledSwitch.isOn {
            clockInOutTimesView.isHidden = false
        } else {
            clockInOutTimesView.isHidden = true
        }
        if clockInTimePicker.date == .distantPast {
            clockInCover.isHidden = false
            removeClockInButton.isHidden = true
        } else {
            clockInCover.isHidden = true
            removeClockInButton.isHidden = false
        }
        
        if clockOutTimePicker.date == .distantPast {
            clockOutCover.isHidden = false
            removeClockOutButton.isHidden = true
        } else {
            clockOutCover.isHidden = true
            removeClockOutButton.isHidden = false
        }
    }
}
