//
//  SetUsersResponse.swift
//  Treem
//
//  Created by Matthew Walker on 11/24/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class SetUsersResponse {
    var badPhones       : [String]? = nil
    var badPhoneCount   : Int       = 0
    
    init(data: JSON) {
        self.badPhoneCount  = data["bad_phone_count"].intValue
        self.badPhones      = self.loadBadPhones(data["bad_phones"]) // set badPhones after badPhoneCount
    }
    
    // recursively load sub branch network
    func loadBadPhones(data: JSON) -> [String]? {
        var badPhones: [String]? = []
        
        for (_, object) in data {
            badPhones?.append(object.stringValue)
        }
        
        if badPhones!.count < 1 {
            badPhones           = nil
            self.badPhoneCount  = 0
        }
        else if self.badPhoneCount < 1 {
            // match count to bad phones array count if not explicitly passed back
            self.badPhoneCount  = badPhones!.count
        }
        
        return badPhones
    }
}