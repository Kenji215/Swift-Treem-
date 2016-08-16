//
//  SeedingSelectedViewController.swift
//  Treem
//
//  Created by Matthew Walker on 10/30/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class SeedingSelectedViewController: UIViewController, SeedingMembersTableViewDelegate {
    
    @IBOutlet weak var clearAllSelectedButton: UIButton!
    @IBAction func clearSelectedButtonTouchUpInside(sender: AnyObject) {
        // deselect all rows
        if (self.modifying == .Selected) {
            self.selectedUsersUpdated([])
        }
        else {
            self.deselectedUsersUpdated([])
        }
        
        self.nestedMembersTableViewController.setUsers([], emptyText: "No members selected")
    }
    
    var delegate        : SeedingMembersTableViewDelegate?

    // Have to know whether we're modifying the list of currently-on-branch friends, or not-on-branch friends
    enum UserType : Int {
        case Selected = 0
        case Deselected = 1
    }
    var modifying       : UserType = .Selected

    lazy var userList = OrderedSet<User>()

    private var nestedMembersTableViewController: SeedingMembersTableViewController!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedSelectedMembersTable" {
            self.nestedMembersTableViewController                       = segue.destinationViewController as! SeedingMembersTableViewController
            
            self.addChildViewController(self.nestedMembersTableViewController)

            self.nestedMembersTableViewController.users                 = self.userList
            if (self.modifying == .Selected) {
                self.nestedMembersTableViewController.selectedUsers         = self.userList
            }
            else {
                self.nestedMembersTableViewController.deselectedUsers         = self.userList
            }
            self.nestedMembersTableViewController.emptyText             = "No members selected"
            self.nestedMembersTableViewController.removeCellOnSelect    = true
            self.nestedMembersTableViewController.delegate              = self

            self.nestedMembersTableViewController.inverseSelection      = (self.modifying == .Deselected)
            
            self.nestedMembersTableViewController.setData(self.userList) // users == userList
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearAllSelectedButton.setTitle(self.getClearButtonTitle(self.userList.count), forState: .Normal)
    }

    func selectedUsersUpdated(users: OrderedSet<User>) {
        self.userList = users

        let count = users.count

        // change title without animating change
        UIView.performWithoutAnimation {
            self.clearAllSelectedButton.setTitle(self.getClearButtonTitle(count), forState: .Normal)
            self.clearAllSelectedButton.layoutIfNeeded()
        }

        self.clearAllSelectedButton.enabled = count > 0

        // since this is selected users pass users still in view
        self.delegate?.selectedUsersUpdated(users)
    }

    func deselectedUsersUpdated(users: OrderedSet<User>) {
        self.userList = users

        let count = users.count

        // change title without animating change
        UIView.performWithoutAnimation {
            self.clearAllSelectedButton.setTitle(self.getClearButtonTitle(count), forState: .Normal)
            self.clearAllSelectedButton.layoutIfNeeded()
        }

        self.clearAllSelectedButton.enabled = count > 0

        // since this is selected users pass users still in view
        self.delegate?.deselectedUsersUpdated(users)
    }

    
    private func getClearButtonTitle(userCount: Int) -> String {
        var clearButtonTitle = "Clear Selected"
        
        if userCount > 0 {
            clearButtonTitle += " (\(userCount))"
        }
        
        return clearButtonTitle
    }

    func initiallyHighlighted(user: User) -> Bool {
        return (self.delegate?.initiallyHighlighted(user))!
    }
}
