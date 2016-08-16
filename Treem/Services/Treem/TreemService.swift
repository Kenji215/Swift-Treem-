//
//  TreemService.swift
//  Treem
//
//  Created by Matthew Walker on 9/23/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import Locksmith
import OAuthSwift
import SwiftyJSON

typealias TreemServiceSuccessHandler    = (data: JSON) -> Void
typealias TreemServiceFailureHandler    = (error: TreemServiceResponseCode, wasHandled: Bool) -> Void
typealias TreemServiceProgressHandler   = (percentComplete: CGFloat, wasCancelled: Bool) -> Void

class TreemService {
    private enum HTTPRequestType: String {
        case GET    = "GET"
        case POST   = "POST"
        case DELETE = "DELETE"
    }
    
    static let baseDomain = AppSettings.treem_service_domain
    
    var oAuthSwift : OAuth1Swift!

    // check error response code of request, return true if error code handled in function
    private func checkRequestErrorCode(response: TreemServiceResponseCode, failureCodesHandled: Set<TreemServiceResponseCode>?) -> Bool {
        
        var errorHandled = false

        // check error
        switch(response) {
            
        case .InvalidAccessToken, .DisabledOAuthToken:
            errorHandled = true
            
            // invalid access token only
            if let codesHandled = failureCodesHandled {
                if codesHandled.contains(.InvalidAccessToken) || codesHandled.contains(.DisabledOAuthToken) {
                    errorHandled = false
                }
            }
            
            if errorHandled {
                // force user to re-login
                AppDelegate.getAppDelegate().logout(true)
            }
            
        case .InvalidConsumerKey:
            errorHandled = true
            
            if let codesHandled = failureCodesHandled {
                if codesHandled.contains(.InvalidConsumerKey) {
                    errorHandled = false
                }
            }
            
            // force user to re-register device
            AppDelegate.getAppDelegate().deviceReset(errorHandled, showMessage: true)
            
        case .InvalidSignature:
            errorHandled = true
            
            if let codesHandled = failureCodesHandled {
                if codesHandled.contains(.InvalidSignature) {
                    errorHandled = false
                }
            }

            if errorHandled {
                AppDelegate.getAppDelegate().deviceSignatureError()
            }
            
        case .DisabledConsumerKey:
            errorHandled = true
            
            if let codesHandled = failureCodesHandled {
                if codesHandled.contains(.DisabledConsumerKey) {
                    errorHandled = false
                }
            }
            
            // force user to re-register device, perform call regardless if handled (needs to be called)
            AppDelegate.getAppDelegate().deviceDisabled()
            
        case .LockedOut:
            errorHandled = true
            
            if let codesHandled = failureCodesHandled {
                if codesHandled.contains(.LockedOut) {
                    errorHandled = false
                }
            }
            
            // only show alert if not handling in a view
            if errorHandled {
                CustomAlertViews.showCustomAlertView(
                    title   : Localization.sharedInstance.getLocalizedString("locked_out", table: "Common"),
                    message : Localization.sharedInstance.getLocalizedString("locked_out_message", table: "Common")
                )
            }
            
        case .InternalServerError:
            errorHandled = true
            
            if let codesHandled = failureCodesHandled {
                if codesHandled.contains(.InternalServerError) {
                    errorHandled = false
                }
            }
            
            // only show alert if not handling in a view
            if errorHandled {
                CustomAlertViews.showGeneralErrorAlertView()
            }
            
        case .NetworkError:
            errorHandled = true
            
            if let codesHandled = failureCodesHandled {
                if codesHandled.contains(.NetworkError) {
                    errorHandled = false
                }
            }
            
            // only show alert if not handling in a view
            if errorHandled {
                CustomAlertViews.showNoNetworkAlertView()
            }
            
        default:
            // do nothing
            break
        }
        
        return errorHandled
    }
    
    // return true if response code checks out
    private func isValidHTTPResponse(response: NSHTTPURLResponse) -> Bool {
        return response.statusCode >= 200 && response.statusCode < 300
    }
    
    func loadAuthentication(url: String) {
        // retrieve consumer credentials
        let consumerTokens  = TreemOAuthConsumerTokenStorable.sharedInstance.getConsumerTokens()
        
        // load connection object for consumer
        self.oAuthSwift = OAuth1Swift(
            consumerKey     : consumerTokens.0,
            consumerSecret  : consumerTokens.1,
            requestTokenUrl : url,
            authorizeUrl    : url,
            accessTokenUrl  : url
        )
        
        let accessTokens = TreemOAuthUserTokenStorable.sharedInstance.getAccessTokens()
        
        // load access tokens into oauth client if present
        if !accessTokens.0.isEmpty && !accessTokens.1.isEmpty {
            self.oAuthSwift.client.credential.oauth_token        = accessTokens.0
            self.oAuthSwift.client.credential.oauth_token_secret = accessTokens.1
        }
    }
    
