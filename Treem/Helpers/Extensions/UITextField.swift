//
//  UITextField.swift
//  Treem
//
//  Created by Matthew Walker on 9/11/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

private var maxLengthTextFieldDictionary = [UITextField:Int]()

extension UITextField {
    
    @IBInspectable var maxLength: Int {
        get {
            if let length = maxLengthTextFieldDictionary[self] {
                return length
            }
            else {
                return Int.max
            }
        }
        set {
            maxLengthTextFieldDictionary[self] = newValue
            addTarget(self, action: "checkTextFieldMaxLength:", forControlEvents: UIControlEvents.EditingChanged)
        }
    }
    
    // check that text field has not exceeded max length
    func checkTextFieldMaxLength(sender: UITextField) {
        if let newText = sender.text {
            if newText.characters.count > maxLength {
                let cursorPosition = selectedTextRange
                
                text = newText.substringWithRange(Range<String.Index>(start: newText.startIndex, end: newText.startIndex.advancedBy(maxLength)))
                
                selectedTextRange = cursorPosition
            }
        }
    }
}
