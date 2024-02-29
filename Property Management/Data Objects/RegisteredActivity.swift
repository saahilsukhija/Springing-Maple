//
//  RegisteredActivity.swift
//  Property Management
//
//  Created by Saahil Sukhija on 2/25/24.
//

import UIKit
import CoreLocation

class RegisteredActivity: Activity {
    
    public var ticketNumber: String?
    public var notes: String?
    
    public var internalID: String?
    
    //public var receiptURL: String?
    
    init(initialCoordinates: CLLocationCoordinate2D, finalCoordinates: CLLocationCoordinate2D, initialDate: Date, finalDate: Date, ticketNumber: String, notes: String, internalID: String = "") {
        
        super.init(initialCoordinates: initialCoordinates, finalCoordinates: finalCoordinates, initialDate: initialDate, finalDate: finalDate)
        
        self.ticketNumber = ticketNumber
        self.notes = notes
        
        self.internalID = internalID
        
        generateID()
        
    }
    
    init(from activity: Activity, ticketNumber: String, notes: String, internalID: String = "") {
        super.init(from: activity)
        
        self.ticketNumber = ticketNumber
        self.notes = notes
        
        self.internalID = internalID
        
        generateID()
        
        
        
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
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
        try container.encode(ticketNumber, forKey: .ticketNumber)
        try container.encode(notes, forKey: .notes)
        try container.encode(internalID, forKey: .internalID)
    }
    
    func generateID(override: Bool = false) {
        if override || self.internalID == "" {
            self.internalID = generateRandomID(numDigits: Constants.NUMBER_DIGITS_IN_ID)
        }
        
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case ticketNumber
        case notes
        case internalID
    }
    
    func generateRandomID(numDigits: Int) -> String {
        
        var finalNumber = "";
        for _ in (0...numDigits) {
            let randomNumber = arc4random_uniform(10)
            finalNumber += String(Int(randomNumber))
        }
        return finalNumber
    }
    
}
