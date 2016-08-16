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
    
    //static let contentBucketName   = "treemtest"

    static let url = "https://content.\(TreemService.baseDomain)/"
    
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
    
    func getContentRepositoryFile(url: NSURL, cacheKey: String?, success: (UIImage? -> ())? = nil) {
        if let download = DownloadContentOperation(url: url, cacheKey: cacheKey) {
            download.completionBlock = {
                dispatch_async(dispatch_get_main_queue(), {
                    if let image = download.image {
                        success?(image)
                    }
                })
            }

            download.start()
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
            
            let identityProvider    = DeveloperAuthenticationIdentityProvider(providerName: AppSettings.aws_cognito_provider_name, repoCreds: repoCreds, regionType: region, accountId: nil)
            let credentialsProvider = AWSCognitoCredentialsProvider(regionType: region, identityProvider: identityProvider, unauthRoleArn: nil, authRoleArn: nil)
            let configuration       = AWSServiceConfiguration(region: AWSRegionType.USEast1, credentialsProvider: credentialsProvider)
            
            AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
            
            let getRequest          = AWSS3GetObjectRequest()
            let path                = url.path!
            let objectKey: String!  = path.substringFromIndex(path.startIndex.advancedBy(1)) // remove the preceeding forward slash from path
            
            getRequest.bucket       = AppSettings.aws_s3_bucket_name
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
        
        TreemService().get(
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
        
        TreemService().get(
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
        
        TreemService().get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    

    func removeImage(contentID: Int, treeSession: TreeSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = TreemContentService.url + "removeimg/" + String(contentID)
        
        TreemService().delete(
            url,
            json                    : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func removeVideo(contentID: Int, treeSession: TreeSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = TreemContentService.url + "removevid/" + String(contentID)
        
        TreemService().delete(
            url,
            json                    : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
}