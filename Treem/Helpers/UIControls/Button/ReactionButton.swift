//
//  ReactionButton.swift
//  Treem
//
//  Created by Matthew Walker on 1/27/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class ReactionButton : UIButton {
    var reaction: Post.ReactionType?    = nil
    
    let bgColor = UIColor.blackColor().colorWithAlphaComponent(0.1)
    
    override var highlighted: Bool {
        get {
            return super.highlighted
        }
        set {
            // if selected show background color
            if newValue {
                self.backgroundColor = bgColor
            }
            // else remove background color
            else if !self.selected {
                self.backgroundColor = nil
            }
            
            super.highlighted = newValue
        }
    }
    
    override var selected: Bool {
        get {
            return super.selected
        }
        set {
            // if selected show background color
            if newValue {
                self.backgroundColor = bgColor
            }
            // else remove background color
            else {
                self.backgroundColor = nil
            }
            
            super.selected = newValue
        }
    }
}
