//
//  ContentItem.swift
//  Treem
//
//  Created by Matthew Walker on 12/16/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class ContentItemDownload: ContentItemDelegate {
    var contentID       : Int = 0
    var contentType     : TreemContentService.ContentTypes? = nil
    
    private var _fileExtension: TreemContentService.ContentFileExtensions? = nil
    
    var fileExtension: TreemContentService.ContentFileExtensions? {
        get {
            // if previously stored
            if self._fileExtension != nil {
                return self._fileExtension
            }
            
            // retrieve from url if present
            if let url = self.contentURL {
                return TreemContentService.ContentFileExtensions.fromString(url.absoluteString.getPathNameExtension())
            }
            
            return nil
        }
        set {
            self._fileExtension = newValue
        }
    }
    
    private(set) var contentURL      : NSURL?       = nil
    private(set) var contentURLId    : String?      = nil
    private(set) var contentWidth    : CGFloat      = 0
    private(set) var contentHeight   : CGFloat      = 0
    
    init(data: JSON) {
        // return content needs valid url
        if let stringUrl = data["c_stream_url"].string, contentURL = NSURL(string: stringUrl) {
            self.contentURL = contentURL
            
            self.contentURLId = data["c_url"].string
        }
        
        self.contentID      = data["c_id"].intValue
        self.contentType    = TreemContentService.ContentTypes(rawValue: data["c_type"].intValue)
        self.contentWidth   = CGFloat(data["c_width"].intValue)
        self.contentHeight  = CGFloat(data["c_height"].intValue)
    }
    
    init(videoObj: ContentItemDownloadVideo){
        self.contentID      = videoObj.contentID
        self.contentType    = TreemContentService.ContentTypes.Video
        
        // the thumbnail url is the default url
        self.contentURL     = videoObj.thumbnailURL
        self.contentURLId   = videoObj.thumbnailURLId
        
        if let width    = videoObj.thumbnailWidth { self.contentWidth = CGFloat(width) }
        if let height   = videoObj.thumbnailHeight { self.contentHeight = CGFloat(height) }
    }
    
    init(imageObj: ContentItemDownloadImage){
        self.contentID      = imageObj.contentID
        self.contentType    = TreemContentService.ContentTypes.Image
        self.contentURL     = imageObj.url
        self.contentURLId   = imageObj.urlId
        
        if let width    = imageObj.width { self.contentWidth = CGFloat(width) }
        if let height   = imageObj.height { self.contentHeight = CGFloat(height) }
    }
}