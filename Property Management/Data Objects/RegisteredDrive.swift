//
//  RegisteredDrive.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/5/24.
//

import UIKit
import CoreLocation
import FirebaseStorage
import MapKit

class RegisteredDrive: RegisteredActivity {
    
    public var milesDriven: Double?
    
    init(initialCoordinates: CLLocationCoordinate2D, finalCoordinates: CLLocationCoordinate2D, initialDate: Date, finalDate: Date, initPlace: String? = nil, finPlace: String? = nil, milesDriven: Double, ticketNumber: String, notes: String, internalID: String = "") {
        
        super.init(initialCoordinates: initialCoordinates, finalCoordinates: finalCoordinates, initialDate: initialDate, finalDate: finalDate, initPlace: initPlace, finPlace: finPlace, ticketNumber: ticketNumber, notes: notes, internalID: internalID)
        
        if milesDriven != -1 {
            self.milesDriven = milesDriven
        } else {
            Drive.getMilesBetween(initialCoordinates, and: finalCoordinates) { miles in
                self.milesDriven = miles
            }
        }
        
        
    }
    
    init(from drive: Drive, ticketNumber: String, notes: String, internalID: String = "") {
        
        super.init(from: drive, ticketNumber: ticketNumber, notes: notes, internalID: internalID)
        
        self.milesDriven = drive.milesDriven
        
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
    
    private enum CodingKeys: String, CodingKey
    {
        case initialLocationGeocoded
        case finalLocationGeocoded
        case milesDriven
    }
    
}
