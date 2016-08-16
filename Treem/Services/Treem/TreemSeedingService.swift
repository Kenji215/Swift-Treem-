//
//  TreemSeedingService.swift
//  Treem
//
//  Created by Matthew Walker on 10/28/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class TreemSeedingService {
    static let sharedInstance = TreemSeedingService()

    private let url = "https://seeding.\(TreemService.baseDomain)/"

    func getBranchMembers(treeSession: TreeSession, existing: Bool, search: String = "", searchOptions: SeedingSearchOptions? = nil, page: Int? = nil, pageSize: Int? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        self.getBranchMembersSpecificBranch(treeSession, branchID: treeSession.currentBranchID, existing: existing, search: search, searchOptions: searchOptions, page: page, pageSize: pageSize, failureCodesHandled: failureCodesHandled, success: success, failure: failure)
    }

    func getBranchMembersSpecificBranch(treeSession: TreeSession, branchID: Int, existing: Bool, search: String = "", searchOptions: SeedingSearchOptions? = nil, page: Int? = nil, pageSize: Int? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        let url = getUrlWithSearchPath(existing, trunk: false, branchID: branchID, search: search)

        var parameters: Dictionary<String,AnyObject> = Dictionary<String,AnyObject>()

        parameters = TreemService.getPagingParameters(parameters, page: page, pageSize: pageSize)
        parameters = self.getSearchParameters(parameters, search: search, searchType: existing ? .BranchNew : .BranchExisting, options: searchOptions)

        TreemService().get(
            url,
            parameters              : parameters,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func getTrunkMembers(treeSession: TreeSession, search: String = "", searchOptions: SeedingSearchOptions? = nil, page: Int? = nil, pageSize: Int? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil,success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url                 = getUrlWithSearchPath(true, trunk: true, search: search)

        var parameters: Dictionary<String,AnyObject> = [:]
        
        parameters = TreemService.getPagingParameters(parameters, page: page, pageSize: pageSize)
        parameters = self.getSearchParameters(parameters, search: search, searchType: .Trunk , options: searchOptions)
        
        TreemService().get(
            url,
            parameters              : parameters,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    private func getUrlWithSearchPath(existing: Bool, trunk: Bool, branchID: Int = 0, search: String) -> String {
        var path : String = self.url
        
        // check for trunk
        if trunk {
            path += "trunk/"
        }
        // else check if particular branch
        else if branchID > 0 {
            path += String(branchID) + "/"
        }
        
        // check if new or existing
        if existing {
            path += "existing"
        }
        else {
            path += "new"
        }
        
        return path
    }

    func searchContacts(treeSession: TreeSession, contacts: [UserContact], search: String = "", searchOptions: SeedingSearchOptions? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url                 = self.getSearchPostURL(self.url + "contacts", search: search, searchType: .PhoneContacts, options: searchOptions)

        var contactsJSON: [JSON] = []
        
        for contact in contacts {
            if let contactJSON = contact.toJSON() {
                contactsJSON.append(contactJSON)
            }
        }
        
        // check if any contacts can be cross referenced in server
        if contactsJSON.count > 0 {
            TreemService().post(
                url,
                json: JSON(contactsJSON),
                headers: treeSession.getTreemServiceHeader(),
                failureCodesHandled: failureCodesHandled,
                success: success,
                failure: failure
            )
        }
        else {
            // if no contacts could be cross referenced on server pass back empty array
            success(data: JSON([]))
        }
    }

    //KN: New with the seeding rework
    func searchUsers(treeSession: TreeSession, contacts: [UserContact]? = nil, search: String = "", searchOptions: SeedingSearchOptions? = nil, page: Int? = nil, pageSize: Int? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        //seeding.domain.com/search/branch_id?search=search_term
        var url = self.url + "search" + (treeSession.currentBranchID > 0 ? ("/" + String(treeSession.currentBranchID)) : "")

        url = self.getSearchPostURL(url, search: search, searchType: .NewSearch, options: searchOptions, page: page, pageSize: pageSize)

        var contactsJSON : [JSON] = []
        if (contacts != nil) {
            for contact in contacts! {
                if let contactJSON = contact.toJSON() {
                    contactsJSON.append(contactJSON)
                }
            }
        }

        TreemService().post(
            url,
            json: JSON(contactsJSON),
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
    }

    func setUsers(treeSession: TreeSession, branchID: Int, users: [UserAdd], failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        let url         = self.url + (branchID > 0 ? String(branchID) : "trunk")
        
        var addUsersJSON: [JSON] = []
        
        for addUser in users {
            if let addUserJSON = addUser.toJSON() {
                addUsersJSON.append(addUserJSON)
            }
        }
        
        TreemService().post(
            url,
            json: JSON(addUsersJSON),
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
    }

    func trimUsers(treeSession: TreeSession, branchID: Int, users: [UserRemove], failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        let url         = self.url + (branchID > 0 ? "trim/" + String(branchID) : "cut")
        
        var removeUsersJSON: [JSON] = []
        
        for removeUser in users {
            if let removeUserJSON = removeUser.toJSON() {
                removeUsersJSON.append(removeUserJSON)
            }
        }
        
        TreemService().delete(
            url,
            json: JSON(removeUsersJSON),
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
    }
    
    private func getSearchParameters(parameters: Dictionary<String,AnyObject>, search: String?, searchType: SeedingSearchViewController.SearchType, options: SeedingSearchOptions?, page: Int? = nil, pageSize: Int? = nil) -> Dictionary<String,AnyObject> {
        
        let hasSearch           = (search != nil && !search!.isEmpty)
        var updatedParameters   = parameters
        
        if hasSearch {
            updatedParameters["search"] = search
        }
        
        if let options = options {
            if !options.areDefaultStatusOptionsSelected(searchType) {
                var statuses: [String] = []
                
                if options.searchFriendStatus {
                    statuses.append(String(User.FriendStatus.Friends.rawValue))
                }
                
                if options.searchInvitedStatus {
                    statuses.append(String(User.FriendStatus.Invited.rawValue))
                }
                
                if options.searchNotFriendsStatus {
                    statuses.append(String(User.FriendStatus.NotFriends.rawValue))
                }
                
                if options.searchPendingStatus {
                    statuses.append(String(User.FriendStatus.Pending.rawValue))
                }

                if statuses.count > 0 {
                    updatedParameters["status"] = statuses.joinWithSeparator(",")
                }
            }
            
            if hasSearch {
                if !options.areDefaultMatchOptionsSelected(searchType) {
                    var matchingOptions: [String] = []
                    
                    if options.matchFirstName {
                        matchingOptions.append("first")
                    }
                    
                    if options.matchLastName {
                        matchingOptions.append("last")
                    }

                    if options.matchEmail {
                        matchingOptions.append("email")
                    }

                    if options.matchUsername {
                        matchingOptions.append("username")
                    }


                    if options.matchPhone {
                        matchingOptions.append("phone")
                    }
                    
                    if matchingOptions.count > 0 {
                        updatedParameters["options"] = matchingOptions.joinWithSeparator(",")
                    }
                }
            }

			if (options.onBranchOnly) {
				updatedParameters["branchOnly"] = true
			}
        }

        if (page != nil && page > 0) {
            updatedParameters["page"] = page
        }

        if (pageSize != nil) {
            updatedParameters["pagesize"] = pageSize
        }
        
        return updatedParameters
    }


    // Build a querystring for the request, given the parameters
    // The service has an issue with Swift's implementation of parameters within the request objects for POST calls, so they need to be written into the URL instead.
    private func getSearchPostURL(url: String, search:String, searchType: SeedingSearchViewController.SearchType, options: SeedingSearchOptions?, page: Int? = nil, pageSize: Int? = nil) -> String {
        let parameters  = self.getSearchParameters(Dictionary<String, AnyObject>(), search: search, searchType: searchType, options: options, page: page, pageSize: pageSize)
        let searchUrl   = url

        var queryString = ""
        for (key, val) in parameters {
            queryString += (queryString == "" ? "?" : "&") +  String(key) + "=" + String(val).encodingForURLQueryValue()!
        }

        return searchUrl + queryString
    }
}