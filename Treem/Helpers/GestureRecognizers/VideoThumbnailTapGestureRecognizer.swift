//
//  VideoThumbnailTapGestureRecognizer.swift
//  Treem
//
//  Created by Matthew Walker on 1/6/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class VideoThumbnailTapGestureRecognizer : UITapGestureRecognizer {
    var videoURL: NSURL
    
    init(target: AnyObject?, action: Selector, videoURL: NSURL) {
        self.videoURL = videoURL
        
        super.init(target: target, action: action)
    }
}