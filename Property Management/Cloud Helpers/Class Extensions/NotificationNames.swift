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
    
    /// Notification when user's visit was detected
    static var newVisitDetected: Notification.Name {
        return .init(rawValue: #function)
    }
    
    
    
    
}