    // GET request
    func get(url: String, parameters: [String: AnyObject]?, headers: [String: String]? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        self.request(url, method: .GET, parameters: parameters, headers: headers, failureCodesHandled: failureCodesHandled, success: success, failure: failure)
    }
    
    // POST request
    func post(url: String, json: JSON?, headers: [String: String]? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        var parameters: Dictionary<String,AnyObject> = [:]
        
        if let json = json, jsonString = json.rawString() {
            parameters["d"] = jsonString
        }
        
        self.request(url, method: .POST, parameters: parameters, headers: headers, failureCodesHandled: failureCodesHandled, success: success, failure: failure)
    }
    
    // DELETE request
    func delete(url: String, json: JSON? = nil, headers: [String: String]? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        var parameters: Dictionary<String,AnyObject> = [:]
        
        if let json = json, jsonString = json.rawString() {
            parameters["d"] = jsonString
        }
        
        self.request(url, method: .DELETE, parameters: parameters, headers: headers, failureCodesHandled: failureCodesHandled, success: success, failure: failure)
    }
    
    private func request(url: String, method: OAuthSwiftHTTPRequest.Method, parameters: [String: AnyObject]? = nil, headers: [String: String]? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        // load authentication tokens prior to request
        self.loadAuthentication(url)

        // create empty parameters dictionary if parameters not passed
        let parameters: [String: AnyObject] = parameters ?? [:]
        
        #if DEBUG
            print("\n# \(method.rawValue) HTTP request")
            print(url)
            
            print("Service parameters:")
            if parameters.count > 0 {
                // don't show the long buffer object for content...
                if(url.lowercaseString.indexOf("//content.") >= 0){
                    print("Content buffer is truncated...")
                }
                else{
                    print(parameters)
                }
            }
            else {
                print("nil")
            }
        #endif

        // create empty request headers dictionary if not passed
        var requestHeaders: [String: String] = headers ?? [:]
        
        // append Accept-Language to header
        requestHeaders["Accept-Language"] = Localization.sharedInstance.getCurrentLocaleIdentifier()
        
        #if DEBUG
            print("Header parameters:")
            
            for (key,value) in requestHeaders {
                print(key,value)
            }
        #endif
        
        self.oAuthSwift.client.request(
            url,
            method: method,
            parameters: parameters,
            headers: requestHeaders,
            success: {
                (data: NSData, response: NSHTTPURLResponse) in
                
                // check http response
                if(self.isValidHTTPResponse(response)) {
                    // get request object from JSON data
                    let json            : SwiftyJSON.JSON           = JSON(data: data)
                    let requestResponse : TreemServiceResponse      = TreemServiceResponse(json: json)
                    let responseCode    : TreemServiceResponseCode  = requestResponse.getResponseCode()
                    
                    #if DEBUG
                        print("Service response:")
                        print(json.rawString(NSUTF8StringEncoding, options: NSJSONWritingOptions.init(rawValue: 0))!)
                        print("Service network response code: \(response.statusCode)")
                        print("# end HTTP request\n")
                    #endif
                    
                    // check the response code
                    if(responseCode == TreemServiceResponseCode.Success) {
                        // if successful response past back "data" value
                        dispatch_async(dispatch_get_main_queue()) {
                            success(data: json["data"])
                        }
                    }
                    else {
                        // pass back non-successful response and if error was handled already
                        dispatch_async(dispatch_get_main_queue()) {
                            failure(error: responseCode, wasHandled: self.checkRequestErrorCode(responseCode, failureCodesHandled: failureCodesHandled))
                        }
                    }
                }
                else {
                    #if DEBUG
                        print("Service network error: \(response.statusCode)")
                        print("# end HTTP request\n")
                    #endif
                    
                    let responseCode = (response.statusCode == 500) ? TreemServiceResponseCode.InternalServerError : TreemServiceResponseCode.NetworkError
                    
                    // show general connection error
                    dispatch_async(dispatch_get_main_queue()) {
                        failure(error: responseCode, wasHandled: self.checkRequestErrorCode(responseCode, failureCodesHandled: failureCodesHandled))
                    }
                }
            },
            failure: {
                (error: NSError) -> Void in
                
                #if DEBUG
                    print("Service network error: \(error.code)")
                    print("# end HTTP request\n")
                #endif

                let responseCode = (error.code == 500) ? TreemServiceResponseCode.InternalServerError : TreemServiceResponseCode.NetworkError
                
                // throw general connection error
                dispatch_async(dispatch_get_main_queue()) {
                    failure(error: responseCode, wasHandled: self.checkRequestErrorCode(responseCode, failureCodesHandled: failureCodesHandled))
                }
            }
        )
    }
    
    static func getPagingParameters(parameters: Dictionary<String, AnyObject>, page: Int?, pageSize: Int?) -> Dictionary<String, AnyObject> {
        var params = parameters
        
        if let page = page where page > 1 {
            params["page"] = page
        }
        
        if let pageSize = pageSize where pageSize > 1 {
            params["pagesize"] = pageSize
        }
        
        return params
    }
}