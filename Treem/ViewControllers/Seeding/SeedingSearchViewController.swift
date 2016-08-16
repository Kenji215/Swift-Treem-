//
//  SeedingSearchViewController.swift
//  Treem
//
//  Created by Matthew Walker on 10/30/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import AddressBook
import libPhoneNumber_iOS

class SeedingSearchViewController: UIViewController, SeedingMembersTableViewDelegate, SeedingMembersDataDelegate, UISearchBarDelegate, UIViewControllerTransitioningDelegate, SeedingSearchOptionsDelegate {
    enum SearchType: Int {
        case Trunk                  = 0
        case BranchExisting
        case BranchNew
        case PhoneContacts
        case SelectBranchFriends         // Dan: When an outside vc is selecting friends for a particular branch
        case NewSearch                   // Search functionality added in during the rework of the Members screen
        case Tagging
		case SharingBranch

    }

    @IBOutlet weak var searchBar            : UISearchBar!

    @IBOutlet weak var searchBarOptionsButton: UIButton!

    @IBOutlet weak var selectedButton       : MemberCountButton!
    @IBOutlet weak var deselectedButton     : MemberCountButton!
    
    @IBOutlet weak var selectAllButton      : CheckboxButton!
    @IBOutlet weak var saveButton           : UIButton!
    @IBOutlet weak var cancelButton         : UIButton!

    @IBOutlet weak var cancelButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelSaveDividerView: UIView!
    @IBOutlet weak var cancelSaveDividerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionOptionsViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var actionOptionsView: UIView!
    @IBOutlet weak var containerView: UIView!
    
    @IBAction func unwindToSeedSearch(segue: UIStoryboardSegue) {
        self.nestedMembersTableViewController.tableView.reloadData()
    }
    
    @IBAction func saveButtonTouchUpInside(sender: AnyObject) {
        
        if (self.currentSearchType == .SelectBranchFriends || self.currentSearchType == .Tagging || self.currentSearchType == .SharingBranch) {
            // it's the delegate's job to do something with this
            self.saveActionOccurred()
        }
        else {
            self.loadingMaskViewController.queueLoadingMask(self.view, showCompletion: {

                if self.currentSearchType == .BranchNew {
                    self.addBranchUsers()
                }
                else if self.currentSearchType == .BranchExisting || self.currentSearchType == .Trunk {
                    self.trimBranchUsers()
                }
                else if self.currentSearchType == .NewSearch {
                    self.addBranchUsers()
                    self.trimBranchUsers()
                }
            })
        }
    }

    @IBAction func cancelButtonTouchUpInside(sender: AnyObject) {

        if !(self.currentSearchType == .SelectBranchFriends || self.currentSearchType == .SharingBranch) {
            self.nestedMembersTableViewController.massManageSelectionStatus(self.selectedUsers, toggledTo: false)
            self.nestedMembersTableViewController.massManageSelectionStatus(self.deselectedUsers, toggledTo: true)
        }
    }

