//
//  RecentLocation.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/11/24.
//

import CoreLocation

class RecentLocation {
    
    var location: CLLocation!
    var date: Date!
    
    init(location: CLLocation!, date: Date!) {
        self.location = location
        self.date = date
    }
}


