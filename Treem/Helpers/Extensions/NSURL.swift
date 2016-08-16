//
//  NSURL.swift
//  Treem
//
//  Created by Matthew Walker on 12/16/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

extension NSURL {
    static func getNSURL(stringNil: String?) -> NSURL? {
        if let unwrappedString = stringNil {
            if unwrappedString.characters.count > 0 {
                return NSURL(string: unwrappedString)
            }
        }
        
        return nil
    }
}
