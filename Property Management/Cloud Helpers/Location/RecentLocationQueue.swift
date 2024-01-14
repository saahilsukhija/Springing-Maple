//
//  RecentLocationQueue.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/11/24.
//

import CoreLocation

class RecentLocationQueue {
    
    private(set) var locations: [RecentLocation]!
    
    //Singleton Instance
    static let shared: RecentLocationQueue = {
        let instance = RecentLocationQueue()
        return instance
    }()
    
    init() {
        locations = []
    }
    
    func putLocation(_ recentLocation: RecentLocation) {
        if locations.count > 10 {
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
