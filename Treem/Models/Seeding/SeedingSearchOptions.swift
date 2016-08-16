//
//  SeedingSearchOptions.swift
//  Treem
//
//  Created by Matthew Walker on 11/20/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

class SeedingSearchOptions {
    var matchFirstName          : Bool = true
    var matchLastName           : Bool = true
    var matchEmail              : Bool = true
    var matchUsername           : Bool = true
    var matchPhone              : Bool = true

    var searchFriendStatus      : Bool = true
    var searchInvitedStatus     : Bool = true
    var searchPendingStatus     : Bool = true
    var searchNotFriendsStatus  : Bool = true

	var onBranchOnly			: Bool = false

    var includeContacts         : Bool = true
    
    func areDefaultOptionsSelected(searchType: SeedingSearchViewController.SearchType) -> Bool {
        return self.areDefaultMatchOptionsSelected(searchType) && self.areDefaultStatusOptionsSelected(searchType)
    }
    
    func areDefaultMatchOptionsSelected(searchType: SeedingSearchViewController.SearchType) -> Bool {
		return matchFirstName && matchLastName && matchEmail && matchPhone && matchUsername
    }
    
    func areDefaultStatusOptionsSelected(searchType: SeedingSearchViewController.SearchType) -> Bool {
        if [SeedingSearchViewController.SearchType.SelectBranchFriends, SeedingSearchViewController.SearchType.Tagging, SeedingSearchViewController.SearchType.SharingBranch].contains(searchType) {
            return searchFriendStatus
        }
        
        return searchFriendStatus && searchInvitedStatus && searchPendingStatus && searchNotFriendsStatus && !onBranchOnly
    }
    
    func setDefaultStatusOptionsForTagged() {
        self.searchFriendStatus     = true
        self.searchInvitedStatus    = false
        self.searchPendingStatus    = false
        self.searchNotFriendsStatus = false
		self.onBranchOnly           = true
    }
}

func ==(lhs: SeedingSearchOptions, rhs: SeedingSearchOptions) -> Bool {
    return  lhs.matchFirstName          == rhs.matchFirstName &&
            lhs.matchLastName           == rhs.matchLastName &&
            lhs.matchEmail              == rhs.matchEmail &&
            lhs.matchPhone              == rhs.matchPhone &&
            lhs.matchUsername           == rhs.matchUsername &&
            lhs.searchFriendStatus      == rhs.searchFriendStatus &&
            lhs.searchInvitedStatus     == rhs.searchInvitedStatus &&
            lhs.searchNotFriendsStatus  == rhs.searchNotFriendsStatus &&
			lhs.searchPendingStatus     == rhs.searchPendingStatus &&
			lhs.onBranchOnly			== rhs.onBranchOnly &&
            lhs.includeContacts         == rhs.includeContacts
}