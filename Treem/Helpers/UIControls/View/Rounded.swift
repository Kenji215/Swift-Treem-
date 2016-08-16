//
//  Rounded.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/15/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class Rounded : UIView{
    
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
        //let c = UIGraphicsGetCurrentContext()
        
        //CGContextSetStrokeColorWithColor(c , UIColor.redColor().CGColor)
        //CGContextStrokePath(c)
        
        
        let context = UIGraphicsGetCurrentContext()
        
        CGContextBeginPath(context)
        
        CGContextAddRect(context, CGRectMake(10, 10, 80, 80))
        
        // top middle
        CGContextMoveToPoint(context, CGRectGetMidX(rect), CGRectGetMinY(rect))     // top middle
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect))  // bottom right
        CGContextAddLineToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect))  // bottom left
        
        CGContextClosePath(context)
        
        CGContextSetFillColorWithColor(context, self.fillShapeColor?.CGColor)
        CGContextFillPath(context)
        
        self.isDrawn = true
        
    }
}
