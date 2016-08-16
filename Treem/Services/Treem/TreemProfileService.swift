//
//  TreemProfileService.swift
//  Treem
//
//  Created by Daniel Sorrell on 12/4/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import libPhoneNumber_iOS

class TreemProfileService {
    static let sharedInstance = TreemProfileService()
    
    private let url = "https://profile.\(TreemService.baseDomain)/"
    
    var currentTreeID           : Int           = 0
    var currentTreeSessionToken : String?       = nil
    
    func getTreeSettings(treeSession: TreeSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url                 = self.url + "user-tree-settings"
        
        TreemService().get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func getSelfProfile(failureCodesHandled: Set<TreemServiceResponseCode>? = nil, parameters: Dictionary<String,AnyObject>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url
        let treeSession         = TreeSession(treeID: 1, token: nil)
        
        TreemService().get(
            url,
            parameters              : parameters,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func getSelfProfileAvatarName(failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let parameters: Dictionary<String,AnyObject>? = ["fields": "id,first,last,avatar"]
        
        self.getSelfProfile(failureCodesHandled, parameters: parameters, success: success, failure: failure)
    }
    
    func getProfile(userID: Int, treeSession: TreeSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url + userID.description
        
        TreemService().get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func setTreeSettings(treeSession: TreeSession, treeSettings: TreeSettings, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        
        let url                 = self.url + "user-tree-settings"
        let postJson            = treeSettings.toJSON()
        
        TreemService().post(
            url,
            json: postJson,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
        
    }
    
    func setSelfProfile(profileSettings: Profile, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url
        let treeSession         = TreeSession(treeID: 1, token: nil)
        let postJson            = profileSettings.toJSON()
        
        TreemService().post(
            url,
            json: postJson,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
    
    }
    
    func changeAccessInformation(phoneNumber: String, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url         = self.url + "change-access-info"
        let treeSession = TreeSession(treeID: 1, token: nil)
        var json:JSON   = [:]
        
        json["phone"].stringValue = NBPhoneNumberUtil().getE164FormattedString(phoneNumber)
        
        TreemService().post(
            url,
            json                : json,
            headers             : treeSession.getTreemServiceHeader(),
            success             : success,
            failure             : failure
        )
    }
    
    func verifyAccessInformation(phoneNumber:String, verificationCode:String, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url                 = self.url + "verify-access-info"
        let treeSession         = TreeSession(treeID: 1, token: nil)
        var json:JSON           = [:]
        
        json["phone"].stringValue               = NBPhoneNumberUtil().getE164FormattedString(phoneNumber)
        json["v_code"].stringValue              = verificationCode
        
        TreemService().post(
            url,
            json                : json,
            headers             : treeSession.getTreemServiceHeader(),
            success             : success,
            failure             : failure
        )
    }

}
