//
//  TreemContentServiceUploadManager.swift
//  Treem
//
//  Created by Matthew Walker on 1/7/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class TreemContentServiceUploadManager {
    var uploadID    : Int       = 0
    var partURL     : NSURL?    = nil
    
    var success         : TreemServiceSuccessHandler!
    var failure         : TreemServiceFailureHandler!
    var progress        : TreemServiceProgressHandler? = nil
    var multiStarted    : (() -> ())? = nil
    
    var failureCodesHandled: Set<TreemServiceResponseCode>? = nil
    
    var contentItemUpload: ContentItemUpload!
    
    private var isUploading: Bool = false
    
    private var treeSession: TreeSession

    private let singleFileByteSizeLimit     = 1048576           // anything over 1mb we're going to break into pieces
    private let singleChunkBytesSize        = 1048576           // 1 mb chunks

    private var totalSteps                  :    Int = 0        // number if things that need to be done (for progress)
    private var numOfChunks                 :    Int = 0        // keeps track of how many chunks are left to finish processing
    
    static let maxContentGigaBytes          = 1
    let maxContentBytes                     = 1073741824    // 1gb is the max file size we'll upload
    
    lazy var multipartUploadQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        
        queue.name                          = "Multipart Upload Queue"
        queue.qualityOfService              = .UserInitiated
        queue.maxConcurrentOperationCount   = 5                             // seems to be the "sweet" spot for performance, may adjust when in a web farm
        
        return queue
    }()
    
    init(treeSession: TreeSession, contentItemUpload: ContentItemUpload, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler, progress: TreemServiceProgressHandler?, multiStarted: (()->())?, failureCodesHandled: Set<TreemServiceResponseCode>? = nil) {
        self.treeSession            = treeSession
        self.success                = success
        self.failure                = failure
        self.progress               = progress
        self.multiStarted           = multiStarted
        self.contentItemUpload      = contentItemUpload
        self.failureCodesHandled    = failureCodesHandled
    }
    
    private func isExtensionSupported(fileExtension: String) -> Bool {
        return TreemContentService.ContentFileExtensions.cases.contains(fileExtension.uppercaseString)
    }
    
    private func isOverMaxContentSize(contentItemUpload: ContentItemUpload) -> Bool {
        if let data = contentItemUpload.data {
            return (data.length > self.maxContentBytes)
        }
        
        return false
    }
    
    func startUpload() {
        if !self.isUploading {
            // check extension first
            if contentItemUpload.fileExtension == .Other {
                // return unsupported type error
                self.failure(error: TreemServiceResponseCode.GenericResponseCode2, wasHandled: false)
            }
            
            else if let data = self.contentItemUpload.data {
                // check if data exceeds max size
                if data.length > self.maxContentBytes {
                    // return file too large error
                    self.failure(error: TreemServiceResponseCode.GenericResponseCode3, wasHandled: false)
                }
                else {
                    self.isUploading = true
                    
                    // tell the progress handler we're at 0%
                    self.progress?(percentComplete: CGFloat(0), wasCancelled: false)
                
                    // check total size to determine whether to do a single or multipart upload
                    if data.length > self.singleFileByteSizeLimit {
                        self.initiateMultipartUpload()
                    }
                    else {
                        self.initiateSinglePartUpload()
                    }
                }
            }
            else {
                // return a generic error
                self.failure(error: TreemServiceResponseCode.OtherError, wasHandled: false)
            }
        }
    }

    private func initiateSinglePartUpload() {
        let url = TreemContentService.url + "upload"

        // perform single part upload in the background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            TreemService().post(
                url,
                json: self.contentItemUpload.toJSONForSinglePartUpload(),
                headers: self.treeSession.getTreemServiceHeader(),
                failureCodesHandled: self.failureCodesHandled,
                success: {
                    data in

                    self.isUploading = false
                    
                    // tell the progress handler we're done
                    dispatch_async(dispatch_get_main_queue()) {
                        self.progress?(percentComplete: CGFloat(1), wasCancelled: false)
                    }
                    
                    // call success handler on main thread as there are likely UI updates
                    dispatch_async(dispatch_get_main_queue()) {
                        self.success(data: data)
                    }
                },
                failure: {
                    error, wasHandled in

                    self.isUploading = false
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.failure(error: error, wasHandled: wasHandled)
                    }
                }
            )
        }
    }
    
    private func initiateMultipartUpload() {
        let url = TreemContentService.url + "initmulti"
        
        // start upload in the background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            // tell the caller it has started
            dispatch_async(dispatch_get_main_queue()) {
                self.multiStarted?()
            }
            
            TreemService().post(
                url,
                json: self.contentItemUpload.toJSONForMultiPartUpload(),
                headers: self.treeSession.getTreemServiceHeader(),
                failureCodesHandled: self.failureCodesHandled,
                success: {
                    data in
                    
                    let uploadID = data["u_id"].intValue
                    
                    if uploadID > 0 {
                        // chunk out upload and send parts
                        if let data = self.contentItemUpload.data {
                            
                            // set some properties
                            self.numOfChunks = Int(floor(Float(data.length) / Float(self.singleChunkBytesSize))) + 1
                            self.totalSteps = self.numOfChunks + 1

                            var partNumber      = 1
                            var offset          = 0
                            let length          = data.length
                            
                            repeat {
                                // get the length of the chunk
                                let thisChunkSize = ((length - offset) > self.singleChunkBytesSize) ? self.singleChunkBytesSize : (length - offset);
                                
                                // get the chunk
                                let chunk = data.subdataWithRange(NSMakeRange(offset, thisChunkSize))

                                self.addChunkOperation(chunk
                                    , upload_id: uploadID
                                    , chunkNumber: partNumber)

                                // update the offset
                                offset += thisChunkSize;
                                partNumber += 1
                            } while (offset < length);
                        }
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.failure(error: TreemServiceResponseCode.OtherError, wasHandled: false)
                        }
                    }
                },
                failure: {
                    error, wasHandled in
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.failure(error: error, wasHandled: wasHandled)
                    }
                }
            )
        }
        

    }
    

    private func endMultipartUpload(uploadID: Int) {
        let url = TreemContentService.url +  "endmulti/" + String(uploadID)

        TreemService().post(
            url,
            json: nil,
            headers: self.treeSession.getTreemServiceHeader(),
            failureCodesHandled: self.failureCodesHandled,
            success: {
                (data) -> Void in
            
                self.isUploading = false
                
                // tell the progress handler we're done!
                dispatch_async(dispatch_get_main_queue()) {
                    self.progress?(percentComplete: CGFloat(1), wasCancelled: false)
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.success(data: data)
                }
                
            },
            failure: {
                (error, wasHandled) -> Void in
                
                self.isUploading = false
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.failure(error: error, wasHandled: wasHandled)
                }
            }
        )
    }
    
    private func abortMultiPartUpload(uploadID: Int) {
        let url = TreemContentService.url +  "abortmulti/" + String(uploadID)

        TreemService().delete(
            url,
            json: nil,
            headers: self.treeSession.getTreemServiceHeader(),
            failureCodesHandled: self.failureCodesHandled,
            success: {
                (data) -> Void in
            },
            failure: {
                (error, wasHandled) -> Void in
            }
        )
    }
    
    private func addChunkOperation(chunk: NSData, upload_id: Int, chunkNumber: Int){
        
        let operation = UploadContentOperation(treeSession: self.treeSession
            , uploadID: upload_id
            , partNumber: chunkNumber
            , chunk: chunk
            , onDone: {
                uploadStatus in
                
                if(self.numOfChunks > 0){
                    
                    // if canceled or failed, kill the upload
                    if((uploadStatus == UploadContentStatus.Cancelled) || (uploadStatus == UploadContentStatus.Failed)){
                        self.isUploading = false
                        self.multipartUploadQueue.cancelAllOperations()
                        self.numOfChunks = 0
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.failure(error: TreemServiceResponseCode.OtherError, wasHandled: false)
                        }
                        
                        self.abortMultiPartUpload(upload_id)
                    }
                    else{
                        self.numOfChunks -= 1
                        
                        // upload how far completed we are...
                        let perc = CGFloat(CGFloat(1) - (CGFloat(self.numOfChunks + 1) / CGFloat(self.totalSteps)))
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.progress?(percentComplete: perc, wasCancelled: false)
                        }
                        
                        // if zero than we're done uploading the chunks, call the complete method
                        if(self.numOfChunks == 0){
                            self.endMultipartUpload(upload_id)
                        }
                    }
                }
        })
        
        self.multipartUploadQueue.addOperation(operation)
        
    }
}
