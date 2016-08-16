//
//  SeedingViewController.swift
//  Treem
//
//  Created by Matthew Walker on 10/28/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class SeedingMembersTableViewController : PagedTableViewController {
    private let minimumSectionsCellCount    = 6
    private let errorViewController         = ErrorViewController.getStoryboardInstance()
    
    lazy var selectedUsers      = OrderedSet<User>()
    lazy var deselectedUsers    = OrderedSet<User>()
    lazy var users              = OrderedSet<User>()

    lazy var selectedArray : [Int] = []
    lazy var deselectedArray : [Int] = []

    lazy var contacts  = OrderedSet<User>()
    
    var delegate            : SeedingMembersTableViewDelegate?
    var removeCellOnSelect  : Bool = false
    var inverseSelection    : Bool = false
    
    var headerColor         = AppStyles.sharedInstance.headerColor
    lazy var headerFont     = UIFont.systemFontOfSize(15, weight: UIFontWeightMedium)

    var statusIconWidth     : CGFloat = 0
    var usernameIconWidth   : CGFloat = 0
    var usernameLeading     : CGFloat = 0

    var removalWarningGiven : Bool = false
    
    static func getStoryboardInstance() -> SeedingMembersTableViewController {
        return UIStoryboard(name: "SeedingMembersTable", bundle: nil).instantiateViewControllerWithIdentifier("SeedingMembersTable") as! SeedingMembersTableViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.useRefreshControl = true

        let cellDefaults = self.tableView.dequeueReusableCellWithIdentifier("SeedingMemberCell") as! MemberTableViewCell
        self.statusIconWidth = cellDefaults.statusIconWidthConstraint.constant
        self.usernameIconWidth = cellDefaults.usernameIconWidthConstraint.constant
        self.usernameLeading = cellDefaults.usernameLabelLeadingConstraint.constant

    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }

    // non-initial set, triggers delegate action
    func setUsers(users: OrderedSet<User>, emptyText: String? = nil, canMemberInvite: Bool = false, showMemberInvite: (()->())? = nil) {
        self.emptyText          = emptyText

        if canMemberInvite {
            self.emptyButtonTitle   = "Invite someone to join"
            self.emptyRecover       = showMemberInvite
        }
        else {
            self.emptyButtonTitle   = nil
            self.emptyRecover       = nil
        }

        //If this is a new search, reset the stored data.
        if self.pageIndex <= self.initialPageIndex {
            self.users = []
            self.clearData()
        }

        // Add the users from the search result to the list of users
        for user in users {
            self.users.insert(user)
        }
        self.checkUsers()
        
        self.delegate?.usersUpdated(self.users)
    }


    func massManageSelectionStatus (users: OrderedSet<User>, toggledTo: Bool) {
        var selectedChanged = false
        var deselectedChanged = false

        //Go through the list of given users and add/remove from the appropriate list
        for user in users {
            self.manageSelectionStatus(user, toggledTo: toggledTo, massOperation: true)

            if (self.delegate?.initiallyHighlighted(user) == true) {
                deselectedChanged = true
            }
            else {
                selectedChanged = true
            }
        }


        //Depending on whether the Deselected or Selected list (or both) got modified, do additional actions
        if (deselectedChanged) {
            self.delegate?.deselectedUsersUpdated(self.deselectedUsers)
        }

        if (selectedChanged) {
            self.delegate?.selectedUsersUpdated(self.selectedUsers)
        }

        self.tableView.reloadData()
    }


    /* Add users to, or remove users from, the corresponding collection.
        selectedUsers are those who are not on branch yet, but will be added (once the request is made).
        deselectedUsers are those who are already on branch, but will get removed once the request is made.
    */
    func manageSelectionStatus (user: User, toggledTo: Bool, massOperation: Bool = false) {
        if (self.delegate?.initiallyHighlighted(user) == true) {
            if (toggledTo == self.inverseSelection) {
                if (!self.removalWarningGiven) {

                    self.delegate?.giveWarningMessage()
                    self.removalWarningGiven = true
                }

                self.deselectedUsers.insert(user)
            }
            else {
                self.deselectedUsers.remove(user)
            }

            if (!massOperation) {
                self.delegate?.deselectedUsersUpdated(self.deselectedUsers)
            }
        }
        else {
            if (toggledTo == self.inverseSelection) {
                self.selectedUsers.remove(user)
            }
            else {
                self.selectedUsers.insert(user)
            }

            if (!massOperation) {
                self.delegate?.selectedUsersUpdated(self.selectedUsers)
            }
        }
    }



    // After the server-side call has a success, we need to locally mark the member as actually being part of the branch now.
    func changeBranchStatus (users: OrderedSet<User>, onBranch: Bool) {
        for user in self.users {
            if (users.contains(user)) {
                user.onBranch = onBranch
            }
        }

        self.setData(self.users)
        self.tableView.reloadData()
    }
    
    private func checkUsers() {
        self.setData(self.users)
        
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> MemberTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SeedingMemberCell", forIndexPath: indexPath) as! MemberTableViewCell

        if let user = self.getUserFromCell(indexPath) {
            // queue avatar load
            if let avatar = user.avatar {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    TreemContentService.sharedInstance.getContentRepositoryFile(avatar, cacheKey: user.avatarId, success: {
                        (image) -> () in
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            _ in
                            
                            cell.avatarImageView.image = image
                        })
                    })
                })
            }
            else {
                cell.avatarImageView.image = UIImage(named: "Avatar")
            }
        }
        
        // change cell styles
        cell.layoutMargins      = UIEdgeInsetsZero
        cell.selectionStyle     = .None

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MemberTableViewCell

        cell.checkboxButton.hidden          = !self.tableView.allowsSelection
        cell.setSelectedStyles(true)

        if self.removeCellOnSelect {
            self.deselectUser(indexPath)
        }
        else if let user = self.getUserFromCell(indexPath) {
            manageSelectionStatus(user, toggledTo: true)
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MemberTableViewCell
        cell.setSelectedStyles(false)

        self.deselectUser(indexPath)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)

        let cell: MemberTableViewCell = cell as! MemberTableViewCell

        // some devices not taking tint style from storyboard (i.e. iPod touch)
        cell.userNameIconImageView.tintColor = UIColor(red: 105/255, green: 105/255, blue: 105/255, alpha: 1.0)
        
        if let user = self.getUserFromCell(indexPath) {

            let contact = self.contacts.filter({$0.contactID == user.contactID}).first

			//What to show as the contact information for a person - could be phone number, email, or nothing.
            let contactDisplay = (contact != nil) ? (contact!.phone ?? contact!.email ?? "") : (user.phone ?? user.email ?? "")

            if self.tableView.allowsSelection {
                if ((self.selectedUsers.contains(user) != self.inverseSelection) || (self.delegate?.initiallyHighlighted(user) == true && (self.deselectedUsers.contains(user) == self.inverseSelection)) ) {
                    tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                    cell.setSelectedStyles(true)
                }
                else {
                    tableView.deselectRowAtIndexPath(indexPath, animated: false)
                    cell.setSelectedStyles(false)
                }
            }
            else {
                cell.checkboxButton.hidden = true
                cell.checkboxButtonWidthConstraint.constant = 0
                cell.cellLeadingConstraint.constant = 0
            }

            var friendStatus = user.friendStatus
            
        //Full name and phone number

            if user.hasName() {
                cell.primaryLabel.text    = user.getFullName()
                cell.secondaryLabel.text  = user.phone ?? contactDisplay
            }
            else {
                cell.primaryLabel.text    = ""
                cell.secondaryLabel.text  = contactDisplay
                
                // if only a number is passed, user has been invited. otherwise they are just a contact in your phone, and haven't yet been invited.
				if (user.phone != nil && user.inviteId > 0) {
					friendStatus = .Invited
				}
            }

        //Username
            if (user.id > 0) {
                cell.usernameLabel.text = (user.username ?? "").isEmpty ? "-" : user.username
                cell.usernameIconWidthConstraint.constant = self.usernameIconWidth
                cell.usernameLabelLeadingConstraint.constant = self.usernameLeading
            }
            else {
                cell.usernameLabel.text = "Not a Treem user"
                cell.usernameIconWidthConstraint.constant = 0
                cell.usernameLabelLeadingConstraint.constant = 0
            }

        //Friendship status icon
            if (friendStatus == .Friends || friendStatus == .Invited || friendStatus == .Pending ){
                if (friendStatus == .Friends) {
                    cell.statusIconImageView.image = UIImage(named: "Friend")
                }
                else {
                    cell.statusIconImageView.image = UIImage(named: "Invited")
                }

                cell.statusIconImageView.hidden = false
                cell.statusIconWidthConstraint.constant = self.statusIconWidth
            }
            else {
                cell.statusIconImageView.hidden = true
                cell.statusIconWidthConstraint.constant = 0
            }

            if (contact != nil) {
                //Show the user's name from your contacts next to what their name on Treem is.
                cell.contactNameLabel.text = ((cell.primaryLabel.text != "") ? " - "  : "") + contact!.getFullName()
            }
            else {
                cell.contactNameLabel.text = ""
            }


        //Tap the cell to view profile
            cell.detailsContainer.addGestureRecognizer(TableRowTapGestureRecognizer(
                target: self
                , action: #selector(SeedingMembersTableViewController.handleTap(_:))
                , indexPath: indexPath
            ))

        //Branches the user is on
            cell.branchesContainer.addBranches(user.colors)
            cell.branchesContainerWidthConstraint.constant = cell.branchesContainer.getWidth()

            //Normally there is a bit of extra padding on the branchesContainer. If the user has no associated phone number, remove that padding so that the branchesContainer is aligned with the Status Icon.
            if (cell.secondaryLabel.text == "") {
                cell.branchesContainerWidthConstraint.constant -= cell.branchesContainer.SPACER_SIZE
            }

            cell.statusIconImageView.tintColor = AppStyles.sharedInstance.midGrayColor
        }
    }

    // Tapping on the member details section
    func handleTap (sender: TableRowTapGestureRecognizer) {
        let indexPath = sender.indexPath
        
        // If they are a Treem member, view profile
        if let user = self.getUserFromCell(indexPath) where user.id > 0 {
            self.delegate?.viewProfile(user.id)
        }
        // If not, just act as if you're selecting the row.
        else {
            self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {

        view.tintColor = AppStyles.sharedInstance.lightGrayColor
        
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = self.headerColor
            header.textLabel?.font      = self.headerFont
        }
    }

    private func deselectUser(indexPath: NSIndexPath) {
        if let user = self.getUserFromCell(indexPath) {
            // remove selected user
            self.manageSelectionStatus(user, toggledTo: false)

            // remove user as well if removing on select
            if self.removeCellOnSelect {
                self.users.remove(user)
                self.resetPageIndex()
                self.checkUsers()
            }
        }
    }

    //Given the cell's index, retrieve the appropriate User object
    private func getUserFromCell (indexPath: NSIndexPath) -> User? {
        if(self.items.indices.contains(indexPath.row)) {
            if let user = self.items[indexPath.row] as? User {
                return user
            }
        }
        
        return nil
    }

    override func setData<T where T: Hashable, T: TableViewCellModelType>(data: OrderedSet<T>) {
        if ((data.count + self.totalRows) < 1) {
            self.clearData()

            // show empty options
            self.showEmptyView()
        }
        else {
            if self.pageIndex <= self.initialPageIndex {
                self.clearData()
            }

            for item in data {
                let isInArray = self.items.indexOf({($0 as! User) == (item as! User)})
                if (isInArray == nil) {
                    self.totalRows += 1
                    item.allRowsIndex = self.totalRows
                    self.items.append(item)
                }
            }
        }
    }
}