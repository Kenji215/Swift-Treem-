//
//  SeedingSearchOptions.swift
//  Treem
//
//  Created by Matthew Walker on 11/19/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import AddressBook
import UIKit

class SeedingSearchOptionsViewController : UIViewController {

    @IBOutlet weak var firstNameCheckboxButton  : CheckboxButton!
    @IBOutlet weak var lastNameCheckboxButton   : CheckboxButton!
    @IBOutlet weak var emailCheckboxButton      : CheckboxButton!
    @IBOutlet weak var phoneCheckboxButton      : CheckboxButton!
    @IBOutlet weak var usernameCheckboxButton   : CheckboxButton!

    @IBOutlet weak var friendsCheckboxButton    : CheckboxButton!
    @IBOutlet weak var pendingCheckboxButton    : CheckboxButton!
    @IBOutlet weak var invitedCheckboxButton    : CheckboxButton!
    @IBOutlet weak var nonfriendsCheckboxButton : CheckboxButton!


    @IBOutlet weak var contactsCheckboxButton: CheckboxButton!

    
    @IBOutlet weak var firstNameLabel   : UILabel!
    @IBOutlet weak var lastNameLabel    : UILabel!
    @IBOutlet weak var emailLabel       : UILabel!
    @IBOutlet weak var phoneLabel       : UILabel!
    @IBOutlet weak var usernameLabel    : UILabel!
    
    @IBOutlet weak var relationshipOptionsView: UIView!

    @IBOutlet weak var relationshipOptionsHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var miscOptionsView: UIView!
    @IBOutlet weak var miscOptionsHeightConstraint: NSLayoutConstraint!


    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
        
