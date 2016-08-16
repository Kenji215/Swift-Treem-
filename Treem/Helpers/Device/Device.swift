//
//  Device.swift
//  Treem
//
//  Created by Matthew Walker on 10/20/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

enum ScreenType: CGFloat {
    case iPhone4 = 480.0
    case iPhone5 = 568.0
    case iPhone6 = 667.0
    case iPhone6Plus = 736.0
    case Unknown = 0.0
}
class Device {
    static let sharedInstance = Device()
    
    var iPhone: Bool {
        return UIDevice().userInterfaceIdiom == .Phone
    }
    
    var mainScreen: UIScreen {
        return UIScreen.mainScreen()
    }

    var screenSize: CGFloat? {
        return self.mainScreen.bounds.height
    }
    
    // smaller than iphone5 resolution
    func isResolutionSmallerThaniPhone5() -> Bool {
        return screenSize < ScreenType.iPhone5.rawValue
    }
    
    func isResolutionSmallerThaniPhone6() -> Bool {
        return screenSize < ScreenType.iPhone6.rawValue
    }
    
    func isResolutionSmallerThaniPhone6Plus() -> Bool {
        return screenSize < ScreenType.iPhone6Plus.rawValue
    }
    
    func isRetina() -> Bool {
        return self.mainScreen.respondsToSelector(#selector(NSDecimalNumberBehaviors.scale)) && self.mainScreen.scale >= 2.0
    }
    
    func isiPad() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }
    
    func isSimulator() -> Bool {
        return (TARGET_OS_SIMULATOR != 0) || (TARGET_IPHONE_SIMULATOR != 0)
    }
}