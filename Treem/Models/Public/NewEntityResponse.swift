//
//  NewEntityResponse.swift
//  Treem
//
//  Created by Randall Banks on 3/18/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

struct NewEntityResponse {
    var id : Int64 = 0
    
    init(json: JSON) {
        self.id = json["id"].int64Value
    }
}