//
//  Profile.swift
//  Treem
//
//  Created by Daniel Sorrell on 12/11/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class Profile {
    
    enum FriendStatus: Int {
        case Pending            = 0
        case Friends            = 2
        case NotFriends         = 5
    }
    
    var userID           : Int64            = 0
    var username         : String?          = nil
    var firstName        : String?          = nil
    var lastName         : String?          = nil
    var nonFriendAccess  : Bool?            = false
    var phone            : String?          = nil
    var dob              : NSDate?          = nil
    var createDate       : NSDate?          = nil
    var email            : String?          = nil
    var profilePic       : String?          = nil
    var profilePicId     : String?          = nil
    var avatar           : String?          = nil
    var avatarId         : String?          = nil
    var residesLocality  : String?          = nil
    var residesProvince  : String?          = nil
    var residesCountry   : String?          = nil
    var branches         : [BranchPath]?    = nil
    var frStatus         : FriendStatus?    = nil
    var lastAction       : Bool?            = nil
    
    init() {}
    
    init (json: JSON) {
        
        self.userID           = json["id"].int64Value
        self.username         = json["username"].string
        self.firstName        = json["first"].string
        self.lastName         = json["last"].string
        self.nonFriendAccess  = (json["n_fr_access"].intValue == 1) ? true : false
        self.phone            = json["phone"].string
        self.dob              = NSDate(iso8601String: json["dob"].string)
        self.createDate       = NSDate(iso8601String: json["create_date"].string)
        self.email            = json["email"].string
        self.profilePic       = json["pr_pic_stream"].string
        self.profilePicId     = json["pr_pic"].string
        self.avatar           = json["avatar_stream_url"].string
        self.avatarId         = json["avatar"].string
        self.residesLocality  = json["r_locality"].string
        self.residesProvince  = json["r_province"].string
        self.residesCountry   = json["r_country"].string
 
        // friend specific info
        self.branches         = BranchPath.init().loadBranchPaths(json["branches"])
        self.frStatus         = FriendStatus(rawValue: json["status"].int ?? FriendStatus.NotFriends.rawValue)
        self.lastAction       = (json["last_action"].intValue == 1) ? true : false
    }
    
    init(_userName: String?, _firstName: String?, _lastName: String?, _nonFriendAccess: Bool?, _dob: NSDate?, _email: String?, _residesLocality: String?, _residesProvince: String?, _residesCountry: String?){
        
        self.username = _userName
        self.firstName = _firstName
        self.lastName = _lastName
        self.nonFriendAccess = _nonFriendAccess
        self.dob = _dob
        self.email = _email
        self.residesLocality = _residesLocality
        self.residesProvince = _residesProvince
        self.residesCountry = _residesCountry
    }
    
    func IsEmpty() -> Bool {
        return ((self.username == nil) &&
                (self.firstName == nil) &&
                (self.lastName == nil) &&
                (self.nonFriendAccess == nil) &&
                (self.dob == nil) &&
                (self.email == nil) &&
                (self.residesLocality == nil) &&
                (self.residesProvince == nil) &&
                (self.residesCountry == nil))
    }
    
    func toJSON() -> JSON {
        var json:JSON = [:]
        
        // only add the json values if they aren't null, only update the values changed
        if(self.username != nil){
            json["username"].string = self.username
        }
        
        if(self.firstName != nil){
            json["first"].string = self.firstName
        }
        
        if(self.lastName != nil){
            json["last"].string = self.lastName
        }
        
        if(self.nonFriendAccess != nil){
            json["n_fr_access"].intValue = (nonFriendAccess == true) ? 1 : 0
        }
        
        if(self.dob != nil){
            json["dob"].string = self.dob!.getISOFormattedString()
        }
        
        if(self.email != nil){
            json["email"].string = self.email
        }
        
        if(self.residesLocality != nil){
            json["r_locality"].string = self.residesLocality
        }
        
        if(self.residesProvince != nil){
            json["r_province"].string = self.residesProvince
        }
        
        if(self.residesCountry != nil){
            json["r_country"].string = self.residesCountry
        }

        return json
    }
    
    private func hasName() -> Bool {
        return !(self.firstName ?? "").isEmpty || !(self.lastName ?? "").isEmpty
    }
    
    func getFullName() -> String {
        return (self.hasName() ? (self.firstName != nil ? self.firstName! + " " : "") + (self.lastName ?? "") :  "").trim()
    }
}