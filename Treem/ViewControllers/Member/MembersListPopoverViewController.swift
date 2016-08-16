//
//  MembersListPopoverViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/17/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
class MembersListPopoverViewController : UITableViewController, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {
    
    var users     : [User]? = nil
    
    let downloadOperations = DownloadContentOperations()
    
    static func getStoryboardInstance() -> MembersListPopoverViewController {
        let vc = UIStoryboard(name: "MemberListPopover", bundle: nil).instantiateInitialViewController() as! MembersListPopoverViewController
        vc.modalPresentationStyle = .Popover
        return vc
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        if let usrs = self.users {
        
            var displayHeight = CGFloat(usrs.count) * self.tableView.rowHeight
            
            // don't let the preferred view be more than 80% of the screen
            let maxViewHeight = UIScreen.mainScreen().bounds.height * 0.8
            if displayHeight > maxViewHeight {
                displayHeight = maxViewHeight
            }
            
            // width won't be more than 70% of the screen
            let maxViewWidth = UIScreen.mainScreen().bounds.width * 0.8
            
            self.preferredContentSize = CGSizeMake(maxViewWidth, displayHeight)
            
            
            self.tableView.separatorColor = UIColor.clearColor()
            self.tableView.reloadData()
        
        }
        else{
            self.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let usrs = self.users {
            return usrs.count
        }
        else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> MemberListTableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MemberListCell", forIndexPath: indexPath) as! MemberListTableViewCell
        
        cell.tag = indexPath.row
        
        if let usrs = self.users {
            if (usrs.indices.contains(indexPath.row)){
                let userObj = usrs[indexPath.row]
                
                cell.firstLastNameLabel.text = userObj.getFullName()
                cell.userNameLabel.text = userObj.username
                
                // if the object has a list icon on it, use it
                if let icon = userObj.listIcon {
                    cell.friendStatusImageView.image = icon
                }
                else{
                    // set friend status image if provided
                    let friendStatus = userObj.friendStatus
                    if friendStatus == .Friends {
                        cell.friendStatusImageView.image = UIImage(named: "Friend")
                    }
                    else if friendStatus == .Invited || friendStatus == .Pending {
                        cell.friendStatusImageView.image = UIImage(named: "Invited")
                    }
                    else {
                        cell.friendStatusImageView.hidden = true
                    }
                }
            
                // get avatar image
                if let avatarURL = userObj.avatar, downloader = DownloadContentOperation(url: avatarURL, cacheKey: userObj.avatarId) {
                    downloader.completionBlock = {
                        if let image = downloader.image where !downloader.cancelled {
                            // perform UI changes back on the main thread
                            dispatch_async(dispatch_get_main_queue(), {
                                
                                // check that the cell hasn't been reused
                                if (cell.tag == indexPath.row) {
                                    
                                    // if cell in view then animate, otherwise add if in table but not visible
                                    if tableView.visibleCells.contains(cell) {
                                        UIView.transitionWithView(
                                            cell.userAvatarImageView,
                                            duration: 0.1,
                                            options: UIViewAnimationOptions.TransitionCrossDissolve,
                                            animations: {
                                                cell.userAvatarImageView.image = image
                                            },
                                            completion: nil
                                        )
                                    }
                                    else {
                                        cell.userAvatarImageView.image = image
                                    }
                                }
                            })
                        }
                    }
                    self.downloadOperations.startDownload(indexPath, downloadContentOperation: downloader)
                }
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // check if cell at indexpath no longer visible
        if tableView.indexPathsForVisibleRows?.indexOf(indexPath) == nil {
            
            #if DEBUG
                print("Cancel content loading for row: \(indexPath.row)")
            #endif
            
            // cancel the current download operations in the cell
            self.downloadOperations.cancelDownloads(indexPath)
        }
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        
        if let usrs = self.users {
            if (usrs.indices.contains(indexPath.row)){
                let userObj = usrs[indexPath.row]
                
                // assume current user
                if userObj.isCurrentUser {
                    let vc = ProfileViewController.getStoryboardInstance()
                    
                    vc.isPresenting = true
                    
                    self.presentViewController(vc, animated: true, completion: nil)
                }
                else {
                    let vc = MemberProfileViewController.getStoryboardInstance()
                    
                    // only one user can be send to the profile page
                    vc.userId = userObj.id
                                    
                    self.presentViewController(vc, animated: true, completion: nil)
                }
            }
        }
        
        return indexPath
    }
}
