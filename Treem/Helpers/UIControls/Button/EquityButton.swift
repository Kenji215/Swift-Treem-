//
//  EquityButton.swift
//  Treem
//
//  Created by Matthew Walker on 4/15/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

@IBDesignable
class EquityButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // position avatar
        if let imageView = self.imageView {
            let iconFrame = CGRectMake((self.titleLabel?.frame.origin.x ?? 0) - 14 - 5, self.bounds.height * 0.5 - 8, 14, 16)
            
            imageView.frame         = iconFrame
            imageView.contentMode   = .ScaleAspectFit
            
            // adjust title x origin
            if let titleLabel = self.titleLabel {
                let newOriginX = iconFrame.origin.x + iconFrame.width + 5
                let originDiff = newOriginX - titleLabel.frame.origin.x
                
                titleLabel.frame = CGRectMake(newOriginX, (self.bounds.height * 0.5) - (titleLabel.frame.height * 0.5), titleLabel.frame.width - originDiff, titleLabel.frame.height)
            }
        }
    }
    
    private func commonInit() {
        self.setTitleColor(UIColor.darkGrayColor(), forState: .Highlighted)
    }
}