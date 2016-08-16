//
//  ImageLoader.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/29/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import Kingfisher

class ImageLoader {
    static let sharedInstance = ImageLoader()

    func loadPublicImage(imgUrl: String?, success: ((UIImage) -> ()), failure: (() ->())?=nil) {
        
        if let url_string = imgUrl, url = NSURL(string: url_string) {
            if ImageCache.sharedInstance.isImageCachedForURL(url) {
                
                #if DEBUG
                    print("Retrieve image from cache: \(url.absoluteString)")
                #endif
                
                // get image from the cache
                let options: KingfisherOptionsInfo = [
                    .ForceRefresh,
                    .CallbackDispatchQueue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
                ]
                
                // retrieve image from the cache
                ImageCache.sharedInstance.retrieveImageForKey(ImageCache.sharedInstance.getCacheKeyForURL(url), options: options, completionHandler: {
                    (image: UIImage?, cachetype: CacheType!) -> () in

                    if let img = image {
                        dispatch_async(dispatch_get_main_queue(), {
                            success(img)
                        })
                    }
                    else {
                        // if we failed to load from the cache for some reason, get it from the url
                        self.downloadFromWeb(url, success: success, failure: failure)
                    }
                })
            }
            else {
                self.downloadFromWeb(url, success: success, failure: failure)
            }
        }
        else {
            failure?()
        }
    }
    
    private func downloadFromWeb(url: NSURL, success: ((UIImage) -> ()), failure: (() ->())?=nil){
        
        #if DEBUG
            print("Download image: \(url.absoluteString)")
        #endif
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        
            if let data = NSData(contentsOfURL: url), image = UIImage(data:data) {
                ImageCache.sharedInstance.storeImage(image
                    , originalData: data
                    , forKey: ImageCache.sharedInstance.getCacheKeyForURL(url)
                    , toDisk: true
                    , completionHandler:
                    {
                        dispatch_async(dispatch_get_main_queue(), {
                            success(image)
                        })
                })
            }
            else {
                dispatch_async(dispatch_get_main_queue(), {
                    failure?()
                })
            }
        })
    }
    
}
