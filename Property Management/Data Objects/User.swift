//
//  User.swift
//  Property Management
//
//  Created by Saahil Sukhija on 12/30/23.
//

import Foundation
import GoogleSignIn

class User {
    
    //Singleton Instance
    static let shared: User = {
        let instance = User()
        // setup code
        return instance
    }()
    
    var team: Team?
    var settings: UserSettings!
    
    init() {
        do {
            team = try UserDefaults.standard.get(objectType: Team.self, forKey: "user_team")
        } catch {
            print("no team available.")
        }
        settings = UserSettings()
    }
    
    func isLoggedIn() -> Bool {
        return GIDSignIn.sharedInstance.currentUser != nil
    }
    
    func getUserName() -> String {
        guard isLoggedIn() else { return "" }
        return GIDSignIn.sharedInstance.currentUser!.profile!.name
    }
    
    func getUserEmail() -> String {
        guard isLoggedIn() else { return "" }
        return GIDSignIn.sharedInstance.currentUser!.profile!.email
    }
    
    func teamHasSpreadsheet() -> Bool {
        return self.team?.hasSpreadsheet() ?? false
    }
    
    func enableNotifications(_ shouldEnable: Bool = true) {
        self.settings.enableNotification(shouldEnable)
    }
    
    func reset() {
        do {
            team = try UserDefaults.standard.get(objectType: Team.self, forKey: "user_team")
        } catch {
            team = nil
        }
        settings = UserSettings()
    }
    
}
