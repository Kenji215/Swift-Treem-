//
//  UIColor.swift
//  Treem
//
//  Created by Matthew Walker on 8/24/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init?(hex:String) {
        // trim hex string value
        var hex             = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        var characterCount  = hex.characters.count
        
        // check for preceeding '#' and remove if present
        if hex.hasPrefix("#") && characterCount > 1 {
            hex = hex.substringFromIndex(hex.startIndex.advancedBy(1))
            characterCount -= 1
        }

        // check that the character count matches a potential hexagon value
        if Set<Int>(arrayLiteral: 3,4,6,8).contains(characterCount) {
            var rgbValue: UInt32    = 0
            
            // parse the hex string to an integer value
            if NSScanner(string: hex).scanHexInt(&rgbValue) {
                var red     : CGFloat   = 0
                var green   : CGFloat   = 0
                var blue    : CGFloat   = 0
                var alpha   : CGFloat   = 1
                
                switch(characterCount) {
                case 3:
                    red   = CGFloat((rgbValue & 0xF00) >> 8)       / 15
                    green = CGFloat((rgbValue & 0x0F0) >> 4)       / 15
                    blue  = CGFloat(rgbValue & 0x00F)              / 15
                case 4:
                    red   = CGFloat((rgbValue & 0xF000) >> 12)     / 15
                    green = CGFloat((rgbValue & 0x0F00) >> 8)      / 15
                    blue  = CGFloat((rgbValue & 0x00F0) >> 4)      / 15
                    alpha = CGFloat(rgbValue & 0x000F)             / 15
                case 6:
                    red   = CGFloat((rgbValue & 0xFF0000) >> 16)   / 255
                    green = CGFloat((rgbValue & 0x00FF00) >> 8)    / 255
                    blue  = CGFloat(rgbValue & 0x0000FF)           / 255
                case 8:
                    red   = CGFloat((rgbValue & 0xFF000000) >> 24) / 255
                    green = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255
                    blue  = CGFloat((rgbValue & 0x0000FF00) >> 8)  / 255
                    alpha = CGFloat(rgbValue & 0x000000FF)         / 255
                default:
                    break
                }

                self.init(red:red, green:green, blue:blue, alpha:alpha)
            }
            else {
                self.init()
                
                // invalid hex color given
                return nil
            }
        }
        else {
            self.init()
            
            // invalid hex color given
            return nil
        }
    }
    
    func colorIsClear() -> Bool {
        if let rgb = self.getRGB() {
            return (rgb.alpha == 0)
        }
        
        return false
    }
    
    // convert to hex string (6 characters, 3 if it can be shorthanded)
    func toHexString(includeHash: Bool = false) -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255) << 16 | (Int)(g*255) << 8 | (Int)(b*255) << 0
        
        var hex = String(format:"%06x", rgb)
        
        // check if hex can be shorthanded
        let r1 = hex[hex.startIndex]
        
        if r1 == hex[hex.startIndex.advancedBy(1)] {
            let g1 = hex[hex.startIndex.advancedBy(2)]
            
            if g1 == hex[hex.startIndex.advancedBy(3)] {
                let b1 = hex[hex.startIndex.advancedBy(4)]
                
                if b1 == hex[hex.startIndex.advancedBy(5)] {
                    // provide shorthand
                    hex = String([r1, g1, b1])
                }
            }
        }
        
        return (includeHash ? "#" : "") + hex
    }
    
    // return a darker color of the current color
    func darkerColorForColor(shift: CGFloat = 0.05) -> UIColor {
        
        var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0

        if self.getRed(&r, green: &g, blue: &b, alpha: &a){
            return UIColor(red: max(r - shift, 0.0), green: max(g - shift, 0.0), blue: max(b - shift, 0.0), alpha: a)
        }
        
        return UIColor()
    }
    
    // return rgb tuple of color
    func getRGB() -> (red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat)? {
        var red    : CGFloat = 0
        var green  : CGFloat = 0
        var blue   : CGFloat = 0
        var alpha  : CGFloat = 0
        
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            red *= 255
            green *= 255
            blue *= 255
            alpha *= 255
            
            return (red:red, green:green, blue:blue, alpha:alpha)
        }
        else {
            return nil
        }
    }
    
    // return a lighter color of the current color
    func lighterColorForColor(shift: CGFloat = 0.10) -> UIColor {
        
        var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
        
        if self.getRed(&r, green: &g, blue: &b, alpha: &a){
            return UIColor(red: min(r + shift, 1.0), green: min(g + shift, 1.0), blue: min(b + shift, 1.0), alpha: a)
        }
        
        return UIColor()
    }
}
