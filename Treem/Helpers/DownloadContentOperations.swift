//
//  DownloadContentOperations
//  Treem
//
//  Created by Matthew Walker on 1/14/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation

class DownloadContentOperations {
    // map downloads to particular index path
    private lazy var downloads = [NSIndexPath: [Int: DownloadContentOperation]]()
    
    lazy var downloadQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        
        queue.name                          = "Index Path Download Queue"
        queue.qualityOfService              = .UserInteractive
        
        return queue
    }()
    
    func cancelAllDownloads() {
        for download in self.downloads {
            self.cancelDownloads(download.0)
        }
    }
    
    func cancelDownloads(indexPath: NSIndexPath) {
        // if downloads occurred on index path
        if let indexDownloads = self.downloads[indexPath] {
            self.downloads[indexPath] = nil
            
            // iterate through all downloads occurring on index path and cancel if active
            for (_, download) in indexDownloads {
                // if not previously downloaded or cancelled, cancel the operation
                if download.status == .New || download.status == .Downloading {
                    download.cancel()
                    download.status = .Cancelled
                }
            }
        }
    }
    
    func startDownload(indexPath: NSIndexPath, downloadContentOperation: DownloadContentOperation) {
        if self.downloads[indexPath] == nil {
            self.downloads[indexPath] = [:]
        }
        
        self.downloads[indexPath]![downloadContentOperation.hashValue] = downloadContentOperation
        
        self.downloadQueue.addOperation(downloadContentOperation)
    }
}