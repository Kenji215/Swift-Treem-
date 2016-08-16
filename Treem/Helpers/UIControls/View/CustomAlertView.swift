//
//  CustomAlertView.swift
//  Treem
//
//  Created by Matthew Walker on 10/20/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class CustomAlertViews {
    
    static func showNoNetworkAlertView(willDismiss: (() -> ())? = nil) {
        CustomAlertViews.showCustomAlertView(
            title       : Localization.sharedInstance.getLocalizedString("no_network_title", table: "Common"),
            message     : Localization.sharedInstance.getLocalizedString("no_network_message", table: "Common"),
            willDismiss : willDismiss)
    }
    
    static func showGeneralErrorAlertView(fromViewController: UIViewController? = nil, willDismiss: (() -> ())? = nil) {
        CustomAlertViews.showCustomAlertView(
            title               : Localization.sharedInstance.getLocalizedString("error", table: "Common"),
            message             : Localization.sharedInstance.getLocalizedString("error_general", table: "Common"),
            fromViewController  : fromViewController,
            willDismiss         : willDismiss
        )
    }
    
    static private func getCustomAlertController(title title: String, message: String) -> UIAlertController {
        return UIAlertController(
            title           : title,
            message         : message,
            preferredStyle  : UIAlertControllerStyle.Alert
        )
    }
    
    static func showCustomAlertView(title title: String, message: String, fromViewController: UIViewController? = nil, willDismiss: (() -> ())? = nil) {
        if message == "" {
            CustomAlertViews.showGeneralErrorAlertView(willDismiss: willDismiss)
        }
        else {
            let alertVC     = CustomAlertViews.getCustomAlertController(title: title, message: message)
            let appDelegate = AppDelegate.getAppDelegate()
            
            alertVC.addAction(UIAlertAction(title: Localization.sharedInstance.getLocalizedString("ok", table: "Common"), style: .Default, handler: { (action: UIAlertAction!) in
                alertVC.dismissViewControllerAnimated(false, completion: nil)
                
                willDismiss?()
            }))
            
            // present alert view controller
            (fromViewController ?? appDelegate.window?.rootViewController)?.presentViewController(alertVC, animated: true, completion: nil)
        }
    }
    
    static func showCustomConfirmView(title title: String, message: String, fromViewController: UIViewController? = nil, yesHandler: ((UIAlertAction) -> Void)?, noHandler: ((UIAlertAction) -> Void)?)  {
        let alertVC     = CustomAlertViews.getCustomAlertController(title: title, message: message)
        let appDelegate = AppDelegate.getAppDelegate()
        
        alertVC.addAction(UIAlertAction(
            title   : Localization.sharedInstance.getLocalizedString("ok", table: "Common"),
            style   : .Default,
            handler : yesHandler
        ))
        
        alertVC.addAction(UIAlertAction(
            title   : Localization.sharedInstance.getLocalizedString("cancel", table: "Common"),
            style   : .Cancel,
            handler : noHandler
        ))
        
        // present alert view controller
        (fromViewController ?? appDelegate.window?.rootViewController)?.presentViewController(alertVC, animated: true, completion: nil)
    }
}
