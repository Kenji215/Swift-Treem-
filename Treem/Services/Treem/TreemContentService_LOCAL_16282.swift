//
//  TreemContentService.swift
//  Treem
//
//  Created by Matthew Walker on 12/10/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import AWSS3
import Kingfisher

class TreemContentService {
    enum ContentTypes: Int {
        case Image = 0
        case Other = -1
        case Video = 1
    }
    
    enum ContentFileExtensions: Int {
        case GIF    = 2
        case JPG    = 0
        case MP4    = 3
        case MOV    = 4
        case MPEG   = 5
        case Other  = -1
        case PNG    = 1
        
        static let cases: Set<String> = [
            "JPG",
            "JPEG",
            "PNG",
            "GIF",
            "MOV",
            "MP4",
            "MPEG"
        ]
        
        static func fromString(fileExtension: String) -> ContentFileExtensions {
            var contentExtension: ContentFileExtensions
            
            switch(fileExtension.uppercaseString) {
            case "GIF"  : contentExtension = ContentFileExtensions.GIF
            case "JPG"  : contentExtension = ContentFileExtensions.JPG
            case "MOV"  : contentExtension = ContentFileExtensions.MOV
            case "MP4"  : contentExtension = ContentFileExtensions.MP4
            case "MPEG" : contentExtension = ContentFileExtensions.MPEG
            case "PNG"  : contentExtension = ContentFileExtensions.PNG
            default     : contentExtension = ContentFileExtensions.Other
            }
            
            return contentExtension
        }
        
        var description : String {
            switch self {
            case .GIF       : return "GIF"
            case .JPG       : return "JPG"
            case .MOV       : return "MOV"
            case .MP4       : return "MP4"
            case .MPEG      : return "MPEG"
            case .PNG       : return "PNG"
            default         : return ""
            }
        }
        
        func isValidExtension() -> Bool {
            return self != .Other
        }
    }
    
    static let sharedInstance = TreemContentService()
    
    static let contentBucketName   = "treemtest"

    static let url                  = "https://content.\(TreemService.baseDomain)/"
    
    // check if repo creds are stored, and if not request them
    func checkRepoCreds(treeSession: TreeSession, complete: (()->())? = nil) {
        let credsStorable = TreemContentCredentialsStorable.sharedInstance
        
        // complete is always called
        //if !credsStorable.credentialsAreStored() {
            self.getRepoCreds(
                treeSession,
                success: {
                    (data) -> Void in
                    
                    let creds = ContentRepoCredentials(data: data)
                    
                    credsStorable.setContentCredentials(creds)
                    
                    complete?()
                },
                failure: {
                    (error, wasHandled) -> Void in
                    
                    complete?()
                }
            )
//        }
//        else {
//            complete?()
//        }
    }
    
    func getContentRepositoryFile(url: NSURL, success: (UIImage? -> ())? = nil) {
        let download = DownloadContentOperation(url: url)
        
        download.completionBlock = {
            dispatch_async(dispatch_get_main_queue(), {
                if let image = download.image {
                    success?(image)
                }
            })
        }
        
        download.start()
    }
    
    //# TODO: Implement
    func getImageDetails(contentID: Int) {
//        let url = self.url + "image/" + String(contentID)
    }
    
    // get content repository credentials
    private func getRepoCreds(treeSession: TreeSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url                 = TreemContentService.url + "creds"
        
        TreemService.sharedInstance.get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    //# TODO: Implement
    func getVideoDetails(contentID: Int) {
//        let url = self.url + "video/" + String(contentID)
    }

    //# TODO: Implement
    func removeImage(contentID: Int) {
//        let url = self.url + "removeimg/" + String(contentID)
    }

    //# TODO: Implement
    func removeVideo(contentID: Int) {
//        let url = self.url + "removevid/" + String(contentID)
    }
}