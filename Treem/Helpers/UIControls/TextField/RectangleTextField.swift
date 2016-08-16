//
//  RectangleTextField.swift
//  Treem
//
//  Created by Matthew Walker on 8/20/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class RectangleTextField: UITextField {
    // amount to pad text in text field
    private let inset: CGFloat = 8
    
    @IBInspectable
    var borderWidth: CGFloat = 1.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.addStyles()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addStyles()
    }
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, self.inset, self.inset)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, self.inset, self.inset)
    }
    
    private func addStyles () {
        self.borderStyle        = UITextBorderStyle.None
        self.layer.borderWidth  = self.borderWidth
        self.layer.borderColor  = AppStyles.sharedInstance.fieldGrayColor.CGColor
    }
}
