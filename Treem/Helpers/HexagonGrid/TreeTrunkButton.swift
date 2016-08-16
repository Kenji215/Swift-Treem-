//
//  TreeTrunkButton.swift
//  Treem
//
//  Created by Matthew Walker on 8/19/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

@IBDesignable
class TreeTrunkButton : UIButton {
    private var fillColorLock   : Bool = false
    
    var topTrunk             : Triangle!
    var bottomTrunkExpandable: Rectangle!
    
    // settings
    var hexagonRadius   : CGFloat = 50
    var hexagonHeight   : CGFloat = 110
    var hexagonWidth    : CGFloat = 55
    
    @IBInspectable
    var fillColor       : UIColor = UIColor.grayColor() {
        willSet {
            // update sub view backgrounds when main fill color set
            if(self.topTrunk != nil) {
                self.topTrunk.fillShapeColor = newValue
            }
            
            if(self.bottomTrunkExpandable != nil) {
                self.bottomTrunkExpandable.fillShapeColor = newValue
            }
        }
    }
    
    var fillColorInitial: UIColor = UIColor.grayColor() {
        didSet {
            self.fillColor = self.fillColorInitial
        }
    }
    
    @IBInspectable
    var lineWidth       : CGFloat = 2.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        // draw triangle for top of trunk
        self.topTrunk       = Triangle()
        let topTrunkHeight  = (self.hexagonRadius * cos(2.0 * CGFloat(M_PI) / 6))
        
        self.topTrunk.frame                  = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.width, topTrunkHeight)
        self.topTrunk.fillShapeColor         = self.fillColor
        self.topTrunk.backgroundColor        = UIColor.clearColor()
        self.topTrunk.userInteractionEnabled = false
        
        self.insertSubview(topTrunk, atIndex: 0)

        // draw rectangle for remainder of trunk (can scale in view)
        self.bottomTrunkExpandable                          = Rectangle()
        self.bottomTrunkExpandable.frame                    = CGRectMake(topTrunk.frame.minX, topTrunk.frame.maxY, topTrunk.frame.width, self.superview!.frame.height - topTrunk.frame.maxY)
        self.bottomTrunkExpandable.fillShapeColor           = self.fillColor
        self.bottomTrunkExpandable.backgroundColor          = UIColor.clearColor()
        self.bottomTrunkExpandable.userInteractionEnabled   = false
        
        self.insertSubview(bottomTrunkExpandable, atIndex: 0)
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        var isInside = false
        
        if (self.bottomTrunkExpandable != nil) {
            isInside = CGRectContainsPoint(bottomTrunkExpandable.frame, point)
        }
        
        if (!isInside && self.topTrunk != nil) {
            isInside = CGRectContainsPoint(topTrunk.frame, point)
        }
        
        return isInside
    }
    
    override var highlighted: Bool {
        didSet {
            if(highlighted) {
                if(!self.fillColorLock) {
                    self.fillColorInitial   = fillColor.copy() as! UIColor
                    self.fillColor          = self.fillColor.lighterColorForColor()
                    
                    self.fillColorLock      = true
                }
            }
            else {
                self.fillColor      = self.fillColorInitial
                self.fillColorLock  = false
            }
        }
    }
}
