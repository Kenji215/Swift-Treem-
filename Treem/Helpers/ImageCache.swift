//
//  ImageCache.swift
//  Treem
//
//  Created by Matthew Walker on 12/22/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import Kingfisher

class ImageCache: Kingfisher.ImageCache {
    static let sharedInstance = ImageCache(name: "ImageCache")

    func getCacheKeyForURL(url: NSURL) -> String {
        return url.absoluteString
    }

    // kingfisher uses absolute url string as key
    func isImageCachedForURL(url: NSURL) -> Bool {
        return self.isImageCachedForKey(self.getCacheKeyForURL(url)).cached
    }
    
    func isCacheKeyValid(cacheKey: String) -> Bool {
        return self.isImageCachedForKey(cacheKey).cached
    }
}