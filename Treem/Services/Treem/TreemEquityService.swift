//
//  TreemEquityService.swift
//  Treem
//
//  Created by Kevin Novak on 11/2/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class TreemEquityService {
    static let sharedInstance = TreemEquityService()

    private let url = "https://equity.\(TreemService.baseDomain)/"

    func getUserRollout(parameters parameters: Dictionary<String,AnyObject>?, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url = self.url + "rollout/"

        TreemService().get(
            url,
            parameters          : Dictionary<String,AnyObject>(),
            failureCodesHandled : failureCodesHandled,
            success             : success,
            failure             : failure
        )
    }

    func getTopFriends(parameters parameters: Dictionary<String,AnyObject>?, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url = self.url + "friends/"

        TreemService().get(
            url,
            parameters          : parameters,
            failureCodesHandled : failureCodesHandled,
            success             : success,
            failure             : failure
        )
    }
    func getHistoricalData(parameters parameters: Dictionary<String,AnyObject>?, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url = self.url + "history/"

        TreemService().get(
            url,
            parameters          : parameters,
            failureCodesHandled : failureCodesHandled,
            success             : success,
            failure             : failure
        )
    }

    func getRewardLog(parameters parameters: Dictionary<String,AnyObject>?, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url = self.url + "log/"

        TreemService().get(
            url,
            parameters          : parameters,
            failureCodesHandled : failureCodesHandled,
            success             : success,
            failure             : failure
        )
    }
}