//
//  RegisteredDrive.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/5/24.
//

import UIKit
import CoreLocation

class RegisteredDrive: Drive {
    
    public var initialLocationGeocoded: String = ""
    public var finalLocationGeocoded: String = ""
    public var moneySpent: Double?
    public var ticketNumber: String?
    public var notes: String?
    
    public var image: UIImage?
    public var internalID: String?
    
    var imagePath: String {
        return "receipts/\(internalID ?? "0")"
    }
    
    init(initialCoordinates: CLLocationCoordinate2D, finalCoordinates: CLLocationCoordinate2D, initialDate: Date, finalDate: Date, moneySpent: Double, ticketNumber: String, notes: String, image: UIImage, internalID: String = "") {
        
        super.init(initialCoordinates: initialCoordinates, finalCoordinates: finalCoordinates, initialDate: initialDate, finalDate: finalDate)
        
        self.moneySpent = moneySpent
        self.ticketNumber = ticketNumber
        self.notes = notes
        
        self.image = image
        self.internalID = internalID
        
        generateID()
        
        LocationManager().getReverseGeoCodedLocation(location: CLLocation(latitude: initialCoordinates.latitude, longitude: initialCoordinates.longitude)) { location, placemark, error in
            self.initialLocationGeocoded = placemark?.name ?? ""
        }
        LocationManager().getReverseGeoCodedLocation(location: CLLocation(latitude: finalCoordinates.latitude, longitude: finalCoordinates.longitude)) { location, placemark, error in
            self.finalLocationGeocoded = placemark?.name ?? ""
        }
        
        
    }
    
    init(from drive: Drive, moneySpent: Double, ticketNumber: String, notes: String, image: UIImage, internalID: String = "") {
        super.init(from: drive)
        
        self.moneySpent = moneySpent
        self.ticketNumber = ticketNumber
        self.notes = notes
        
        self.image = image
        self.internalID = internalID
        
        self.initialLocationGeocoded = drive.initialPlace ?? ""
        self.finalLocationGeocoded = drive.finalPlace ?? ""
        
        generateID()
        
        if self.initialLocationGeocoded == "" {
            LocationManager().getReverseGeoCodedLocation(location: CLLocation(latitude: super.initialCoordinate.latitude, longitude: super.initialCoordinate.longitude)) { location, placemark, error in
                self.initialLocationGeocoded = placemark?.name ?? ""
            }
        }
        if self.finalLocationGeocoded == "" {
            LocationManager().getReverseGeoCodedLocation(location: CLLocation(latitude: super.finalCoordinate.latitude, longitude: super.finalCoordinate.longitude)) { location, placemark, error in
                self.finalLocationGeocoded = placemark?.name ?? ""
            }
        }
        
        
        
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        initialLocationGeocoded = try values.decode(String.self, forKey: .initialLocationGeocoded)
        finalLocationGeocoded = try values.decode(String.self, forKey: .finalLocationGeocoded)
        moneySpent = try values.decode(Double.self, forKey: .moneySpent)
        ticketNumber = try values.decode(String.self, forKey: .ticketNumber)
        notes = try values.decode(String.self, forKey: .notes)
        internalID = try values.decode(String.self, forKey: .internalID)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(initialLocationGeocoded, forKey: .initialLocationGeocoded)
        try container.encode(finalLocationGeocoded, forKey: .finalLocationGeocoded)
        try container.encode(moneySpent, forKey: .moneySpent)
        try container.encode(ticketNumber, forKey: .ticketNumber)
        try container.encode(notes, forKey: .notes)
        try container.encode(internalID, forKey: .internalID)
    }
    
    func setInitialGeocodedLocation(_ loc: String) {
        self.initialLocationGeocoded = loc
    }
    
    func setFinalGeocodedLocation(_ loc: String) {
        self.finalLocationGeocoded = loc
    }
    
    func generateID(override: Bool = false) {
        if override || self.internalID == "" {
            self.internalID = generateRandomID(numDigits: Constants.NUMBER_DIGITS_IN_ID)
        }
        
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case initialLocationGeocoded
        case finalLocationGeocoded
        case moneySpent
        case ticketNumber
        case notes
        case internalID
    }
    
    func generateRandomID(numDigits: Int) -> String {
        
        var finalNumber = "";
        for i in (0...numDigits) {
            var randomNumber = arc4random_uniform(10)
            finalNumber += String(Int(randomNumber))
        }
        return finalNumber
    }
}
