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
    
    private let contentBucketName   = "treemtest"

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
        // filter out empty urls
        if url.absoluteString.isEmpty {
            return
        }
        
        // check if file has already been cached
        if ImageCache.sharedInstance.isImageCachedForURL(url) {
            print("Retrieve from cache: \(url.absoluteString)")
            
            // get image from the cache
            let options: KingfisherManager.Options = (forceRefresh: true, lowPriority: false, cacheMemoryOnly: false, shouldDecode: true, queue: dispatch_get_main_queue(), scale: 1.0)
            
            // retrieve image from the cache
            ImageCache.sharedInstance.retrieveImageForKey(ImageCache.sharedInstance.getCacheKeyForURL(url), options: options, completionHandler: {
                (image: UIImage?, cachetype: CacheType!) -> () in
                
                if let image = image {
                    success?(image)
                }
            })
        }
            // if not cached, get repo credentials for request
        else {
            print("Content Request: \(url.absoluteString)")
            
            self.getRepoData(url, success: {
                repoData in
                
                // cache image (if valid) for potential later reuse
                if let image = UIImage(data: repoData) {
                    ImageCache.sharedInstance.storeImage(image, originalData: repoData, forKey: ImageCache.sharedInstance.getCacheKeyForURL(url), toDisk: true, completionHandler: {
                        _ in
                        
                        // run on main thread as there are likely UI changes in success closure
                        dispatch_async(dispatch_get_main_queue(), {
                            success?(image)
                        })
                    })
                }

            })
        }
    }
    
    // returns raw data from repo
    func getContentRepositoryData(url: NSURL, success: (NSData -> ())? = nil) {
        // filter out empty urls
        if url.absoluteString.isEmpty {
            return
        }
        
        self.getRepoData(url, success: success)
    }
    
    private func getRepoData(url: NSURL, success: (NSData -> ())? = nil){
        
        if let repoCreds = TreemContentCredentialsStorable.sharedInstance.getContentRepoCredentials() {
            // load AmazonS3 defaults
            let region = AWSRegionType.USEast1
            
            let identityProvider    = DeveloperAuthenticationIdentityProvider(providerName: "awscognito.treemtest.com", repoCreds: repoCreds, regionType: region, accountId: nil)
            let credentialsProvider = AWSCognitoCredentialsProvider(regionType: region, identityProvider: identityProvider, unauthRoleArn: nil, authRoleArn: nil)
            let configuration       = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: credentialsProvider)
            
            AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
            
            let getRequest          = AWSS3GetObjectRequest()
            let path                = url.path!
            let objectKey: String!  = path.substringFromIndex(path.startIndex.advancedBy(1)) // remove the preceeding forward slash from path
            
            getRequest.bucket       = self.contentBucketName
            getRequest.key          = objectKey
            
            let transferManager = AWSS3.defaultS3()
            
            transferManager.getObject(getRequest).continueWithBlock({
                (task) -> AnyObject! in
                
                if let error = task.error {
                    #if DEBUG
                        dispatch_async(dispatch_get_main_queue(), {
                            print("Error AWSS3 Load: " + getRequest.key!.debugDescription + ". " + error.description + "\n")
                        })
                    #endif
                }
                else if let exception = task.exception {
                    #if DEBUG
                        dispatch_async(dispatch_get_main_queue(), {
                            print("Exception AWSS3 Load: " + getRequest.key!.debugDescription + ". " + exception.description + "\n")
                        })
                    #endif
                }
                else if let data = task.result?.body as? NSData {
                    #if DEBUG
                        print("Success AWSS3 Load: " + getRequest!.key!.debugDescription + "\n")
                    #endif
                    
                    success?(data)
                }
                
                return nil
            })
        }
    }
    
    func getImageDetails(contentID: Int, treeSession: TreeSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = TreemContentService.url + "image/" + contentID.description
        
        TreemService.sharedInstance.get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
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
    
    func getVideoDetails(contentID: Int, treeSession: TreeSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = TreemContentService.url + "video/" + contentID.description
        
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
    func removeImage(contentID: Int) {
//        let url = self.url + "removeimg/" + String(contentID)
    }

    //# TODO: Implement
    func removeVideo(contentID: Int) {
//        let url = self.url + "removevid/" + String(contentID)
    }
}