//
//  OrderedSet.swift
//  Treem
//
//  Created by Matthew Walker on 10/30/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

struct OrderedSet<T: Hashable> : SequenceType, GeneratorType, ArrayLiteralConvertible {
    var keys    : Array<Int>        = []
    var values  : Dictionary<Int,T> = [:]
    
    var count: Int {
        return self.keys.count
    }
    
    init() {}
    
    /* ArrayLiteralConvertible */
    init(arrayLiteral: T...) {
        for element in arrayLiteral {
            self.insert(element)
        }
    }
    
    /* SequenceType */
    func filter(includeElement: (T) -> Bool) -> [T] {
        var filteredItems = [T]()

        for value in self.values.values where includeElement(value) == true {
            filteredItems += [value]
        }
        
        return filteredItems
    }
    
    typealias Generator = OrderedSet
    
    func generate() -> Generator {
        return self
    }
    
    /* GeneratorType */
    var currentElement = 0
    
    mutating func next() -> T? {
        if currentElement < self.keys.count {
            let curItem = currentElement
            
            currentElement += 1
            
            return self.values[self.keys[curItem]]
        }
        
        return nil
    }
    
    subscript(index: Int) -> T? {
        get
        {
            let key = self.keys[index]
            
            return self.values[key]
        }
    }
    
    func contains(value: T) -> Bool {
        return self.values[value.hashValue] != nil
    }
    
    mutating func insert(value: T) {
        let key = value.hashValue
    
        if self.values.updateValue(value, forKey: key) == nil {
            self.keys.append(key)
        }
    }
    
    mutating func remove(value: T) {
        let key = value.hashValue
        
        self.values.removeValueForKey(key)

        if let index = self.keys.indexOf(key) {
            self.keys.removeAtIndex(index)
        }
    }
    
    mutating func removeAtIndex(index: Int) {
        let key = self.keys[index]
        
        self.keys.removeAtIndex(index)
        self.values.removeValueForKey(key)
    }
    
    mutating func append(setToAppend: OrderedSet) {
        for item in setToAppend { self.insert(item) }
    }
    
    func getValue(value: T) -> T? {
        return self.values[value.hashValue]
    }
}