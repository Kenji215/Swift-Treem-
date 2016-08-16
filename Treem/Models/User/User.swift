//
//  User.swift
//  Treem
//
//  Created by Matthew Walker on 10/23/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class User : NSObject, TableViewCellModelType {
    enum FriendStatus: Int {
        case Pending            = 0
        case Friends            = 2
        case NotFriends         = 5
        case Invited            = 6
        case NotInTreem         = 7
    }
    
    enum UserStatus: Int {
        case Full               = 0
        case TempVerified       = 1
        case TempUnverified     = 2
    }
    
    override var hashValue: Int {
        return "\(self.phone?.stringByReplacingOccurrencesOfString(",", withString: "-") ?? "0"),\(self.id),\(self.contactID)".hashValue
    }
    
    var id          : Int           = 0
    var inviteId    : Int           = 0
    var username    : String?       = nil
    var firstName   : String?       = nil
    var lastName    : String?       = nil
    var dob         : NSDate?       = nil
    var avatar      : NSURL?        = nil
    var avatarId    : String?       = nil
    var phone       : String?       = nil
    var email       : String?       = nil
    var userStatus  : UserStatus?   = nil
    var friendStatus: FriendStatus? = nil
    var colors      : [String]?     = nil
    var onBranch    : Bool?         = false
    var listIcon    : UIImage?      = nil
    
    var isCurrentUser : Bool = false
    
    var contactID   : Int32          = 0
    
    var allRowsIndex: Int = 0
    
    override init() {}
    
    init(data: JSON) {

        self.id             = data["id"].intValue
        self.inviteId       = data["iv_id"].intValue
        self.username       = data["username"].string
        self.firstName      = data["first"].string
        self.lastName       = data["last"].string
        self.dob            = NSDate(iso8601String: data["dob"].string)
        self.phone          = data["phone"].string
        self.email          = data["email"].string
        self.userStatus     = UserStatus(rawValue: data["user_status"].int ?? UserStatus.TempUnverified.rawValue)
        self.friendStatus   = FriendStatus(rawValue: data["status"].int ?? FriendStatus.NotFriends.rawValue)
        self.contactID      = data["c_id"].int32Value
        self.colors         = data["color"].arrayValue.map { $0.string! }
        self.onBranch       = data["on_branch"].boolValue
        self.isCurrentUser  = data["self"].intValue == 1

        if self.colors?.count < 1 {
            self.colors = nil
        }
        
        if let avatar = data["avatar_stream_url"].string, url = NSURL(string: avatar) {
            self.avatar = url
            
            self.avatarId = data["avatar"].string
        }
    }
    
    // update user object from user created from contact
    func updateFromContactUser(user: User) {
        self.id         = user.id
        
        if let username = user.username {
            self.username = username
        }
        
        if let avatar = user.avatar {
            self.avatar = avatar
        }
    }
    
    func getFullName() -> String {
        return (self.hasName() ? (self.firstName != nil ? self.firstName! + " " : "") + (self.lastName ?? "") :  "").trim()
    }
    
    func getSectionIndexIdentifier() -> String {
        let fullName = self.getFullName()
        
        if fullName.isEmpty {
            return self.phone ?? self.username ?? ""
        }

        return self.getFullName()
    }

    static func getUsersFromData(data: JSON) -> OrderedSet<User> {
        var users = OrderedSet<User>()
        
        for (_, userData) in data {
            users.insert(User(data: userData))
        }
        
        return users
    }

    static func getFirstUserFromContactSearch(data: JSON) -> User? {
        if data.count > 0 {
            let user = User(data: data[0])
            
            if (user.id > 0 || user.inviteId > 0) && user.contactID > 0 {
                return user
            }
        }
        
        return nil
    }
    
    static func getUsersFromContactSearch(data: JSON) -> Dictionary<Int32, User> {
        var users = Dictionary<Int32, User>()
        
        for (_, userData) in data {
            let user = User(data: userData)
            
            if (user.id > 0 || user.inviteId > 0) && user.contactID > 0 {
                users[user.contactID] = user
            }
        }
        
        return users
    }
    
    static func getUsersFromContacts(contacts: [UserContact], filter: String? = nil, searchOptions: SeedingSearchOptions? = nil) -> OrderedSet<User> {
        var users = OrderedSet<User>()
        
        let hasFilter   = !(filter ?? "").isEmpty
        
        var matchName   = true
        var matchPhone  = true
        var matchEmail  = true
        
        if let options = searchOptions {
            matchName  = options.matchFirstName || options.matchLastName
            matchPhone = options.matchPhone
            matchEmail = options.matchEmail
        }
        
        let insertUser = {
            (contact: UserContact, phone: String?, email: String?) in
            
            let user = User()
            
            // populate object
            user.contactID  = contact.contactID
            user.firstName  = contact.firstName
            user.lastName   = contact.lastName
            user.phone      = phone
            user.email      = email
            
            if hasFilter {
                let first   : String    = contact.firstName?.lowercaseString ?? ""
                let last    : String    = contact.lastName?.lowercaseString ?? ""
                let phone   : String    = phone ?? ""
                let email   : String    = email ?? ""
                let filter  : String    = filter!.lowercaseString

                // match beginning of string
                if  (matchName && ((!first.isEmpty && (first).indexOf(filter) == 0) || (!last.isEmpty && (last).indexOf(filter) == 0))) ||
                    (matchPhone && (!phone.isEmpty && (phone).indexOf(filter) == 0)) ||
                    (matchEmail && (!email.isEmpty && (email).indexOf(filter) == 0)) {
                        users.insert(user)
                }
            }
            else {
                users.insert(user)
            }
        }
        
        for contact in contacts {
            if (contact.phoneNumbers.count + contact.emails.count) > 0 {
            
                // one phone number per user (duplicates should be filtered already)
                for phoneNumber in contact.phoneNumbers {
                    insertUser (contact, phoneNumber, nil)
                }

                for email in contact.emails {
                    insertUser (contact, nil, email)
                }
            }
            else
            {
                insertUser(contact, nil, nil)
            }
        }
        
        return users
    }
    
    static func sortUsersByName(lhs : User, rhs : User) -> Bool
    {
        let lhsHasName = lhs.hasName()
        let rhsHasName = rhs.hasName()

        // if neighbor member has names, sort by phone
        if !lhsHasName && !rhsHasName {
            return lhs.phone < rhs.phone
        }
        // if left doesn't have name and right does
        else if !lhsHasName {
            return false
        }
        // if right doesn't have name and left does
        else if !rhsHasName {
            return true
        }
        // compare user names
        else {
            if lhs.firstName == rhs.firstName {
                if lhs.lastName == rhs.lastName {
                    return lhs.username < lhs.lastName
                }
                else {
                    return lhs.lastName < lhs.firstName
                }
            }
            else {
                return lhs.firstName < rhs.firstName
            }
        }
    }
    
    func hasName() -> Bool {
        return !(self.firstName ?? "").isEmpty || !(self.lastName ?? "").isEmpty
    }
}

// users are equal if their phone, ID, and contact IDs match
func ==(lhs: User, rhs: User) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

