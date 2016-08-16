//
//  TreemAuthorizationService.swift
//  Treem
//
//  Created by Matthew Walker on 10/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class TreemAuthorizationService {
    static let sharedInstance = TreemAuthorizationService()

    private let url = "https://authorization.\(TreemService.baseDomain)/"
    
    func getChallengeQuestion(previousQuestionID: String?, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url         = self.url + (previousQuestionID ?? "")
        
        TreemService().get(
            url,
            parameters          : Dictionary<String,AnyObject>(),
            failureCodesHandled : failureCodesHandled,
            success             : success,
            failure             : failure
        )
    }
    
    func authorizeApp(questionID: String, answerID: String, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url         = self.url
        var json:JSON   = [:]
        
        json["id"].stringValue      = questionID
        json["a_id"].stringValue    = answerID
        
        TreemService().post(
            url,
            json    : json,
            success : success,
            failure : failure
        )
    }}