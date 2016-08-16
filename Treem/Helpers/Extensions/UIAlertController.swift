//
//  UIAlertController.swift
//  Treem
//
//  Created by Matthew Walker on 3/31/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

extension UIAlertController {
    // fix a bug with iOS9, alerts showing in current window, and device orientation
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

    public override func shouldAutorotate() -> Bool {
        return false
    }
}
