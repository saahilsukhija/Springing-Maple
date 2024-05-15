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
    var spreadsheetID: String? {
        return User.shared.team?.spreadsheetID
    }
    var functions: Functions!
    
    init() {
        functions = Functions.functions()
        loadSpreadsheet()
    }
    
    func loadSpreadsheet() {

    }
    
    func appendToSpreadsheet(_ values: [String : Any]) {
        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
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
        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
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

        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
        
        Task {
            let dict = ["spreadsheetID" : spreadsheetID,
                        "username" : User.shared.getUserName(),
                        "apiKey" : Constants.API_KEYS.google_sheet_api,
                        "date" : drive.initialDate.toMonthYearDate(),
                        "initialLocation" : drive.initialPlace ?? "(none)",
                        "finalLocation" : drive.finalPlace ?? "none",
                        "initialTime" : drive.initialDate.toHourMinuteTime(),
                        "finalTime" : drive.finalDate.toHourMinuteTime(),
                        "money" : "0.00",
                        "type" : "Drive",
                        "ticketNumber" : drive.ticketNumber ?? "",
                        "receiptLink" : "",
                        "notes" : drive.notes ?? "",
                        "duration": drive.finalDate.durationSince(drive.initialDate),
                        "milesDriven": "\(drive.milesDriven ?? -1)"]
            SpreadsheetEntryQueue.shared.putEntry(type: .drive, data: dict)
        }
        
    }
    
    func appendRegisteredWorkToSpreadsheet(_ work: RegisteredWork) {

        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
        
        Task {
            let link = try? await work.getReceiptURL()
            let dict = ["spreadsheetID" : spreadsheetID,
                        "username" : User.shared.getUserName(),
                        "apiKey" : Constants.API_KEYS.google_sheet_api,
                        "date" : work.initialDate.toMonthYearDate(),
                        "initialLocation" : work.initialPlace ?? "(none)",
                        "finalLocation" : work.finalPlace ?? "(none)",
                        "initialTime" : work.initialDate.toHourMinuteTime(),
                        "finalTime" : work.finalDate.toHourMinuteTime(),
                        "money" : "\(work.moneySpent ?? 0.00)",
                        "type" : "Work",
                        "ticketNumber" : work.ticketNumber,
                        "receiptLink" : link ?? "",
                        "notes" : work.notes,
                        "duration": work.finalDate.durationSince(work.initialDate),
                        "milesDriven": ""]
            
            SpreadsheetEntryQueue.shared.putEntry(type: .work, data: dict)
        }
        
    }
    
    func addUserSheet() {
        
        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
        
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
    
    func appendBreakToSpreadsheet(start: Date, end: Date) {
        
        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
        
        let dict = ["spreadsheetID" : spreadsheetID,
                    "username" : User.shared.getUserName(),
                    "apiKey" : Constants.API_KEYS.google_sheet_api,
                    "date" : start.toMonthYearDate(),
                    "initialTime" : start.toHourMinuteTime(),
                    "finalTime" : end.toHourMinuteTime()
                    ]
        functions.httpsCallable("append_break_to_spreadsheet").call(dict) { result, error in
            if let error = error {
                print("error: \(error)")
            }
            guard let val = result?.data as? String else {
                return
            }
            print(val)
        }
    }
    
    func appendSummaryToSpreadsheet(date: Date) {
        
        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
        
        Task {
            let count = try await FirestoreDatabase.shared.getDailyCounter(.general)
            let dict = ["spreadsheetID" : spreadsheetID,
                        "username" : User.shared.getUserName(),
                        "apiKey" : Constants.API_KEYS.google_sheet_api,
                        "date" : date.toMonthYearDate(),
                        "activities" : "\(count)"
            ]
            functions.httpsCallable("append_dailysummary_to_spreadsheet").call(dict) { result, error in
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
    
    
    func createNewSpreadsheet(from team: Team, spreadsheetName: String, completion: @escaping((String) -> Void)) {

        let dict = ["teamID": team.id, "spreadsheetName": spreadsheetName, "teamName" : team.name, "email" : User.shared.getUserEmail(), "apiKey" : Constants.API_KEYS.google_sheet_api]
        functions.httpsCallable("create_spreadsheet").call(dict) { result, error in
            if let error = error {
                print("error: \(error)")
            }
            guard let val = result?.data as? String else {
                completion("")
                return
            }
            completion(val)
        }
    }
    
}

class SpreadsheetEntryQueue {
    
    private(set) var entries: [SpreadsheetEntry]!
    var isRunning: Bool!
    
    //Singleton Instance
    static let shared: SpreadsheetEntryQueue = {
        let instance = SpreadsheetEntryQueue()
        return instance
    }()
    
    init() {
        entries = []
        isRunning = false
    }
    
    func putEntry(_ entry: SpreadsheetEntry) {
        entries.append(entry)
        executeNext()
    }
    
    func putEntry(type: SpreadsheetEntry.ActivityType = .drive, data: [String : String?]) {
        entries.append(SpreadsheetEntry(type: type, data: data))
        executeNext()
    }
    
    func executeNext() {
        guard entries.count > 0 else {
            print("finished spreadsheet entries");
            self.isRunning = false
            return
        }
        guard let spreadsheetID = GoogleSheetAssistant.shared.spreadsheetID else {
            print("NO SPREADSHEET ID")
            self.isRunning = false
            return
        }
        guard !isRunning else { return }
        let entry = entries[0]
        self.isRunning = true
        Task {
            GoogleSheetAssistant.shared.functions.httpsCallable("append_drive_to_spreadsheet").call(entry.data) { result, error in
                if let error = error {
                    print("error: \(error)")
                }
                guard let val = result?.data as? String else {
                    return
                }
                self.entries.removeFirst()
                self.isRunning = false
                self.executeNext()
            }
        }
    }
        
}

class SpreadsheetEntry {
    
    var type: ActivityType!
    var data: [String : String?]!
    
    init(type: ActivityType!, data: [String : String?]!) {
        self.type = type
        self.data = data
    }
    
    enum ActivityType: String {
        case drive = "drive"
        case work = "work"
    }
    
}
