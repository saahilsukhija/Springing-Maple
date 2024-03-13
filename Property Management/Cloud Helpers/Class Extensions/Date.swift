//
//  Date.swift
//  Property Management
//
//  Created by Saahil Sukhija on 1/3/24.
//

import Foundation

extension Date
{
    static let ongoingDate = Date(timeIntervalSince1970: 0)
    
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
    
    func toMonthYearDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM"
        
        let month = dateFormatter.string(from: self)
        
        dateFormatter.dateFormat = "dd"
        
        let day = dateFormatter.string(from: self)
        
        dateFormatter.dateFormat = "yy"
        
        let year = dateFormatter.string(from: self)
        
        return "\(month)/\(day)/\(year)"
    }
    
    
    
    func durationSince(_ date: Date) -> String {
        let diffSeconds = abs(Int(self.timeIntervalSince1970 - date.timeIntervalSince1970))
        
        let hours = diffSeconds / 3600
        let minutes = diffSeconds / 60 - hours * 60
        
        var out = "\(hours):"
        
        if minutes < 10 {
            out += "0\(minutes)"
        } else {
            out += "\(minutes)"
        }
        return out
        
    }
    func secondsSince(_ date: Date) -> Int {
        return abs(Int(self.timeIntervalSince(date)))
    }
    
    mutating func setSameDay(as other: Date) {
        let calendar = Calendar.current
        
        var dateComponents: DateComponents? = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        var otherComponents: DateComponents? = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: other)
        dateComponents?.day = otherComponents?.day
        dateComponents?.month = otherComponents?.month
        dateComponents?.year = otherComponents?.year
        
        let date: Date? = calendar.date(from: dateComponents!)
        self = date!
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
