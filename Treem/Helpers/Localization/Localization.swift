//
//  Localization.swift
//  Treem
//
//  Created by Matthew Walker on 10/6/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

class Localization {
    static let sharedInstance = Localization()
    
    // ISO 2-digit country codes (ISO 3166)
    enum ISOCountryCodes: String {
        case UnitedStates = "US"
    }
    
    func getCurrentLocale() -> NSLocale {
        var locale = NSLocale.currentLocale()
        
        if locale.localeIdentifier == "" {
            // try system locale
            locale = NSLocale.systemLocale()
        }
        
        return locale
    }
    
    func getCurrentLocaleIdentifier() -> String {
        var language: String = self.getCurrentLocale().localeIdentifier

        // Apple uses '_' between language and country instead of the ISO standard '-'
        language = language.stringByReplacingOccurrencesOfString("_", withString: "-")
        
        return language
    }
    
    func getCurrentLocaleCountryCode() -> String {
        let locale  = NSLocale.currentLocale()

        var countryCode: String
        
        // check current locale first
        if let country = locale.objectForKey(NSLocaleCountryCode) {
            countryCode = country as! String
        }
        // check system locale second
        else {
            let systemLocale = NSLocale.systemLocale()
            
            if let country = systemLocale.objectForKey(NSLocaleCountryCode) {
                countryCode = country as! String
            }
            else {
                countryCode = ISOCountryCodes.UnitedStates.rawValue
            }
        }
        
        return countryCode
    }
    
    func getLocalizedString(key: String, table: String, bundle: NSBundle = NSBundle.mainBundle(), value: String = "", comment: String = "") -> String {
        
        return NSLocalizedString(key, tableName: table, bundle: bundle, value: value, comment: comment)
    }
}