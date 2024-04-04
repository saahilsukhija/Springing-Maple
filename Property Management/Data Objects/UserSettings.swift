//
//  UserSettings.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/29/24.
//

import Foundation


class UserSettings: Codable {
    
    private(set) var notificationsEnabled: Bool! = false
    
    var clockInTime: DateComponents?
    var clockOutTime: DateComponents?
    
    init() {
        do {
            let s = try UserDefaults.standard.get(objectType: UserSettings.self, forKey: "user_settings")
            self.clockInTime = s?.clockInTime
            self.clockOutTime = s?.clockOutTime
            if let notificationsEnabled = s?.notificationsEnabled {
                self.notificationsEnabled = notificationsEnabled
            } else {
                self.notificationsEnabled = false
            }
        } catch {
            self.notificationsEnabled = false
            print("no user settings available.")
        }
    }
    
    func enableNotification(_ shouldEnable: Bool = true) {
        self.notificationsEnabled = shouldEnable
        if !shouldEnable {
            removeNotificationTimes(type: .clockIn)
            removeNotificationTimes(type: .clockOut)
        }
        do {
            try UserDefaults.standard.set(object: self, forKey: "user_settings")
        } catch {}
    }
    
    func setNotificationTimes(type: ClockInNotificationSettings, hour: Int, min: Int) {
        
        if type == .clockIn {
            clockInTime = DateComponents()
            clockInTime?.hour = hour
            clockInTime?.minute = min
            
            NotificationManager.shared.scheduleClockNotification(type: .clockIn)
        }
        else if type == .clockOut {
            clockOutTime = DateComponents()
            clockOutTime?.hour = hour
            clockOutTime?.minute = min
            
            NotificationManager.shared.scheduleClockNotification(type: .clockOut)
        }
        
        do {
            try UserDefaults.standard.set(object: self, forKey: "user_settings")
        } catch {}
    }
    
    func removeNotificationTimes(type: ClockInNotificationSettings) {
        if type == .clockIn {
            clockInTime = nil
        }
        if type == .clockOut {
            clockOutTime = nil
        }
        
        do {
            try UserDefaults.standard.set(object: self, forKey: "user_settings")
        } catch {}
        
        
    }
    enum ClockInNotificationSettings: String {
        
        case clockIn = "clock in"
        case clockOut = "clock out"
        
    }
    
    
    
}
