//
//  OrderedDictionary.swift
//  Treem
//
//  Created by Matthew Walker on 11/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

struct OrderedDictionary<Tk : Hashable, Tv> : SequenceType, GeneratorType, DictionaryLiteralConvertible {
    var keys    : Array<Tk>         = []
    var values  : Dictionary<Tk,Tv> = [:]
    
    var count: Int {
        return self.keys.count
    }
    
    init() {}
    
    subscript(key: Tk) -> Tv? {
        get {
            return self.values[key]
        }
        set(newValue) {
            if newValue == nil {
                self.values.removeValueForKey(key)
                self.keys = self.keys.filter({$0 != key})
                
                return
            }
            
            let oldValue = self.values.updateValue(newValue!, forKey: key)
            
            if oldValue == nil {
                self.keys.append(key)
            }
        }
    }
    
    typealias Generator = OrderedDictionary
    
    func generate() -> OrderedDictionary {
        return self
    }
    
    /* GeneratorType */
    var currentElement = 0
    
    mutating func next() -> (Tk, Tv?)? {
        if currentElement < self.keys.count {
            let curItem = currentElement
            
            currentElement += 1
            
            let key = self.keys[curItem]
            
            return (key, self.values[key])
        }
        
        return nil
    }
    
    func getValueFromIndex(index: Int) -> Tv? {
        return self.values[self.keys[index]]
    }
    
    func getIndex() {
        return 
    }
    
    mutating func setValueAtIndex(index: Int, value: Tv?) {
        let key = self.keys[index]
        
        if let value = value {
            self.values[key] = value
        }
        else {
            self.values.removeValueForKey(key)
            self.keys.removeAtIndex(index)
        }
    }
    
    /* DictionaryLiteralConvertible */
    init(dictionaryLiteral: (Tk, Tv)...) {
        for element in dictionaryLiteral {
            self[element.0] = element.1
        }
    }
}