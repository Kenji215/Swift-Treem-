//
//  AppDelegate.swift
//  Treem
//
//  Created by Matthew Walker on 7/8/15.
//  Copyright (c) 2015 Treem LLC. All rights reserved.
//

import UIKit
import OAuthSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        AppStyles.sharedInstance.loadDefaultAppStyles()
        
        self.configPushNotifications()
        
        // Set application window
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        self.window?.makeKeyAndVisible()
        
        // preload keyboard (slow initial delay on first load)
        let field = UITextField()
        self.window?.addSubview(field)
        field.becomeFirstResponder()
        field.resignFirstResponder()
        field.removeFromSuperview()
        
        // set default thread pool for OAuth requests
        OAuthSwiftHTTPRequest.executionContext = {
            block in
            
            return dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
        }
        
        #if DEBUG
            // do nothing
        #else
            // clear keychain of access tokens on first run of application (in case app reinstalled)
            let defaults = NSUserDefaults.standardUserDefaults()
            
            // if app has not been previously loaded
            if defaults.objectForKey("appHasLoaded") == nil {
                
                // clear access tokens in case of reinstall
                TreemOAuthUserTokenStorable.sharedInstance.clearAccessTokens()
                
                defaults.setValue("true", forKey: "appHasLoaded")
                defaults.synchronize()
            }
        #endif
        
        // Check if authenticated show main screen
        if(self.isDeviceAuthenticated()) {
            if(self.isUserAuthenticated()) {
                // both device and user are authenticated show main view
                self.showMainScreen(false)
            }
            else {
                // device is authenticated but user is not, go to user login
                self.showSignup(false)
            }
        }
        else {
            // clear user access tokens just in case
            TreemOAuthUserTokenStorable.sharedInstance.clearAccessTokens()
            
            // device is not authenticated go to initial signup screen
            self.showSignup(false)
        }

        return true
    }
    
    private func configPushNotifications(){
        
        // ask if we can use push notifications
        let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        let uiApp = UIApplication.sharedApplication()
        
        uiApp.registerUserNotificationSettings(settings)
        uiApp.registerForRemoteNotifications()
        
        // clear current app icon badge could since they opened the app
        uiApp.applicationIconBadgeNumber = 0
        
    }
    
    // when application comes back from background
    func applicationDidBecomeActive(application: UIApplication){
        
        // clear badge icone when app becomes active again
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
    
    // receive push notification while app is open...
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]){
        
        //clear icon badge
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        
        // do some other stuff later...
    }
    
    // able to get the device token
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        
        AppSettings.sharedInstance.setDeviceToken(deviceToken)
        
    }
    
    // not able to get the device token
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        
        AppSettings.sharedInstance.device_token = ""
    }

    static func getStatusBarDefaultHeight() -> CGFloat {
        return 20
    }
    
    private func showSignup(animated:Bool) {
        let viewController = UIStoryboard(name: "Signup", bundle: nil).instantiateInitialViewController()
        
        if(animated) {
            UIView.transitionWithView(self.window!, duration: AppStyles.sharedInstance.viewAnimationDuration, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.window?.rootViewController = viewController
                }, completion: nil)
        }
        else {
            self.window?.rootViewController = viewController
        }
    }
    
    // Show main tree screen
    func showMainScreen(animated: Bool) {
        // load the main tree storyboard
        let viewController = MainViewController.getStoryboardInstance()

        if(animated) {
            if let window = self.window {
                UIView.transitionWithView(
                    window,
                    duration: AppStyles.sharedInstance.viewAnimationDuration,
                    options: .TransitionCrossDissolve,
                    animations: {
                        self.window?.rootViewController = viewController
                    },
                    completion: nil
                )
            }
            else {
                self.window?.rootViewController = viewController
            }
        }
        else {
            self.window?.rootViewController = viewController
        }
    }
    
    func isDeviceAuthenticated() -> Bool {
        // if UUID is set
        if TreemOAuthConsumerUUIDStorable.sharedInstance.UUIDIsSet() {
            // check if device specific consumer tokens set
            return TreemOAuthConsumerTokenStorable.sharedInstance.deviceSpecificTokensAreSet()
        }
        else {
            // clear consumer tokens if no UUID present
            TreemOAuthConsumerTokenStorable.sharedInstance.clearConsumerTokens()
            
            return false
        }
    }
    
    private func isUserAuthenticated() -> Bool {
        return TreemOAuthUserTokenStorable.sharedInstance.tokensAreSet()
    }

    func logout(badToken: Bool = false, onCancel: (() -> ())? = nil) {
        
        let logoutClosure: () -> () = {
            self.showSignup(true)
            
            // call logout to clean up resources server side
            TreemAuthenticationService.sharedInstance.logout(
                [
                    TreemServiceResponseCode.InvalidAccessToken,    // ignore invalid access token
                    TreemServiceResponseCode.DisabledOAuthToken     // ignore disabled access token
                ],
                success: {
                    data in
                    
                    // clear user access tokens just in case
                    TreemOAuthUserTokenStorable.sharedInstance.clearAccessTokens()
                },
                failure: {
                    error, wasHandled in
                    
                    // need to reset
                    if (error == TreemServiceResponseCode.InvalidAccessToken || error == TreemServiceResponseCode.DisabledOAuthToken) {
                        // clear user access tokens just in case
                        TreemOAuthUserTokenStorable.sharedInstance.clearAccessTokens()
                    }
                }
            )
        }
        
        if (badToken) {
            CustomAlertViews.showCustomAlertView(
                title: Localization.sharedInstance.getLocalizedString("logout", table: "Common"),
                message: Localization.sharedInstance.getLocalizedString("logout_message", table: "Common"),
                willDismiss: logoutClosure
            )
        }
        else {
            CustomAlertViews.showCustomConfirmView(
                title       : Localization.sharedInstance.getLocalizedString("logout_confirm_title", table: "Common"),
                message     : Localization.sharedInstance.getLocalizedString("logout_confirm_message", table: "Common"),
                yesHandler: {
                    (action: UIAlertAction!) in
            
                    logoutClosure()
                    
                    if let onCancel = onCancel {
                        onCancel()
                    }
                },
                noHandler: {
                    (action: UIAlertAction!) in
                    
                    if let onCancel = onCancel {
                        onCancel()
                    }
                }
            )
        }
    }
    
    func deviceReset(showSignup: Bool = false, showMessage: Bool = false) {
        // clear access tokens
        TreemOAuthUserTokenStorable.sharedInstance.clearAccessTokens()
        
        // clear consumer tokens
        TreemOAuthConsumerTokenStorable.sharedInstance.clearConsumerTokens()
        
        // show signup (shouldn't be true if already on signup)
        if showSignup {
            self.showSignup(true)
        }
        
        if showMessage {
            CustomAlertViews.showCustomAlertView(
                title   : Localization.sharedInstance.getLocalizedString("device_connection_error", table: "Common"),
                message : Localization.sharedInstance.getLocalizedString("device_connection_error_message", table: "Common")
            )
        }
    }
    
    func deviceSignatureError() {
        CustomAlertViews.showCustomAlertView(
            title   : Localization.sharedInstance.getLocalizedString("device_signature_error", table: "Common"),
            message : Localization.sharedInstance.getLocalizedString("device_signature_error_message", table: "Common")
        )
    }
    
    func deviceDisabled() {

        CustomAlertViews.showCustomAlertView(
            title   : Localization.sharedInstance.getLocalizedString("device_disabled", table: "Common"),
            message : Localization.sharedInstance.getLocalizedString("device_disabled_message", table: "Common")
        )
    }
    
    static func getAppDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    static func openAppSettings() {
        if let url = NSURL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}



