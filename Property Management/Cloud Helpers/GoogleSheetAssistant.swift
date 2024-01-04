//
//  SheetsAssistant.swift
//  Property Management
//
//  Created by Saahil Sukhija on 10/31/23.
//

import Foundation
import GoogleSignIn
import FirebaseFunctions

class SheetsAssistant {
    
    static var shared = SheetsAssistant()
    var spreadsheetID: String
    var functions: Functions!
    
    init() {
        spreadsheetID = "1daenlobEFeHHejUucuiLmwH4mPpna2LNLxZ_8u6xKPc"
        functions = Functions.functions()
        loadSpreadsheet()
    }
    
    func loadSpreadsheet() {
        functions.httpsCallable("append_to_sheet").call(["spreadsheetID": spreadsheetID]) { result, error in
          if let error = error as NSError? {
            if error.domain == FunctionsErrorDomain {
              let code = FunctionsErrorCode(rawValue: error.code)
              let message = error.localizedDescription
              let details = error.userInfo[FunctionsErrorDetailsKey]
                print(message)
            }
          }
          if let data = result?.data as? [String: Any], let text = data["result"] as? String {
              print("data: \(data)\ntext: " + text)
          }
        }
    }
    
    
}
