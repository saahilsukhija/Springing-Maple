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
    
    func appendRegisteredDriveToSpreadsheet(_ drive: RegisteredDrive, deletePreviousEntry: Bool) {
        
        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
        
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
        DispatchQueue.main.async {
            if deletePreviousEntry {
                SpreadsheetEntryQueue.shared.putEntry(type: .deleteitem, data: dict)
            }
            SpreadsheetEntryQueue.shared.putEntry(type: .drive, data: dict)
        }
        
    }
    
    func appendRegisteredWorkToSpreadsheet(_ work: RegisteredWork, deletePreviousEntry: Bool) {
        
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
            
            DispatchQueue.main.async {
                if deletePreviousEntry {
                    SpreadsheetEntryQueue.shared.putEntry(type: .deleteitem, data: dict)
                }
                SpreadsheetEntryQueue.shared.putEntry(type: .drive, data: dict)
            }
        }
        
    }
    
    func appendUnregisteredDriveToSpreadsheet(_ drive: Drive) {
        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
        
        let dict = ["spreadsheetID" : spreadsheetID,
                    "username" : User.shared.getUserName(),
                    "apiKey" : Constants.API_KEYS.google_sheet_api,
                    "date" : drive.initialDate.toMonthYearDate(),
                    "initialLocation" : drive.initialPlace ?? "(none)",
                    "finalLocation" : drive.finalPlace ?? "(none)",
                    "initialTime" : drive.initialDate.toHourMinuteTime(),
                    "finalTime" : drive.finalDate.toHourMinuteTime(),
                    "money" : "",
                    "type" : "Drive",
                    "ticketNumber" : "",
                    "receiptLink" : "",
                    "notes" : "",
                    "duration": drive.finalDate.durationSince(drive.initialDate),
                    "milesDriven": "\(drive.milesDriven ?? 0)"]
        
        DispatchQueue.main.async {
            SpreadsheetEntryQueue.shared.putEntry(type: .unregistereddrive, data: dict)
        }
    }
    
    func appendUnregisteredWorkToSpreadsheet(_ work: Work) {
        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
        
        let dict = ["spreadsheetID" : spreadsheetID,
                    "username" : User.shared.getUserName(),
                    "apiKey" : Constants.API_KEYS.google_sheet_api,
                    "date" : work.initialDate.toMonthYearDate(),
                    "initialLocation" : work.initialPlace ?? "(none)",
                    "finalLocation" : work.finalPlace ?? "(none)",
                    "initialTime" : work.initialDate.toHourMinuteTime(),
                    "finalTime" : work.finalDate.toHourMinuteTime(),
                    "money" : "",
                    "type" : "Work",
                    "ticketNumber" : "",
                    "receiptLink" : "",
                    "notes" : "",
                    "duration": work.finalDate.durationSince(work.initialDate),
                    "milesDriven": ""]
        
        DispatchQueue.main.async {
            SpreadsheetEntryQueue.shared.putEntry(type: .unregistereddrive, data: dict)
        }
    }
    
    func deleteItemFromSpreadsheet(_ activity: Activity) {
        let dict = ["spreadsheetID" : spreadsheetID,
                    "username" : User.shared.getUserName(),
                    "apiKey" : Constants.API_KEYS.google_sheet_api,
                    "date" : activity.initialDate.toMonthYearDate(),
                    "initialTime" : activity.initialDate.toHourMinuteTime(),
                    "finalTime" : activity.finalDate.toHourMinuteTime(),
                    "money" : "",
                    "type" : "",
                    "ticketNumber" : "",
                    "receiptLink" : "",
                    "notes" : "",
                    "milesDriven": ""]
        
        DispatchQueue.main.async {
            SpreadsheetEntryQueue.shared.putEntry(type: .deleteitem, data: dict)
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
        SpreadsheetEntryQueue.shared.putEntry(type: .createnewsheet, data: dict)
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
        SpreadsheetEntryQueue.shared.putEntry(type: .breaksession, data: dict)
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
            DispatchQueue.main.async {
                SpreadsheetEntryQueue.shared.putEntry(type: .dailysummary, data: dict)
            }
        }
    }
    
    func getPropertyList() {
        guard let spreadsheetID = spreadsheetID else {
            print("NO SPREADSHEET ID")
            return
        }
        
        Task {
            let dict = ["spreadsheetID" : spreadsheetID,
                        "username" : User.shared.getUserName(),
                        "apiKey" : Constants.API_KEYS.google_sheet_api,
            ]
            functions.httpsCallable("get_property_list").call(dict) { result, error in
                if let error = error {
                    print("error: \(error)")
                }
                if let data = (result?.data as? [String : Any]) {
                    if let values = (data["data"] as? [String : Any])?["values"] as? [[String]] {
                        SavedLocations.shared.removeDeletedLocations(pairs: values)
                        for pair in values {
                            let actual = pair[0]
                            let assigned = pair[1]
                            
                            SavedLocations.shared.addLocation(actualName: actual, assignedName: assigned)
                        }
                    }
                }
            }
        }
    }
    
    func createNewSpreadsheet(from team: Team, spreadsheetName: String, completion: @escaping((String) -> Void)) {
        
        let dict = ["teamID": team.id, "spreadsheetName": spreadsheetName, "teamName" : team.name, "email" : User.shared.getUserEmail(), "apiKey" : Constants.API_KEYS.google_sheet_api]
        SpreadsheetEntryQueue.shared.putEntry(type: .createspreadsheet, data: dict)
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
        DispatchQueue.main.async { [self] in
            entries.append(entry)
            executeNext()
        }
    }
    
    func putEntry(type: SpreadsheetEntry.ActivityType = .drive, data: [String : String?]) {
        DispatchQueue.main.async { [self] in
            entries.append(SpreadsheetEntry(type: type, data: data))
            executeNext()
        }
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
            print("Starting SpreadsheetRequest: \(entry.type.rawValue)")
            GoogleSheetAssistant.shared.functions.httpsCallable(entry.type.rawValue).call(entry.data) { result, error in
                if let error = error {
                    print("Error doing \(entry.type.rawValue): \(error.localizedDescription)")
                }
                print("FINISHED")
                
                self.entries.removeFirst()
                self.isRunning = false
                
                if entry.type == .createnewsheet {
                    self.entries.insert(SpreadsheetEntry(type: .resetheader, data: entry.data), at: 0)
                }
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
        case drive = "append_drive_to_spreadsheet"
        case dailysummary = "append_dailysummary_to_spreadsheet"
        case breaksession = "append_break_to_spreadsheet"
        case createspreadsheet = "create_spreadsheet"
        case createnewsheet = "create_new_sheet"
        case getpropertylist = "get_property_list"
        case resetheader = "reset_header"
        case unregistereddrive = "append_unreg_drive_to_spreadsheet"
        case deleteitem = "delete_item_from_spreadsheet"
    }
    
}
