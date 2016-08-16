//
//  MediaTapGestureRecognizer.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/18/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class MediaTapGestureRecognizer : UITapGestureRecognizer {
    var contentURL      : NSURL?    = nil
    var contentID       : Int?      = nil
    var contentURLId    : String?   = nil
    var contentOwner    : Bool      = false
    var contentType     : TreemContentService.ContentTypes? = nil
    
    init(target: AnyObject?, action: Selector, contentURL: NSURL?, contentURLId: String?, contentID: Int?, contentType: TreemContentService.ContentTypes?, contentOwner: Bool) {
        self.contentURL     = contentURL
        self.contentURLId   = contentURLId
        self.contentID      = contentID
        self.contentType    = contentType
        self.contentOwner   = contentOwner
        
        super.init(target: target, action: action)
    }
}
