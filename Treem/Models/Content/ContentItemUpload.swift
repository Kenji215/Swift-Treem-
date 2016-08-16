//
//  ContentItemUpload.swift
//  Treem
//
//  Created by Matthew Walker on 12/16/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

enum ContentItemOrientation: Int {
    case Unrecognized               = 0
    case LandscapeLeft              = 1
    case LandscapeRight             = 2
    case LandscapePortrait          = 3
    case LandscapePortraitInverted  = 4
}

class ContentItemUpload: ContentItemDelegate {
    var contentID       : Int = 0
    var contentType     : TreemContentService.ContentTypes? = nil
    var fileExtension   : TreemContentService.ContentFileExtensions? = nil
    var data            : NSData? = nil
    var orientation     : ContentItemOrientation? = nil
    
    // local file references
    var fileURL : NSURL?    = nil
    
    init() {}
    
    init(fileExtension: TreemContentService.ContentFileExtensions, data: NSData) {
        self.fileExtension  = fileExtension
        self.data           = data
    }
    
    init(fileExtension: TreemContentService.ContentFileExtensions, fileURL: NSURL) {
        self.fileExtension  = fileExtension
        self.data           = NSData(contentsOfURL: fileURL)
    }
    
    func toJSONForSinglePartUpload() -> JSON {
        var json:JSON = [:]
        
        if let data = self.data {
            json["buffer"].stringValue      = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            json["buffer_size"].intValue    = data.length
        }
        
        if let fileExtension = self.fileExtension {
            json["type"].intValue = fileExtension.rawValue
        }
        
        if let orientation = self.orientation {
            json["orientation"].intValue = orientation.rawValue
        }

        return json
    }
    
    func toJSONForMultiPartUpload() -> JSON {
        var json:JSON = [:]
        
        if let fileExtension = self.fileExtension {
            json["type"].intValue = fileExtension.rawValue
        }
        
        if let orientation = self.orientation {
            json["orientation"].intValue = orientation.rawValue
        }
        
        return json
    }
    
    static func loadContentItems(data: JSON) -> [ContentItemDelegate]? {
        var items : [ContentItemDelegate]? = []
        
        for (_, postData) in data {
            
            // populate object based on content type and add to heterogenous array
            let contentType = TreemContentService.ContentTypes(rawValue: postData["c_type"].int ?? -1)
            
            if contentType == .Video {
                items!.append(ContentItemDownloadVideo(data: postData))
            }
            else if contentType == .Image {
                items!.append(ContentItemDownloadImage(data: postData))
            }
            
        }
        
        if(items!.count < 1){
            items = nil
        }
        
        return items
    }
}