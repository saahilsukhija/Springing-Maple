//
//  SavedLocation.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/2/24.
//

import Foundation
import CoreLocation

class SavedLocation {
    
    var actualLocation: String!
    var assignedName: String!
    var coordinate: CLLocation!
    
    init(actualLocation: String!, assignedName: String!) {
        self.actualLocation = actualLocation
        self.assignedName = assignedName
        
        LocationManager.reverseGeocode(address: actualLocation) { placemark, error in
            if let error = error {
                print("Error saving SavedLocation: \(error.localizedDescription)")
                return
            }
            self.coordinate = placemark?[0].location
        }
    }
    
    func inRange(_ location: CLLocation) -> Bool {
        let range = Constants.SAVED_LOCATION_RANGE
        
        return Int(location.distance(from: coordinate)) < range
    }
}
