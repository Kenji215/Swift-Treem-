//
//  Rollout.swift
//  Treem
//
//  Created by Kevin Novak on 11/4/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class Rollout {
    var user_id         : Int       = 0
    var user_first_last : String    = ""
    var points          : Int       = 0
    var change_today    : Int       = 0
    var percentile      : Double    = 0

    init() {}

    init (json: JSON) {
        self.user_id            = json["user_id"].intValue
        self.user_first_last    = json["user_first_last"].stringValue
        self.points             = json["points"].intValue
        self.change_today       = json["change_today"].intValue
        self.percentile         = json["percentile"].doubleValue
    }

    init (_user_id: Int, _user_first_last: String, _points: Int, _change_today: Int, _percentile: Double)
    {
        self.user_id            = _user_id
        self.user_first_last    = _user_first_last
        self.points             = _points
        self.change_today       = _change_today
        self.percentile         = _percentile
    }
}