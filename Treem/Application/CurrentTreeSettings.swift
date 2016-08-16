//
//  TreeSettings.swift
//  Treem
//
//  Created by Daniel Sorrell on 12/4/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

enum TreeType: Int {
    case Main   = 1
    case Secret = 2
    case Public = 3
}

class CurrentTreeSettings {
    
    static let sharedInstance = CurrentTreeSettings()
    
    // tree types
    static let mainTreeID              = 1
    static let secretTreeID            = 2
    static let publicTreeID            = 3
    
    var treeSession: TreeSession = TreeSession(treeID: 1, token: nil) // default initial tree
    
    var currentBranchID: Int {
        return self.treeSession.currentBranch?.id ?? 0
    }
    
    var currentTree: TreeType {
        return TreeType(rawValue: CurrentTreeSettings.sharedInstance.treeSession.treeID)!
    }
}
