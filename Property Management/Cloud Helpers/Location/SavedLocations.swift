//
//  SavedLocation.swift
//  Property Management
//
//  Created by Saahil Sukhija on 6/2/24.
//

import Foundation
import CoreLocation

class SavedLocations: Codable {
    private(set) var locations: [Location]! = []
    
    //Singleton Instance
    static let shared: SavedLocations = {
        let instance = SavedLocations()
        return instance
    }()
    
    init() {
        if UserDefaults.standard.isKeyPresent(key: "savedLocations") {
            do {
                let queue = try UserDefaults.standard.get(objectType: SavedLocations.self, forKey: "savedLocations")
                locations = queue?.locations
                print("restored savedLocations from defaults")
            } catch {
                locations = []
            }
        } else {
            locations = []
        }
    }
    
    func addLocation(_ location: Location) {
        if !contains(actualName: location.actualName, assignedName: location.assignedName) {
            locations.append(location)
        }
    }
    
    func addLocation(actualName: String, assignedName: String) {
        if !contains(actualName: actualName, assignedName: assignedName) {
            locations.append(Location(actualName: actualName, assignedName: assignedName))
        }
    }
    
    func contains(actualName: String, assignedName: String) -> Bool {
        for location in locations {
            if location.actualName == actualName && location.assignedName == assignedName {
                return true
            }
        }
        return false
    }
    
    func assignedName(for actualName: String) -> String? {
        for location in locations {
            if location.actualName == actualName {
                return location.assignedName
            }
        }
        return nil
    }
    
    func assignedName(for loc: CLLocation) -> String? {
        for location in locations {
            if location.inRange(loc) {
                return location.assignedName
            }
        }
        return nil
    }
    
    func removeDeletedLocations(pairs: [[String]]) {
        locations.removeAll { location in //actual, given
            if !pairs.contains([location.actualName, location.assignedName]) {
               // print(pairs)
                //print("removing \(location.actualName!) - \(location.assignedName!) from list")
            }
            return !pairs.contains([location.actualName, location.assignedName])
        }
        AppDelegate.saveVariables()
    }
    
    class Location: Codable {
        
        var actualName: String!
        var assignedName: String!
        
        var coordinate: CLLocation? {
            if let lat = myLat, let lon = myLon {
                return CLLocation(latitude: myLat, longitude: myLon)
            } else {
                return nil
            }
        }
        
        private var myLat: Double!
        private var myLon: Double!
        
        init(actualName: String!, assignedName: String!) {
            self.actualName = actualName
            self.assignedName = assignedName
            
            LocationManager.reverseGeocode(address: actualName) { placemark, error in
                if let error = error {
                    print("Error saving SavedLocation: \(error.localizedDescription)")
                    return
                }
                self.myLat = placemark?[0].location?.coordinate.latitude
                self.myLon = placemark?[0].location?.coordinate.longitude
            }
        }
        
        func inRange(_ location: CLLocation) -> Bool {
            let range = Constants.SAVED_LOCATION_RANGE
            if let coordinate = coordinate {
                return Int(location.distance(from: coordinate)) < range
            } else {
                return false
            }
        }
    }

    
}

