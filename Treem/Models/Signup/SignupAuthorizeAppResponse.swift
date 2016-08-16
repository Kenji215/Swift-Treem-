//
//  SignupAuthorizeAppResponse.swift
//  Treem
//
//  Created by Matthew Walker on 10/13/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import Locksmith
import SwiftyJSON

class SignupAuthorizeAppResponse {
    init?(json: JSON) {
        // set consumerUUID first
        if (TreemOAuthConsumerUUIDStorable.sharedInstance.setConsumerUUID(
            json["oauth_consumer_uuid"].stringValue
            )) == LocksmithError.NoError {
        
            // followed by consumer token
            TreemOAuthConsumerTokenStorable.sharedInstance.setConsumerToken(
                consumerToken         : json["oauth_consumer_key"].stringValue,
                consumerTokenSecret   : json["oauth_consumer_secret"].stringValue
            )
        }
        else {
            return nil
        }
    }
}
