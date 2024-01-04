//
//  Visit.swift
//  Property Management
//
//  Created by Saahil Sukhija on 12/30/23.
//

import CoreLocation

final class Visit: CLVisit, Codable {
    private let myLat: Double
    private let myLong: Double
    private let myArrivalDate: Date
    private let myDepartureDate: Date
    
    override var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: myLat, longitude: myLong)
    }
    
    override var arrivalDate: Date {
        return myArrivalDate
    }
    
    override var departureDate: Date {
        return myDepartureDate
    }
    
    init(coordinates: CLLocationCoordinate2D, arrivalDate: Date, departureDate: Date) {
        myLat = coordinates.latitude
        myLong = coordinates.longitude
        myArrivalDate = arrivalDate
        myDepartureDate = departureDate
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(myLat, forKey: .myLat)
        try container.encode(myLong, forKey: .myLong)
        try container.encode(myArrivalDate, forKey: .myArrivalDate)
        try container.encode(myDepartureDate, forKey: .myDepartureDate)
    }
    
    private enum CodingKeys: String, CodingKey {
      case myLat
      case myLong
      case myArrivalDate
      case myDepartureDate
    }
    
}

