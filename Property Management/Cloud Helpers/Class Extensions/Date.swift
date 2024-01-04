//
//  Date.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/3/24.
//

import Foundation

extension Date
{
    func toHourMinuteTime() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"

        let dateString = formatter.string(from: Date())
        return dateString   // "4:44 PM on June 23, 2016\n"
    }
}
