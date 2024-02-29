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
            let dict = ["spreadsheetID" : spreadsheetID,
                        "username" : User.shared.getUserName(),
                        "apiKey" : Constants.API_KEYS.google_sheet_api,
                        "date" : drive.initialDate.toMonthDate(),
                        "initialLocation" : drive.initialPlace ?? "(none)",
                        "finalLocation" : drive.finalPlace ?? "none",
                        "initialTime" : drive.initialDate.toHourMinuteTime(),
                        "finalTime" : drive.finalDate.toHourMinuteTime(),
                        "money" : "0.00",
                        "type" : "Drive",
                        "ticketNumber" : drive.ticketNumber,
                        "receiptLink" : "",
                        "notes" : drive.notes]
            print(User.shared.getUserName())
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
    
    func appendRegisteredWorkToSpreadsheet(_ work: RegisteredWork) {
        Task {
            let link = try? await work.getReceiptURL()
            let dict = ["spreadsheetID" : spreadsheetID,
                        "username" : User.shared.getUserName(),
                        "apiKey" : Constants.API_KEYS.google_sheet_api,
                        "date" : work.initialDate.toMonthDate(),
                        "initialLocation" : work.initialPlace ?? "(none)",
                        "finalLocation" : work.finalPlace ?? "(none)",
                        "initialTime" : work.initialDate.toHourMinuteTime(),
                        "finalTime" : work.finalDate.toHourMinuteTime(),
                        "money" : "\(work.moneySpent ?? 0.00)",
                        "type" : "Work",
                        "ticketNumber" : work.ticketNumber,
                        "receiptLink" : link ?? "",
                        "notes" : work.notes]
            
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
    
    func addUserSheet() {
        let dict = ["spreadsheetID" : spreadsheetID,
                    "username" : User.shared.getUserName(),
                    "apiKey" : Constants.API_KEYS.google_sheet_api,
                    ]
        functions.httpsCallable("create_new_sheet").call(dict) { result, error in
            if let error = error {
                print("error: \(error)")
            }
            guard let val = result?.data as? String else {
                return
            }
            print(val)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.functions.httpsCallable("reset_header").call(dict) { result, error in
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
    }
    
    func appendToSpreadsheet(_ val: Int) {
        appendToSpreadsheet(String(val))
    }
    
}
