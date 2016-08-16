//
//  checkboxButton.swift
//  Treem
//
//  Created by Matthew Walker on 11/6/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

@IBDesignable
class CheckboxButton : UIButton {
    
    let checkedColor    = UIColor(red: 137/255.0, green: 173/255.0, blue: 77/255.0, alpha: 1.0)
    let uncheckedColor  = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
    let readOnlyColor   = AppStyles.sharedInstance.midGrayColor
    
    let checkedImage    = "Checked"
    let uncheckedImage  = "Unchecked"
    
    @IBInspectable
    var checked : Bool = false {
        didSet {
            self.updateImage()
            self.updateColor()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.updateImage()
        self.updateColor()
        
        self.addTarget(self, action: Selector("buttonTouchUpInside"), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.updateImage()
        self.updateColor()
        
        self.addTarget(self, action: Selector("buttonTouchUpInside"), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    private func updateImage() {
        
        self.setImage(UIImage(named: (self.checked ? self.checkedImage : self.uncheckedImage))?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: .Normal)
    }
    
    func buttonTouchUpInside() {
        self.checked = !checked
    }
    
    func setReadOnlyColor() {
        self.tintColor = self.readOnlyColor
    }
    
    func updateColor() {
        let color = self.checked ? self.checkedColor : self.uncheckedColor
        
        self.tintColor = color
        self.setTitleColor(color, forState: .Normal)
    }
}