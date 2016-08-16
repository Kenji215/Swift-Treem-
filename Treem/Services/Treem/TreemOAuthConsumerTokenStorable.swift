//
//  TreemOAuthConsumerTokenStorable.swift
//  Treem
//
//  Created by Matthew Walker on 10/13/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Locksmith

class TreemOAuthConsumerTokenStorable: OAuthTokenStorable, ReadableSecureStorable, CreateableSecureStorable, DeleteableSecureStorable {
    static let sharedInstance = TreemOAuthConsumerTokenStorable()
    
    // service & account on the keychain
    let service = "Treem"
    let account = "TreemConsumer"
    
    private let keyConsumerToken        = "consumerToken"
    private let keyConsumerTokenSecret  = "consumerTokenSecret"
    
    // store both the consumer's access token as well as the consumer's access token secret
    private(set) var consumerToken          : String? = nil
    private(set) var consumerTokenSecret    : String? = nil
    
    // data to store/update consumer token
    var data: [String: AnyObject] {
        var dict : [String: AnyObject] = Dictionary<String, AnyObject>()
        
        if(self.consumerToken != nil && self.consumerTokenSecret != nil) {
            dict[keyConsumerToken]         = self.consumerToken
            dict[keyConsumerTokenSecret]   = self.consumerTokenSecret
        }
        
        return dict
    }
    
    // clear access tokens
    func clearConsumerTokens() -> LocksmithError {
        return self.setConsumerToken(consumerToken: nil, consumerTokenSecret: nil)
    }
    
    func getConsumerTokens() -> (key: String, secret: String) {
        var consumerKey     : String = ""
        var consumerSecret  : String = ""
        
        // get current UUID
        let consumerUUID = TreemOAuthConsumerUUIDStorable.sharedInstance.getUUID()
        
        // if no current UUID
        if consumerUUID == nil {
            // clear consumer tokens if UUID can't be retrieved (consumer tokens will default to app tokens)
            TreemOAuthConsumerTokenStorable.sharedInstance.clearConsumerTokens()
        }
        // if current UUID, check device specific consumer credentials
        else {
            let consumerTokens = self.getDeviceSpecificConsumerTokens()
            
            consumerKey     = consumerTokens.0
            consumerSecret  = consumerTokens.1 + consumerUUID!
        }
        
        // get app defaults if no device specific consumer credentials set
        if consumerKey.isEmpty || consumerSecret.isEmpty {
            consumerKey     = Encryption.sharedInstance.getObfuscatedKeyWithClassTypes(AppSettings.treemConsumerKey, className: "Treem.TreeViewController", className2: "Treem.AlertsViewController", className3: "Treem.SignupVerificationViewController")
            consumerSecret  = Encryption.sharedInstance.getObfuscatedKeyWithClassTypes(AppSettings.treemConsumerSecret, className: "Treem.BranchViewController", className2: "Treem.SignupPhoneViewController", className3: "Treem.TreeAddFormViewController")
        }
        
        return (consumerKey,consumerSecret)
    }
    
    private func getDeviceSpecificConsumerTokens() -> (key: String, secret: String) {
        var consumerKey     : String = ""
        var consumerSecret  : String = ""
        
        if let consumerTokenStorable = self.readFromSecureStore() {
            if let data = consumerTokenStorable.data {
                consumerKey     = data[keyConsumerToken]        as! String
                consumerSecret  = data[keyConsumerTokenSecret]  as! String
            }
        }
        
        return (consumerKey, consumerSecret)
    }
    
    // both token and token secret need to be set when setting one or the other
    func setConsumerToken(consumerToken consumerToken: String?, consumerTokenSecret: String?) -> LocksmithError {
        // delete prior key in keychain if present
        do {
            #if DEBUG
                print("# Delete Consumer Tokens")
            #endif
            
            try self.deleteFromSecureStore()
        }
        catch {}
        
        if (consumerToken != nil && consumerTokenSecret != nil) {
            self.consumerToken        = consumerToken
            self.consumerTokenSecret  = consumerTokenSecret
            
            do {
                #if DEBUG
                    print("# Set Consumer Tokens")
                #endif
                
                try self.createInSecureStore()
            }
            catch {
                #if DEBUG
                    print("Locksmith error: " + LocksmithError.Undefined.rawValue)
                #endif
                
                return LocksmithError.Undefined
            }
        }
        else {
            self.consumerToken        = nil
            self.consumerTokenSecret  = nil
        }
        
        #if DEBUG
            print("Locksmith error: " + LocksmithError.NoError.rawValue)
        #endif
        
        return LocksmithError.NoError
    }
    
    func deviceSpecificTokensAreSet() -> Bool {
        let consumerTokens = self.getDeviceSpecificConsumerTokens()
        
        return !consumerTokens.0.isEmpty && !consumerTokens.1.isEmpty
    }
}

