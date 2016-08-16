//
//  KeyboardHelper.swift
//  Treem
//
//  Created by Matthew Walker on 3/31/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class KeyboardHelper {
    static func adjustViewAboveKeyboard(willChangeFrameNotification: NSNotification, currentView: UIView, constraint: NSLayoutConstraint, layoutUpdateView: UIView? = nil, completion: (()->())? = nil) {
        var info                    = willChangeFrameNotification.userInfo!
        
        // keyboard info values
        let keyboardEndFrame        = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let duration                = info[UIKeyboardAnimationDurationUserInfoKey] as! Double
        let curve                   = info[UIKeyboardAnimationCurveUserInfoKey] as! UInt
        
        // other frame values
        let deviceBounds                = Device.sharedInstance.mainScreen.bounds
        let isOpen                      = keyboardEndFrame.origin.y >= 0 && keyboardEndFrame.origin.y < deviceBounds.height
        let currentViewFrame            = currentView.convertRect(currentView.frame, toView: nil)
        let currentViewDistanceBottom   = deviceBounds.maxY - currentViewFrame.maxY

        // finish any layout needed prior to applying constraint
        currentView.layoutIfNeeded()
        layoutUpdateView?.layoutIfNeeded()
        
        constraint.constant = isOpen ? keyboardEndFrame.size.height - currentViewDistanceBottom : 0
        
        // calculate delay based on textfield distance from bottom
        let delay: NSTimeInterval = isOpen ? Double(currentViewDistanceBottom / keyboardEndFrame.height) * duration * 0.35 : 0
        
        UIView.animateWithDuration(
            duration,
            delay: delay,
            options: UIViewAnimationOptions(rawValue: curve),
            animations: {
                () -> Void in
                
                (layoutUpdateView ?? currentView).layoutIfNeeded()
            },
            completion: {
                _ in
                
                completion?()
            }
        )
    }
}
