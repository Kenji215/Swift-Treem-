//
//  TreeSettings.swift
//  Treem
//
//  Created by Daniel Sorrell on 12/4/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class TreeSettings {
    var push_notif         : Bool = false

    
    init() {}
    
    init (json: JSON) {
        self.push_notif         = (json["push_notif"].intValue == 1) ? true : false
    }
    
    init(_push_notif: Bool){
        self.push_notif = _push_notif
    }
   
    func toJSON() -> JSON {
        var json:JSON = [:]
        
        // if id available use id
        json["push_notif"].intValue = (push_notif == true) ? 1 : 0
        
        return json
    }
}
