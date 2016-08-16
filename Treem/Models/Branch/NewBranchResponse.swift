//
//  NewBranchResponse.swift
//  Treem
//
//  Created by Matthew Walker on 10/5/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

struct NewBranchResponse {
    var id             : Int = 0
    
    init(json: JSON) {
        self.id = json["id"].intValue
    }
}