//
//  Drive.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/4/24.
//

import Foundation
import CoreLocation

class Drive: Codable, Equatable {

    private let initLat: Double
    private let initLong: Double
    private let finalLat: Double
    private let finalLong: Double
    private let myFinalDate: Date
    private let myInitialDate: Date
    var initialPlace: String?
    var finalPlace: String?
    
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
    
    init(initialCoordinates: CLLocationCoordinate2D, finalCoordinates: CLLocationCoordinate2D, initialDate: Date, finalDate: Date, initPlace: String? = nil, finPlace: String? = nil) {
        initLat = initialCoordinates.latitude
        initLong = initialCoordinates.longitude
        myInitialDate = initialDate
        finalLat = finalCoordinates.latitude
        finalLong = finalCoordinates.longitude
        myFinalDate = finalDate
        
        initialPlace = initPlace
        finalPlace = finPlace

    }
    
    init(from drive: Drive) {
        initLat = drive.initLat
        initLong = drive.initLong
        myInitialDate = drive.myInitialDate
        finalLat = drive.finalLat
        finalLong = drive.finalLong
        myFinalDate = drive.myFinalDate
        
        initialPlace = drive.initialPlace
        finalPlace = drive.finalPlace
        
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
        try container.encode(initialPlace, forKey: .initialPlace)
        try container.encode(finalPlace, forKey: .finalPlace)
    }
    
    static func == (lhs: Drive, rhs: Drive) -> Bool {
        return lhs.initialDate.compare(rhs.initialDate) == .orderedSame && lhs.finalDate.compare(rhs.finalDate) == .orderedSame && lhs.initLat == rhs.initLat && lhs.initLong == rhs.initLong
    }
    
    private enum CodingKeys: String, CodingKey {
        case initLat
        case initLong
        case finalLat
        case finalLong
        case myFinalDate
        case myInitialDate
        case initialPlace
        case finalPlace
    }
    
}
