//
//  FeedActionButton.swift
//  Treem
//
//  Created by Matthew Walker on 2/29/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

@IBDesignable
class FeedActionButton: UIButton {
    // highlighted/selected color
    private var selectColor     = AppStyles.sharedInstance.darkGrayColor
    
    // default color of non-selected/non-highlighted
    @IBInspectable
    var defaultColor: UIColor = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0) {
        didSet {
            self.checkColors()
        }
    }
    
    // set an active flag without using native 'selected' property which can alter the styles undesirably
    @IBInspectable
    var active: Bool = false {
        didSet {
            self.checkColors()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setDefaults()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setDefaults()
    }
    
    override var highlighted: Bool {
        get {
            return super.highlighted
        }
        set {
            super.highlighted = newValue
            
            // if selected show background color
            if newValue {
                self.tintColor = selectColor
                
                // prevent default lower opacity
                self.imageView?.alpha   = 1.0
                self.titleLabel?.alpha  = 1.0
            }
            // else remove background color
            else if !self.active {
                self.checkColors()
            }
        }
    }
    
    private func setDefaults() {
        self.tintColor = defaultColor
        
        self.setTitleColor(defaultColor, forState: .Normal)
        self.setTitleColor(selectColor, forState: .Selected)
        self.setTitleColor(selectColor, forState: .Highlighted)
    }
    
    private func checkColors() {
        let color = (active || highlighted) ? selectColor : defaultColor
        
        self.tintColor = color
        
        UIView.performWithoutAnimation({
            self.setTitleColor(color, forState: .Normal)
            self.layoutIfNeeded()
        })
    }
}