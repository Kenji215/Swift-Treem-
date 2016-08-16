//
//  UserAdd.swift
//  Treem
//
//  Created by Matthew Walker on 11/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import libPhoneNumber_iOS

class UserAdd {
    var id          : Int           = 0
    var phone       : String?       = nil
    
    init() {}
    
    init(user: User) {
        self.id             = user.id
        self.phone          = user.phone
    }
    
    func toJSON() -> JSON? {
        var json:JSON = [:]
        
        // if id available use id
        if (id > 0) {
            json["id"].intValue = id
            
            return json
        }
        // otherwise check for phone
        else if let phone = self.phone {
            if !phone.isEmpty {
                json["phone"].stringValue = NBPhoneNumberUtil().getE164FormattedString(phone)
                
                return json
            }
        }
        
        return nil
    }
}