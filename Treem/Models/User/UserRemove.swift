//
//  UserRemove.swift
//  Treem
//
//  Created by Matthew Walker on 11/22/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class UserRemove {
    var id          : Int   = 0
    var inviteId    : Int   = 0
    
    init() {}
    
    init(user: User) {
        self.id             = user.id
        self.inviteId       = user.inviteId
    }
    
    func toJSON() -> JSON? {
        var json:JSON = [:]
        
        // if id available use id
        if (self.id > 0) {
            json["id"].intValue = self.id
            
            return json
        }
            // otherwise check for phone
        else if self.inviteId > 0 {
            json["iv_id"].intValue = self.inviteId
            
            return json
        }
        
        return nil
    }
}