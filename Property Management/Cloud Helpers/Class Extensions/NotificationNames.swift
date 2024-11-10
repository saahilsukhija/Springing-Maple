//
//  NotificationNames.swift
//  CongressionalAppBiking
//
//  Created by Saahil Sukhija on 7/8/21.
//

import Foundation

extension Notification.Name {
    /// Notification when user successfully sign in using Google
    static var signInGoogleCompleted: Notification.Name {
        return .init(rawValue: #function)
    }
    
    /// Notification when user's location was updated
    static var locationUpdated: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var newDriveStarted: Notification.Name {
        return .init(rawValue: #function)
    }
    
    /// Notification when user's drive was detected
    static var newDriveFinished: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var workMarkedAsRegistered: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var workMarkedAsDeleted: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var cloudWorkDetected: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var driveMarkedAsRegistered: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var driveMarkedAsDeleted: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var mergedActivityMarkedAsRegistered: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var mergedActivityMarkedAsDeleted: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var cloudDriveDetected: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var shouldShowTicketNumberAlert: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var userClockedIn: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var userClockedOut: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var shouldUpdateTableView: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var locationAuthorized: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var dropboxAuthenticationComplete: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var dropboxImageUploadCompleted: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var dropboxImageUploadFailed: Notification.Name {
        return .init(rawValue: #function)
    }
    
    static var applicationEnteredForeground: Notification.Name {
        return .init(rawValue: #function)
    }
    
    
    
}
