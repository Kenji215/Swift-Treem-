//
//  SecretTreeLoginViewController.swift
//  Treem
//
//  Created by Matthew Walker on 9/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class SecretTreeLoginViewController: UIViewController {
    @IBAction func unwindToSecretTreeLogin(segue: UIStoryboardSegue) {}
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var enterButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var enterButtonBottomConstraint: NSLayoutConstraint!
    
    @IBAction func pinTextFieldEditingChanged(sender: AnyObject) {
        var enabled = false
        
        if let text = pinTextField.text {
            if case 4 ... 8 = text.characters.count {
                enabled = true
            }
        }
        
        // enable/disable next button
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.enterButton, enabled: enabled, withAnimation: true)
    }
    
    @IBAction func EnterTouchUpInside(sender: UIButton) {
        
        // check PIN
        self.loadingMaskViewController.queueLoadingMask(self.view, showCompletion: {
            if let text = self.pinTextField.text {
                TreemAuthenticationService.sharedInstance.checkPin(
                    TreeSession(treeID: CurrentTreeSettings.secretTreeID, token: nil),
                    pin: text,
                    success: {
                        data in
                        
                        // store tree session id
                        let checkPinResponse = CheckPinResponse(json: data)
                        
                        self.currentTreeSessionToken = checkPinResponse.token
                        
                        self.loadingMaskViewController.cancelLoadingMask(nil)
                        
                        // segue to secret tree
                        self.performSegueWithIdentifier("unwindToSecretTreeViewSegue", sender: self)
                    },
                    failure: {
                        error, wasHandled in
                        
                        // cancel loading mask and return to view with alert
                        self.loadingMaskViewController.cancelLoadingMask({
                            // PIN format error
                            if (error == TreemServiceResponseCode.GenericResponseCode2) {
                                CustomAlertViews.showCustomAlertView(
                                    title: Localization.sharedInstance.getLocalizedString("error", table: "Common"),
                                    message: Localization.sharedInstance.getLocalizedString("pin_format_error", table: "SecretTreeLogin"),
                                    willDismiss: {
                                        // clear pin text field
                                        self.pinTextField.text = ""
                                        self.pinTextField.becomeFirstResponder()
                                    }
                                )
                            }
                            // Invalid PIN error
                            else if (error == TreemServiceResponseCode.GenericResponseCode4) {
                                CustomAlertViews.showCustomAlertView(
                                    title: Localization.sharedInstance.getLocalizedString("pin_incorrect_title", table: "SecretTreeLogin"),
                                    message: Localization.sharedInstance.getLocalizedString("pin_incorrect_message", table: "SecretTreeLogin"),
                                    willDismiss: {
                                        // clear pin text field
                                        self.pinTextField.text = ""
                                        self.pinTextField.becomeFirstResponder()
                                    }
                                )
                            }
                            // Locked out error
                            else if (error == TreemServiceResponseCode.GenericResponseCode3) {
                                CustomAlertViews.showCustomAlertView(
                                    title: Localization.sharedInstance.getLocalizedString("pin_lockout_title", table: "SecretTreeLogin"),
                                    message: Localization.sharedInstance.getLocalizedString("pin_lockout_message", table: "SecretTreeLogin"),
                                    willDismiss: {
                                        // clear pin text field
                                        self.pinTextField.text = ""
                                        self.pinTextField.becomeFirstResponder()
                                    }
                                )
                            }
                            else if !wasHandled {
                                CustomAlertViews.showGeneralErrorAlertView()
                            }
                        })
                    }
                )
            }
        })
    }
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    var currentTreeSessionToken: String? = nil
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // default with keyboard open
        UIView.animateWithDuration(
            AppStyles.sharedInstance.viewAnimationDuration,
            animations: {
                () -> Void in
                
                self.pinTextField.becomeFirstResponder()
            }
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load header view styles
        AppStyles.sharedInstance.setSubHeaderBarStyles(headerView)
        
        // disable enter button initially
        AppStyles.sharedInstance.setButtonDefaultStyles(self.enterButton)
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.enterButton, enabled: false)
        
        self.closeButton.tintColor = AppStyles.sharedInstance.whiteColor
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // add observers to listen for the keyboard to be pulled up or hidden
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SecretTreeLoginViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    //handle moving elements when keyboard is shown
    func keyboardWillChangeFrame(notification: NSNotification) {
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.enterButtonBottomConstraint)
    }
}
