//
//  SeedingInviteViewController.swift
//  Treem
//
//  Created by Matthew Walker on 11/18/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import libPhoneNumber_iOS

class SeedingInviteViewController: UIViewController {
    
    @IBOutlet weak var phoneNumberTextField: RectangleTextField!
    @IBOutlet weak var helpTextView: UITextView!
    @IBOutlet weak var inviteButton: UIButton!
    
    @IBOutlet weak var invitedMessageLabel: UILabel!
    @IBOutlet weak var helpTextViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userContainerView: UIView!
    @IBOutlet weak var userContainerViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction func cancelButtonTouchUpInside(sender: AnyObject) {
        if self.hasPerformedInvite {
            if let onSuccess = self.onInviteSuccess {
                onSuccess()
            }
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func inviteButtonTouchUpInside(sender: AnyObject) {
        self.phoneNumberTextField.resignFirstResponder()

        let userAdd = UserAdd()
        
        userAdd.phone = self.formattedPhone
        
        self.loadingMaskViewController.queueLoadingMask(self.view, showCompletion: {
            TreemSeedingService.sharedInstance.setUsers(
                CurrentTreeSettings.sharedInstance.treeSession,
                branchID: CurrentTreeSettings.sharedInstance.currentBranchID,
                users: [userAdd],
                success: {
                    data in
                    
                    self.loadingMaskViewController.cancelLoadingMask(nil)
                    
                    self.hasPerformedInvite         = true
                    
                    self.invitedMessageLabel.text   = "✓ " + (self.existingMember ? "Member added" : "Invite sent to: " + self.formattedPhone)
                    self.invitedMessageLabel.hidden = false
                    
                    self.phoneNumberTextField.text  = nil
                    
                    self.phoneNumberTextFieldEditingChanged(self.phoneNumberTextField)
                },
                failure: {
                    error, wasHandled in
                    
                    self.loadingMaskViewController.cancelLoadingMask({
                        if !wasHandled {
                            if error == TreemServiceResponseCode.GenericResponseCode5 {
                                CustomAlertViews.showCustomAlertView(title: "Error", message: "Cannot invite your own account", fromViewController: self, willDismiss: {
                                    self.phoneNumberTextField.becomeFirstResponder()
                                })
                            }
                            else {
                                CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: {
                                    self.phoneNumberTextField.becomeFirstResponder()
                                })
                            }
                        }
                    })
                }
            )
        })
    }
    
    @IBAction func phoneNumberTextFieldEditingChanged(sender: AnyObject) {
        var enabled = false
        
        // remove previous user result
        for view in self.userContainerView.subviews {
            view.removeFromSuperview()
        }
        
        self.userContainerViewHeightConstraint.constant = 0
        self.view.layoutIfNeeded()
        
        // cancel previous timer
        if let timer = self.searchTimer {
            timer.invalidate()
        }
        
        // check if valid phone number
        if let phone = self.phoneNumberTextField.text {
            let formattedPhone = NBPhoneNumberUtil().getE164FormattedString(phone)
            
            enabled = !formattedPhone.isEmpty
            
            if enabled {
                self.formattedPhone = formattedPhone
                
                self.loadingMaskViewController.queueLoadingMask(self.inviteButton, showCompletion: {
                    // if search is empty add no delay, otherwise add delay for when typing
                    self.searchTimer = NSTimer.scheduledTimerWithTimeInterval(
                        self.searchTimerDelay,
                        target: self,
                        selector: Selector("checkPhoneNumber:"),
                        userInfo: formattedPhone,
                        repeats: false
                    )
                })
            }
            else {
                self.loadingMaskViewController.cancelLoadingMask(nil)
                
                AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.inviteButton, enabled: false, withAnimation: true)
            }
        }
        else {
            AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.inviteButton, enabled: false)


        }
    }
    
    private let loadingMaskViewController       = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController             = ErrorViewController.getStoryboardInstance()
    
    private var hasPerformedInvite: Bool        = false
    private var formattedPhone: String          = ""
    
    var searchTimer             : NSTimer?
    var searchTimerDelay        : NSTimeInterval = 0.5
    
    var onInviteSuccess         : (()->())?     = nil
    
    var existingMember          : Bool          = false

    var passedNumber            : String?       = ""
    
    static func getStoryboardInstance() -> SeedingInviteViewController {
        return UIStoryboard(name: "SeedingInvite", bundle: nil).instantiateViewControllerWithIdentifier("SeedingInvite") as! SeedingInviteViewController
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateWithDuration(
            AppStyles.sharedInstance.viewAnimationDuration,
            animations: {
                () -> Void in
                
                self.phoneNumberTextField.becomeFirstResponder()
            }
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.invitedMessageLabel.hidden = true

        // If there was a phone number passed to this screen, put it into the textbox and run the validation
        if (self.passedNumber != "") {
            self.phoneNumberTextField.text = self.passedNumber
            self.phoneNumberTextFieldEditingChanged(self.phoneNumberTextField)
        }

        self.helpTextView.removeEdgeInsets()
        
        self.userContainerViewHeightConstraint.constant = 0
        self.view.layoutIfNeeded()
        
        // disable next button initially
        AppStyles.sharedInstance.setButtonDefaultStyles(self.inviteButton)
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.inviteButton, enabled: false)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // adjust text view height layout based on text content
        self.helpTextViewHeightConstraint.constant = self.helpTextView.sizeThatFits(self.helpTextView.bounds.size).height
    }
    
    func checkPhoneNumber(timer: NSTimer) {
        if let phone = timer.userInfo as? String {
            let contact = UserContact()
            
            contact.contactID    = 1
            contact.phoneNumbers = [phone]

            // check phone number
            TreemSeedingService.sharedInstance.searchContacts(
                CurrentTreeSettings.sharedInstance.treeSession,
                contacts: [contact],
                search: phone,
                success: {
                    data in
                    
                    var existingMember = false
                    
                    // get user from return
                    if let user = User.getFirstUserFromContactSearch(data) {
                        if user.id > 0 {
                            // show corresponding user and 'Add'
                            let tableVC = SeedingMembersTableViewController.getStoryboardInstance()
                            
                            user.phone = phone
                            
                            tableVC.users = [user]
                            tableVC.tableView.allowsSelection           = false
                            tableVC.tableView.scrollEnabled             = false
                            tableVC.tableView.userInteractionEnabled    = false
                            
                            tableVC.setUsers([user])
                            
                            let subView = tableVC.view
                            subView.translatesAutoresizingMaskIntoConstraints = false

                            self.userContainerViewHeightConstraint.constant = tableVC.tableView.rowHeight
                            
                            self.userContainerView.addSubview(subView)

                            subView.frame = CGRectMake(0, 0, self.userContainerView.frame.width, tableVC.tableView.rowHeight)
                            
                            UIView.performWithoutAnimation({
                                self.inviteButton.setTitle("Add Member", forState: .Normal)
                                self.inviteButton.layoutIfNeeded()
                            })

                            existingMember = true
                        }
                    }
                    
                    self.existingMember = existingMember
                    
                    if !existingMember {
                        // set back to "Invite" title in case last call resulted in "Add Member"
                        UIView.performWithoutAnimation({
                            self.inviteButton.setTitle("Invite", forState: .Normal)
                            self.inviteButton.layoutIfNeeded()
                        })
                    }
                    
                    AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.inviteButton, enabled: true, withAnimation: false)
                    
                    self.loadingMaskViewController.cancelLoadingMask(nil)
                },
                failure: {
                    error, wasHandled in


                    AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.inviteButton, enabled: false)
                    
                    self.loadingMaskViewController.cancelLoadingMask(nil)
                }
            )
        }
    }
}
