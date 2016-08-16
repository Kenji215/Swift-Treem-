//
//  UITextView.swift
//  Treem
//
//  Created by Matthew Walker on 10/16/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

extension UITextView {
    
    // handles bug where setting text while not selectable drops existing textview styles
    func setTextSafely (text: String) {
        let selectable  = self.selectable
        
        self.selectable = true
        self.text       = text
        self.selectable = selectable
    }
    
    func removeEdgeInsets() {
        self.textContainerInset = UIEdgeInsetsZero
        self.textContainer.lineFragmentPadding = 0
    }
}