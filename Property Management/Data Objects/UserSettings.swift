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
    
    private(set) var driveNotificationsEnabled: Bool! = true
    private(set) var workNotificationsEnabled: Bool! = true
    
    private(set) var autoUploadDrives: Bool! = false
    private(set) var autoSavePhotos: Bool! = true
    
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
            
            if let driveNotificationsEnabled = s?.driveNotificationsEnabled {
                self.driveNotificationsEnabled = driveNotificationsEnabled
            } else {
                self.driveNotificationsEnabled = true
            }
            
            if let workNotificationsEnabled = s?.workNotificationsEnabled {
                self.workNotificationsEnabled = workNotificationsEnabled
            } else {
                self.workNotificationsEnabled = true
            }
            
            if let autoUploadDrives = s?.autoUploadDrives {
                self.autoUploadDrives = autoUploadDrives
            }
            else {
                self.autoUploadDrives = false
            }
            
            if let savePhotos = s?.autoSavePhotos {
                self.autoSavePhotos = savePhotos
            } else {
                self.autoSavePhotos = true
            }
        } catch {
            self.notificationsEnabled = false
            self.driveNotificationsEnabled = false
            self.workNotificationsEnabled = false
            self.autoUploadDrives = false
            self.autoSavePhotos = true
            print("no user settings available.")
        }
    }
    
    func enableNotification(_ shouldEnable: Bool = true) {
        self.notificationsEnabled = shouldEnable
        if !shouldEnable {
            removeNotificationTimes(type: .clockIn)
            removeNotificationTimes(type: .clockOut)
            driveNotificationsEnabled = false
            workNotificationsEnabled = false
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
        NotificationManager.shared.removeClockInOutNotifications(type: type)
        
        do {
            try UserDefaults.standard.set(object: self, forKey: "user_settings")
        } catch {}
        
    }
    
    func enableDriveNotifications(_ enabled: Bool = true) {
        self.driveNotificationsEnabled = enabled
        
        do {
            try UserDefaults.standard.set(object: self, forKey: "user_settings")
        } catch {}
    }
    
    func enableWorkNotifications(_ enabled: Bool = true) {
        self.workNotificationsEnabled = enabled
        
        do {
            try UserDefaults.standard.set(object: self, forKey: "user_settings")
        } catch {}
    }
    
    func enableAutoUploadDrives(_ enabled: Bool = true) {
        self.autoUploadDrives = enabled
        
        do {
            try UserDefaults.standard.set(object: self, forKey: "user_settings")
        } catch {}
    }
    
    func enableAutoSavePhotos(_ enabled: Bool = true) {
        self.autoSavePhotos = enabled
        
        do {
            try UserDefaults.standard.set(object: self, forKey: "user_settings")
        } catch {}
    }
    
    enum ClockInNotificationSettings: String {
        
        case clockIn = "clock in"
        case clockOut = "clock out"
        
    }
    
    
    
}
