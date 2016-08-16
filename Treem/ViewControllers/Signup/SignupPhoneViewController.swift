//
//  SignupPhoneViewController.swift
//  Treem
//
//  Created by Matthew Walker on 10/5/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import libPhoneNumber_iOS

class SignupPhoneViewController: UIViewController {
    
    var changingNumber                              : Bool? = nil       // used to tell if we're changing an existing number or setting a new one
    var callingPhoneLabel                           : UILabel? = nil    // label passed by calling view to update phone number when changed
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var cellphoneTextField           : RectangleTextField!
    @IBOutlet weak var LoginFormView                : UIView!
    @IBOutlet weak var nextButton                   : UIButton!
    @IBOutlet weak var helpTextView                 : UITextView!
    @IBOutlet weak var helpTextViewHeightConstraint : NSLayoutConstraint!
    
    @IBOutlet weak var nextButtonBottomConstraint: NSLayoutConstraint!
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.view.endEditing(true)      // clear keyboard first
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cellphoneTextFieldEditingChanged(sender: AnyObject) {
        var enabled = false
        
        // check if valid phone number
        if let cellText = self.cellphoneTextField.text {
            let number = NBPhoneNumberUtil().getE164FormattedString(cellText)
            
            enabled = !number.isEmpty
        }

        // enable/disable next button
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.nextButton, enabled: enabled, withAnimation: true)
    }
    
    @IBAction func LoginTouchUpInside(sender: AnyObject) {
        self.cellphoneTextField.resignFirstResponder()

        if let cellText = self.cellphoneTextField.text {
            self.loadingMaskViewController.queueLoadingMask(self.view, showCompletion: {
                
                if(self.changingNumber == true){
                    TreemProfileService.sharedInstance.changeAccessInformation(
                        cellText,
                        success: {
                            (data) -> Void in
                            
                            self.loadingMaskViewController.cancelLoadingMask(nil)
                            
                            if data.intValue == 0 {
                                self.performSegueWithIdentifier("verificationCodeSegue", sender: self)
                            }
                            else {
                                CustomAlertViews.showGeneralErrorAlertView()
                            }
                        },
                        failure: {
                            (error, wasHandled) -> Void in
                            
                            // cancel loading mask and return to view with alert
                            self.loadingMaskViewController.cancelLoadingMask({
                                // invalid phone number
                                if ((error == TreemServiceResponseCode.GenericResponseCode1) ||
                                    (error == TreemServiceResponseCode.GenericResponseCode2)) {
                                    CustomAlertViews.showCustomAlertView(
                                        title   : Localization.sharedInstance.getLocalizedString("invalid_number", table: "SignupPhoneNumber"),
                                        message : Localization.sharedInstance.getLocalizedString("invalid_number_message", table: "SignupPhoneNumber"),
                                        fromViewController: self,
                                        willDismiss:  {
                                            self.cellphoneTextField.becomeFirstResponder()
                                        }
                                    )
                                }
                                else if (error == TreemServiceResponseCode.GenericResponseCode3){
                                    CustomAlertViews.showCustomAlertView(
                                        title   : Localization.sharedInstance.getLocalizedString("existing_number", table: "SignupPhoneNumber"),
                                        message : Localization.sharedInstance.getLocalizedString("existing_number_self_message", table: "SignupPhoneNumber"),
                                        fromViewController: self,
                                        willDismiss:  {
                                            self.cellphoneTextField.becomeFirstResponder()
                                        }
                                    )
                                }
                                else if (error == TreemServiceResponseCode.GenericResponseCode4){
                                    CustomAlertViews.showCustomAlertView(
                                        title   : Localization.sharedInstance.getLocalizedString("existing_number", table: "SignupPhoneNumber"),
                                        message : Localization.sharedInstance.getLocalizedString("existing_number_other_message", table: "SignupPhoneNumber"),
                                        fromViewController: self,
                                        willDismiss:  {
                                            self.cellphoneTextField.becomeFirstResponder()
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
                else {
                    // call authentication service
                    TreemAuthenticationService.sharedInstance.checkPhoneNumber(
                        cellText,
                        failureCodesHandled: [
                            TreemServiceResponseCode.InvalidAccessToken
                        ],
                        success: {
                            (data) -> Void in

                            self.loadingMaskViewController.cancelLoadingMask(nil)
                            
                            if data.intValue == 0 {
                                self.performSegueWithIdentifier("verificationCodeSegue", sender: self)
                            }
                            else {
                                CustomAlertViews.showGeneralErrorAlertView()
                            }
                        },
                        failure: {
                            (error, wasHandled) -> Void in
                            
                            // cancel loading mask and return to view with alert
                            self.loadingMaskViewController.cancelLoadingMask({
                                // invalid phone number
                                if error == TreemServiceResponseCode.GenericResponseCode1 {
                                    CustomAlertViews.showCustomAlertView(
                                        title   : Localization.sharedInstance.getLocalizedString("invalid_number", table: "SignupPhoneNumber"),
                                        message : Localization.sharedInstance.getLocalizedString("invalid_number_message", table: "SignupPhoneNumber"),
                                        willDismiss:  {
                                            self.cellphoneTextField.becomeFirstResponder()
                                        }
                                    )
                                }
                                else if error == TreemServiceResponseCode.GenericResponseCode2 {
                                    CustomAlertViews.showCustomAlertView(
                                        title   : "Invitation Only",
                                        message : "Treem is a next generation social media application that will set the standard on how people communicate. We are currently beta testing Treem with a select group of users prior to making it publicly available. Thank you for your interest in Treem. We should be commercially available shortly.",
                                        willDismiss:  {
                                            self.cellphoneTextField.becomeFirstResponder()
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
    }
    
    @IBAction func unwindToSignupCellphone(segue: UIStoryboardSegue) {}
    
    static func getStoryboardInstance() -> SignupPhoneViewController {
        return UIStoryboard(name: "SignupPhoneNumber", bundle: nil).instantiateInitialViewController() as! SignupPhoneViewController
    }
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // default with keyboard open
        UIView.animateWithDuration(
            AppStyles.sharedInstance.viewAnimationDuration,
            animations: {
                () -> Void in
                
                self.cellphoneTextField.becomeFirstResponder()
            }
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.helpTextView.removeEdgeInsets()
        
        // disable next button initially
        AppStyles.sharedInstance.setButtonDefaultStyles(self.nextButton)
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.nextButton, enabled: false)
        
        // hide the close button if not changing phone number (if setting for the first time)
        if(self.changingNumber != true){ self.closeButton.hidden = true }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // add observers to listen for the keyboard to be pulled up or hidden
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignupPhoneViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // load translated text into textview (xcode bug, uitextview not translated directly)
        self.helpTextView.setTextSafely(Localization.sharedInstance.getLocalizedString("EiQ-et-LzY.text", table: "SignupPhoneNumber"))
        
        // adjust text view height layout based on text content
        self.helpTextViewHeightConstraint.constant = self.helpTextView.sizeThatFits(self.helpTextView.bounds.size).height
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // pass phone number when going to verification code view
        if segue.identifier == "verificationCodeSegue" {
            if let verifyVC = segue.destinationViewController as? SignupVerificationViewController {
                verifyVC.phoneNumberDigits = NBPhoneNumberUtil().getE164FormattedString(self.cellphoneTextField.text!)
                verifyVC.changingNumber = self.changingNumber
                verifyVC.callingViewController = self
                verifyVC.callingPhoneLabel = self.callingPhoneLabel
            }
        }
    }
    
    //handle moving elements when keyboard is shown
    func keyboardWillChangeFrame(notification: NSNotification) {
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.nextButtonBottomConstraint, layoutUpdateView: self.nextButton)
    }
}
