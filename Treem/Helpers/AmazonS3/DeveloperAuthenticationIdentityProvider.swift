//
//  DeveloperAuthenticationIdentityProvider.swift
//  Treem
//
//  Created by Matthew Walker on 12/21/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import AWSCore

class DeveloperAuthenticationIdentityProvider : AWSAbstractCognitoIdentityProvider {
    private var _providerName   : String = ""
    private var _token          : String = ""

    override var providerName: String {
        get {
            return _providerName
        }
    }
    
    override var token: String {
        get {
            return self._token
        }
        set {
            self._token = newValue
        }
    }
    
    init(providerName: String, repoCreds: ContentRepoCredentials, regionType: AWSRegionType, accountId: String!) {
        let logins         = [providerName: repoCreds.token!]
        
        super.init(regionType: regionType, identityId: repoCreds.id!, accountId: accountId, identityPoolId: repoCreds.poolId!, logins: logins)
        
        self.identityId     = repoCreds.id!
        self.token          = repoCreds.token!
        self._providerName  = providerName
    }
    
    override func getIdentityId() -> AWSTask! {
        // identity id already returned from Treem Services
        return AWSTask(result: nil)
    }
    
    override func refresh() -> AWSTask! {
        // token already returned from Treem Services
        return AWSTask(result: nil)
    }
}