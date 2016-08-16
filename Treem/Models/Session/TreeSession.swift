//
//  TreeSession.swift
//  Treem
//
//  Created by Matthew Walker on 1/7/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation

class TreeSession {
    var treeID          : Int       = 0
    var token           : String?   = nil
    var currentBranch   : Branch?   = nil
    
    var currentBranchID: Int {
        return currentBranch?.id ?? 0
    }
    
    private let keyTreeSessionID = "treem-sid"
    
    init() {}
    
    init(treeID: Int, token: String?) {
        self.treeID = treeID
        self.token  = token
    }
    
    // get custom Tree http header for the services that need it
    func getTreemServiceHeader() -> [String : String]? {
        var header: [String : String]? = nil
        
        if self.treeID > 0 {
            header = [self.keyTreeSessionID : "tree_id=\(self.treeID)"]
            
            if let token = self.token where !token.isEmpty {
                header![self.keyTreeSessionID]! += ",token=" + token
            }
        }
        
        return header
    }
}