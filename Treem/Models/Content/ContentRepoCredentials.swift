//
//  ContentRepoCredentials
//  Treem
//
//  Created by Matthew Walker on 12/11/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class ContentRepoCredentials {
    var id      : String? = nil
    var token   : String? = nil
    var poolId  : String? = nil
    var expires : NSDate? = nil
    
    init () {}
    
    init(data: JSON) {
        self.id         = data["id"].stringValue
        self.token      = data["token"].stringValue
        self.poolId     = data["poolId"].stringValue
        self.expires    = NSDate(iso8601String: data["expires"].stringValue)
    }
}