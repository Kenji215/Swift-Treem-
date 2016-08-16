//
//  CheckPinResponse.swift
//  Treem
//
//  Created by Matthew Walker on 10/19/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

struct CheckPinResponse {
    var token : String = ""
    
    init(json: JSON) {
        self.token = json["token"].stringValue
    }
}