//
//  TreemOAuthUserTokenStorable.swift
//  Treem
//
//  Created by Matthew Walker on 9/25/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Locksmith

class TreemOAuthUserTokenStorable: OAuthTokenStorable, ReadableSecureStorable, CreateableSecureStorable, DeleteableSecureStorable {
    static let sharedInstance = TreemOAuthUserTokenStorable()
    
    // service & account on the keychain
    let service = "Treem"
    let account = "TreemUser"

    // store both the user's access token as well as the user's access token secret
    private(set) var accessToken         : String? = nil
    private(set) var accessTokenSecret   : String? = nil

    private let keyAccessToken          = "accessToken"
    private let keyAccessTokenSecret    = "accessTokenSecret"
    
    // data to store
    var data: [String: AnyObject] {
        var dict : [String: AnyObject] = Dictionary<String, AnyObject>()
        
        if(self.accessToken != nil && self.accessTokenSecret != nil) {
            dict[keyAccessToken]         = self.accessToken
            dict[keyAccessTokenSecret]   = self.accessTokenSecret
        }

        return dict
    }
    
    // clear access tokens
    func clearAccessTokens() -> LocksmithError {
        return self.setAccessToken(accessToken: nil, accessTokenSecret: nil)
    }
    
    // get access tokens (public, secret)
    func getAccessTokens() -> (String, String) {
        var accessToken        : String = ""
        var accessTokenSecret  : String = ""
        
        if let consumerTokenStorable = self.readFromSecureStore() {
            if let data = consumerTokenStorable.data {
                accessToken         = data[keyAccessToken]          as! String
                accessTokenSecret   = data[keyAccessTokenSecret]    as! String
            }
        }
        
        return (accessToken,accessTokenSecret)
    }
    
    // both token and token secret need to be set when setting one or the other
    func setAccessToken(accessToken accessToken: String?, accessTokenSecret: String?) -> LocksmithError {
        // delete prior key in keychain if present
        do {
            #if DEBUG
            print("# Delete User Tokens")
            #endif
                
            try self.deleteFromSecureStore()
        }
        catch {
            #if DEBUG
            print("Locksmith error: " + LocksmithError.Undefined.rawValue)
            #endif
        }
        
        if (accessToken != nil && accessTokenSecret != nil) {
            self.accessToken        = accessToken
            self.accessTokenSecret  = accessTokenSecret
            
            do {
                #if DEBUG
                print("# Set User Tokens")
                #endif
                
                try self.createInSecureStore()
            
            } catch {
                #if DEBUG
                print("Locksmith error: " + LocksmithError.Undefined.rawValue)
                #endif
                
                return LocksmithError.Undefined
            }
        }
        else {
            self.accessToken        = nil
            self.accessTokenSecret  = nil
        }
        
        #if DEBUG
        print("Locksmith error: " + LocksmithError.NoError.rawValue)
        #endif
            
        return LocksmithError.NoError
    }
    
    // true if user access tokens set
    func tokensAreSet() -> Bool {
        let accessTokens = self.getAccessTokens()
        
        return !accessTokens.0.isEmpty && !accessTokens.1.isEmpty
    }
}
