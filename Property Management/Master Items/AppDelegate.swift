//
//  AppDelegate.swift
//  Property Management
//
//  Created by Saahil Sukhija on 10/31/23.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import SwiftyDropbox

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return true }
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if error != nil || user == nil {
                print("no previous sign in")
            } else {
                print("user logged in: \(User.shared.getUserEmail())")
            }
        }
        
        DropboxClientsManager.setupWithAppKey(Constants.API_KEYS.dropbox_app_key)
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    //MARK: Firebase
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
//        let oauthCompletion: DropboxOAuthCompletion = {
//            if let authResult = $0 {
//                switch authResult {
//                case .success:
//                    print("Success! User is logged into DropboxClientsManager.")
//                case .cancel:
//                    print("Authorization flow was manually canceled by user!")
//                case .error(_, let description):
//                    print("Error: \(String(describing: description))")
//                }
//            }
//        }
//        let canHandleUrl = DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false, completion: oauthCompletion)
        
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("will terminate")
        NotificationManager.shared.sendNotificationNow(title: "Springing Maple has been terminated!", subtitle: "Things may not work as expected. Please reopen the app.")
        AppDelegate.saveVariables()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        //NotificationManager.shared.sendNotificationNow(title: "App going into the background", subtitle: "for test purposes")
        LocationManager.shared.restartMotionManager()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        LocationManager.shared.restartMotionManager()
        print("Did enter foreground")
        NotificationCenter.default.post(name: .applicationEnteredForeground, object: nil)
        //NotificationManager.shared.sendNotificationNow(title: "Restarting motion manager", subtitle: "for test purposes")
    }
    func applicationDidBecomeActive(_ application: UIApplication) {

        // app becomes active
        // this method is called on first launch when app was closed / killed and every time app is reopened or change status from background to foreground (ex. mobile call)
        NotificationCenter.default.post(name: .applicationEnteredForeground, object: nil)
    }
    
    static func saveVariables() {
        //print("saving variables...")
        do {
            try UserDefaults.standard.set(object: Stopwatch.shared, forKey: "stopwatch")
            try UserDefaults.standard.set(object: RecentLocationQueue.shared, forKey: "recentLocationQueue")
            try UserDefaults.standard.set(object: SavedLocations.shared, forKey: "savedLocations")
            
            if let lastDrive = LocationManager.shared.lastDriveCreated {
                try UserDefaults.standard.set(object: lastDrive, forKey: "lastDriveCreated")
            }
            if let team = User.shared.team {
                try UserDefaults.standard.set(object: team, forKey: "user_team")
            }
            
            if let settings = User.shared.settings {
                try UserDefaults.standard.set(object: settings, forKey: "user_settings")
            }
            if let dropbox = User.shared.dropbox {
                try UserDefaults.standard.set(object: dropbox, forKey: "user_dropbox")
            }
            UserDefaults.standard.set(LocationManager.shared.isDriving, forKey: "isDriving")
            
            if let loc = LocationManager.shared.startDriveLocation {
                UserDefaults.standard.set(loc.coordinate.latitude, forKey: "startDriveLocation_lat")
                UserDefaults.standard.set(loc.coordinate.longitude, forKey: "startDriveLocation_lon")
            } else {
                UserDefaults.standard.removeObject(forKey: "startDriveLocation_lat")
                UserDefaults.standard.removeObject(forKey: "startDriveLocation_lon")
            }
            
            if let time = LocationManager.shared.startDriveTime {
                try UserDefaults.standard.set(object: time, forKey: "startDriveTime")
            } else {
                UserDefaults.standard.removeObject(forKey: "startDriveTime")
            }
        } catch {
            print("error while storing stopwatch / recentLocationQueue in UserDefaults")
        }
    }
}

