//
//  TreemServiceResponse.swift
//  Treem
//
//  Created by Matthew Walker on 9/29/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

enum TreemServiceResponseCode: Int {
    case InternalServerError    = -2
    case NetworkError           = -1
    case GenericResponseCode1   = 1
    case GenericResponseCode2   = 2
    case GenericResponseCode3   = 3
    case GenericResponseCode4   = 4
    case GenericResponseCode5   = 5
    case GenericResponseCode6   = 6
    case GenericResponseCode7   = 7
    case GenericResponseCode8   = 8
    case GenericResponseCode9   = 9
    case GenericResponseCode10  = 10
    case Success                = 0
    case DisabledConsumerKey    = 90
    case DisabledOAuthToken     = 91
    case InvalidAccessToken     = 92
    case InvalidHeader          = 93
    case InvalidSignatureMethod = 94
    case RequestWasUsed         = 95
    case RequestHasExpired      = 96
    case InvalidConsumerKey     = 97
    case InvalidSignature       = 98
    case OtherError             = 99
    case LockedOut              = 100
}

struct TreemServiceResponse {
    var error   : Int?          = nil
    var data    : AnyObject?    = nil
    
    init(json: JSON) {
        self.error  = json["error"].int
        self.data   = json["data"].object
    }
    
    func getResponseCode() -> TreemServiceResponseCode {
        // start with error, require success to be asserted
        var responseCode = TreemServiceResponseCode.OtherError
        
        // if error code returned in call
        if let error = self.error {
            // either match a defined error or return a general error
            responseCode = TreemServiceResponseCode(rawValue: error) ?? TreemServiceResponseCode.OtherError
        }
        // if error code not returned in call, assume success if any data is passed back
        else if data != nil {
            responseCode = TreemServiceResponseCode.Success
        }
        
        return responseCode
    }
}