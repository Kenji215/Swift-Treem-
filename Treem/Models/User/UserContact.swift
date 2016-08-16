//
//  PhoneContact.swift
//  Treem
//
//  Created by Matthew Walker on 11/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import libPhoneNumber_iOS

class UserContact : Hashable {
    var contactID   : Int32     = 0
    var phonebookID : Int32     = 0
    var firstName   : String?   = nil
    var lastName    : String?   = nil
    var phoneNumbers: [String]  = []
    var emails      : [String]  = []
    
    init() {}

    var hashValue: Int {
        return "\(self.contactID),\(self.firstName),\(self.lastName)".hashValue
    }
    
    // return a JSON object for editing a branch (no position properties are changed)
    func toJSON() -> JSON? {
        var json:JSON = [:]
        
        // send branch_id only when updating existing
        if self.contactID > 0 {
            json["c_id"].int32Value = self.contactID
        }
        else {
            return nil
        }
        
        if (self.phoneNumbers.count > 0 || self.emails.count > 0) {
            if (self.phoneNumbers.count > 0) {
                var numbers: [JSON] = []
                
                for number in phoneNumbers {
                    numbers.append(JSON(NBPhoneNumberUtil().getE164FormattedString(number)))
                }
                
                if numbers.count > 1 {
                    json["phone_arr"] = JSON(numbers)
                }
                else {
                    json["phone_arr"].stringValue = numbers[0].stringValue
                }
            }


            if (self.emails.count > 0){
                var emails: [JSON] = []

                for email in self.emails {
                    emails.append(JSON(email))
                }

                if emails.count > 1 {
                    json["email_arr"] = JSON(emails)
                }
                else {
                    json["email_arr"].stringValue = emails[0].stringValue
                }
            }
        }
        else {
            return nil
        }
        
        if let first = self.firstName {
            json["first"].stringValue = first
        }
        
        if let last = self.lastName {
            json["last"].stringValue = last
        }
        
        return json
    }
    	
    func hasName() -> Bool {
        return !(self.firstName ?? "").isEmpty || !(self.lastName ?? "").isEmpty
    }

    func getFullName() -> String {
        return (self.hasName() ? (self.firstName != nil ? self.firstName! + " " : "") + (self.lastName ?? "") :  "").trim()
    }
}

// positions are equal if both x and y value match
func ==(lhs: UserContact, rhs: UserContact) -> Bool {
    return lhs.contactID == rhs.contactID && lhs.firstName == rhs.lastName && lhs.lastName == rhs.lastName
}