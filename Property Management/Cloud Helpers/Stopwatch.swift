//
//  Stopwatch.swift
//  Stopwatch
//
//  Created by Kiran Kunigiri on 10/15/15.
//  Copyright © 2015 Kiran Kunigiri. All rights reserved.
//

import Foundation
import UIKit


// MARK: Stopwatch
class Stopwatch: Codable {
    
    //Singleton Instance
    static let shared: Stopwatch = {
        let instance = Stopwatch()
        // setup code
        return instance
    }()
    
    private var startDate: Date!
    private(set) var isRunning = false
    
    private var breaks: [Break]!
    private(set) var isOnBreak: Bool! = false
    private var currentBreak: Break?

    init() {
        if UserDefaults.standard.isKeyPresent(key: "stopwatch") {
            do {
                let stopwatch = try UserDefaults.standard.get(objectType: Stopwatch.self, forKey: "stopwatch")
                startDate = stopwatch?.startDate
                isRunning = stopwatch!.isRunning
                isOnBreak = stopwatch?.isOnBreak
                breaks = stopwatch?.breaks
                currentBreak = stopwatch?.currentBreak
                print("restored from defaults")
            } catch {
                startDate = nil
                isOnBreak = false
                isRunning = false
                breaks = []
            }
        } else {
            startDate = nil
            isOnBreak = false
            isRunning = false
            breaks = []
        }
    }
    
    func start() {
        if !isRunning {
            startDate = Date()
            isRunning = true
            NotificationCenter.default.post(name: .userClockedIn, object: nil)
        }
    }
    
    //Returns (startDate, endDate)
    func end() -> (Date, Date) {
        isRunning = false
        breaks = []
        currentBreak = nil
        isOnBreak = false
        
        NotificationCenter.default.post(name: .userClockedOut, object: nil)
        return (startDate, Date())
    }
    
    func startBreak() {
        guard !isOnBreak && isRunning else {
            return
        }
        
        currentBreak = Break()
        isOnBreak = true
        
        NotificationCenter.default.post(name: .userClockedOut, object: nil)
    }
    
    //Returns (startDate, endDate)
    func endBreak() -> (Date, Date) {
        guard isOnBreak && currentBreak != nil else {
            return (Date(), Date())
        }
        currentBreak?.endBreak = Date()
        isOnBreak = false
        breaks.append(currentBreak!)
        let start = currentBreak!.startBreak
        currentBreak = nil
        NotificationCenter.default.post(name: .userClockedIn, object: nil)
        return (start!, Date())
    }
    
    func shouldTrackLocation() -> Bool {
        return !isOnBreak && isRunning
    }
    
    
}

extension Stopwatch {
    //Date: Start date
    func getTimeElapsed(_ date: Date) -> (hour: Int?, minute: Int?, second: Int?) {
        guard isRunning else {
            return (hour: nil, minute: nil, second: nil)
        }
        
        let current = Date()
        let hour = (current - date).hour
        let minute = (current - date).minute
        let second = (current - date).second
        
        return (hour: hour, minute: minute, second: second)
    }
    
    func getTimeString() -> String {
        guard isRunning else {
            return "00:00:00"
        }
        let output = getTimeElapsed(startDate)
        
        let hour = output.hour
        let minute = (output.minute ?? 0) % 60
        let second = (output.second ?? 0) % 60
        
        var text = ""
        if hour == nil {
            text += "00"
        } else if hour! < 10 {
            text += "0\(hour!)"
        } else {
            text += "\(hour!)"
        }
        text += ":"
        if minute < 10 {
            text += "0\(minute)"
        } else {
            text += "\(minute)"
        }
        text += ":"
        if second < 10 {
            text += "0\(second)"
        } else {
            text += "\(second)"
        }
        return text
    }
    
    func getCurrentBreakTimeString() -> String {
        guard let currentBreak = currentBreak else {
            return "00:00"
        }
        let output = getTimeElapsed(currentBreak.startBreak)
        
        let minute = (output.minute ?? 0)%60
        let second = (output.second ?? 0)%60
        
        var text = ""
        
        if minute < 10 {
            text += "0\(minute)"
        } else {
            text += "\(minute)"
        }
        text += ":"
        if second < 10 {
            text += "0\(second)"
        } else {
            text += "\(second)"
        }
        return text
    }
    
    func getCurrentTimes() -> (String, String, String) {
        guard isRunning else {
            return ("00", "00", "00")
        }
        let output = getTimeElapsed(startDate)
        
        let hour = output.hour ?? 0
        let minute = (output.minute ?? 0) % 60
        let second = (output.second ?? 0) % 60
        
        var hourStr = ""
        var minStr = ""
        var secStr = ""
        
        if hour < 10 {
            hourStr += "0\(hour)"
        } else {
            hourStr += "\(hour)"
        }
        
        if minute < 10 {
            minStr += "0\(minute)"
        } else {
            minStr += "\(minute)"
        }

        if second < 10 {
            secStr += "0\(second)"
        } else {
            secStr += "\(second)"
        }
        return (hourStr, minStr, secStr)
        
        
    }
    
    func getCurrentBreakTimes() -> (Int, Int) {
        guard let currentBreak = currentBreak else {
            return (0, 0)
        }
        let output = getTimeElapsed(currentBreak.startBreak)
        
        let minute = (output.minute ?? 0)
        let second = (output.second ?? 0)%60
        
        return (minute, second)
        
        
    }
    
}

class Break: Codable {
    
    var startBreak: Date!
    var endBreak: Date?
    
    init(startBreak: Date! = Date(), endBreak: Date? = nil) {
        self.startBreak = startBreak
        self.endBreak = endBreak
    }
    
    func stopBreak() {
        self.endBreak = Date()
    }
}
