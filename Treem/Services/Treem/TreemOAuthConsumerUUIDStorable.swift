//
//  TreemOAuthConsumerUUIDStorable.swift
//  Treem
//
//  Created by Matthew Walker on 10/13/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import Locksmith

class TreemOAuthConsumerUUIDStorable: OAuthTokenStorable, ReadableSecureStorable, CreateableSecureStorable, DeleteableSecureStorable {
    static let sharedInstance = TreemOAuthConsumerUUIDStorable()
    
    // service & account on the keychain
    let service = "Treem"
    let account = "TreemUUID"
    
    private let keyConsumerUUID = "consumerUUID"
    
    private(set) var consumerUUID : String? = nil
    
    // data to store
    var data: [String: AnyObject] {
        var dict : [String: AnyObject] = Dictionary<String, AnyObject>()
        
        if(self.consumerUUID != nil) {
            dict[self.keyConsumerUUID] = self.consumerUUID
        }
        
        return dict
    }
    
    // can receive a new consumer token/key outside of UUID if the UUID persisted
    func setConsumerUUID(consumerUUID: String?) -> LocksmithError {
        // delete prior key in keychain if present
        do {
            #if DEBUG
                print("# Delete Consumer UUID")
            #endif
            
            try self.deleteFromSecureStore()
        }
        catch {}
        
        #if DEBUG
            print("Locksmith error: " + LocksmithError.NoError.rawValue)
        #endif

        if (consumerUUID != nil && !consumerUUID!.isEmpty) {
            self.consumerUUID = consumerUUID

            do {
                #if DEBUG
                    print("# Set Consumer UUID")
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
            self.consumerUUID = nil
        }
        
        #if DEBUG
            print("Locksmith error: " + LocksmithError.NoError.rawValue)
        #endif
        
        return LocksmithError.NoError
    }
    
    func getUUID() -> String? {
        var uuid: String? = nil
        
        if let account = self.readFromSecureStore() {
            if let data = account.data {
                uuid = data[self.keyConsumerUUID] as? String
                
                if let id = uuid {
                    if id.isEmpty {
                        // return nil if empty
                        uuid = nil
                    }
                }
            }
        }
        
        return uuid
    }
    
    func UUIDIsSet() -> Bool {
        let uuid = self.getUUID()
        
        return uuid != nil && !uuid!.isEmpty
    }
}