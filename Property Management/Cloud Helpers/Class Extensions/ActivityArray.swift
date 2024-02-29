//
//  ActivityArray.swift
//  Property Management
//
//  Created by Saahil Sukhija on 2/25/24.
//

import Foundation

extension [Activity] {
    
    mutating func sortAscending() {
        sort { act1, act2 in
            return act1.finalDate < act2.finalDate
        }
    }
    
    private mutating func removeDrives() {
        self.removeAll { activity in
            return activity is Drive
        }
    }
    
    private mutating func removeWorks() {
        self.removeAll { activity in
            return activity is Work
        }
    }
    
    mutating func replaceDrives(with drives: [Drive]) {
        removeDrives()
        self.append(contentsOf: drives)
        sortAscending()
    }
    
    mutating func replaceWorks(with works: [Work]) {
        removeWorks()
        self.append(contentsOf: works)
        sortAscending()
    }
    
    func getDrives() -> [Drive] {
        let drives = self.filter { activity in
            return activity is Drive
        } as! [Drive]
        return drives
    }
    
    func getWorks() -> [Work] {
        let works = self.filter { activity in
            return activity is Work
        } as! [Work]
        return works
    }
}
