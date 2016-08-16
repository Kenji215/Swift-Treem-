//
//  TreemContentCredentialsStorable
//  Treem
//
//  Created by Matthew Walker on 12/11/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import AWSS3

class TreemContentCredentialsStorable {
    static let sharedInstance           = TreemContentCredentialsStorable()
    
    private let keyContentRepoId       = "contentRepoId"
    private let keyContentRepoToken    = "contentRepoToken"
    private let keyContentPoolId       = "contentRepoPoolId"
    private let keyContentExpires      = "contentRepoTokenExpires"
    
    private let userDefaults           = NSUserDefaults.standardUserDefaults()
    
    func credentialsAreStored() -> Bool {
        if let creds = self.getContentRepoCredentials() {
            return !(creds.id ?? "").isEmpty && !(creds.token ?? "").isEmpty && !(creds.poolId ?? "").isEmpty
        }
        
        return false
    }
    
    func getContentRepoCredentials() -> ContentRepoCredentials? {
        let id      = self.userDefaults.objectForKey(self.keyContentRepoId)     as? String
        let token   = self.userDefaults.objectForKey(self.keyContentRepoToken)  as? String
        let poolId  = self.userDefaults.objectForKey(self.keyContentPoolId)     as? String
        let expires = self.userDefaults.objectForKey(self.keyContentExpires)    as? NSDate
        
        // if not all necessary properties are set return nil
        if id == nil || token == nil || poolId == nil {
            return nil
        }
        
        let repoCredentials = ContentRepoCredentials()
        
        repoCredentials.id         = id
        repoCredentials.token      = token
        repoCredentials.poolId     = poolId
        repoCredentials.expires    = expires

        return repoCredentials
    }
    
    func setContentCredentials(repoCredentials: ContentRepoCredentials) {
        // make sure all necessary properties are set
        if !(repoCredentials.id ?? "").isEmpty && !(repoCredentials.token ?? "").isEmpty && !(repoCredentials.poolId ?? "").isEmpty {
            self.userDefaults.setObject(repoCredentials.id, forKey: self.keyContentRepoId)
            self.userDefaults.setObject(repoCredentials.token, forKey: self.keyContentRepoToken)
            self.userDefaults.setObject(repoCredentials.poolId, forKey: self.keyContentPoolId)
            self.userDefaults.setObject(repoCredentials.expires, forKey: self.keyContentExpires)
        }
    }
}