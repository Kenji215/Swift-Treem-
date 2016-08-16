//
//  ReselectableSegmentedControl.swift
//  Treem
//
//  Created by Matthew Walker on 11/3/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class ReselectableSegmentedControl: UISegmentedControl {
    @IBInspectable var allowReselection: Bool = true
    
    var previousSelectedSegmentIndex: Int = -1
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.previousSelectedSegmentIndex = self.selectedSegmentIndex
        
        super.touchesEnded(touches, withEvent: event)
        
        if self.allowReselection && self.previousSelectedSegmentIndex == self.selectedSegmentIndex {
            if let touch = touches.first {
                let touchLocation = touch.locationInView(self)
                
                if CGRectContainsPoint(self.bounds, touchLocation) {
                    self.sendActionsForControlEvents(.ValueChanged)
                }
            }
        }
    }
}