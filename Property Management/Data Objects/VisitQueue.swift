//
//  Queue.swift
//  Property Management
//
//  Created by Saahil Sukhija on 12/30/23.
//

struct VisitQueue {
    private var elements: [Visit] = []
    
    mutating func enqueue(_ value: Visit) {
        elements.append(value)
    }
    
    mutating func dequeue() -> Visit? {
        guard !elements.isEmpty else {
            return nil
        }
        return elements.removeFirst()
    }
    
    var head: Visit? {
        return elements.first
    }
    
    var tail: Visit? {
        return elements.last
    }
    
    init(elements: [Visit]) {
        self.elements = elements
    }
    
    init() {
        self.elements = []
    }
}
