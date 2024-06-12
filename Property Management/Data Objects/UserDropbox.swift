//
//  UserDropbox.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/12/24.
//

import Foundation
import SwiftyDropbox
class UserDropbox: Codable {
    
    var isConnected: Bool {
        return DropboxClientsManager.authorizedClient != nil
    }
    
    var selectedFolder: DropboxFolder?
    
    init() {
        do {
            let s = try UserDefaults.standard.get(objectType: UserDropbox.self, forKey: "user_dropbox")
            self.selectedFolder = s?.selectedFolder
        } catch {
            
        }
    }
    
    func setSelectedFolder(_ folder: DropboxFolder) {
        self.selectedFolder = folder
    }
    
    
    
}
