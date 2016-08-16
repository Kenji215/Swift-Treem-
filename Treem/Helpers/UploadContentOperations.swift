//
//  UploadContentOperations.swift
//  Treem
//
//  Created by Matthew Walker on 1/18/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation

class UploadMultipartContent {
    let byteChunks  : [UInt8]!
    
    lazy var uploadQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        
        queue.name                          = "Upload Content Queue"
        queue.qualityOfService              = .UserInteractive
        
        return queue
    }()
    
    init(bytes: [UInt8], chunkSize: Int) {
        self.byteChunks = bytes
    }
}