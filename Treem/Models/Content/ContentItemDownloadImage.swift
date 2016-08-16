//
//  ContentItemDownloadImage.swift
//  Treem
//
//  Created by Matthew Walker on 12/16/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class ContentItemDownloadImage : ContentItemDownload {
    var url             : NSURL?    = nil
    var urlId           : String?   = nil
    var width           : Int?      = nil
    var height          : Int?      = nil
    var createDate      : NSDate?   = nil
    var owner           : Bool      = false
    
    override init(data: JSON) {
        self.url        = NSURL.getNSURL(data["stream_url"].string)
        self.urlId      = data["url"].string
        self.width      = data["width"].int
        self.height     = data["height"].int        
        
        self.createDate         = NSDate(iso8601String: data["create_date"].string)
        self.owner              = (data["owner"].intValue == 1) ? true : false
        
        super.init(data: data)
        
        self.contentType = .Image
    }
}