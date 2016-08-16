//
//  BranchPath.swift
//  Treem
//
//  Created by Daniel Sorrell on 12/22/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class BranchPath{
    var color       : String?       = nil
    var path        : [String]?      = nil
    
    init(){}
    
    init(json: JSON) {
        self.color          = json["color"].string
        self.path           = json["path"].arrayValue.map{ $0.string! }
    }
    
    // load the branch paths from the json
    func loadBranchPaths(data: JSON) -> [BranchPath]? {
        var paths: [BranchPath]? = []
        
        for(_, object) in data {
            let brPath = BranchPath(json: object)
            
            if(brPath.path != nil){ paths?.append(brPath) }
        }
        
        if(paths!.count < 1) { paths = nil }
        
        return paths
    }
}