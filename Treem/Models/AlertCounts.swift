//
//  AlertCounts.swift
//  Treem
//
//  Created by Tracy Merrill on 4/27/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON


class AlertCount: NSObject {
    
    var totalAlerts : Int = 0
    var unreadAlerts : Int = 0
    var totalNonRequestAlerts : Int = 0
    var unreadNonRequestAlerts : Int = 0
    var totalFriendAlerts : Int = 0
    var unreadFriendAlerts : Int = 0
    var totalBranchAlerts : Int = 0
    var unreadBranchAlerts : Int = 0
    
    init (data: JSON) {
        super.init()
        
        self.totalAlerts = data["total"].intValue
        self.unreadAlerts = data["unread"].intValue
        self.totalNonRequestAlerts = data["total_nonrequest"].intValue
        self.unreadNonRequestAlerts = data["unread_nonrequest"].intValue
        self.totalFriendAlerts = data["friend"].intValue
        self.unreadFriendAlerts = data["friend_unread"].intValue
        self.totalBranchAlerts = data["branch"].intValue
        self.unreadBranchAlerts = data["branch_unread"].intValue

    }
}