//
//  String.swift
//  Treem
//
//  Created by Matthew Walker on 10/2/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import Foundation

extension String {
    
    // initialize string with an array of UInt8 integer values
    init?(utf8chars:[UInt8]) {
        var str         = ""
        var generator   = utf8chars.generate()
        var utf8        = UTF8()
        var done        = false
        
        while !done {
            let r = utf8.decode(&generator)
            
            switch (r) {
            case .EmptyInput:
                done = true
            case let .Result(val):
                str.append(Character(val))
            case .Error:
                return nil
            }
        }
        
        self = str
    }
    
    // composed count takes into account emojis that are represented by character sequences
    var composedCount : Int {
        var count = 0
        
        enumerateSubstringsInRange(startIndex..<endIndex, options: .ByComposedCharacterSequences) { _ in count += 1}
        
        return count
    }
    
    // check if string contains other strings
    func contains(find: String) -> Bool {
        return self.rangeOfString(find) != nil ? true : false
    }
    
    // encode string for a url query parameter value
    func encodingForURLQueryValue() -> String? {
        let characterSet = NSMutableCharacterSet.alphanumericCharacterSet()
        characterSet.addCharactersInString("-._~")
        
        return stringByAddingPercentEncodingWithAllowedCharacters(characterSet)
    }
    
    func getPathNameExtension() -> String {
        return (self as NSString).pathExtension
    }

    func labelHeightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        if self.isEmpty {
            return 0
        }
        
        let label = UILabel(frame: CGRectMake(0,0,width,0))
        
        label.font          = font
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.text          = self
        
        label.sizeToFit()
        label.layoutIfNeeded()
        
