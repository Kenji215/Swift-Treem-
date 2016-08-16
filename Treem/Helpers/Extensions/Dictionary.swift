//
//  Dictionary.swift
//  Treem
//
//  Created by Matthew Walker on 10/19/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func merge<K, V>(dict: [K: V]){
        for (k, v) in dict {
            self.updateValue(v as! Value, forKey: k as! Key)
        }
    }
}