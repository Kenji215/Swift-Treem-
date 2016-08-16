//
//  UserLoginResponse.swift
//  Treem
//
//  Created by Matthew Walker on 10/7/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class UserLoginResponse {
    var userStatus          : User.UserStatus?   = nil

    init(json: JSON) {
        self.userStatus = User.UserStatus(rawValue: json["user_status"].intValue) ?? nil
        
        // token only stored on full user
        if self.userStatus == User.UserStatus.Full || self.userStatus == User.UserStatus.TempVerified {
            TreemOAuthUserTokenStorable.sharedInstance.setAccessToken(
                accessToken         : json["oauth_token"].stringValue,
                accessTokenSecret   : json["oauth_token_secret"].stringValue
            )
        }
    }
}