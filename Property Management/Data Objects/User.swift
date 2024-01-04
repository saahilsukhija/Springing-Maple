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
    
    init() {
        team = Team("10000")
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
    
}
