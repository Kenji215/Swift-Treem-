//
//  SeedingTableViewDelegate.swift
//  Treem
//
//  Created by Matthew Walker on 10/29/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

protocol SeedingMembersTableViewDelegate {
    // called when users in table view is selected/deselected
    func selectedUsersUpdated(users: OrderedSet<User>)
    func deselectedUsersUpdated(users: OrderedSet<User>)
    func saveActionOccurred(addedUsers: OrderedSet<User>, removedUsers: OrderedSet<User>)

    func getBranchID() -> Int

    // called when users in the table view have been changed
    func usersUpdated(users: OrderedSet<User>)

    func viewProfile(userID: Int)

    func giveWarningMessage()

    func initiallyHighlighted(user: User) -> Bool
}

extension SeedingMembersTableViewDelegate {
    // default empty implementations
    func selectedUsersUpdated(users: OrderedSet<User>) {}
    func deselectedUsersUpdated(users: OrderedSet<User>) {}
    func saveActionOccurred(addedUsers: OrderedSet<User>, removedUsers: OrderedSet<User>) {}
    func getBranchID() -> Int { return CurrentTreeSettings.sharedInstance.currentBranchID }

    func usersUpdated(users: OrderedSet<User>) {}
    func viewProfile(userID: Int) {}

    func giveWarningMessage() {}

    func initiallyHighlighted(user: User) -> Bool { return false }
}