        return ceil(label.frame.height)
    }
    
    func labelCopyableHeightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        if self.isEmpty {
            return 0
        }
        
        let label = CopyableLabel(frame: CGRectMake(0,0,width,0))
        
        label.font          = font
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.text          = self
        
        label.sizeToFit()
        label.layoutIfNeeded()
        
        return ceil(label.frame.height)
    }
    
    func labelCopyableSizeFromText(font: UIFont) -> CGSize {
        if self.isEmpty {
            return CGSizeZero
        }
        
        let label = CopyableLabel(frame: CGRectZero)
        
        label.font          = font
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.text          = self

        label.sizeToFit()
        label.layoutIfNeeded()
        
        return CGSize(width: ceil(label.frame.width), height: ceil(label.frame.height))
    }
    
    // get index of substring in string, or -1 if not contained in other string
    func indexOf(target: String) -> Int
    {
        let range = self.rangeOfString(target)
        if let range = range {
            return self.startIndex.distanceTo(range.startIndex)
        }
        else {
            return -1
        }
    }
    
    // check if letters or digits only (if empty string returns true)
    func isAlphaNumeric() -> Bool {
        let alphaNumeric     = NSCharacterSet.alphanumericCharacterSet()
        
        var isAlphaNumeric = true
        
        for char in self.unicodeScalars {
            if !alphaNumeric.longCharacterIsMember(char.value) {
                // character not alpha
                isAlphaNumeric = false
                break
            }
        }
        
        return isAlphaNumeric
    }
    
    // check if digits only (if empty string returns true)
    func isDigitsOnly() -> Bool {
        let digits  = NSCharacterSet.decimalDigitCharacterSet()
        
        var isDigitsOnly = true
        
        for char in self.unicodeScalars {
            if !digits.longCharacterIsMember(char.value) {
                // character not alpha
                isDigitsOnly = false
                break
            }
        }
        
        return isDigitsOnly
    }

    // check if letters only (if empty string returns true)
    func isValidName() -> Bool {
        let letters     = NSCharacterSet.letterCharacterSet()
        let punctuation = NSCharacterSet.punctuationCharacterSet()
        
        var isValidName = true
        
        for char in self.unicodeScalars {
            if !letters.longCharacterIsMember(char.value) && !punctuation.longCharacterIsMember(char.value) {
                // character not alpha
                isValidName = false
                break
            }
        }
        
        return isValidName
    }
    
    func isAlphaPunctuationWhiteSpace() -> Bool {
        let letters     = NSCharacterSet.letterCharacterSet()
        let punctuation = NSCharacterSet.punctuationCharacterSet()
        let whitespace  = NSCharacterSet.whitespaceCharacterSet()
        
        var isAlphaPunctuationWhiteSpace = true
        
        for char in self.unicodeScalars {
            if !letters.longCharacterIsMember(char.value) && !punctuation.longCharacterIsMember(char.value) && !whitespace.longCharacterIsMember(char.value) {
                // character not letter or whitespace
                isAlphaPunctuationWhiteSpace = false
                break
            }
        }
        
        return isAlphaPunctuationWhiteSpace
    }
    
    // check if string is a valid email address
    func isValidEmail() -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}", options: .CaseInsensitive)
            return regex.firstMatchInString(self, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count)) != nil
        }
        catch {
            return false
        }
    }
    
    func trim() -> String
    {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    func widthWithConstrainedHeight(height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect  = CGSize(width: CGFloat.max, height: height)
        let boundingBox     = self.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)

        return ceil(boundingBox.width)
    }
    
    var length: Int {
        get {
            return self.characters.count
        }
    }
    
    func replace(target: String, withString: String) -> String
    {
        return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
    subscript (i: Int) -> Character
        {
        get {
            let index = startIndex.advancedBy(i)
            return self[index]
        }
    }
    
    subscript (r: Range<Int>) -> String
        {
        get {
            let startIndex = self.startIndex.advancedBy(r.startIndex)
            let endIndex = self.startIndex.advancedBy(r.endIndex - 1)
            
            return self[Range(start: startIndex, end: endIndex)]
        }
    }
    
    func subString(startIndex: Int, length: Int) -> String
    {
        let start = self.startIndex.advancedBy(startIndex)
        let end = self.startIndex.advancedBy(startIndex + length)
        return self.substringWithRange(Range<String.Index>(start: start, end: end))
    }
    
    func indexOf(target: String, startIndex: Int) -> Int
    {
        let startRange = self.startIndex.advancedBy(startIndex)
        
        let range = self.rangeOfString(target, options: NSStringCompareOptions.LiteralSearch, range: Range<String.Index>(start: startRange, end: self.endIndex))
        
        if let range = range {
            return self.startIndex.distanceTo(range.startIndex)
        } else {
            return -1
        }
    }
    
    private var vowels: [String]
        {
        get
        {
            return ["a", "e", "i", "o", "u"]
        }
    }
    
    private var consonants: [String]
        {
        get
        {
            return ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "z"]
        }
    }
    
    func pluralize(count: Int) -> String
    {
        if count == 1 {
            return self
        } else {
            let lastChar = self.subString(self.length - 1, length: 1)
            let secondToLastChar = self.subString(self.length - 2, length: 1)
            var prefix = "", suffix = ""
            
            if lastChar.lowercaseString == "y" && vowels.filter({x in x == secondToLastChar}).count == 0 {
                prefix = self[0...self.length - 1]
                suffix = "ies"
            } else if lastChar.lowercaseString == "s" || (lastChar.lowercaseString == "o" && consonants.filter({x in x == secondToLastChar}).count > 0) {
                prefix = self[0...self.length]
                suffix = "es"
            } else {
                prefix = self[0...self.length]
                suffix = "s"
            }
            
            return prefix + (lastChar != lastChar.uppercaseString ? suffix : suffix.uppercaseString)
        }
    }
    
    func parseForUrl() -> String {
        if self.isEmpty {
            return ""
        }
        
        // Need an empty range object.  Using a temp string for this.
        let tempString = ""
        var endOfUrl = tempString.rangeOfString("z")
        var endUrlIndex = tempString.endIndex
        
        let currentText = (self as String)
        
        var outUrl : String = ""
        
        var startOfUrl = currentText.lowercaseString.rangeOfString("http://")
        if startOfUrl == nil {
            startOfUrl = currentText.lowercaseString.rangeOfString("https://")
        }
        if startOfUrl == nil {
            for suffix in UrlEnd.allValues {
                endOfUrl = currentText.lowercaseString.rangeOfString(suffix.rawValue)
                
                if endOfUrl != nil {
                    break
                }
            }
        }
        
        if startOfUrl != nil || endOfUrl != nil {
            
            if (startOfUrl != nil) {
                var stringStart = currentText.substringToIndex(startOfUrl!.endIndex)
                
                stringStart = stringStart.replace("\n", withString: " ")
                
                var startUrlIndex = stringStart.rangeOfString(" ", options: .BackwardsSearch)?.startIndex.advancedBy(1)
                
                var stringEnd = currentText.substringFromIndex((startOfUrl?.endIndex)!)
                
                stringEnd = stringEnd.replace("\n",withString: " ")
                
                if stringEnd != "" && stringEnd.contains(" "){
                    endUrlIndex = (stringEnd.rangeOfString(" ")?.endIndex.predecessor())!
                }
                
                if startUrlIndex == nil {
                    startUrlIndex = stringStart.startIndex
                }
                if endUrlIndex == tempString.endIndex {
                    endUrlIndex = stringEnd.endIndex
                }
                
                let urlStart = stringStart.substringWithRange(Range<String.Index>(start: startUrlIndex!, end: stringStart.endIndex))
                var urlEnd = stringEnd.substringWithRange(Range<String.Index>(start: stringEnd.startIndex, end: endUrlIndex))
                
                if urlEnd != "" {
                    while urlEnd.substringFromIndex(urlEnd.endIndex.predecessor()) == "." {
                        urlEnd.removeAtIndex(urlEnd.endIndex.predecessor())
                    }
                }
                
                outUrl = urlStart + urlEnd
            }
            else if (endOfUrl != nil) {
                var stringStart = currentText.substringToIndex((endOfUrl?.endIndex)!)
                
                stringStart = stringStart.replace("\n", withString: " ")
                
                var startUrlIndex = stringStart.rangeOfString(" ", options: .BackwardsSearch)?.startIndex.advancedBy(1)
                
                var stringEnd = currentText.substringFromIndex((endOfUrl?.endIndex)!)
                
                stringEnd = stringEnd.replace("\n",withString: " ")
                
                if !stringEnd.isEmpty && (stringEnd == " " || stringEnd == "/") {
                    endUrlIndex = (stringEnd.rangeOfString(" ")?.endIndex.predecessor())!
                }
                
                if startUrlIndex == nil {
                    startUrlIndex = stringStart.startIndex
                }
                
                let urlStart = stringStart.substringWithRange(Range<String.Index>(start: startUrlIndex!, end: stringStart.endIndex))
                var urlEnd = stringEnd.substringWithRange(Range<String.Index>(start: stringEnd.startIndex, end: endUrlIndex))
                
                if urlEnd != "" {
                    while urlEnd.substringFromIndex(urlEnd.endIndex.predecessor()) == "." {
                        urlEnd.removeAtIndex(urlEnd.endIndex.predecessor())
                    }
                }
                
                outUrl = urlStart + urlEnd
            }
        }
        return outUrl
    }
}