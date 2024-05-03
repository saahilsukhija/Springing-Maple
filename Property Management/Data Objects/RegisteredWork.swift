//
//  RegisteredWork.swift
//  Property Management
//
//  Created by Saahil Sukhija on 2/25/24.
//

import UIKit
import CoreLocation
import FirebaseStorage

class RegisteredWork: RegisteredActivity {
    
    public var moneySpent: Double?
    
    public var image: UIImage?
    
    public var imagePath: String {
        return "receipts/\(internalID ?? "0").jpeg"
    }
    //public var receiptURL: String?
    
    init(initialCoordinates: CLLocationCoordinate2D, finalCoordinates: CLLocationCoordinate2D, initialDate: Date, finalDate: Date, initPlace: String? = nil, finPlace: String? = nil, moneySpent: Double, ticketNumber: String, notes: String, image: UIImage?, internalID: String = "") {
        
        super.init(initialCoordinates: initialCoordinates, finalCoordinates: finalCoordinates, initialDate: initialDate, finalDate: finalDate, initPlace: initPlace, finPlace: finPlace, ticketNumber: ticketNumber, notes: notes, internalID: internalID)
        
        self.moneySpent = moneySpent
        self.image = image
        
        
    }
    
    init(from work: Work, moneySpent: Double, ticketNumber: String, notes: String, image: UIImage, internalID: String = "") {
        
        super.init(from: work, ticketNumber: ticketNumber, notes: notes, internalID: internalID)
        
        self.moneySpent = moneySpent
        self.image = image
        
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        moneySpent = try values.decode(Double.self, forKey: .moneySpent)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func encode(to encoder: Encoder) throws {
        
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(moneySpent, forKey: .moneySpent)
    }
    
    private enum CodingKeys: String, CodingKey
    {
        case initialLocationGeocoded
        case finalLocationGeocoded
        case moneySpent
    }
    
    func getReceiptURL() async throws -> String  {
        let reference = Storage.storage().reference(withPath: "receipts/\(internalID ?? "0").jpeg")
        do {
           let string = try await reference.downloadURL().absoluteString
           return string
        }
        catch {
            print("unable to get receipt URL")
            return "N/A"
        }
    }
    
}
