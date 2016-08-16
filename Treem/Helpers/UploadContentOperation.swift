//
//  UploadContentOperations.swift
//  Treem
//
//  Created by Matthew Walker on 1/18/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

enum UploadContentStatus: Int {
    case New            = 0
    case Uploading      = 1
    case Cancelled      = 2
    case Failed         = 3
    case Success        = 4
}

class UploadContentOperation: NSOperation {
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
    
    var status      : UploadContentStatus = .New
    let treeSession : TreeSession!
    let uploadID    : Int
    let partNumber  : Int
    let chunk       : NSData
    var complete    : ((UploadContentStatus) -> ())? = nil
    var error       : NSError? = nil
    
    init(treeSession: TreeSession, uploadID: Int, partNumber: Int, chunk: NSData, onDone: ((UploadContentStatus) -> ())) {
        self.treeSession    = treeSession
        self.uploadID       = uploadID
        self.partNumber     = partNumber
        self.chunk          = chunk
        self.complete       = onDone
    }
    
    
    override func start() {
        // check if operation should proceed
        if self.finished || self.cancelled {
            self.done(.Cancelled)
            
            return
        }
        
        self._executing = true
        
        // send chunk
        self.sendMultipartChunk()
    }
    
    
    deinit {
        self.done(.Cancelled)
    }
    
    private func done(status: UploadContentStatus) {
        self.status = status
        
        self._executing = false
        self._finished  = true
        
        self.complete?(status)
    }
    
    private func sendMultipartChunk() {
        let url         = TreemContentService.url +  "sendmulti/\(self.uploadID)/\(self.partNumber)"
        var json: JSON  = [:]
        
        json["buffer"].stringValue      = self.chunk.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue:0))
        json["buffer_size"].intValue    = self.chunk.length
        
        TreemService().post(
            url,
            json: json,
            headers: self.treeSession.getTreemServiceHeader(),
            success: {
                (data) -> Void in
                
                #if DEBUG
                    print("Chunk: " + String(self.partNumber) + " completed")
                #endif
                
                // success
                self.done(.Success)
            },
            failure: {
                (error, wasHandled) -> Void in

                // failed
                self.done(.Failed)
            }
        )
    }
}