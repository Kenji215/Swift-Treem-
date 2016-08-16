//
//  UserProfileButton.swift
//  Treem
//
//  Created by Matthew Walker on 4/15/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

@IBDesignable
class UserProfileButton: UIButton {
    
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
            imageView.contentMode = .ScaleAspectFit
            
            let iconFrame = CGRectMake(0, self.bounds.height * 0.5 - 10, 20, 20) // y origin is height + 5 padding
            
            imageView.frame = iconFrame
            
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

