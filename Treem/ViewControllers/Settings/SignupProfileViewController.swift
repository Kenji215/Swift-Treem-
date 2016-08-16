//
//  SignupProfileViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/14/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class SignupProfileViewController : UIViewController {
    
    @IBOutlet weak var usernameTextField        : RectangleTextField!
    @IBOutlet weak var firstNameTextField       : RectangleTextField!
    @IBOutlet weak var lastNameTextField        : RectangleTextField!
    @IBOutlet weak var birthDateTextField       : RectangleTextField!
    @IBOutlet weak var nextButton               : UIButton!
    @IBOutlet weak var phoneNumberLabel         : UILabel!
    @IBOutlet weak var userNameErrorLabel       : UILabel!
    @IBOutlet weak var firstNameErrorLabel      : UILabel!
    @IBOutlet weak var lastNameErrorLabel       : UILabel!
    @IBOutlet weak var birthDateErrorLabel      : UILabel!
    
    @IBOutlet weak var userNameErrorLabelHeightConstraint   : NSLayoutConstraint!
    @IBOutlet weak var firstNameErrorLabelHeightConstraint  : NSLayoutConstraint!
    @IBOutlet weak var lastNameErrorLabelHeightConstraint   : NSLayoutConstraint!
    
    @IBOutlet weak var birthDateErrorLabelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var nextButtonBottomConstraint: NSLayoutConstraint!
    
    @IBAction func usernameTextFieldEditingChanged(sender: AnyObject) {
        self.checkUsername()
        self.checkSaveButtonEnable()
    }
    
    @IBAction func firstNameTextFieldEditingChanged(sender: AnyObject) {
        self.checkFirstName()
        self.checkSaveButtonEnable()
    }
    
    @IBAction func lastNameTextFieldEditingChanged(sender: AnyObject) {
        self.checkLastName()
        self.checkSaveButtonEnable()
    }
    
    @IBAction func birthDateTextFieldEditingDidBegin(sender: UITextField) {
        // show date picker
        self.datePicker = UIDatePicker()
        
        self.datePicker.datePickerMode   = UIDatePickerMode.Date
        self.datePicker.backgroundColor  = UIColor.whiteColor()
        
        // get minimum date
        let calendar        = NSCalendar.currentCalendar()
        let dateComponents  = NSDateComponents()
        
        dateComponents.year     = 1900
        dateComponents.month    = 1
        dateComponents.day      = 1
        
        self.datePicker.minimumDate = calendar.dateFromComponents(dateComponents)
        
        sender.inputView = self.datePicker
        
        self.datePicker.addTarget(self, action: #selector(SignupProfileViewController.birthDatePickerValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        // if first time loading date picker, set it to the server dob
        if(self.datePickerDate != nil){
            self.datePicker.setDate(self.datePickerDate!, animated: false)
        }
        else{
            self.datePicker.setDate(self.maxDatePickerDate!, animated: false)
            self.birthDatePickerValueChanged(self.datePicker)
        }
    }
    
    @IBAction func birthDateTextFieldEditingDidEnd(sender: UITextField) {
        let dobError = self.checkDob(true)
        self.checkSaveButtonEnable(dobError)
    }

    @IBAction func nextButtonTouchUpInside(sender: AnyObject) {
        self.dismissKeyboard()
        
        if let username = self.usernameTextField.text, firstName = self.firstNameTextField.text, lastName = self.lastNameTextField.text {
        
            // create user from form data
            let user = User()
            
            user.username   = username.trim()
            user.firstName  = firstName.trim()
            user.lastName   = lastName.trim()
            user.dob        = self.datePicker.date

            self.loadingMaskViewController.queueLoadingMask(self.view, showCompletion: {
                // call authentication service
                TreemAuthenticationService.sharedInstance.registerUser(
                    user,
                    success: {
                        (data) -> Void in
                        
                        self.loadingMaskViewController.cancelLoadingMask({
                            // show main screen if successful
                            AppDelegate.getAppDelegate().showMainScreen(true)
                        })
                    },
                    failure: {
                        (error, wasHandled) -> Void in
                        
                        // cancel loading mask and return to view with alert
                        self.loadingMaskViewController.cancelLoadingMask({
                            // invalid phone number
                            if error == TreemServiceResponseCode.GenericResponseCode3 {
                                CustomAlertViews.showCustomAlertView(
                                    title   : Localization.sharedInstance.getLocalizedString("username_exists", table: "SignupProfile"),
                                    message : Localization.sharedInstance.getLocalizedString("username_exists_message", table: "SignupProfile")
                                )
                            }
                            else if !wasHandled {
                                CustomAlertViews.showGeneralErrorAlertView()
                            }
                        })
                    }
                )
            })
        }
    }
    
    // dob must be at least 13
    private var maxDatePickerDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Year, value: -13, toDate: NSDate(), options: [])
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    private var datePicker                  : UIDatePicker!
    private var datePickerDate              : NSDate? = nil
    
    private var errorLabelHeightConstraint: CGFloat = 20 // updated from storyboard
    
    private var isUsernameUnique = true
    
    var phoneNumber: String? = nil
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    //handle moving elements when keyboard is shown
    func keyboardWillChangeFrame(notification: NSNotification) {
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.nextButtonBottomConstraint)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SignupProfileViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        self.phoneNumberLabel.text = phoneNumber ?? "-"
        
        // disable next button initially
        AppStyles.sharedInstance.setButtonDefaultStyles(self.nextButton)
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.nextButton, enabled: false)
        
        self.errorLabelHeightConstraint = firstNameErrorLabelHeightConstraint.constant
        
        // hide error labels initially
        self.userNameErrorLabelHeightConstraint.constant    = 0
        self.firstNameErrorLabelHeightConstraint.constant   = 0
        self.lastNameErrorLabelHeightConstraint.constant    = 0
        self.birthDateErrorLabelHeightConstraint.constant   = 0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // add observers to listen for the keyboard to be pulled up or hidden
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SignupProfileViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    // clear open keyboards on tap
    func dismissKeyboard() {
        self.view.endEditing(true)
        
        if let dp = self.datePicker {
            dp.resignFirstResponder()
            
            // call change event manually
            //self.birthDateTextFieldEditingChanged(self.birthDateTextField)
        }
    }
    
    private func animateErrorHeightConstraint(errorText: String? = nil, errorLabel: UILabel, heightConstraint: NSLayoutConstraint, constant: CGFloat) {
        // alter error text
        if let text = errorText {
            errorLabel.text = " " + text
        }
        else {
            errorLabel.text = nil
        }
        
        if constant != heightConstraint.constant {
            heightConstraint.constant = constant

            UIView.animateWithDuration(
                AppStyles.sharedInstance.viewAnimationDuration,
                animations: {
                    // animate constraint
                    self.view.layoutIfNeeded()
                }
            )
        }
    }
    
    func birthDatePickerValueChanged(sender:UIDatePicker) {
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        birthDateTextField.text = dateFormatter.stringFromDate(sender.date)
        
        self.setDobValue(sender.date)
        
        // see if we can enable the save button
        let dobError = self.checkDob(false)
        self.checkSaveButtonEnable(dobError)
    }
    
    private func checkUsername() {
        let heightConstant  = self.errorLabelHeightConstraint

        if self.isUsernameValid() {
            
            // check if username already taken
            TreemAuthenticationService.sharedInstance.checkUsername(
                self.usernameTextField.text!.trim(),
                failureCodesHandled: [
                    TreemServiceResponseCode.NetworkError, // don't show error if couldn't retrieve result
                    TreemServiceResponseCode.LockedOut
                ],
                success: {
                    data in
                    
                    self.isUsernameUnique = true
                    
                    // check if button should be reenabled
                    self.checkSaveButtonEnable()
                    
                    // clear error if present
                    self.animateErrorHeightConstraint(nil, errorLabel: self.userNameErrorLabel, heightConstraint: self.userNameErrorLabelHeightConstraint, constant: 0)
                },
                failure: {
                    error, wasHandled in
                    
                    if error == TreemServiceResponseCode.GenericResponseCode2 {
                        self.animateErrorHeightConstraint(
                            Localization.sharedInstance.getLocalizedString("username_already_taken", table: "SignupProfile"),
                            errorLabel: self.userNameErrorLabel,
                            heightConstraint: self.userNameErrorLabelHeightConstraint,
                            constant: heightConstant
                        )
                        
                        self.isUsernameUnique = false
                        
                        // disable save if username taken
                        self.checkSaveButtonEnable()
                    }
                }
            )
        }
        else {
            self.isUsernameUnique = true
            
            self.animateErrorHeightConstraint(
                Localization.sharedInstance.getLocalizedString("SZh-Ad-sZX.text", table: "SignupProfile"),
                errorLabel: self.userNameErrorLabel,
                heightConstraint: self.userNameErrorLabelHeightConstraint,
                constant: heightConstant
            )
        }
    }
    
    private func checkFirstName() {
        let isValid         = self.isFirstNameValid()
        let text: String?   = isValid ? nil : Localization.sharedInstance.getLocalizedString("bch-Vy-6Ly.text", table: "SignupProfile")
        let heightConstant  = isValid ? 0 : self.errorLabelHeightConstraint
        
        self.animateErrorHeightConstraint(
            text,
            errorLabel: self.firstNameErrorLabel,
            heightConstraint: self.firstNameErrorLabelHeightConstraint,
            constant: heightConstant
        )
    }
    
    private func checkLastName() {
        let isValid         = self.isLastNameValid()
        let text: String?   = isValid ? nil : Localization.sharedInstance.getLocalizedString("bch-Vy-6Ly.text", table: "SignupProfile")
        let heightConstant  = self.isLastNameValid() ? 0 : self.errorLabelHeightConstraint
        
        self.animateErrorHeightConstraint(
            text,
            errorLabel: self.lastNameErrorLabel,
            heightConstraint: self.lastNameErrorLabelHeightConstraint,
            constant: heightConstant
        )
    }
    
    private func isUsernameValid() -> Bool {
        var isValid = false
        
        // username is alphanumeric
        if var username = self.usernameTextField.text {
            username = username.trim()
            
            if username.characters.count > 0 {
                isValid = username.isAlphaNumeric()
            }
        }
        
        return isValid
    }
    
    private func isFirstNameValid() -> Bool {
        var isValid = false
        
        // first name is letters only
        if var firstName = self.firstNameTextField.text {
            firstName = firstName.trim()
            
            if firstName.characters.count > 0 {
                isValid = firstName.isValidName()
            }
        }
        
        return isValid
    }
    
    private func isLastNameValid() -> Bool {
        var isValid = false
        
        // last name is letters only
        if var lastName = self.lastNameTextField.text {
            lastName = lastName.trim()
            
            if lastName.characters.count > 0 {
                isValid = lastName.isValidName()
            }
        }
        
        return isValid
    }

    private func checkDob(showError: Bool) -> Bool {
        var isValid         = false
        var errorText: String? = nil
        
        let curDate = NSDate()
        
        if(self.datePickerDate != nil) {
            
            print(self.datePickerDate!)
            
            if (self.datePickerDate?.compare(curDate) == NSComparisonResult.OrderedDescending) { //If selected date is greater than today
                errorText = Localization.sharedInstance.getLocalizedString("error_future_date", table: "Profile")
            }
            else if (self.datePickerDate?.compare(self.maxDatePickerDate!) == NSComparisonResult.OrderedDescending) { //If selected date would mean the user is <13 years old
                errorText = Localization.sharedInstance.getLocalizedString("error_under_13", table: "Profile")
            }
            else if (self.datePickerDate?.compare(self.datePicker.minimumDate!) == NSComparisonResult.OrderedAscending) { //If they've picked something from too long ago
                errorText = Localization.sharedInstance.getLocalizedString("error_past_date", table: "Profile")
            }
            else {
                isValid = true
            }
        }

        // show error if we are showing it...
        if(showError){
            let text: String?   = errorText
            let heightConstant  = isValid ? 0 : self.errorLabelHeightConstraint

            self.animateErrorHeightConstraint(
                text,
                errorLabel: self.birthDateErrorLabel,
                heightConstraint: self.birthDateErrorLabelHeightConstraint,
                constant: heightConstant
            )
        }
        
        return isValid
    }

    
    private func checkSaveButtonEnable(dobError: Bool?=nil) -> Bool {
        
        var isDobValid:Bool
        // if a dob error was passed, use it else check it
        if let doberr = dobError { isDobValid = doberr }
        else{ isDobValid = self.checkDob(false) }
        
        let enabled = self.isUsernameUnique &&
                    self.isUsernameValid() &&
                    self.isFirstNameValid() &&
                    self.isLastNameValid() &&
                    isDobValid
        
        
        // enable/disable next button
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.nextButton, enabled: enabled, withAnimation: true)
        
        return enabled
    }
    
    
    func setDobValue(dateObj: NSDate){
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        self.datePickerDate = dateObj
    }
}
