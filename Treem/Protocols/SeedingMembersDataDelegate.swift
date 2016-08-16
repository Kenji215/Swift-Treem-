//
//  SeedingDataDelegate.swift
//  Treem
//
//  Created by Matthew Walker on 11/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

protocol SeedingMembersDataDelegate {
    // called to load users
    func loadData(filter: String?, completion: () -> OrderedSet<User>)
}

extension SeedingMembersDataDelegate {
    // default empty implementations
    func loadData(filter: String? = nil, completion: () -> OrderedSet<User>) {}
}