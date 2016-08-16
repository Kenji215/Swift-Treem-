//
//  TreemBranchService.swift
//  Treem
//
//  Created by Matthew Walker on 9/30/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class TreemBranchService {
    static let sharedInstance = TreemBranchService()
    
    private let url = "https://branches.\(TreemService.baseDomain)/"
    
    // get user branches
    func getUserBranches(treeSession: TreeSession, parameters: Dictionary<String,AnyObject>?, parentBranchID: Int? = nil, responseCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        var url = self.url
        
        // append branch ID if looking for a particular branch
        if let parentID = parentBranchID {
            if parentID > 0 {
                url += String(parentID)
            }
        }
        
        var parameters = parameters ?? Dictionary<String,AnyObject>()
        
        // request only the desired branch properties
        parameters["fields"] = "id,name,color,position,icon,url,ex_type,children"

        TreemService().get(
            url,
            parameters              : parameters,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : responseCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    // set user branch
    func setUserBranch(treeSession: TreeSession, branch: Branch, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        var url = self.url
        var json: JSON
        
        // if updating a branch, append the id to the url and add update settings
        if branch.id > 0 {
            url += String(branch.id)
            json = branch.branchUpdatePropertiesToJSON()
        }
        // add a new branch and add branch settings
        else {
            json = branch.branchNewPropertiesToJSON(treeSession.treeID)
        }

        TreemService().post(
            url,
            json                    : json,
            headers                 : treeSession.getTreemServiceHeader(),
            success                 : success,
            failure                 : failure
        )
    }
    
    // delete user branch
    func deleteUserBranch(treeSession: TreeSession, deleteBranchID: Int, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        if deleteBranchID > 0 {
            let url = self.url + String(deleteBranchID)
            
            TreemService().delete(
                url,
                headers     : treeSession.getTreemServiceHeader(),
                success     : success,
                failure     : failure
            )
        }
    }
    
    // move user branch
    func moveUserBranch(treeSession: TreeSession, branch: Branch, toParentID: Int, toBranchPosition: BranchPosition, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        // move is updating an existing branch only to a valid parent
        if branch.id > 0 && toParentID > -1 {
            let url                 = self.url + String(branch.id)
            let json                = branch.branchMovePropertiesToJSON(treeSession.treeID, newParentID: toParentID, newPosition: toBranchPosition)
            
            TreemService().post(
                url,
                json                    : json,
                headers                 : treeSession.getTreemServiceHeader(),
                success                 : success,
                failure                 : failure
            )
        }
    }


    /* Sharing branches */
    func shareBranch(treeSession: TreeSession, branchID: Int, recipients: [Int], success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url = self.url + String(branchID) + "/share"

        TreemService().post(
            url,
            json                    : JSON(recipients),
            headers                 : treeSession.getTreemServiceHeader(),
            success                 : success,
            failure                 : failure
        )


    }

    func acceptShare(treeSession: TreeSession, shareID: Int, placementInfo: Branch, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url = self.url + "share/" + String(shareID)
        let json = placementInfo.branchPlacementToJSON()

        TreemService().post(
            url,
            json                    : json,
            headers                 : treeSession.getTreemServiceHeader(),
            success                 : success,
            failure                 : failure
        )

    }

    func declineShare(treeSession: TreeSession, alerts: Set<Alert>, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url = self.url + "share/decline"
        
        var alertsJSON: [JSON] = []
        
        for alert in alerts {
            if let alertClearJSON = alert.toJSON() {
                alertsJSON.append(alertClearJSON)
            }
        }

        TreemService().post(
            url,
            json                    : JSON(alertsJSON),
            headers                 : treeSession.getTreemServiceHeader(),
            success                 : success,
            failure                 : failure
        )

    }


    /* End sharing branches */
}