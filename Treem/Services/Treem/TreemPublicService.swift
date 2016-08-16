//
//  TreemPublicService.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/28/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import libPhoneNumber_iOS

class TreemPublicService {
    static let sharedInstance = TreemPublicService()
    
    private let url = "https://public.\(TreemService.baseDomain)/" 
    
    func getEntities(page: Int? = nil, pageSize: Int? = nil, exploreId: Int? = nil, search: String?, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url = self.url + "entities" + ((exploreId != nil) ? "/" + exploreId!.description : "")
        
        var parameters = Dictionary<String,AnyObject>()
        
        // add pagination params
        parameters = TreemService.getPagingParameters(parameters, page: page, pageSize: pageSize)
        
        // request only the desired branch properties
        parameters["search"] = search
        
        TreemService().get(
            url,
            parameters              : parameters,
            headers                 : nil,
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func setEntity(treeSession: TreeSession, entity: PublicEntity, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url = self.url + "userentity" + ((entity.public_link_id > 0) ? "/" + String(entity.public_link_id) : "")
        var json: JSON

        json = entity.entityUpdatePropertiesToJSON()
        
        TreemService().post(
            url,
            json                    : json,
            headers                 : treeSession.getTreemServiceHeader(),
            success                 : success,
            failure                 : failure
        )
    }
    
    func deleteEntities(treeSession: TreeSession, deleteEntityLinkID: Int64, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        if deleteEntityLinkID > 0 {
            let url = self.url + String(deleteEntityLinkID)
            
            TreemService().delete(
                url,
                headers     : treeSession.getTreemServiceHeader(),
                success     : success,
                failure     : failure
            )
        }
    }
}
