//
//  SecretTreeSignupViewController.swift
//  Treem
//
//  Created by Matthew Walker on 9/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class SecretTreeSignupViewController: UIViewController {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var newPINTextField: UITextField!
    @IBOutlet weak var reenterNewPINTextField: UITextField!
    @IBOutlet weak var currentPINTextField: UITextField!
    @IBOutlet weak var setButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var setButtonBottomConstraint: NSLayoutConstraint!
    
    @IBAction func newPINTextFieldEditingChanged(sender: AnyObject) {
        self.checkPINEntry()
    }
    
    @IBAction func reenterNewPINTextFieldEditingChanged(sender: AnyObject) {
        self.checkPINEntry()
    }
    
    @IBAction func currentPINTextFieldEditingChanged(sender: AnyObject) {
        self.checkPINEntry()
    }
    
    @IBAction func setButtonTouchUpInside(sender: AnyObject) {
        // close keyboard before confirm alert
        self.view.endEditing(true)
        
        // perform form validation
        if let newPINText = newPINTextField.text, let reenterNewPINText = reenterNewPINTextField.text {
            if (newPINText != reenterNewPINText) {
                CustomAlertViews.showCustomAlertView(
                    title: Localization.sharedInstance.getLocalizedString("non_matching_pins_title", table: "SecretTreeSetPin"),
                    message: Localization.sharedInstance.getLocalizedString("non_matching_pins_message", table: "SecretTreeSetPin")
                )
                
                return
            }
        }
        else {
            CustomAlertViews.showCustomAlertView(
                title: Localization.sharedInstance.getLocalizedString("no_pin_entered_title", table: "SecretTreeSetPin"),
                message: Localization.sharedInstance.getLocalizedString("no_pin_entered_message", table: "SecretTreeSetPin")
            )
            
            return
        }
        
        CustomAlertViews.showCustomConfirmView(
            title       : Localization.sharedInstance.getLocalizedString("set_pin_title", table: "SecretTreeSetPin"),
            message     : Localization.sharedInstance.getLocalizedString("set_pin_message", table: "SecretTreeSetPin"),
            yesHandler: {
                (action: UIAlertAction!) in
                
                // set PIN in database
                self.loadingMaskViewController.queueLoadingMask(self.view, showCompletion: {
                    if let pin = self.newPINTextField.text {
                        
                        TreemAuthenticationService.sharedInstance.setPin(
                            TreeSession(treeID: CurrentTreeSettings.secretTreeID, token: nil),
                            pin: pin,
                            existingPin: self.currentPINTextField.text,
                            success: {
                                data in
                                
                                self.loadingMaskViewController.cancelLoadingMask(nil)
                                
                                // unwind back to sign in
                                self.performSegueWithIdentifier("unwindToSecretTreeLoginSegue", sender: self)
                            },
                            failure: {
                                error, wasHandled in
                                
                                // cancel loading mask and return to view with alert
                                self.loadingMaskViewController.cancelLoadingMask({
                                    if !wasHandled {
                                        // PIN format error
                                        if (error == TreemServiceResponseCode.GenericResponseCode2) {
                                            CustomAlertViews.showCustomAlertView(
                                                title: Localization.sharedInstance.getLocalizedString("error", table: "Common"),
                                                message: Localization.sharedInstance.getLocalizedString("pin_format_error", table: "SecretTreeLogin")
                                            )
                                        }
                                            // PIN lockout error
                                        else if (error == TreemServiceResponseCode.GenericResponseCode3) {
                                            CustomAlertViews.showCustomAlertView(
                                                title: Localization.sharedInstance.getLocalizedString("pin_lockout_title", table: "SecretTreeLogin"),
                                                message: Localization.sharedInstance.getLocalizedString("pin_lockout_message", table: "SecretTreeLogin"),
                                                willDismiss: {
                                                    // clear pin text field
                                                    self.newPINTextField.text           = nil
                                                    self.reenterNewPINTextField.text    = nil
                                                    self.currentPINTextField.text       = nil
                                                }
                                            )
                                        }
                                    }
                                    else {
                                        CustomAlertViews.showGeneralErrorAlertView()
                                    }
                                })
                            }
                        )
                    }
                })
            },
            noHandler: nil
        )
    }
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // default with keyboard open
        UIView.animateWithDuration(
            AppStyles.sharedInstance.viewAnimationDuration,
            animations: {
                () -> Void in
                
                self.newPINTextField.becomeFirstResponder()
            }
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load header view styles
        AppStyles.sharedInstance.setSubHeaderBarStyles(self.headerView)
        
        // set disabled initially
        AppStyles.sharedInstance.setButtonDefaultStyles(self.setButton)
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.setButton, enabled: false)
        
        // override appearance styles
        self.backButton.tintColor = UIColor.whiteColor().darkerColorForColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // add observers to listen for the keyboard to be pulled up or hidden
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SecretTreeSignupViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    //handle moving elements when keyboard is shown
    func keyboardWillChangeFrame(notification: NSNotification) {
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.setButtonBottomConstraint)
    }
    
    private func checkPINEntry() {
        var enabled = false
        
        if let newPINText = self.newPINTextField.text {
            if case 4 ... 8 = newPINText.characters.count {
                if let reenterNewPINText = self.reenterNewPINTextField.text {
                    if newPINText == reenterNewPINText {
                        if let currentPINText = self.currentPINTextField.text {
                            let charCount = currentPINText.characters.count

                            if charCount == 0 || (charCount > 3 && charCount < 9) {
                                enabled = true
                            }
                        }
                        else {
                            enabled = true
                        }
                    }
                }
            }
        }
        
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.setButton, enabled: enabled, withAnimation: true)
    }
}
