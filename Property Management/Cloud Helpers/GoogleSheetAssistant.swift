//
//  SheetsAssistant.swift
//  Property Management
//
//  Created by Saahil Sukhija on 10/31/23.
//

import Foundation
import GoogleSignIn
import FirebaseFunctions

class GoogleSheetAssistant {
    
    static var shared = GoogleSheetAssistant()
    var spreadsheetID: String
    var functions: Functions!
    
    init() {
        spreadsheetID = "1daenlobEFeHHejUucuiLmwH4mPpna2LNLxZ_8u6xKPc"
        functions = Functions.functions()
        loadSpreadsheet()
    }
    
    func loadSpreadsheet() {

    }
    
    func appendToSpreadsheet(_ values: [String : Any]) {
        var dict: Dictionary<String, Any> = ["spreadsheetID": spreadsheetID, "apiKey": Constants.API_KEYS.google_sheet_api]
        dict += values
        functions.httpsCallable("append_to_spreadsheet").call(dict) { result, error in
            if let error = error {
                print("error: \(error)")
            }
            guard let val = result?.data as? String else {
                return
            }
            print(val)
        }
    }
    
    func appendToSpreadsheet(_ val: String) {
        
        functions.httpsCallable("append_to_spreadsheet").call(["spreadsheetID": spreadsheetID, "apiKey": Constants.API_KEYS.google_sheet_api, "value": val == "" ? "(none)" : val]) { result, error in
            if let error = error {
                print("error: \(error)")
            }
            guard let val = result?.data as? String else {
                return
            }
            print(val)
        }
    }
    
    func appendRegisteredDriveToSpreadsheet(_ drive: RegisteredDrive) {
        Task {
            let link = try? await drive.getReceiptURL()
            let dict = ["spreadsheetID" : spreadsheetID,
                        "apiKey" : Constants.API_KEYS.google_sheet_api,
                        "date" : drive.initialDate.toMonthDate(),
                        "initialLocation" : drive.initialLocationGeocoded,
                        "finalLocation" : drive.finalLocationGeocoded,
                        "initialTime" : drive.initialDate.toHourMinuteTime(),
                        "finalTime" : drive.finalDate.toHourMinuteTime(),
                        "money" : "$\(drive.moneySpent ?? 0.00)",
                        "ticketNumber" : drive.ticketNumber,
                        "receiptLink" : link ?? "",
                        "notes" : drive.notes]
            
            functions.httpsCallable("append_drive_to_spreadsheet").call(dict) { result, error in
                if let error = error {
                    print("error: \(error)")
                }
                guard let val = result?.data as? String else {
                    return
                }
                print(val)
            }
        }
        
    }
    
    func appendToSpreadsheet(_ val: Int) {
        appendToSpreadsheet(String(val))
    }
    
}
