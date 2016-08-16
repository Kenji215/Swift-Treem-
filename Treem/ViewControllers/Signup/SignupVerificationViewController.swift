//
//  SignupVerificationViewController.swift
//  Treem
//
//  Created by Matthew Walker on 10/5/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class SignupVerificationViewController: UIViewController {
    
    var changingNumber                              : Bool? = nil                   // used to tell if we're changing an existing number or setting a new one
    var callingViewController                       : UIViewController? = nil
    var callingPhoneLabel                           : UILabel? = nil
    
    @IBOutlet weak var closeButton                  : UIButton!
    @IBOutlet weak var signupCodeLabel              : UILabel!
    @IBOutlet weak var sendNewCodeButton            : UIButton!
    
    @IBOutlet weak var verificationCodeTextField    : RectangleTextField!
    @IBOutlet weak var verificationFormView         : UIView!
    
    @IBOutlet weak var helpTextView                 : UITextView!
    
    @IBOutlet weak var helpTextViewHeightConstraint : NSLayoutConstraint!
    @IBOutlet weak var nextButton                   : UIButton!
    @IBOutlet weak var phoneNumberLabel             : UILabel!
    @IBOutlet weak var resendVerificationCodeButton : UIButton!
    @IBOutlet weak var resendCodeSentLabel          : UILabel!
    @IBOutlet weak var nextButtonBottomConstraint   : NSLayoutConstraint!
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.dismissView()
    }
    
    @IBAction func verificationCodeTextEditingChanged(sender: AnyObject) {
        var enabled = false
        
        // check if code entered
        if let code = self.verificationCodeTextField.text {
            // at least 3 characters entered
            if code.characters.count > 2 {
                enabled = true
            }
        }
        
        // enable/disable next button
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.nextButton, enabled: enabled, withAnimation: true)
    }
    
    // hit next -> check invitation/validation code
    @IBAction func nextButtonTouchUpInside(sender: AnyObject) {
        
        if let verifyCode = self.verificationCodeTextField.text {
            let appDelegate = AppDelegate.getAppDelegate()
            
            self.loadingMaskViewController.queueLoadingMask(
                appDelegate.window!,
                showCompletion: {
                
                if(self.changingNumber == true){
                    TreemProfileService.sharedInstance.verifyAccessInformation(
                        self.phoneNumberDigits,
                        verificationCode: verifyCode.trim(),
                        success: {
                            (data) -> Void in
                            
                            self.loadingMaskViewController.cancelLoadingMask(nil)
                            
                            if data.intValue == 0 {
                                // update the phone label of the calling view (if passed)
                                if(self.callingPhoneLabel != nil) { self.callingPhoneLabel!.text = self.phoneNumberDigits }
                                
                                CustomAlertViews.showCustomAlertView(
                                    title: Localization.sharedInstance.getLocalizedString("phone_changed_title", table: "SignupVerification"),
                                    message: Localization.sharedInstance.getLocalizedString("phone_changed_message", table: "SignupVerification"),
                                    fromViewController: self,
                                    willDismiss: {
                                        self.dismissView()
                                    }
                                )
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
                                if (error == TreemServiceResponseCode.GenericResponseCode3){
                                    CustomAlertViews.showCustomAlertView(
                                        title: Localization.sharedInstance.getLocalizedString("invalid_code_title", table: "SignupVerification"),
                                        message: Localization.sharedInstance.getLocalizedString("invalid_code_message", table: "SignupVerification"),
                                        fromViewController: self,
                                        willDismiss:  {
                                            self.verificationCodeTextField.becomeFirstResponder()
                                            self.verificationCodeTextField.text = nil
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
                    TreemAuthenticationService.sharedInstance.verifyUserDevice(
                        self.phoneNumberDigits,
                        signupCode: verifyCode.trim(),
                        success: {
                            (data) -> Void in

                            self.loadingMaskViewController.cancelLoadingMask({
                                let userLoginResponse = UserLoginResponse(json: data)
                                
                                if userLoginResponse.userStatus == User.UserStatus.Full {
                                    appDelegate.showMainScreen(true)
                                }
                                else if userLoginResponse.userStatus == User.UserStatus.TempVerified {
                                    // user needs to setup profile information
                                    let signupProfileVC = UIStoryboard(name: "SignupProfile", bundle: nil).instantiateInitialViewController() as! SignupProfileViewController
                                    
                                    signupProfileVC.phoneNumber = self.phoneNumberLabel.text
                                    
                                    self.navigationController?.pushViewController(signupProfileVC, animated: true)
                                }
                                else if userLoginResponse.userStatus == User.UserStatus.TempUnverified {
                                    CustomAlertViews.showCustomAlertView(
                                        title: Localization.sharedInstance.getLocalizedString("unverified_user_title", table: "SignupVerification"),
                                        message: Localization.sharedInstance.getLocalizedString("unverified_user_message", table: "SignupVerification"),
                                        willDismiss:  {
                                            self.verificationCodeTextField.becomeFirstResponder()
                                            self.verificationCodeTextField.text = nil
                                        }
                                    )
                                }
                                // user status nil
                                else {
                                    CustomAlertViews.showCustomAlertView(
                                        title: Localization.sharedInstance.getLocalizedString("invalid_user_title", table: "SignupVerification"),
                                        message: Localization.sharedInstance.getLocalizedString("invalid_user_message", table: "SignupVerification")
                                    )
                                }
                            })
                        },
                        failure: {
                            (error) -> Void in

                            // cancel loading mask and return to view with alert
                            self.loadingMaskViewController.cancelLoadingMask({
                                CustomAlertViews.showCustomAlertView(
                                    title: Localization.sharedInstance.getLocalizedString("invalid_code_title", table: "SignupVerification"),
                                    message: Localization.sharedInstance.getLocalizedString("invalid_code_message", table: "SignupVerification")
                                )
                            })
                        }
                    )
                }
            })
        }
    }
    
    @IBAction func resendVerificationCodeTouchUpInside(sender: AnyObject) {
        self.loadingMaskViewController.queueLoadingMask(self.resendVerificationCodeButton, showCompletion: {
            
            if(self.changingNumber == true){
                TreemProfileService.sharedInstance.changeAccessInformation(
                    self.phoneNumberDigits,
                    success: {
                        (data) -> Void in
                        
                        self.loadingMaskViewController.cancelLoadingMask(nil)
                        self.displayLastRequestDate()
                    },
                    failure: {
                        (error, wasHandled) -> Void in
                        
                        // cancel loading mask and return to view with alert
                        self.loadingMaskViewController.cancelLoadingMask({

                            // if someone else took this number while waiting....
                            // show error and go back a screen
                            if (error == TreemServiceResponseCode.GenericResponseCode4){
                                CustomAlertViews.showCustomAlertView(
                                    title   : Localization.sharedInstance.getLocalizedString("existing_number", table: "SignupPhoneNumber"),
                                    message : Localization.sharedInstance.getLocalizedString("existing_number_other_message", table: "SignupPhoneNumber"),
                                    fromViewController: self,
                                    willDismiss:  {
                                        self.dismissViewControllerAnimated(true, completion: nil)
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
                    self.phoneNumberDigits,
                    success: {
                        (data) -> Void in
                        self.loadingMaskViewController.cancelLoadingMask(nil)
                        self.displayLastRequestDate()
                    },
                    failure: {
                        (error) -> Void in
                        
                        // cancel loading mask and return to view with alert
                        self.loadingMaskViewController.cancelLoadingMask({
                            CustomAlertViews.showGeneralErrorAlertView()
                        })
                    }
                )
            }
        })
    }
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    var phoneNumberDigits: String = ""
    
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
        
        // if there is room, open the keyboard automatically
        if !Device.sharedInstance.isResolutionSmallerThaniPhone5() {
            UIView.animateWithDuration(
                AppStyles.sharedInstance.viewAnimationDuration,
                animations: {() -> Void in
                    self.verificationCodeTextField.becomeFirstResponder()
                }
            )
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // disable next button initially
        AppStyles.sharedInstance.setButtonDefaultStyles(self.nextButton)
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.nextButton, enabled: false)
        
        self.helpTextView.removeEdgeInsets()
        
        // show phone number label
        if self.phoneNumberDigits != "" {
            self.phoneNumberLabel.text = self.phoneNumberDigits
        }
        else {
            // shouldn't reach this case
            self.phoneNumberLabel.hidden = true
        }
        
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // load translated text into textview (xcode bug, uitextview not translated directly)
        if(self.changingNumber != true){
            self.helpTextView.setTextSafely(Localization.sharedInstance.getLocalizedString("Hkk-9p-PYf.text", table: "SignupVerification"))
        }
        else{   // if changing phone number, change some of the text
            self.closeButton.setTitle(Localization.sharedInstance.getLocalizedString("close_button", table: "SignupVerification"), forState: .Normal)
            self.signupCodeLabel.text = Localization.sharedInstance.getLocalizedString("verification_title", table: "SignupVerification")
            self.helpTextView.setTextSafely(Localization.sharedInstance.getLocalizedString("verification_message", table: "SignupVerification"))
            self.sendNewCodeButton.setTitle(Localization.sharedInstance.getLocalizedString("verification_send_new", table: "SignupVerification"), forState: .Normal)
        }
        
        // adjust text view height layout based on text content
        self.helpTextViewHeightConstraint.constant = self.helpTextView.sizeThatFits(self.helpTextView.bounds.size).height
    }
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.verificationCodeTextField.resignFirstResponder()
        super.touchesBegan(touches, withEvent: event)
    }
    
    private func dismissView(){
        self.view.endEditing(true)      // clear keyboard first
        if(self.callingViewController != nil){
            self.dismissViewControllerAnimated(false, completion: {self.callingViewController!.dismissViewControllerAnimated(false, completion: nil)})
        }
        else{
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    private func displayLastRequestDate(){
        let formatter = NSDateFormatter()
        
        formatter.timeStyle = .ShortStyle
        
        self.resendCodeSentLabel.text   = Localization.sharedInstance.getLocalizedString("last_requested_at", table: "SignupVerification") + " " + formatter.stringFromDate(NSDate())
        self.resendCodeSentLabel.hidden = false
    }
    
    //handle moving elements when keyboard is shown
    func keyboardWillChangeFrame(notification: NSNotification) {
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.nextButtonBottomConstraint)
    }
}
