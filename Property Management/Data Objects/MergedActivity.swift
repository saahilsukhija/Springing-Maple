//
//  MergedActivity.swift
//  Property Management
//
//  Created by Saahil Sukhija on 10/14/24.
//

import Foundation

class MergedActivity: Activity {
    
    public var drive: Drive!
    public var work: Work!
    
    init(drive: Drive, work: Work) {
        super.init(from: drive)
        self.drive = drive
        self.work = work
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
