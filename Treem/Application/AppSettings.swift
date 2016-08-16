//
//  AppSettings.swift
//  Treem
//
//  Created by Daniel Sorrell on 12/1/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class AppSettings {
    static let sharedInstance = AppSettings()
    
    // config variables
    
    // treem service
    static let treem_service_domain = "treemtest.com"
    static let treemConsumerKey     : [UInt8] = [56, 85, 49, 56, 67, 81, 98, 111, 120, 88, 109, 84, 97, 122, 116, 108, 104, 48, 66, 84, 66, 70, 101, 70, 84, 54, 83, 121, 81, 80, 87, 108, 48, 68, 49, 49, 50, 56, 65, 48, 45, 97, 99, 66, 46, 100, 116, 109, 50, 105, 105, 105, 65, 85, 95, 46, 65, 52]
    static let treemConsumerSecret  : [UInt8] = [56, 52, 55, 100, 98, 97, 57, 55, 45, 51, 51, 97, 97, 45, 52, 99, 51, 98, 45, 57, 56, 51, 51, 45, 49, 52, 101, 51, 98, 100, 55, 56, 98, 97, 56, 102, 95, 122, 65, 50, 75, 89, 122, 108, 45, 48, 54, 87, 87, 119, 69, 101, 118, 90, 52, 109, 115, 109, 103]
    
    // amazon
    static let aws_s3_bucket_name = "treemtest"
    static let aws_cognito_provider_name = "awscognito.treemtest.com"
    
    // sinch (chat) config settings
    static let sinch_application_key: [UInt8] = [56, 48, 99, 50, 101, 57, 51, 50, 45, 56, 57, 100, 53, 45, 52, 49, 99, 56, 45, 56, 100, 52, 51, 45, 100, 55, 48, 57, 100, 98, 97, 53, 101, 48, 56, 99]

    static let sinch_application_secret: [UInt8] = [84, 56, 73, 88, 86, 51, 57, 49, 43, 69, 87, 120, 101, 65, 117, 110, 70, 102, 99, 88, 99, 119, 61, 61]
    
    static let sinch_environment_host   = "sandbox.sinch.com"

    // trending website (from public tree)
    static let public_tree_trending_site = "https://whatstrending.com/"
    
    // help website
    static let treem_help_site = "https://help.treemtest.com/"
    
    var device_token : String    = ""
    
    static let max_post_image_resolution: CGFloat = 1024
    
    func setDeviceToken(deviceTokenData : NSData){
        
        let tokenChars = UnsafePointer<CChar>(deviceTokenData.bytes)
        var tokenString = ""
        
        for i in 0 ..< deviceTokenData.length {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        
        self.device_token = tokenString
    }
    
}