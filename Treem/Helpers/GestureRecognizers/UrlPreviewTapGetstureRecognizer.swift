//
//  UrlPreviewTapGestureRecognizer.swift
//  Treem
//
//  Created by Tracy Merrill on 2/17/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class UrlPreviewTapGestureRecognizer : UITapGestureRecognizer {
    var linkData: WebPageData? = nil
    
    init(target: AnyObject?, action: Selector, data: WebPageData?) {
        self.linkData = data
        
        super.init(target: target, action: action)
    }
}

