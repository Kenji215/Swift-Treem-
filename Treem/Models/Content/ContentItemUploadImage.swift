//
//  ContentItemUploadImage.swift
//  Treem
//
//  Created by Matthew Walker on 1/3/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

class ContentItemUploadImage: ContentItemUpload {
    var image       : UIImage?      = nil
    var profile     : Bool?         = nil
    
    // initialization fails if image type can't be converted to NSData
    init?(fileExtension: TreemContentService.ContentFileExtensions, image: UIImage, profile: Bool? = nil) {
        if let data = ContentItemUploadImage.getDataFromImage(fileExtension, image: image) {
            super.init(fileExtension: fileExtension, data: data)
            
            self.contentType = .Image
            
            // image specific properties
            self.image          = image
            self.profile        = profile
        }
        else {
            super.init()
            
            self.contentType = .Image
            
            // if image couldn't be created
            return nil
        }
    }
    
    // get data from image object
    static private func getDataFromImage(fileExtension: TreemContentService.ContentFileExtensions, image: UIImage) -> NSData? {
        if fileExtension == .JPG {
            return UIImageJPEGRepresentation(image, 0.95)
        }
        else if fileExtension == .PNG {
            return UIImagePNGRepresentation(image)
        }
        
        return nil
    }
    
    override func toJSONForSinglePartUpload() -> JSON {
        var json = super.toJSONForSinglePartUpload()
        
        if let profile = self.profile{
            json["profile"].intValue = (profile == true) ? 1 : 0
        }
        
        return json
    }
}
