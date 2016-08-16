//
//  TreemAlertService.swift
//  Treem
//
//  Created by Kevin Novak on 12/4/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class TreemAlertService {
    static let sharedInstance = TreemAlertService()

    private let url = "https://alerts.\(TreemService.baseDomain)/"
    
    func getAlertCounts(treeSession: TreeSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url = self.url + "count/"
        
        TreemService().get(
            url,
            parameters: nil,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
    }

    func getAlerts(treeSession: TreeSession, page: Int? = nil, pageSize: Int? = nil, parameters: Dictionary<String,AnyObject>? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url = self.url + "alert/"

        var parameters = parameters ?? Dictionary<String,AnyObject>()

        parameters = TreemService.getPagingParameters(parameters, page: page, pageSize: pageSize)

        TreemService().get(
            url,
            parameters              : parameters,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }

    func setAlertRead(treeSession: TreeSession, alerts: Set<Alert>, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        var alertsJSON: [JSON] = []
        
        for alert in alerts {
            if let alertReadJSON = alert.toJSON() {
                alertsJSON.append(alertReadJSON)
            }
        }

        let url = self.url + "viewed/"

        TreemService().post(
            url,
            json: JSON(alertsJSON),
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
    }
    
    func clearAlert(treeSession: TreeSession, alerts: Set<Alert>, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        var alertsJSON: [JSON] = []
        
        for alert in alerts {
            if let alertClearJSON = alert.toJSON() {
                alertsJSON.append(alertClearJSON)
            }
        }
        
        let url = self.url + "clear/"
        
        TreemService().delete(
            url,
            json: JSON(alertsJSON),
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
        
    }
}