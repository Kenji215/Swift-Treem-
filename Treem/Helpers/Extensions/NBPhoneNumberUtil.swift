//
//  NBPhoneUtil.swift
//  Treem
//
//  Created by Matthew Walker on 11/10/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import libPhoneNumber_iOS

extension NBPhoneNumberUtil {
    func getE164FormattedString(phone: String) -> String {
        var formatted = ""
        
        do {
            let nbPhoneNumber = try self.parse(phone, defaultRegion: Localization.sharedInstance.getCurrentLocaleCountryCode())
            
            if (NBPhoneNumberUtil.sharedInstance().isValidNumber(nbPhoneNumber)) {
                formatted = try self.format(nbPhoneNumber, numberFormat: NBEPhoneNumberFormat.E164)
            }
        }
        catch {}
        
        return formatted
    }
    
    func getRFC3966FormattedString(phone: String, allowExtensions: Bool = false) -> String {
        var formatted = ""
        
        do {
            let nbPhoneNumber   = try self.parse(phone, defaultRegion: Localization.sharedInstance.getCurrentLocaleCountryCode())
            let e164Format      = try self.format(nbPhoneNumber, numberFormat: NBEPhoneNumberFormat.RFC3966)
            
            // don't allow extensions
            if !allowExtensions && !e164Format.contains(";ext") {
                formatted = e164Format
            }
        }
        catch {}
        
        return formatted
    }
}