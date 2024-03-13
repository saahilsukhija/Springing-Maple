//
//  Drive.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/4/24.
//

import Foundation
import CoreLocation
import MapKit

class Drive: Activity {
    
    public var milesDriven: Double? = 0
    
    init(from activity: Activity, milesDriven: Double = 0) {
        super.init(from: activity)
        
        self.milesDriven = milesDriven
        
        if milesDriven == 0 {
            Drive.getMilesBetween(self.initialCoordinate, and: self.finalCoordinate) { miles in
                self.milesDriven = miles
            }
        }
    }
    
    init(initialCoordinates: CLLocationCoordinate2D, finalCoordinates: CLLocationCoordinate2D, initialDate: Date, finalDate: Date, initPlace: String? = nil, finPlace: String? = nil, milesDriven: Double = 0) {
        super.init(initialCoordinates: initialCoordinates, finalCoordinates: finalCoordinates, initialDate: initialDate, finalDate: finalDate, initPlace: initPlace, finPlace: finPlace)
        
        self.milesDriven = milesDriven
        
        if milesDriven == 0 {
            Drive.getMilesBetween(self.initialCoordinate, and: self.finalCoordinate) { miles in
                self.milesDriven = miles
            }
        }
    }
    
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        milesDriven = try values.decode(Double.self, forKey: .milesDriven)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(milesDriven, forKey: .milesDriven)
    }
    
    static func getMilesBetween(_ sourceP: CLLocationCoordinate2D, and destP: CLLocationCoordinate2D, completion: @escaping((Double) -> Void)) {
        let source = MKPlacemark(coordinate: sourceP)
        let destination = MKPlacemark(coordinate: destP)
                
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)

        // Specify the transportation type
        request.transportType = MKDirectionsTransportType.automobile;

        // If you want only the shortest route, set this to a false
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

         // Now we have the routes, we can calculate the distance using
         directions.calculate { (response, error) in
            if let response = response, let route = response.routes.first {
                completion(route.distance/1609.34)
            }
             else {
                 print(error!)
             }
         }
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case initialLocationGeocoded
        case finalLocationGeocoded
        case milesDriven
    }
    
}
