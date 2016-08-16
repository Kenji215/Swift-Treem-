//
//  Abuse.swift
//  Treem
//
//  Created by Tracy Merrill on 3/24/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class Abuse: NSObject, TableViewCellModelType {
    var abuseId         : Int = 0
    var reported        : NSDate? = nil
    var from_user       : User? = nil
    var reason          : AbuseReasons? = nil

    
    var allRowsIndex: Int = 0
    
    enum AbuseReasons : Int{

        case RACISM = 0
        case SEXUAL = 1
        case PROFANITY = 2
        case OFFENSIVE = 3
        
        var description: String {
            switch self {
            case .RACISM:
                return Localization.sharedInstance.getLocalizedString("RACISM", table: "PostAbuse")
            case .SEXUAL:
                return Localization.sharedInstance.getLocalizedString("SEXUAL", table: "PostAbuse")
            case .PROFANITY:
                return Localization.sharedInstance.getLocalizedString("PROFANITY", table: "PostAbuse")
            case.OFFENSIVE:
                return Localization.sharedInstance.getLocalizedString("OFFENSIVE", table: "PostAbuse")
            }
        }
        
        static let allValues = [AbuseReasons.RACISM, .SEXUAL, .PROFANITY, .OFFENSIVE]
    }
    
    override init() {}
    
    init (data: JSON) {
        super.init()
        self.abuseId = data["abuse_id"].intValue
        self.reported = NSDate(iso8601String: data["reported"].string)
        self.from_user = User(data: data["fr_usr"])
        self.reason = AbuseReasons(rawValue: data["reason"].intValue)
    }
    
    init (reason: AbuseReasons) {
        self.reason = reason
    }
    
    static func getAbuseFromData(data:JSON) -> (abuseReports: OrderedSet<Abuse>, users: Dictionary<Int,User>) {
        var abuseReports = OrderedSet<Abuse>()
        var users = Dictionary<Int, User>()
        
        for (_, abuseData) in data {
            let abuse = Abuse(data: abuseData)
            
            abuseReports.insert(abuse)
            users[abuse.from_user!.id] = abuse.from_user
        }
        
        return (abuseReports: abuseReports, users: users)
    }


}