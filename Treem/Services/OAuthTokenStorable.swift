//
//  OAuthTokenStorable.swift
//  Treem
//
//  Created by Matthew Walker on 9/28/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Locksmith

public protocol OAuthTokenStorable: SecureStorable, AccountBasedSecureStorable  {
    // The service to which the type belongs
    var service: String { get }
}

public protocol OAuthTokenStorableResultType: GenericPasswordSecureStorable, SecureStorableResultType, AccountBasedSecureStorableResultType {}

public extension OAuthTokenStorableResultType {
    var service: String {
        return resultDictionary[String(kSecAttrService)] as! String
    }
}

public extension SecureStorable where Self : OAuthTokenStorable {
    // store the properties used to query the keychain, query should only have the basic search parameters
    private var genericOAuthTokenSearchPropertyDictionary: [String: AnyObject] {
        var dictionary = [String: AnyObject?]()
        
        dictionary[String(kSecAttrService)]     = service
        dictionary[String(kSecClass)]           = LocksmithSecurityClass.GenericPassword.rawValue
        
        let toMergeWith = [
            accountSecureStoragePropertyDictionary
        ]
        
        for dict in toMergeWith {
            dictionary = Dictionary(initial: dictionary, toMerge: dict)
        }
        
        return Dictionary(withoutOptionalValues: dictionary)
    }
    
    // store additional properties not used in the keychain query but need to be stored
    private var genericOAuthTokenStoragePropertyDictionary: [String: AnyObject] {
        var dictionary = [String: AnyObject?]()

        dictionary[String(kSecAttrAccessible)]  = LocksmithAccessibleOption.WhenUnlockedThisDeviceOnly.rawValue

        dictionary = Dictionary(initial: dictionary, toMerge: genericOAuthTokenSearchPropertyDictionary)

        return Dictionary(withoutOptionalValues: dictionary)
    }
}

struct GenericOAuthTokenResult: OAuthTokenStorableResultType {
    var resultDictionary: [String: AnyObject]
}

public extension ReadableSecureStorable where Self : OAuthTokenStorable {
    var asReadableSecureStoragePropertyDictionary: [String: AnyObject] {
        var old = genericOAuthTokenSearchPropertyDictionary
        
        old[String(kSecReturnData)]         = true
        old[String(kSecMatchLimit)]         = kSecMatchLimitOne
        old[String(kSecReturnAttributes)]   = kCFBooleanTrue
        
        return old
    }
}

public extension ReadableSecureStorable where Self : OAuthTokenStorable {
    func readFromSecureStore() -> OAuthTokenStorableResultType? {
        do {
            let result = try performSecureStorageAction(performReadRequestClosure, secureStoragePropertyDictionary: asReadableSecureStoragePropertyDictionary)
            return GenericOAuthTokenResult(resultDictionary: result!)
        } catch {
            return nil
        }
    }
}

public extension CreateableSecureStorable where Self : OAuthTokenStorable {
    var asCreateableSecureStoragePropertyDictionary: [String: AnyObject] {
        var old = genericOAuthTokenStoragePropertyDictionary // on create all data is stored
        
        old[String(kSecValueData)] = NSKeyedArchiver.archivedDataWithRootObject(data)
        
        return old
    }
}

public extension CreateableSecureStorable where Self : OAuthTokenStorable {
    func createInSecureStore() throws {
        try performSecureStorageAction(performCreateRequestClosure, secureStoragePropertyDictionary: asCreateableSecureStoragePropertyDictionary)
    }
}

public extension DeleteableSecureStorable where Self : OAuthTokenStorable {
    var asDeleteableSecureStoragePropertyDictionary: [String: AnyObject] {
        return genericOAuthTokenSearchPropertyDictionary
    }
}

public extension DeleteableSecureStorable where Self : OAuthTokenStorable {
    func deleteFromSecureStore() throws {
        try performSecureStorageAction(performDeleteRequestClosure, secureStoragePropertyDictionary: asDeleteableSecureStoragePropertyDictionary)
    }
}
