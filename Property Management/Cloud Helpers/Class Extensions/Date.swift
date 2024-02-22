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
        
        let dateString = formatter.string(from: self)
        return dateString   // "4:44 PM on June 23, 2016\n"
    }
    
    func toMonthDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM"

        let month = dateFormatter.string(from: self)

        dateFormatter.dateFormat = "dd"

        let day = dateFormatter.string(from: self)

        return "\(month)/\(day)"
    }
    
    func secondsSince(_ date: Date) -> Int {
//        let calendar = Calendar.current
//        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: date)
//        let nowComponents = calendar.dateComponents([.hour, .minute, .second], from: self)
//        
//        let difference = calendar.dateComponents([.second], from: timeComponents, to: nowComponents).second!
//        return difference
        return abs(Int(self.timeIntervalSince(date)))
    }
    
    static func -(recent: Date, previous: Date) -> (month: Int?, day: Int?, hour: Int?, minute: Int?, second: Int?) {
        let day = Calendar.current.dateComponents([.day], from: previous, to: recent).day
        let month = Calendar.current.dateComponents([.month], from: previous, to: recent).month
        let hour = Calendar.current.dateComponents([.hour], from: previous, to: recent).hour
        let minute = Calendar.current.dateComponents([.minute], from: previous, to: recent).minute
        let second = Calendar.current.dateComponents([.second], from: previous, to: recent).second
        
        return (month: month, day: day, hour: hour, minute: minute, second: second)
    }
    
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }
    
    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
    
}
