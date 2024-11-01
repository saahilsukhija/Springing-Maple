//
//  RecentLocationQueue.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/11/24.
//

import CoreLocation

class PendingDriveQueue: Codable {
    
    private(set) var drives: [Drive]!
    
    //Singleton Instance
    static let shared: PendingDriveQueue = {
        let instance = PendingDriveQueue()
        return instance
    }()
    
    init() {
        if UserDefaults.standard.isKeyPresent(key: "pendingDriveQueue") {
            do {
                let queue = try UserDefaults.standard.get(objectType: PendingDriveQueue.self, forKey: "pendingDriveQueue")
                drives = queue?.drives
                print("restored PendingDriveQueue from defaults")
            } catch {
                drives = []
            }
        } else {
            drives = []
        }
    }
    
    func putDrive(_ drive: Drive) {
        drives.append(drive)
    }
    
    func getDrive(finalTime: Date, finalPlace: String, remove: Bool = false) -> Drive? {
        for (i, d) in drives.enumerated() {
            if d.finalDate.toHourMinuteTime() == finalTime.toHourMinuteTime() && d.finalPlace == finalPlace  {
                if remove {
                    self.drives.remove(at: i)
                    AppDelegate.saveVariables()
                }
                return d
            }
        }
        return nil
    }
    
    
}
