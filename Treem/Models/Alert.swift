//
//  Alert.swift
//  Treem
//
//  Created by Kevin Novak on 12/4/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class Alert: NSObject, TableViewCellModelType {
    var alertId         : Int = 0
    var sourceId        : Int = 0
    var created         : NSDate? = nil
    var from_user       : User? = nil
    var reason          : Reasons? = nil
    var alert_viewed    : Bool? = true
    var inAppAlert      : Bool = false
    var inAppAlertId    : String? = nil

    var allRowsIndex: Int = 0

    enum Reasons : Int {
        case PENDING_FRIEND_REQUEST     = 0
        case ACCEPTED_FRIEND_REQUEST    = 1
        case ACCEPTED_FRIEND_INVITE     = 2
        case POST_REPLY                 = 3
        case POST_REACTION              = 4
        case POST_SHARE                 = 5
        case POST_ABUSE_SENT            = 6
        case POST_ABUSE_REVOKED         = 7
        case COMMENT_REPLY              = 8
        case TAGGED_POST                = 9
        //some chat alerts take up types 10 and 11
        case BRANCH_SHARE               = 12
        case POST_REPLY_REACTION        = 13
        
        // this is purely for DB record retrieval
        case NON_REQUEST_ALERTS         = 99
        
        case POST_UPLOAD_FINISHED       = 100
        case CHAT_UPLOAD_FINISHED       = 101
        case REPLY_UPLOAD_FINISHED      = 102
    }
    
    init (data: JSON) {
        super.init()

        self.alertId = data["a_id"].intValue
        self.sourceId = data["s_id"].intValue
        self.created = NSDate(iso8601String: data["created"].string)
        self.from_user = User(data: data["fr_usr"])
        self.reason = Reasons(rawValue: data["reason"].intValue)
        self.alert_viewed = data["viewed"].boolValue
    }

    init (reason: Reasons, id: Int) {
        self.reason = reason
        self.sourceId = id
    }
    
    static func getAlertsFromData(data:JSON, nonRequestAlerts: Bool = true) -> (alerts: OrderedSet<Alert>, users: Dictionary<Int,User>) {
        var alerts = OrderedSet<Alert>()
        var users = Dictionary<Int, User>()

        for (_, alertData) in data {
            let alert = Alert(data: alertData)

            alerts.insert(alert)
            users[alert.from_user!.id] = alert.from_user
        }

        if nonRequestAlerts {
            return self.combineWithInAppAlerts((alerts: alerts, users: users))
        }
        else{
            return (alerts: alerts, users:users)
        }
    }

    private static func combineWithInAppAlerts(serverAlerts: (alerts: OrderedSet<Alert>, users: Dictionary<Int,User>)) -> (alerts: OrderedSet<Alert>, users: Dictionary<Int,User>) {
        var rObj = serverAlerts
        let rAlerts = rObj.alerts
        
        if var inAppAlerts = InAppNotifications.sharedInstance.getInAppAlerts(){
            inAppAlerts.append(rAlerts)
            rObj.alerts = inAppAlerts
        }
        
        return rObj;
    }
    
    func getReasonText (fromName: String) -> String {
        var reasonText : String = ""

        if let reason : Reasons = self.reason {
            var resource_name : String = ""
            
            switch (reason) {
                case .ACCEPTED_FRIEND_REQUEST:  resource_name = "ACCEPTED_FRIEND_REQUEST"
                case .PENDING_FRIEND_REQUEST:   resource_name = "PENDING_FRIEND_REQUEST"
                case .ACCEPTED_FRIEND_INVITE:   resource_name = "ACCEPTED_FRIEND_INVITE"
                case .POST_REPLY:               resource_name = "POST_REPLY"
                case .POST_REACTION:            resource_name = "POST_REACTION"
                case .POST_SHARE:               resource_name = "POST_SHARE"
                case .POST_ABUSE_SENT:          resource_name = "POST_ABUSE_SENT"
                case .POST_ABUSE_REVOKED:       resource_name = "POST_ABUSE_REVOKED"
                case .COMMENT_REPLY:            resource_name = "COMMENT_REPLY"
                case .TAGGED_POST:              resource_name = "TAGGED_POST"
                case .BRANCH_SHARE:             resource_name = "BRANCH_SHARE"
                case .POST_UPLOAD_FINISHED:     resource_name = "POST_UPLOAD_FINISHED"
                case .CHAT_UPLOAD_FINISHED:     resource_name = "CHAT_UPLOAD_FINISHED"
                case .POST_REPLY_REACTION:      resource_name = "POST_REPLY_REACTION"
                case .REPLY_UPLOAD_FINISHED:    resource_name = "REPLY_UPLOAD_FINISHED"
                
                // not used
                case .NON_REQUEST_ALERTS:       resource_name = "NON_REQUEST_ALERTS"
            }

            reasonText = String(format: Localization.sharedInstance.getLocalizedString(resource_name, table: "Alerts") , fromName)

        }
        else {
            reasonText = ""
        }

        return reasonText;
    }

    func getResponseButton(buttonNum: Int) -> (text: String, action: String)? {
        if let reason = self.reason {
            var resource_name = ""

            switch (reason) {
                case .PENDING_FRIEND_REQUEST, .BRANCH_SHARE:
                    switch (buttonNum) {
                        case 1: resource_name = "accept"
                        case 2: resource_name = "decline"
                        default: break
                    }
                default:
                    break
            }

            if (!resource_name.isEmpty) {
                let resource_text = Localization.sharedInstance.getLocalizedString(resource_name, table: "Alerts")

                return (resource_text, resource_name + ":")
            }
        }

        return nil
    }

    func getUserFullName() -> String {
        var fromName : String = ""
        
        if let name = self.from_user?.getFullName() {
            fromName = name
        }
        
        return fromName
    }
    
    func toJSON() -> JSON? {
        var json:JSON = [:]
        
        // if id available use id
        if (alertId > 0) {
            json["a_id"].intValue = alertId
            
            json["viewed"].intValue = Int(self.alert_viewed!)
            
            json["s_id"].intValue = sourceId
            
            return json
        }
        return nil
    }
}