        if let delegate = delegate {
            let options = SeedingSearchOptions()
            
            options.matchFirstName          = self.firstNameCheckboxButton.checked
            options.matchLastName           = self.lastNameCheckboxButton.checked
            options.matchEmail              = self.emailCheckboxButton.checked
            options.matchUsername           = self.usernameCheckboxButton.checked
            options.matchPhone              = self.phoneCheckboxButton.checked
            options.searchFriendStatus      = self.friendsCheckboxButton.checked
            options.searchInvitedStatus     = self.invitedCheckboxButton.checked
            options.searchNotFriendsStatus  = self.nonfriendsCheckboxButton.checked
            options.searchPendingStatus     = self.pendingCheckboxButton.checked
            options.includeContacts         = self.contactsCheckboxButton.checked
            
            // check if options differ
            var optionsChanged = false
            
            if let passedOptions = self.passedOptions {
                optionsChanged = !(options == passedOptions)
            }
            else {
                optionsChanged = options.areDefaultOptionsSelected(self.forSearchType)
            }
            
            delegate.didDismissSearchOptions(optionsChanged, options: options)
        }
    }
    
    @IBAction func setDefaultsButtonTouchUpInside(sender: AnyObject) {
        
        for checkbox in self.matchingCheckboxes {
            checkbox.checked = true
            checkbox.userInteractionEnabled = true
        }
        
        for checkbox in self.relationshipCheckboxes {
            checkbox.checked = true
            checkbox.userInteractionEnabled = true
        }

        for checkbox in self.miscCheckboxes {
            checkbox.checked = (ABAddressBookGetAuthorizationStatus() == .Authorized)
            checkbox.userInteractionEnabled = true
        }
    }

    @IBAction func matchingCheckboxButtonTouchUpInside(sender: CheckboxButton) {
        self.checkSectionCheckboxes(self.matchingCheckboxes)
    }
    
    @IBAction func relationshipButtonTouchUpInside(sender: CheckboxButton) {
        self.checkSectionCheckboxes(self.relationshipCheckboxes)
    }


    //If the user checks the "Include Conacts" button, make sure we have permission to search contacts.
    @IBAction func contactSearchTouchUpInside(sender: CheckboxButton) {
        if (sender.checked) {
            let authorization = ABAddressBookGetAuthorizationStatus()
            switch(authorization) {
            case .Denied:
                self.addressBookNotGranted(true)

            case .Restricted:
                self.addressBookNotGranted(false)

            case .Authorized:
                self.promptAddressBookAccess()

            case .NotDetermined:
                self.promptAddressBookAccess()
            }
        }
    }


    private func promptAddressBookAccess() {
        if let addressBook: ABAddressBook = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue() {
            ABAddressBookRequestAccessWithCompletion(addressBook, {
                (granted: Bool, error: CFError!) in

                dispatch_async(dispatch_get_main_queue()) {
                    if !granted {
                        self.addressBookNotGranted(true)
                    }
                }
            })
        }
    }

    //If user tries to search contacts, but the app lacks permissions, then alert the user as such
    //If they have the capacity to grant address book permissions, then add a button to open up permission settings.
    private func addressBookNotGranted(canChangePermission: Bool) {

        self.contactsCheckboxButton.checked = false

        let alertController = UIAlertController(
            title           : "Missing permissions",
            message         : "Treem does not have access to your phone's contacts",
            preferredStyle  : UIAlertControllerStyle.Alert
        )

        alertController.addAction(UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.Cancel,
            handler: nil
        ))

        //If there's the ability to change permissions, then add a button that will open up permission settings
        if (canChangePermission) {
            alertController.addAction(UIAlertAction(
                title: "Go to app permissions",
                style: UIAlertActionStyle.Default,
                handler: self.manageAppSettings
            ))
        }

        self.presentViewController(alertController, animated: true, completion: nil)
    }

    private func manageAppSettings(action: UIAlertAction) {
        AppDelegate.openAppSettings()
    }

    var delegate        : SeedingSearchOptionsDelegate? = nil
    var passedOptions   : SeedingSearchOptions?         = nil
    
    var matchingCheckboxes      : [CheckboxButton] = []
    var relationshipCheckboxes  : [CheckboxButton] = []
    var miscCheckboxes          : [CheckboxButton] = []
    
    var forSearchType: SeedingSearchViewController.SearchType = .NewSearch
    
    static func getStoryboardInstance() -> SeedingSearchOptionsViewController {
        return UIStoryboard(name: "SeedingSearchOptions", bundle: nil).instantiateViewControllerWithIdentifier("SeedingSearchOptions") as! SeedingSearchOptionsViewController
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.matchingCheckboxes = [
            self.firstNameCheckboxButton,
            self.lastNameCheckboxButton,
            self.usernameCheckboxButton,
            self.phoneCheckboxButton
        ]

        self.relationshipCheckboxes = [
            self.friendsCheckboxButton,
            self.invitedCheckboxButton,
            self.pendingCheckboxButton,
            self.nonfriendsCheckboxButton
        ]

        if (self.forSearchType == .SelectBranchFriends || self.forSearchType == .Tagging || self.forSearchType == .SharingBranch) {

            self.relationshipOptionsView.hidden = true
            self.relationshipOptionsHeightConstraint.constant = 0

            self.miscOptionsView.hidden         = true
            self.miscOptionsHeightConstraint.constant = 0

        }
        else {
            self.matchingCheckboxes.append(self.emailCheckboxButton)
            self.miscCheckboxes.append(self.contactsCheckboxButton)
        }

        
        // load initial options (if provided)
        self.passedOptions = delegate?.searchOptions
        
        if let options = self.passedOptions {
            self.firstNameCheckboxButton.checked    = options.matchFirstName
            self.lastNameCheckboxButton.checked     = options.matchLastName
            self.emailCheckboxButton.checked        = options.matchEmail
            self.usernameCheckboxButton.checked     = options.matchUsername
            self.phoneCheckboxButton.checked        = options.matchPhone
            self.friendsCheckboxButton.checked      = options.searchFriendStatus
            self.invitedCheckboxButton.checked      = options.searchInvitedStatus
            self.pendingCheckboxButton.checked      = options.searchPendingStatus
            self.nonfriendsCheckboxButton.checked   = options.searchNotFriendsStatus
            self.contactsCheckboxButton.checked     = options.includeContacts
            
            self.checkSectionCheckboxes(self.matchingCheckboxes)
            self.checkSectionCheckboxes(self.relationshipCheckboxes)
        }
    }
    
    private func checkSectionCheckboxes(checkboxes: [CheckboxButton]) {
        var selectedCount = 0
        var lastSelected: CheckboxButton? = nil
        
        // check if two options selected
        for checkBox in checkboxes {
            if checkBox.checked {
                ++selectedCount
                lastSelected = checkBox
                
                if selectedCount > 1 {
                    break
                }
            }
        }
        
        // if one option left and selected
        if selectedCount < 2 && lastSelected != nil {
            if let lastChecked = lastSelected {
                lastChecked.userInteractionEnabled = false
                lastChecked.setReadOnlyColor()
            }
        }
        else {
            // enable all checkboxes
            for checkbox in checkboxes {
                checkbox.userInteractionEnabled = true
                checkbox.updateColor()
            }
        }
    }
}
