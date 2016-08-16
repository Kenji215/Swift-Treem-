//
//  DownloadContentOperation
//  Treem
//
//  Created by Matthew Walker on 1/14/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import AWSS3
import Kingfisher

enum DownloadContentStatus: Int {
    case New            = 0
    case Downloading    = 1
    case Cancelled      = 2
    case Failed         = 3
    case Success        = 4
}

class DownloadContentOperation: NSOperation {
    var status      : DownloadContentStatus = .New
    let url         : NSURL!
    var error       : NSError?  = nil
    var image       : UIImage?  = nil
    var cacheKey    : String!
    var dataTask    : NSURLSessionDataTask? = nil
    
    var _executing: Bool = false {
        willSet { // KVO compliance
            self.willChangeValueForKey("isExecuting")
        }
        didSet {
            self.didChangeValueForKey("isExecuting")
        }
    }
    
    var _finished: Bool = false {
        willSet { // KVO compliance
            self.willChangeValueForKey("isFinished")
        }
        didSet {
            self.didChangeValueForKey("isFinished")
        }
    }
    
    init?(url: NSURL, cacheKey: String?) {
        self.url        = url
        self.cacheKey   = cacheKey ?? url.absoluteString // use provided cache key or default to url (which may be temporary)
        
        super.init()
        
        // make sure url is filled out
        if url.absoluteString.isEmpty {
            return nil
        }
    }
    
    // always allow concurrency
    override var asynchronous: Bool {
        return true
    }
    
    override var executing: Bool {
        return self._executing
    }
    
    override var finished: Bool {
        return self._finished
    }
    
    override func start() {
        // check if operation should proceed
        if self.finished || self.cancelled {
            self.done(.Cancelled)
            
            return
        }

        self._executing = true

        // check if file has already been cached
        if ImageCache.sharedInstance.isCacheKeyValid(self.cacheKey) {
            #if DEBUG
            print("Retrieve from cache: \(url.absoluteString)")
            #endif

            if self.cancelled {
                self.done(.Cancelled)
            }
            else {
                let options: KingfisherOptionsInfo = [
                    .CallbackDispatchQueue(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0))
                ]
                
                // retrieve image from the cache
                ImageCache.sharedInstance.retrieveImageForKey(self.cacheKey, options: options, completionHandler: {
                    (image: UIImage?, cachetype: CacheType!) -> () in
                    
                    if !self.cancelled {
                        if let image = image {
                            self.image = image
                        }
                        
                        self.done(.Success)
                    }
                    else {
                        self.done(.Cancelled)
                    }
                })
            }
        }
        // if not cached, get repo credentials for request, and retrieve file from server
        else {
            #if DEBUG
            print("Content Request: \(url.absoluteString)")
            #endif
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: self.url)) {
                data, response, error in
                
                if error != nil {
                    self.done(.Cancelled)
                }
                
                if let data = data {
                    #if DEBUG
                        print("Success AWSS3 Load: " + self.url.absoluteString + "\n")
                    #endif
                    
                    // cache image (if valid) for potential later reuse
                    if let image = UIImage(data: data) {
                        ImageCache.sharedInstance.storeImage(image, originalData: data, forKey: self.cacheKey, toDisk: true, completionHandler: {
                            
                            if !self.cancelled {
                                self.image = image
                                
                                self.done(.Success)
                            }
                            else {
                                self.done(.Cancelled)
                            }
                        })
                    }
                    else {
                        self.done(.Failed)
                    }
                }
            }
            
            task.resume()
        }
    }

    deinit {
        self.done(.Cancelled)
    }
    
    private func done(status: DownloadContentStatus) {
        self.status = status
        
        // if object deallocated, cancel the current url connection if set
        if let task = self.dataTask {
            task.cancel()
        }
        
        self._executing = false
        self._finished  = true
    }
}