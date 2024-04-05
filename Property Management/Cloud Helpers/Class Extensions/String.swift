//
//  String.swift
//  Property Management
//
//  Created by Saahil Sukhija on 3/10/24.
//

import Foundation

extension String {
    
    func removeNumbers() -> String  {
        
        var count = 0
        
        for (i, c) in self.enumerated() {
            if c.isNumber || !c.isLetter {
                count += 1
            } else {
                break
            }
        }
        
        return self.substring(from: count).trim()
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func index(of char: Character) -> Int? {
        return firstIndex(of: char)?.utf16Offset(in: self)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}
