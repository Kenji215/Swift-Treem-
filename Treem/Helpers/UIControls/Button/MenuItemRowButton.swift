//
//  MenuItemRowButton.swift
//  Treem
//
//  Created by Matthew Walker on 3/22/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

@IBDesignable
class MenuItemRowButton : UIButton {
    
    private let iconWidth           : CGFloat = 34
    private let iconHeight          : CGFloat = 22
    private let iconTextWidthSpacer : CGFloat = 10
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var titleFrame  = CGRectZero
        var iconFrame   = CGRectZero
        
        // position title
        if let titleLabel = self.titleLabel {
            titleFrame = titleLabel.frame
//            titleFrame = CGRectMake(34, self.bounds.height - titleFrame.size.height, self.bounds.width, titleFrame.size.height)
//            
//            titleLabel.frame            = titleFrame
//            titleLabel.textAlignment    = .Center
        }
        
        // position image
        if let imageView = self.imageView {
            let scaledSize  = UIImage.getResizeImageScaleSize(CGSize(width: self.iconWidth, height: self.iconHeight), oldSize: imageView.image!.size)
//
            iconFrame = CGRectMake(self.iconWidth * 0.5 - scaledSize.width * 0.5, self.bounds.height * 0.5 - scaledSize.height * 0.5, scaledSize.width, scaledSize.height)
            
            imageView.frame = iconFrame
        }
        
        // if both title and icon present
        if titleFrame != CGRectZero && iconFrame != CGRectZero {
            // position both in center if both present (with spacer in between)
//            let totalHeight = titleFrame.height + iconFrame.height + iconTextVerticalSpacer
//            
//            var minY = self.bounds.size.height * 0.5  - (totalHeight * 0.5)
//            
//            if minY < 0 {
//                minY = 0
//            }
            
//            imageView?.frame.origin.y   = self.bounds.height
            titleLabel?.frame.origin.x  = self.iconWidth + self.iconTextWidthSpacer
        }
    }
}
