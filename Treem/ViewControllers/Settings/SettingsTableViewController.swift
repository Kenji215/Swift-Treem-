//
//  SettingsTableViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/14/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class SettingsTableViewController : UITableViewController, UINavigationControllerDelegate {
    
    @IBAction func unwindToSettingsTable(segue: UIStoryboardSegue) {}
    
    private struct menuItem {
        var titleKey: String
        var storyboardName: String
        var storyboardIdentifier: String
    }
    
    // setting menu items (title, controller identifier)
    private var menuItems: [menuItem] = [
        menuItem(titleKey: "profile", storyboardName: "Profile", storyboardIdentifier: "Profile"),
        menuItem(titleKey: "help", storyboardName: "Help", storyboardIdentifier: "Help"),
//        menuItem(titleKey: "terms", storyboardName: "Terms", storyboardIdentifier: "Terms"), TODO: Add at some point
        menuItem(titleKey: "logout", storyboardName: "Login", storyboardIdentifier: "Login") // check for "Login" references below
    ]
    
    private var backButton                      : UIBarButtonItem!
    private var backButtonHorizontalConstraint  : NSLayoutConstraint!
    private var grandparentViewController       : SettingsViewController!
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // show tree settings only for trees that have settings
        if CurrentTreeSettings.sharedInstance.currentTree != .Public {
            self.menuItems.insert(menuItem(titleKey: "tree_settings", storyboardName: "TreeSettings", storyboardIdentifier: "TreeSettings"), atIndex: 1)
        }
        
        // set self as navigation delegate
        self.navigationController?.delegate = self
        
        // set table view styles
        self.tableView.separatorColor = AppStyles.sharedInstance.dividerColor
        
        // zeroing footer removes trailing empty cells
        self.tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, self.tableView.frame.size.width, 1))
        
        self.grandparentViewController = self.navigationController?.parentViewController as! SettingsViewController
        
        // back button hidden by default
        self.grandparentViewController.BackButton.hidden = true
        self.grandparentViewController.BackButton.addTarget(self, action: #selector(SettingsTableViewController.backSettingsTouchUpInside), forControlEvents: .TouchUpInside)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.menuItems.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if(menuItems.indices.contains(indexPath.row)){
            let menuItem = menuItems[indexPath.row]
            
            // check for logout first 
            if(menuItem.storyboardIdentifier == "Login") {
                self.loadingMaskViewController.queueLoadingMask(self.grandparentViewController.view, showCompletion: nil)

                AppDelegate.getAppDelegate().logout(onCancel: {
                    self.loadingMaskViewController.cancelLoadingMask(nil)
                })
                
                // deselect row so that it's clear on return
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
            }
            else {
                if let navVC = self.navigationController {
                    let vc = UIStoryboard(name: menuItem.storyboardName, bundle: nil).instantiateViewControllerWithIdentifier(menuItem.storyboardIdentifier)
                    
                    // deselect row so that it's clear on return
                    tableView.deselectRowAtIndexPath(indexPath, animated: false)
                    
                    navVC.pushViewController(vc, animated: true)

                    // animate title in parent
                    let grandparentVC = self.grandparentViewController
                    
                    UIView.animateWithDuration(0.1,
                        animations: {
                            grandparentVC.SettingsLabel.alpha  = 0
                        },
                        completion: {
                            _ in
                            
                            grandparentVC.BackButton.alpha      = 0
                            grandparentVC.BackButton.hidden     = false
                            
                            grandparentVC.SettingsLabel.text = Localization.sharedInstance.getLocalizedString(menuItem.titleKey, table: "Settings")
                            
                            UIView.animateWithDuration(0.2,
                                animations: {
                                    grandparentVC.SettingsLabel.alpha   = 1
                                    grandparentVC.BackButton.alpha      = 1
                            })
                        }
                    )
                }
            }
        }
    }
    
    func backSettingsTouchUpInside() {
        let grandparentVC = self.grandparentViewController
        
        self.navigationController?.popViewControllerAnimated(true)

        UIView.animateWithDuration(0.1,
            animations: {
                grandparentVC.SettingsLabel.alpha   = 0
                grandparentVC.BackButton.alpha      = 0
            },
            completion: {
                _ in
                
                grandparentVC.SettingsLabel.text = Localization.sharedInstance.getLocalizedString("settings", table: "Settings")
                
                UIView.animateWithDuration(0.2,
                    animations: {
                        grandparentVC.SettingsLabel.alpha = 1.0
                
                })
            }
        )
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingsTableCell") as! SettingsTableViewCell
        
        cell.divider.backgroundColor = AppStyles.sharedInstance.dividerColor
        
        if(self.menuItems.indices.contains(indexPath.row)){
            cell.rowLabel?.text    = Localization.sharedInstance.getLocalizedString(self.menuItems[indexPath.row].titleKey, table: "Settings")
            
            // hide disclosure arrow on login
            cell.disclosureLabel.hidden = (self.menuItems[indexPath.row].storyboardIdentifier == "Login")
        }
        
        return cell
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        // Adding sub view to navigation controller
        if (operation == .Push) {
            return AppStyles.directionLeftViewAnimatedTransition
        }
        
        // Removing top view controller from navigation controller
        else if (operation == .Pop) {
            return AppStyles.directionRightViewAnimatedTransition
        }
        
        return nil
    }
}
