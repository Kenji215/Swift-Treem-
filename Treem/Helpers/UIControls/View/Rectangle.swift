//
//  Rectangle.swift
//  Treem
//
//  Created by Matthew Walker on 8/19/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class Rectangle : UIView {
    private var isDrawn: Bool = false    
    
    @IBInspectable
    var fillShapeColor: UIColor? {
        willSet {
            // redraw to show updated color
            if (self.isDrawn) {
                self.setNeedsDisplay()
            }
        }
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        CGContextBeginPath(context)
        
        // top middle
        CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect))     // top left
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect))  // top right
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect))  // bottom right
        CGContextAddLineToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect))  // bottom left
        
        CGContextClosePath(context)
        CGContextSetFillColorWithColor(context, self.fillShapeColor?.CGColor)
        CGContextFillPath(context)
        
        self.isDrawn = true
    }
}
