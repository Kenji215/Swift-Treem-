//
//  NSLocale.swift
//  Treem
//
//  Created by Matthew Walker on 10/6/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

extension NSLocale {
    func getTopPreferredLanguage() -> String {
        return NSLocale.preferredLanguages()[0]
    }

    func getTopPreferredCountryCode() -> String {
        let locale = NSLocale(localeIdentifier: self.getTopPreferredLanguage())
        let countryCode = locale.objectForKey(NSLocaleCountryCode) as! String
        
        return countryCode
    }
}