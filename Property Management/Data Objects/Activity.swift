//
//  Activity.swift
//  Property Management
//
//  Created by Saahil Sukhija on 2/25/24.
//

import Foundation
import CoreLocation

class Activity: Codable, Equatable {
    
    private let initLat: Double
    private let initLong: Double
    private let finalLat: Double
    private let finalLong: Double
    private let myFinalDate: Date
    private let myInitialDate: Date
    private var myInitialPlace: String?
    private var myFinalPlace: String?
    
    var initialCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: initLat, longitude: initLong)
    }
    
    var finalCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: finalLat, longitude: finalLong)
    }
    
    var finalDate: Date {
        return myFinalDate
    }
    
    var initialDate: Date {
        return myInitialDate
    }
    
    var initialPlace: String? {
        return myInitialPlace
    }
    
    var finalPlace: String? {
        return myFinalPlace
    }
    
    init(initialCoordinates: CLLocationCoordinate2D, finalCoordinates: CLLocationCoordinate2D, initialDate: Date, finalDate: Date, initPlace: String? = nil, finPlace: String? = nil) {
        initLat = initialCoordinates.latitude
        initLong = initialCoordinates.longitude
        myInitialDate = initialDate
        finalLat = finalCoordinates.latitude
        finalLong = finalCoordinates.longitude
        myFinalDate = finalDate
        
        myInitialPlace = initPlace
        myFinalPlace = finPlace
        
        loadPlaces()

    }
    
    init(from activity: Activity) {
        initLat = activity.initLat
        initLong = activity.initLong
        myInitialDate = activity.myInitialDate
        finalLat = activity.finalLat
        finalLong = activity.finalLong
        myFinalDate = activity.myFinalDate
        
        myInitialPlace = activity.initialPlace
        myFinalPlace = activity.finalPlace
        
        loadPlaces()
    }
    
    func loadPlaces() {
        if self.initialPlace == nil || self.initialPlace == "" {
            LocationManager().getReverseGeoCodedLocation(location: CLLocation(latitude: self.initialCoordinate.latitude, longitude: self.initialCoordinate.longitude)) { location, placemark, error in
                print("finished reverse geocoding")
                var text = ""
                if let error = error {
                    text = "(error)"
                    print(error.localizedDescription)
                } else {
                    text = placemark?.name ?? "(error 2)"
                }
                
                DispatchQueue.main.async {
                    self.setInitPlace(text)
                }
            }
        }
        
        if self.finalPlace == nil || self.finalPlace == "" {
            LocationManager().getReverseGeoCodedLocation(location: CLLocation(latitude: self.finalCoordinate.latitude, longitude: self.finalCoordinate.longitude)) { location, placemark, error in
                var text = ""
                if let error = error {
                    text = "(error)"
                    print(error.localizedDescription)
                } else {
                    text = placemark?.name ?? "(error 2)"
                }
                
                DispatchQueue.main.async {
                    self.setFinalPlace(text)
                }
            }
        }
    }
    
    func setInitPlace(_ place: String) {
        myInitialPlace = place
    }
    
    func setFinalPlace(_ place: String) {
        myFinalPlace = place
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(initLat, forKey: .initLat)
        try container.encode(initLong, forKey: .initLong)
        try container.encode(myInitialDate, forKey: .myInitialDate)
        try container.encode(finalLat, forKey: .finalLat)
        try container.encode(finalLong, forKey: .finalLong)
        try container.encode(myFinalDate, forKey: .myFinalDate)
        try container.encode(myInitialPlace, forKey: .myInitialPlace)
        try container.encode(myFinalPlace, forKey: .myFinalPlace)
    }
    
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.initialDate.compare(rhs.initialDate) == .orderedSame && lhs.finalDate.compare(rhs.finalDate) == .orderedSame && lhs.initLat == rhs.initLat && lhs.initLong == rhs.initLong
    }
    
    private enum CodingKeys: String, CodingKey {
        case initLat
        case initLong
        case finalLat
        case finalLong
        
        case myInitialDate
        case myFinalDate
        
        case myInitialPlace
        case myFinalPlace
    }
    
}