    @IBAction func searchBarOptionsButtonTouchUpInside(sender: AnyObject) {
        let vc = SeedingSearchOptionsViewController.getStoryboardInstance()
        
        vc.delegate         = self
        vc.forSearchType    = self.currentSearchType
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func selectedButtonTouchUpInside(sender: AnyObject) {
        // transition to selected
        let vc = UIStoryboard(name: "SeedingSelected", bundle: nil).instantiateInitialViewController() as! SeedingSelectedViewController
        
        vc.userList    = self.selectedUsers
        vc.delegate    = self

        self.navigationController?.pushViewController(vc, animated: true)
    }

    @IBAction func deselectedButtonTouchUpInside(sender: AnyObject) {
        // transition to selected
        let vc = UIStoryboard(name: "SeedingSelected", bundle: nil).instantiateInitialViewController() as! SeedingSelectedViewController

        vc.userList    = self.deselectedUsers
        vc.delegate    = self
        vc.modifying   = .Deselected

        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func selectAllButtonTouchUpInside(sender: CheckboxButton) {

        self.nestedMembersTableViewController.massManageSelectionStatus(self.nestedMembersTableViewController.users, toggledTo: sender.checked)
    }
    
    private var nestedMembersTableViewController: SeedingMembersTableViewController!
    
    private let loadingMaskViewController       = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController             = ErrorViewController.getStoryboardInstance()
    
    private var tapGestureRecognizer: UITapGestureRecognizer? = nil
    
    var currentSearchType       : SearchType    = .NewSearch
    
    lazy var users                   = OrderedSet<User>()
    lazy var selectedUsers           = OrderedSet<User>()
    lazy var deselectedUsers         = OrderedSet<User>()

    var contactsList : [UserContact] = []

    var delegate                : SeedingMembersTableViewDelegate? = nil
    
    var searchTimer             : NSTimer?
    var searchTimerDelay        : NSTimeInterval = 0.5
    
    var currentSearchText       : String? = nil
    
    var redrawOnReturn = false

    private var initialActionOptionsViewHeight: CGFloat = 0
    
    private lazy var _searchOptions = SeedingSearchOptions()
    
    var searchOptions: SeedingSearchOptions {
        return self._searchOptions
    }
    
    static func storyboardInstance() -> SeedingSearchViewController {
        return UIStoryboard(name: "SeedingSearch", bundle:nil).instantiateViewControllerWithIdentifier("SeedingSearch") as! SeedingSearchViewController
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedSeedingMembersTable" {
            self.nestedMembersTableViewController = segue.destinationViewController as! SeedingMembersTableViewController
            
            self.addChildViewController(self.nestedMembersTableViewController)
            
            self.nestedMembersTableViewController.delegate          = self
        }
    }
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.dismissKeyboard()
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set search delegate to self
        self.searchBar.delegate = self
        
        self.cancelButton.tintColor = AppStyles.sharedInstance.midGrayColor
        
        // default action view to closed
        self.initialActionOptionsViewHeight = self.actionOptionsViewHeightConstraint.constant
        self.actionOptionsViewHeightConstraint.constant = 0
        
        self.actionOptionsView.backgroundColor = AppStyles.sharedInstance.darkGrayColor
        
        self.getMembers()
        
        self.selectAllButton.checked = false
        self.selectAllButton.enabled = false //Initialize to being disabled. Enable it once we get a set of users.

        self.deselectedButton.sign = "-"
        self.deselectedButton.count = self.deselectedButton.count //Force the button to get redrawn

        if (self.currentSearchType == .SelectBranchFriends || self.currentSearchType == .SharingBranch) {
            // hide the cancel button (and cell)
            self.cancelButton.hidden = true
            self.cancelSaveDividerView.hidden = true
            self.cancelButtonWidthConstraint.constant = 0
            self.cancelSaveDividerWidthConstraint.constant = 0
            
            self.deselectedButton.hidden = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // reload members with force update (i.e. when members are edited elsewhere)
        if self.redrawOnReturn {
            self.nestedMembersTableViewController.tableView.reloadData()

            self.redrawOnReturn = false
        }
    }

    func initiallyHighlighted(user: User) -> Bool {
        return self.delegate?.initiallyHighlighted(user) ??  (user.onBranch! == true)
    }

    func selectedUsersUpdated(users: OrderedSet<User>) {
        self.selectedUsers = users

        self.selectedButton.count = self.selectedUsers.count

        self.delegate?.selectedUsersUpdated(users)

        self.nestedMembersTableViewController.selectedUsers = self.selectedUsers

        self.recalculateButtons()
    }

    func deselectedUsersUpdated(users: OrderedSet<User>) {
        self.deselectedUsers = users

        self.deselectedButton.count = self.deselectedUsers.count

        self.delegate?.deselectedUsersUpdated(users)

        self.nestedMembersTableViewController.deselectedUsers = self.deselectedUsers

        self.recalculateButtons()
    }

    func giveWarningMessage() {

        if (self.delegate?.giveWarningMessage != nil) {

            self.delegate?.giveWarningMessage()
        }
        else {
            var warningTitle = ""
            var warningMessage = ""

            //If on trunk, removing means unfriending. Otherwise, removing just means removing from that specific branch.
            if (CurrentTreeSettings.sharedInstance.treeSession.currentBranchID == 0) {
                warningTitle = Localization.sharedInstance.getLocalizedString("unfriending_warning_title", table: "SeedingSelected")
                warningMessage = Localization.sharedInstance.getLocalizedString("unfriending_warning_message", table: "SeedingSelected")
            }
            else {
                warningTitle = Localization.sharedInstance.getLocalizedString("removal_warning_title", table: "SeedingSelected")
                warningMessage = Localization.sharedInstance.getLocalizedString("removal_warning_message", table: "SeedingSelected")
            }
            CustomAlertViews.showCustomAlertView(
                title: warningTitle
                , message: warningMessage
                , fromViewController: self
            )
        }
    }


    func saveActionOccurred(){
        self.delegate?.saveActionOccurred(self.selectedUsers, removedUsers: self.deselectedUsers)
    }

    func recalculateButtons() {
        let selectedCount       = self.selectedUsers.count
        let deselectedCount     = self.deselectedUsers.count
        let combinedCount       = self.selectedUsers.count + self.deselectedUsers.count
        let hasCount            = (combinedCount > 0)
        var isActionViewVisible = self.actionOptionsViewHeightConstraint.constant > 0
        var viewToggled         = false

        self.cancelButton.enabled   = hasCount
        self.saveButton.enabled     = hasCount
        
        // toggle display of button container view as needed
        if hasCount && !isActionViewVisible {
            self.view.layoutIfNeeded()
            self.actionOptionsViewHeightConstraint.constant = self.initialActionOptionsViewHeight
            
            viewToggled         = true
            isActionViewVisible = true
        }
        else if !hasCount && isActionViewVisible {
            self.view.layoutIfNeeded()
            self.actionOptionsViewHeightConstraint.constant = 0
            
            viewToggled = true
        }
        
        var title: String? = nil
        
        // adjust title
        if isActionViewVisible {
            // update text to reflect whether adding, removing or both
            if selectedCount < 1 && deselectedCount > 0 {
                title = self.getRemoveOnlySelectTitle()
            }
            else if deselectedCount < 1 && selectedCount > 0 {
                title = self.getAddOnlySelectTitle()
            }
            else {
                title = Localization.sharedInstance.getLocalizedString("save", table: "Common")
            }

            if viewToggled {
                UIView.performWithoutAnimation({
                    self.saveButton.setTitle(title, forState: .Normal)
                    self.saveButton.layoutIfNeeded()
                })
            }
            else {
                self.saveButton.setTitle(title, forState: .Normal)
            }
        }
        
        // animate view change if occurring
        if viewToggled {
            UIView.animateWithDuration(
                AppStyles.sharedInstance.viewAnimationDuration,
                animations: {
                    self.view.layoutIfNeeded()
                }
            )
        }
        
        self.redrawOnReturn = true
    }

    func usersUpdated(users: OrderedSet<User>) {
        self.selectAllButton.enabled = (users.count + self.nestedMembersTableViewController.totalRows) > 0

        self.selectAllButton.checked = false
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        var formattedSearchText = searchText
        
        // cancel previous timer
        if let timer = self.searchTimer {
            timer.invalidate()
        }

        // check if searching for phone number, and format correctly if so
        if self.isSearching(formattedSearchText) {
            let formattedPhone = NBPhoneNumberUtil().getE164FormattedString(formattedSearchText)
            
            if !formattedPhone.isEmpty {
                formattedSearchText = formattedPhone
            }
        }
        
        self.currentSearchText = formattedSearchText
        
        // reset paging
        self.nestedMembersTableViewController.resetPageIndex()
        
        // if search is empty add no delay, otherwise add delay for when typing
        self.searchTimer = NSTimer.scheduledTimerWithTimeInterval(
            formattedSearchText.isEmpty ? 0 : self.searchTimerDelay,
            target: self,
            selector: #selector(SeedingSearchViewController.getMembers),
            userInfo: nil,
            repeats: false
        )
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        //Looks for taps on table view
        if self.tapGestureRecognizer == nil {
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SeedingSearchViewController.dismissKeyboard))
            self.nestedMembersTableViewController.view.addGestureRecognizer(self.tapGestureRecognizer!)
        }
    }

    func getMembers() {
        // remove prior error view (if added)
        self.errorViewController.removeErrorView()
        
        // show loading mask
        self.nestedMembersTableViewController.showLoadingMask()

        // search for members in a particular area
        switch self.currentSearchType {
        case .BranchExisting:
            self.nestedMembersTableViewController.pagedDataCall = self.getBranchMembers

            
            self.getBranchMembers(self.nestedMembersTableViewController.pageIndex, pageSize: self.nestedMembersTableViewController.pageSize)
        case .BranchNew:
            self.nestedMembersTableViewController.pagedDataCall = self.getBranchMembers

            
            if self.isSearching(self.currentSearchText) {
                self.getBranchMembers(self.nestedMembersTableViewController.pageIndex, pageSize: self.nestedMembersTableViewController.pageSize)
            }
                // on adding members, no call is needed when not searching
            else {
                self.nestedMembersTableViewController.setUsers([], emptyText: "")
            }
        case .PhoneContacts:
            // load phone contacts

            self.checkAddressBookAccess()

        case .Trunk:
            self.nestedMembersTableViewController.pagedDataCall = self.getTrunkMembers
            
            // load trunk members
            self.getTrunkMembers(self.nestedMembersTableViewController.pageIndex, pageSize: self.nestedMembersTableViewController.pageSize)


        case .NewSearch:
            self.nestedMembersTableViewController.pagedDataCall = self.searchUsers

            if (self._searchOptions.includeContacts) {
                self.checkAddressBookAccess()
            }
            else {
                self.searchUsers(self.nestedMembersTableViewController.pageIndex, pageSize: self.nestedMembersTableViewController.pageSize)
            }

		case .SelectBranchFriends, .Tagging, .SharingBranch:
			self.nestedMembersTableViewController.pagedDataCall = self.searchUsers

			//Search will return only full Friends who are branch members.
			self._searchOptions.setDefaultStatusOptionsForTagged()
			self._searchOptions.includeContacts = false

			self.searchUsers(self.nestedMembersTableViewController.pageIndex, pageSize: self.nestedMembersTableViewController.pageSize)

		}
    }
    
    private func getAddOnlySelectTitle() -> String {
        if (self.currentSearchType == .SelectBranchFriends) {
            return Localization.sharedInstance.getLocalizedString("select", table: "Common")
        }
		else if (self.currentSearchType == .SharingBranch) {
			return Localization.sharedInstance.getLocalizedString("share", table: "Common")
		}
        else if (self.currentSearchType == .Tagging) {
            return "Tag"
        }
        
        return Localization.sharedInstance.getLocalizedString("add", table: "Common")
    }
    
    private func getRemoveOnlySelectTitle() -> String {
        return Localization.sharedInstance.getLocalizedString("Remove", table: "Common")
    }

    // Gets a list of members who do not belong to any branch       -       domain.com/trunk
    private func getTrunkMembers(page: Int, pageSize: Int) {

        // load members in trunk
        TreemSeedingService.sharedInstance.getTrunkMembers(
            CurrentTreeSettings.sharedInstance.treeSession,
            search: self.currentSearchText ?? "",
            searchOptions: self._searchOptions,
            page: page,
            pageSize: pageSize,
            failureCodesHandled:
            [
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.DisabledConsumerKey
            ],
            success:
            {
                data in
                
                let users = User.getUsersFromData(data)

                self.nestedMembersTableViewController.setUsers(users, emptyText: self.getNoMatchesText(self.currentSearchText), canMemberInvite: true, showMemberInvite: self.showMemberInvite)
                
                self.nestedMembersTableViewController.cancelLoadingMask()
            },
            failure: {
                error, wasHandled in
                
                self.nestedMembersTableViewController.cancelLoadingMask()
                
                // cancel loading mask
                if !wasHandled {
                    let recover = {
                        self.getTrunkMembers(page, pageSize: pageSize)
                    }
                    
                    // if network error
                    if (error == TreemServiceResponseCode.NetworkError) {
                        self.errorViewController.showNoNetworkView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                    else if (error == TreemServiceResponseCode.LockedOut) {
                        self.errorViewController.showLockedOutView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                    else if (error == TreemServiceResponseCode.DisabledConsumerKey) {
                        self.errorViewController.showDeviceDisabledView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                    else {
                        self.errorViewController.showGeneralErrorView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                }
            }
        )
    }


    // Gets a list of members who belong to the given branch        -       domain.com/existing
    private func getBranchMembers(page: Int, pageSize: Int) {
        let existing = (self.currentSearchType == .BranchExisting || self.currentSearchType == .SelectBranchFriends || self.currentSearchType == .Tagging || self.currentSearchType == .SharingBranch)
        let specifiedBranch = self.delegate?.getBranchID() ?? CurrentTreeSettings.sharedInstance.currentBranchID

        // load members in trunk
        TreemSeedingService.sharedInstance.getBranchMembersSpecificBranch(
            CurrentTreeSettings.sharedInstance.treeSession,
            branchID: specifiedBranch,
            existing: existing,
            search: self.currentSearchText ?? "",
            searchOptions: self._searchOptions,
            page: page,
            pageSize: pageSize,
            failureCodesHandled:
            [
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.DisabledConsumerKey
            ],
            success:
            {
                data in

                let users = User.getUsersFromData(data)

                self.nestedMembersTableViewController.setUsers(users, emptyText: self.getNoMatchesText(self.currentSearchText), canMemberInvite: existing ? false : self.isSearching(self.currentSearchText), showMemberInvite: self.showMemberInvite)
                
                self.nestedMembersTableViewController.cancelLoadingMask()
            },
            failure: {
                error, wasHandled in

                self.nestedMembersTableViewController.cancelLoadingMask()
                
                // cancel loading mask
                if !wasHandled {
                    let recover = {
                        self.getBranchMembers(page, pageSize: pageSize)
                    }
                    
                    // if network error
                    if (error == TreemServiceResponseCode.NetworkError) {
                        self.errorViewController.showNoNetworkView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                    else if (error == TreemServiceResponseCode.LockedOut) {
                        self.errorViewController.showLockedOutView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                    else if (error == TreemServiceResponseCode.DisabledConsumerKey) {
                        self.errorViewController.showDeviceDisabledView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                    else {
                        self.errorViewController.showGeneralErrorView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                }
            }
        )

    }

    // Reworked member search                                       -       domain.com/search
    private func searchUsers(page: Int, pageSize: Int) {

        //Build the contacts list if the search says to include it
        if (self._searchOptions.includeContacts) {
            if (self.contactsList.count == 0 || self.nestedMembersTableViewController.pageIndex == 1) {
                self.contactsList = self.buildContactsList()
                self.nestedMembersTableViewController.contacts = User.getUsersFromContacts(self.contactsList)
            }
        }
        else {
            self.contactsList = []
            self.nestedMembersTableViewController.contacts = OrderedSet<User>()
        }

        TreemSeedingService.sharedInstance.searchUsers(
            CurrentTreeSettings.sharedInstance.treeSession,
            contacts: self.contactsList,
            search: self.currentSearchText ?? "",
            searchOptions: self._searchOptions,
            page: page,
            pageSize: pageSize,
            failureCodesHandled:
            [
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.DisabledConsumerKey
            ],
            success: {
                data in
                let users = User.getUsersFromData(data)

                self.nestedMembersTableViewController.setUsers(users, emptyText: self.getNoMatchesText(self.currentSearchText), canMemberInvite: (self.currentSearchType == .NewSearch), showMemberInvite: self.showMemberInvite)

                self.nestedMembersTableViewController.cancelLoadingMask()
            },
            failure: {
                error, wasHandled in

                self.nestedMembersTableViewController.cancelLoadingMask()

                // cancel loading mask
                if !wasHandled {
                    let recover = {
                        self.searchUsers(page, pageSize: pageSize)
                    }

                    // if network error
                    if (error == TreemServiceResponseCode.NetworkError) {
                        self.errorViewController.showNoNetworkView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                    else if (error == TreemServiceResponseCode.LockedOut) {
                        self.errorViewController.showLockedOutView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                    else if (error == TreemServiceResponseCode.DisabledConsumerKey) {
                        self.errorViewController.showDeviceDisabledView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                    else {
                        self.errorViewController.showGeneralErrorView(self.nestedMembersTableViewController.view, recover: recover)
                    }
                }
            }
        )

     }


    private func getNoMatchesText(filter: String?) -> String? {
        if self.isSearching(filter) {
            return "No matching members"
        }
        else if self.currentSearchType == .BranchNew {
            return ""
        }
        else if self.currentSearchType == .BranchExisting {
            return "No members have been added."
        }
        else {
            return "No members"
        }
    }
    
    private func addressBookNotGranted(canChangePermission: Bool) {

        self._searchOptions.includeContacts = false
        self.searchUsers(self.nestedMembersTableViewController.pageIndex, pageSize: self.nestedMembersTableViewController.pageSize)
    }

    private func checkAddressBookAccess() {
        // check for address book permissions
        let authorization = ABAddressBookGetAuthorizationStatus()
        
        switch(authorization) {
        case .Denied:
            // show access not granted with option to change permission setting
            self.addressBookNotGranted(true)
            
        case .Restricted:
            // show access not granted without option to change permission setting
            self.addressBookNotGranted(false)
            
        case .Authorized:
            // load contacts
            self.promptAddressBookAccess()
            
        case .NotDetermined:
            // prompt member if app can access address book
            self.promptAddressBookAccess()
        }
    }
    
    private func isSearching(filter: String?) -> Bool {
        return !(filter ?? "").isEmpty
    }
    
    private func promptAddressBookAccess() {
        if let addressBook: ABAddressBook = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue() {
            ABAddressBookRequestAccessWithCompletion(addressBook, {
                (granted: Bool, error: CFError!) in

                dispatch_async(dispatch_get_main_queue()) {
                    if granted {
                        self.searchUsers(self.nestedMembersTableViewController.pageIndex, pageSize: self.nestedMembersTableViewController.pageSize)
                    }
                    else {
                        // not granted
                        self.addressBookNotGranted(true)
                    }
                }
            })
        }
    }	


    func buildContactsList() -> [UserContact] {
        var userContacts: [UserContact] = []

		if let addressBook: ABAddressBook = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue() {

			//Retrieve contacts from all address books (e.g. iCloud, Google, Exchange....). Sort by the user's preferred sorting setting
			let contacts = (ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue() as [ABRecordRef]).sort() {
				ABPersonComparePeopleByName($0, $1, ABPersonSortOrdering(ABPersonGetSortOrdering())) != .CompareGreaterThan
			}

			#if DEBUG
				print("Import contacts count: \(contacts.count)")
			#endif

			let phoneUtil = NBPhoneNumberUtil()

			var tempContactID : Int32 = 1

			for record:ABRecordRef in contacts {
                let person = UserContact()

                let first   = ABRecordCopyValue(record, kABPersonFirstNameProperty)?.takeRetainedValue() as? String
                let last    = ABRecordCopyValue(record, kABPersonLastNameProperty)?.takeRetainedValue() as? String
				let phones  = ABRecordCopyValue(record, kABPersonPhoneProperty).takeUnretainedValue() as ABMultiValueRef
				let emails  = ABRecordCopyValue(record, kABPersonEmailProperty).takeUnretainedValue() as ABMultiValueRef

                person.firstName  = first
                person.lastName   = last
				person.contactID  = tempContactID
				person.phonebookID = ABRecordGetRecordID(record)

				let phoneCount = ABMultiValueGetCount(phones)
				let emailCount = ABMultiValueGetCount(emails)

				for i in 0..<phoneCount
				{
					let phoneUnmanaged  = ABMultiValueCopyValueAtIndex(phones, i)
					let phoneNumber     = phoneUnmanaged.takeUnretainedValue() as! String

					// Bug workaround: e.164 Format from NBPhoneNumberUtil doesn't parse extensions, check RFC3966 instead so those numbers can be filtered out
					let formattedNumber = phoneUtil.getRFC3966FormattedString(phoneNumber)

					if !formattedNumber.isEmpty {
						let e164Number = phoneUtil.getE164FormattedString(phoneNumber)

						if (e164Number != "") {
							let contact = UserContact()
							contact.firstName   = person.firstName
							contact.lastName    = person.lastName
							contact.contactID   = tempContactID
							tempContactID += 1

							contact.phonebookID = person.phonebookID
							contact.emails      = person.emails
							contact.phoneNumbers = [e164Number]

							userContacts.append(contact)
						}
					}
				}

				for i in 0..<emailCount
				{
					let emailUnmanaged  = ABMultiValueCopyValueAtIndex(emails, i)
					let email           = emailUnmanaged.takeUnretainedValue() as! String

					if (email.isValidEmail()) {

						let contact = UserContact()
						contact.firstName = person.firstName
						contact.lastName = person.lastName
						contact.contactID = tempContactID
						tempContactID += 1

						contact.emails = [email]

						userContacts.append(contact)
					}
				}
			}
		}
        return userContacts
    }

    private func addBranchUsers() {
        var users: [UserAdd] = []

        // pass only the necessary user data
        for selectedUser in self.selectedUsers {

			//if this is a contact and not yet a user, grab their phone number from the contact object
			if (selectedUser.id == 0 && selectedUser.contactID > 0) {
				if let contact = self.contactsList.filter({$0.contactID == selectedUser.contactID}).first {
					selectedUser.phone = contact.phoneNumbers.count > 0 ? contact.phoneNumbers[0] : nil
				}
			}

			users.append(UserAdd(user: selectedUser))
        }

        if (users.count > 0) {

            TreemSeedingService.sharedInstance.setUsers(
                CurrentTreeSettings.sharedInstance.treeSession,
                branchID: CurrentTreeSettings.sharedInstance.currentBranchID,
                users: users,
                failureCodesHandled: nil,
                success: {
                    data in

                    let setResponse = SetUsersResponse(data: data)
                    
                    if let badPhones = setResponse.badPhones {
                        var message = "Some phone numbers were not able to be added due to the numbers being invalid.\n\nTotal invalid numbers: \(setResponse.badPhoneCount).\n"
                        
                        if setResponse.badPhoneCount > badPhones.count {
                           message += "Some invalid numbers given:"
                        }
                        
                        message += "\n"
                        
                        for phone in badPhones {
                            message += "\(phone)\n"
                        }
                        
                        CustomAlertViews.showCustomAlertView(title: "Invalid Phone Number", message: message, willDismiss: {
                            // partial success need to reload view as it's not determined which rows were added/not-added
                            self.nestedMembersTableViewController.massManageSelectionStatus(self.selectedUsers, toggledTo: false)
                            self.nestedMembersTableViewController.resetPageIndex()
                            self.getMembers()
                        })


                        self.loadingMaskViewController.cancelLoadingMask(nil)

                    }
                    else {
                        let changedUsers = self.selectedUsers
                        
                        self.nestedMembersTableViewController.massManageSelectionStatus(changedUsers, toggledTo: false)
                        self.nestedMembersTableViewController.changeBranchStatus(changedUsers, onBranch: true)

                        self.loadingMaskViewController.cancelLoadingMask(nil)

                    }
                },
                failure: {
                    error, wasHandled in

                    self.loadingMaskViewController.cancelLoadingMask({
                        if !wasHandled {
                            if error == TreemServiceResponseCode.GenericResponseCode1 {
                                CustomAlertViews.showCustomAlertView(title: "Error Adding Members", message: "Check that the selected members have a valid phone number.")
                            }
                            else {
                                CustomAlertViews.showGeneralErrorAlertView()
                            }
                        }
                    })
                }
            )
        }
		else {
			self.loadingMaskViewController.cancelLoadingMask(nil)
		}
    }
    
    private func showMemberInvite() {
        let vc = SeedingInviteViewController.getStoryboardInstance()


        //If they've typed a phone number into the search box, pass that along to the Invitation screen
        let formattedPhone = NBPhoneNumberUtil().getE164FormattedString(self.currentSearchText!)
        if !formattedPhone.isEmpty {
            vc.passedNumber = formattedPhone
        }
        
        vc.transitioningDelegate    = self
        vc.modalPresentationStyle   = .Custom
        
        vc.onInviteSuccess = {
            self.getMembers()
        }
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    private func trimBranchUsers() {
        var users: [UserRemove] = []
        
        // pass only the necessary user data
        for selectedUser in self.deselectedUsers {
            users.append(UserRemove(user: selectedUser))
        }


        if (users.count > 0) {
            TreemSeedingService.sharedInstance.trimUsers(
                CurrentTreeSettings.sharedInstance.treeSession,
                branchID: CurrentTreeSettings.sharedInstance.currentBranchID,
                users: users,
                failureCodesHandled: nil,
                success: {
                    data in

                    let changedUsers = self.deselectedUsers
                    self.nestedMembersTableViewController.massManageSelectionStatus(changedUsers, toggledTo: true)
                    self.nestedMembersTableViewController.changeBranchStatus(changedUsers, onBranch: false)

                    self.loadingMaskViewController.cancelLoadingMask(nil)
                },
                failure: {
                    error, wasHandled in

                    self.loadingMaskViewController.cancelLoadingMask({
                        if !wasHandled {
                            CustomAlertViews.showGeneralErrorAlertView()
                        }
                    })
                }
            )
        }
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return AppStyles.directionUpViewAnimatedTransition
    }
    
    func didDismissSearchOptions (optionsChanged: Bool, options: SeedingSearchOptions) {
        self._searchOptions = options
        
        self.searchBarOptionsButton.setImage(UIImage(named: options.areDefaultOptionsSelected(self.currentSearchType) ? "Settings" : "SettingsSet"), forState: .Normal)
        
        // redo search with search options
        if optionsChanged {
            // reset paging
            self.nestedMembersTableViewController.resetPageIndex()
            
            self.getMembers()
        }
    }

    func viewProfile (userID: Int) {
        let vc = MemberProfileViewController.getStoryboardInstance()

        vc.transitioningDelegate    = self
        vc.modalPresentationStyle   = .Custom

        // only one user can be send to the profile page
        vc.userId = userID
        vc.friendChangeCallback = { self.getMembers() }          // couldn't get "viewWillAppear()" to fire when closing... work around

        self.presentViewController(vc, animated: true, completion: nil)
    }

    // clear open keyboards on tap
    func dismissKeyboard() {
        self.view.endEditing(true)
        self.searchBar.resignFirstResponder()
        
        if self.tapGestureRecognizer != nil {
            self.nestedMembersTableViewController.view.removeGestureRecognizer(self.tapGestureRecognizer!)
            self.tapGestureRecognizer = nil
        }
    }
}
