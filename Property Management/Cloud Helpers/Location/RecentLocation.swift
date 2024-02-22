//
//  RecentLocation.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/11/24.
//

import CoreLocation

class RecentLocation: Codable {
    
    private var lat: Double!
    private var long: Double!
    
    var location: CLLocation {
        return CLLocation(latitude: lat, longitude: long)
    }
    
    var date: Date!
    
    init(location: CLLocation!, date: Date!) {
        self.lat = location.coordinate.latitude
        self.long = location.coordinate.longitude
        self.date = date
    }
}


