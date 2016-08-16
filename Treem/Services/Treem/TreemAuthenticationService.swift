//
//  TreemAuthenticationService.swift
//  Treem
//
//  Created by Matthew Walker on 10/6/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON
import libPhoneNumber_iOS

class TreemAuthenticationService {
    static let sharedInstance = TreemAuthenticationService()
    
    private let url = "https://authentication.\(TreemService.baseDomain)/"
    
    func checkPhoneNumber(phoneNumber: String, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url         = self.url + "check"
        var json:JSON   = [:]
        
        json["phone"].stringValue = NBPhoneNumberUtil().getE164FormattedString(phoneNumber)
        
        TreemService().post(
            url,
            json                : json,
            failureCodesHandled : failureCodesHandled,
            success             : success,
            failure             : failure
        )
    }
    
    func checkPin(treeSession: TreeSession, pin: String, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url         = self.url + "checkpin"
        var json:JSON   = [:]
        
        json["pin"].stringValue = pin
        
        TreemService().post(
            url,
            json    : json,
            headers : treeSession.getTreemServiceHeader(),
            success : success,
            failure : failure
        )
    }
    
    func checkUsername(username: String, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url         = self.url + "username/" + username
        
        TreemService().get(
            url,
            parameters          : nil,
            headers             : nil,
            failureCodesHandled : failureCodesHandled,
            success             : success,
            failure             : failure
        )
    }
    
    func logout(failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url = self.url + "logout"
        
        TreemService().delete(
            url,
            failureCodesHandled : failureCodesHandled,
            success             : success,
            failure             : failure
        )
    }
    
    func registerUser(user: User, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url         = self.url
        var json:JSON   = [:]
        
        if let username = user.username, first = user.firstName, last = user.lastName, dob = user.dob {
            json["username"].stringValue    = username
            json["first"].stringValue       = first
            json["last"].stringValue        = last
            json["dob"].stringValue         = dob.getISOFormattedString()
            
            TreemService().post(
                url,
                json    : json,
                success : success,
                failure : failure
            )
        }
        else {
            failure(error: TreemServiceResponseCode.OtherError, wasHandled: false)
        }
    }
    
    func resendVerificationCode(phoneNumber:String, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url         = self.url + "resend"
        var json:JSON   = [:]
        
        json["phone"].stringValue = NBPhoneNumberUtil().getE164FormattedString(phoneNumber)
        
        TreemService().post(
            url,
            json    : json,
            success : success,
            failure : failure
        )
    }
    
    func setPin(treeSession: TreeSession, pin: String, existingPin: String?, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url         = self.url + "setpin"
        var json:JSON   = [:]
        
        json["pin"].stringValue = pin
        
        if let existingPin = existingPin {
            if !existingPin.isEmpty {
                json["existing_pin"].stringValue = existingPin
            }
        }

        TreemService().post(
            url,
            json    : json,
            headers : treeSession.getTreemServiceHeader(),
            success : success,
            failure : failure
        )
    }
    
    func verifyUserDevice(phoneNumber:String, signupCode:String, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        let url         = self.url + "verify"
        let device      = UIDevice.currentDevice()
        var json:JSON   = [:]

        json["phone"].stringValue               = NBPhoneNumberUtil().getE164FormattedString(phoneNumber)
        json["signup_code"].stringValue         = signupCode
        json["device_os"].stringValue           = "ios"
        json["device_name"].stringValue         = device.name + " (" + device.model + ")"
        json["device_guid"].stringValue         = AppSettings.sharedInstance.device_token
        json["device_form_factor"].stringValue  = device.model
        
        TreemService().post(
            url,
            json    : json,
            success : success,
            failure : failure
        )
    }
}