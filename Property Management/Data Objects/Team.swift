//
//  Team.swift
//  Property Management
//
//  Created by Saahil Sukhija on 12/31/23.
//

import Foundation

class Team: Codable {
    
    var id: String!
    var name: String!
    var spreadsheetID: String?
    
    init(_ id: String, name: String, spreadsheetID: String = "") {
        self.id = id
        self.name = name
        self.spreadsheetID = spreadsheetID
    }
    
    init(id: String) async throws {
        do {
            let t = try await FirestoreDatabase.shared.getTeam(from: id)
            self.id = t.id
            self.name = t.name
            self.spreadsheetID = t.spreadsheetID
        } catch {
            throw NSError()
        }
    }
    
    init(name: String = "") async {
        self.id = await Team.generateID()
        self.name = name
    }
    
    static func generateID() async -> String {
        
        var id = generateRandomID(numDigits: Constants.NUMBER_DIGITS_IN_TEAM_ID)
        do {
            while try await FirestoreDatabase.shared.teamDoesExist(id) {
                id = generateRandomID(numDigits: Constants.NUMBER_DIGITS_IN_TEAM_ID)
            }
            return id
        } catch {
            return id
        }
        
        
    }
    
    static func generateRandomID(numDigits: Int) -> String {
        
        var finalNumber = "";
        for _ in (0..<numDigits) {
            let randomNumber = arc4random_uniform(10)
            finalNumber += String(Int(randomNumber))
        }
        return finalNumber
    }
    
    func hasSpreadsheet() -> Bool {
        if self.spreadsheetID == nil || self.spreadsheetID == "" {
            return false
        }
        return true
    }
    
}
