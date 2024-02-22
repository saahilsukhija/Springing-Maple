//
//  RecentLocationQueue.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/11/24.
//

import CoreLocation

class RecentLocationQueue: Codable {
    
    private(set) var locations: [RecentLocation]!
    
    //Singleton Instance
    static let shared: RecentLocationQueue = {
        let instance = RecentLocationQueue()
        return instance
    }()
    
    init() {
        if UserDefaults.standard.isKeyPresent(key: "recentLocationQueue") {
            do {
                let queue = try UserDefaults.standard.get(objectType: RecentLocationQueue.self, forKey: "recentLocationQueue")
                locations = queue?.locations
                print("restored RecentLocationQueue from defaults")
            } catch {
                locations = []
            }
        } else {
            locations = []
        }
    }
    
    func putLocation(_ recentLocation: RecentLocation) {
        if locations.count > 150 {
            locations.removeFirst()
            locations.append(recentLocation)
            return
        }
        locations.append(recentLocation)
    }
    
    func getRecentLocation() -> RecentLocation? {
        return locations.last
    }
    
    func getOldestLocation() -> RecentLocation? {
        return locations.first
    }
    
    //Under minute away, and pick the largest one
    func getLocation(within minute: Int) -> RecentLocation? {
        let second = minute*60
        let current = Date()
        var closestLocation: RecentLocation?
        var closestTime: Int = .min
        for location in locations {
            let since = current.secondsSince(location.date)
            if since <= second && since > closestTime {
                closestLocation = location
                closestTime = since
            }
        }
        return closestLocation
    }
    
    
}
