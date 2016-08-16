//
//  MenuItemButton.swift
//  Treem
//
//  Created by Matthew Walker on 3/4/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//


import UIKit

@IBDesignable
class MenuItemButton: UIButton {
    
    @IBInspectable
    var iconTextVerticalSpacer: CGFloat = 5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var titleFrame  = CGRectZero
        var iconFrame   = CGRectZero
        
        // position title
        if let titleLabel = self.titleLabel {
            titleFrame = titleLabel.frame
            titleFrame = CGRectMake(0, self.bounds.height - titleFrame.size.height, self.bounds.width, titleFrame.size.height)
            
            titleLabel.frame            = titleFrame
            titleLabel.textAlignment    = .Center
        }
        
        // position image
        if let imageView = self.imageView {
            let iconSize = CGSize(width: self.bounds.size.width, height: 24)
            let scaledSize = UIImage.getResizeImageScaleSize(iconSize, oldSize: imageView.image!.size)

            iconFrame = CGRectMake((self.bounds.size.width * 0.5 - scaledSize.width * 0.5), 0, scaledSize.width, scaledSize.height)
            
            imageView.frame = iconFrame
        }
        
        // if both title and icon present
        if titleFrame != CGRectZero && iconFrame != CGRectZero {
            // position both in center if both present (with spacer in between)
            let totalHeight = titleFrame.height + iconFrame.height + iconTextVerticalSpacer
            
            var minY = self.bounds.size.height * 0.5  - (totalHeight * 0.5)
            
            if minY < 0 {
                minY = 0
            }
            
            imageView?.frame.origin.y   = minY
            titleLabel?.frame.origin.y  = minY + iconTextVerticalSpacer + iconFrame.height
        }
    }
}
