//
//  ContentItemVideo.swift
//  Treem
//
//  Created by Matthew Walker on 12/16/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class ContentItemDownloadVideo : ContentItemDownload {
    var videoURL        : NSURL? = nil
    var thumbnailURL    : NSURL? = nil
    var thumbnailURLId  : String? = nil
    var thumbnailWidth  : Int? = nil
    var thumbnailHeight : Int? = nil
    var createDate      : NSDate? = nil
    var owner           : Bool = false
    
    override init(data: JSON) {
        self.videoURL           = NSURL.getNSURL(data["v_url"].string)
        self.thumbnailURL       = NSURL.getNSURL(data["t_stream_url"].string)
        self.thumbnailURLId     = data["t_url"].string
        self.thumbnailWidth     = data["t_width"].int
        self.thumbnailHeight    = data["t_height"].int
        self.createDate         = NSDate(iso8601String: data["create_date"].string)
        self.owner              = (data["owner"].intValue == 1) ? true : false
        
        super.init(data: data)
        
        self.contentType = .Video
    }
    
}