//
//  WebPageData.swift
//  Treem
//
//  Created by Tracy Merrill on 1/26/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

enum UrlEnd : String {
    case Com = ".com"
    case Net = ".net"
    case Org = ".org"
    case Biz = ".biz"
    case Edu = ".edu"
    case Gov = ".gov"
    
    static let allValues = [UrlEnd.Com,UrlEnd.Net,UrlEnd.Org,UrlEnd.Biz,UrlEnd.Edu,UrlEnd.Gov]
}

class WebPageData: NSObject {
    
    // model properties
    var linkUrl                     : String?        = nil
    var linkTitle                   : String?        = nil
    var linkImage                   : String?        = nil
    var linkDescription             : String?        = nil
    var imageOrigHeight             : String?        = nil
    var imageOrigWidth              : String?        = nil
    
    override init() {}
    
    // load from JSON
    init(data: JSON) {
        super.init()
        
        self.linkUrl                = data["l_url"].string
        self.linkTitle              = data["l_title"].string
        self.linkImage              = data["l_img_url"].string
        self.linkDescription        = data["l_desc"].string
        self.imageOrigHeight        = data["imageOrigHeight"].string
        self.imageOrigWidth         = data["imageOrigWidth"].string
        
        // safer nil conditional checks on each link property
        if (self.linkUrl?.isEmpty == true)           { self.linkUrl = nil }
        if (self.linkTitle?.isEmpty == true)         { self.linkTitle = nil }
        if (self.linkImage?.isEmpty == true)         { self.linkImage = nil }
        if (self.linkDescription?.isEmpty == true)   { self.linkDescription = nil }
    }
}