//
//  AlertsTableViewController.swift
//  Treem
//
//  Created by Kevin Novak on 12/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class AlertsTableViewController : PagedTableViewController {
    
    private let errorViewController = ErrorViewController.getStoryboardInstance()
    
    private let loadingMaskViewController       = LoadingMaskViewController.getStoryboardInstance()
    private var isWorking                           : Bool = false
    
    let downloadOperations = DownloadContentOperations()
    
    private var alerts      : OrderedSet<Alert> = []
    private var alertUsers  : Dictionary<Int,User>  = [:]
    
    var currentTotal : Int? = 0
    var currentUnread : Int? = 0
    var alertCounts : AlertCount? = nil
    
    var alertCellDefault : AlertTableViewCell!  //Store sizes, constraints, etc. upon initial load
    var delegate : AlertsViewController? = nil
    
    var tableViewDelegate: AlertsTableViewDelegate? = nil
    var friendRequestsOnly = false
    var branchRequestsOnly = false
    
    lazy var selectedAlerts = Dictionary<NSIndexPath,Alert>()
    
    private let buttonContainerInitialHeight: CGFloat = 42
    
    private var isThreadWorking : Bool = false
    
    static func getStoryboardInstance() -> AlertsTableViewController {
        return UIStoryboard(name: "Alerts", bundle: nil).instantiateViewControllerWithIdentifier("AlertsTableView") as! AlertsTableViewController
    }
    
    // MARK: View Controller Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setting these to static values to prevent an iOS bug causing the cells being dispatched to bounce/reload on the new paged request.
        if !self.friendRequestsOnly && !self.branchRequestsOnly {
            self.tableView.estimatedRowHeight   = 80
            self.tableView.rowHeight            = 80
        }
        else {
            self.tableView.estimatedRowHeight   = 125
            self.tableView.rowHeight            = 125
        }
        
        if friendRequestsOnly {
            self.emptyText = Localization.sharedInstance.getLocalizedString("no_friend_requests", table: "Alerts")
        }
        else if branchRequestsOnly {
            self.emptyText = Localization.sharedInstance.getLocalizedString("no_branch_requests", table: "Alerts")
        }
        else {
            self.emptyText = Localization.sharedInstance.getLocalizedString("no_alerts", table: "Alerts")
        }
        
        self.useRefreshControl = true
        self.pagedDataCall = self.getAlerts
        
        self.alertCellDefault = self.tableView.dequeueReusableCellWithIdentifier("AlertCell") as! AlertTableViewCell
        
        self.getAlerts(self.pageIndex, pageSize: self.pageSize)
        
    }
    
    // MARK: TableView Controller Methods
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> AlertTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AlertCell", forIndexPath: indexPath) as! AlertTableViewCell
        
        cell.layoutMargins      = UIEdgeInsetsZero
        cell.selectionStyle     = .None
        
        cell.checkboxButton.checked = false
        cell.checkboxButton.tag     = indexPath.row
        cell.checkboxButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AlertsTableViewController.checkboxTouchUpInside(_:))))
        
        if(self.items.indices.contains(indexPath.row)){
            if let alert = getAlertForRowAtIndexPath(indexPath) {
                let fullName = alert.getUserFullName()
                
                if let _ = self.selectedAlerts[indexPath] {
                    cell.checkboxButton.checked = true
                }
                
                cell.messageTextLabel.text = alert.getReasonText(fullName)
                cell.messageTextLabel.boldSubstring(fullName, weight: UIFontWeightSemibold)
                
                //Response buttons
                cell.Response1Button = self.setResponseButton(1, alert: alert, rowNum: indexPath.row, origButton: cell.Response1Button)
                cell.Response2Button = self.setResponseButton(2, alert: alert, rowNum: indexPath.row, origButton: cell.Response2Button)
                
                if cell.Response1Button.hidden == true && cell.Response2Button.hidden == true {
                    cell.buttonContainerHeightConstraint.constant = 0
                }
                else {
                    cell.buttonContainerHeightConstraint.constant = self.buttonContainerInitialHeight
                }
                
                if let from_user = alert.from_user {
                    if let avatarURL = from_user.avatar, downloader = DownloadContentOperation(url: avatarURL, cacheKey: from_user.avatarId) {
                        
                        downloader.completionBlock = {
                            if let image = downloader.image where !downloader.cancelled {
                                // perform UI changes back on the main thread
                                dispatch_async(dispatch_get_main_queue(), {
                                    // check that the cell hasn't been reused
                                    if (cell.tag == indexPath.row) {
                                        UIView.transitionWithView(
                                            cell.avatar,
                                            duration: 0.1,
                                            options: UIViewAnimationOptions.TransitionCrossDissolve,
                                            animations: {
                                                cell.avatar.image = image
                                            },
                                            completion: nil
                                        )
                                    }
                                })
                            }
                        }
                        
                        self.downloadOperations.startDownload(indexPath, downloadContentOperation: downloader)
                    }
                    
                    if from_user.id > 0 {
                        // add gesture for profile view
                        cell.avatar.tag = from_user.id
                        cell.avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(AlertsTableViewController.profileTouchUpInside(_:))))
                    }
                    else {
                        cell.avatar.image = nil
                    }
                }
                else {
                    cell.avatar.hidden = true
                    cell.avatarWidthConstraint.constant = 0
                }
            }
            else {
                cell.messageTextLabel.text = nil
            }
            
            if Device.sharedInstance.isRetina() {
                cell.lowerGapHeightConstraint.constant = 0.5
            }
        }
        else {
            cell.messageTextLabel.text = nil
        }
        
        return cell
    }
    
    // Build out the table - Populate the cells with data, give them actionable buttons
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
        
        let cell: AlertTableViewCell = cell as! AlertTableViewCell
        
        cell.tag = indexPath.row
        
        if(self.items.indices.contains(indexPath.row)){
            if let alert = getAlertForRowAtIndexPath(indexPath) {
                let fullName = alert.getUserFullName()
                
                //Text and date
                cell.messageTextLabel.text = alert.getReasonText(fullName)
                cell.messageTextLabel.boldSubstring(fullName, weight: UIFontWeightSemibold)
                
                cell.dateLabel.text = alert.created?.getRelativeDateFormattedString()
                
                //Unread indication - Show the text "Unread" in the cell
                cell.unreadIndicator.hidden = (alert.alert_viewed == true)
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let alert = getAlertForRowAtIndexPath(indexPath) {
            self.callResponseActionForAlertType(alert, row: indexPath.row)
        }
    }
    
    private func getAlertForRowAtIndexPath (indexPath: NSIndexPath) -> Alert? {
        if(self.items.indices.contains(indexPath.row)) {
            if let alert = self.items[indexPath.row] as? Alert {
                return alert
            }
        }
        
        return nil
    }
    
    func checkboxTouchUpInside(sender: UITapGestureRecognizer) {
        if let checkbox = sender.view as? CheckboxButton, tag = sender.view?.tag {
            let indexPath = NSIndexPath(forRow: tag, inSection: 0)
            
            if let alert = self.getAlertForRowAtIndexPath(indexPath) {
                if !checkbox.checked {
                    checkbox.checked = true
                    
                    self.selectedAlerts[indexPath] = alert
                }
                else {
                    checkbox.checked = false
                    
                    self.selectedAlerts.removeValueForKey(indexPath)
                }
                
                self.tableViewDelegate?.selectedAlertsUpdated(self.selectedAlerts)
            }
        }
    }
    
    func profileTouchUpInside(sender: UITapGestureRecognizer) {
        if let tag = sender.view?.tag {
            let vc = MemberProfileViewController.getStoryboardInstance()
            
            // only one user can be send to the profile page
            vc.userId = tag
            
            vc.friendChangeCallback = {
                if let refresh = self.refreshControl {
                    refresh.beginRefreshing()
                    self.tableView.setContentOffset(CGPointMake(0, self.tableView.contentOffset.y - refresh.frame.size.height), animated: true)
                    refresh.sendActionsForControlEvents(.ValueChanged)
                }
            }
            
            self.presentViewController(vc, animated: true, completion: nil)
        }
    }
    
    // Build each button - Setting the title and action for each.
    func setResponseButton (buttonNum: Int, alert: Alert, rowNum: NSInteger, origButton: UIButton) -> UIButton {
        let newButton : UIButton = origButton;
        
        if let responseObj = alert.getResponseButton(buttonNum) {
            
            //Clear values that might be set from previous cells
            newButton.removeTarget(nil, action: nil, forControlEvents: .AllEvents)
            newButton.hidden = false
            
            UIView.performWithoutAnimation({
                newButton.setTitle(responseObj.text, forState: UIControlState.Normal)
                newButton.layoutIfNeeded() //Prevents a redraw animation from occurring, which makes the button flash for a few frames
            })
            
            
            newButton.tag = rowNum
            
            newButton.addTarget(self, action: Selector(responseObj.action), forControlEvents: UIControlEvents.TouchUpInside)
        }
        else {
            newButton.hidden = true
        }
        
        return newButton
    }
    
    //Dummy action to just toggle the read/unread status of an alert for testing purposes
    func toggleAlertViewed(sender: UIButton) {
        var toggle : Bool
        
        if let alert = getAlertObj(sender.tag) {
            if (alert.alert_viewed == true) {
                toggle = false
            }
            else {
                toggle = true
            }
            
            setAlertViewed(alert, is_viewed: toggle)
        }
    }
    
    
    // MARK: Response Actions
    
    // Call main action (tapping on row but not selecting any nested views that have their own events)
    private func callResponseActionForAlertType(alert: Alert, row: Int) {
        
        if let reason = alert.reason {
            switch (reason) {
                
            case .ACCEPTED_FRIEND_INVITE:
                self.view_equity(alert)
                
            // Alert types that lead to profile view of the 'from' user
            case .ACCEPTED_FRIEND_REQUEST, .PENDING_FRIEND_REQUEST:
                self.view_profile(alert)
                
            // Alert types that lead to viewing current user's post
            case .POST_REPLY, .POST_REACTION, .POST_ABUSE_SENT, .POST_UPLOAD_FINISHED, .POST_REPLY_REACTION:
                self.view_your_post(alert)
                
            // Alert types that lead to viewing the 'from' user post
            case .POST_SHARE, .COMMENT_REPLY, .TAGGED_POST, .REPLY_UPLOAD_FINISHED:
                self.view_their_post(alert)
                
            // Alert to view guidelines
            case .POST_ABUSE_REVOKED:
                self.view_guidelines(alert)
                
            // Alert: chat upload complete
            case .CHAT_UPLOAD_FINISHED:
                self.view_chat_upload(alert)
                
            default: break
            }
            
        }
    }
    
    //View the equity screen
    private func view_equity (alert: Alert) {
        self.setAlertViewed(alert)
        
        self.delegate?.viewEquity()
    }
    
    //Accept friend request - prompts the user as to whether they want to store the new friend on the Trunk or to select a Branch.
    func accept (sender: UIButton) {
        if let alert = getAlertObj(sender.tag), from_user = alert.from_user {
            
            if (alert.reason == .PENDING_FRIEND_REQUEST) {
                self.delegate?.viewBranchSelection(
                    from_user.id
                    , success: {
                        
                        self.alerts.remove(alert)
                        self.updateCurrentView(true)
                })
                
            }
            else if (alert.reason == .BRANCH_SHARE) {
                self.delegate?.acceptBranchShare(
                    alert.sourceId
                    , success: {
                        self.alerts.remove(alert)
                        self.updateCurrentView(true)
                    }
                )
            }
            
        }
    }

    func decline (sender: UIButton) {
        
        //Make sure the alert is valid, and contains a from_user object
        if let alert = self.getAlertObj(sender.tag) {
            if (alert.reason == .PENDING_FRIEND_REQUEST) {
                declineFriend(alert)
            }
            else if (alert.reason == .BRANCH_SHARE) {
                declineBranch(alert)
            }
        }
    }
    
    //Decline friend request - Have a popup dialog asking for confirmation before doing so.
    func declineFriend(alert: Alert) {
        
        let prevReadStatus = alert.alert_viewed     //Make note of what the previous status was before doing anything
        
        let confirmation = UIAlertController(
            title: Localization.sharedInstance.getLocalizedString("decline_prompt_title", table: "Alerts"),
            message: Localization.sharedInstance.getLocalizedString("decline_prompt_details", table: "Alerts"),
            preferredStyle: UIAlertControllerStyle.Alert
        )
        
        confirmation.addAction(UIAlertAction(
            title: Localization.sharedInstance.getLocalizedString("decline_confirm", table: "Alerts")
            , style: UIAlertActionStyle.Destructive
            , handler: {
                (action: UIAlertAction!) in
                
                self.showLoadingMaskOnParent()
                
                TreemSeedingService.sharedInstance.trimUsers(
                    CurrentTreeSettings.sharedInstance.treeSession,
                    branchID: 0,
                    users: [UserRemove(user: alert.from_user!)],
                    failureCodesHandled: nil,
                    success: {
                        data in
                        
                        self.alertCounts!.totalFriendAlerts -= 1
                        self.alertCounts!.totalAlerts -= 1
                        self.currentTotal? -= 1
                        
                        if alert.alert_viewed == false {
                            self.alertCounts!.unreadAlerts -= 1
                            self.alertCounts!.unreadFriendAlerts -= 1
                            self.currentUnread? -= 1
                        }
                        
                        self.alerts.remove(alert)
                        self.updateCurrentView(true)
                        
                    },
                    failure: {
                        error, wasHandled in
                        
                        //If there was a failure in the call, revert the viewed status.
                        self.setAlertViewed(alert, is_viewed: prevReadStatus!)
                        
                        if self.isWorking {
                            self.loadingMaskViewController.cancelLoadingMask({})
                        }
                    }
                )
            }
            ))
        
        confirmation.addAction(UIAlertAction(
            title: Localization.sharedInstance.getLocalizedString("decline_cancel", table: "Alerts"),
            style: UIAlertActionStyle.Cancel,
            handler: {
                
                (action: UIAlertAction!) in
                // remove the loading mask
                if self.isWorking {
                    self.loadingMaskViewController.cancelLoadingMask({})
                }
            }
            ))
        
        self.presentViewController(confirmation, animated: true, completion: nil)
    }
    
    //Decline branch share - Have a popup dialog asking for confirmation before doing so.
    func declineBranch(alert: Alert) {
        
        let confirmation = UIAlertController(
            title: Localization.sharedInstance.getLocalizedString("decline_share_title", table: "Alerts"),
            message: Localization.sharedInstance.getLocalizedString("decline_share_details", table: "Alerts"),
            preferredStyle: UIAlertControllerStyle.Alert
        )
        
        confirmation.addAction(UIAlertAction(
            title: Localization.sharedInstance.getLocalizedString("decline_confirm", table: "Alerts")
            , style: UIAlertActionStyle.Destructive
            , handler: {
                (action: UIAlertAction!) in
                
                self.showLoadingMaskOnParent()
                
                TreemBranchService.sharedInstance.declineShare(
                    CurrentTreeSettings.sharedInstance.treeSession,
                    alerts: Set(arrayLiteral: alert),
                    success: {
                        data in
                        
                        self.alertCounts!.totalBranchAlerts -= 1
                        self.alertCounts!.totalAlerts -= 1
                        self.currentTotal? -= 1
                        
                        if alert.alert_viewed == false {
                            self.alertCounts!.unreadAlerts -= 1
                            self.alertCounts!.unreadBranchAlerts -= 1
                            self.currentUnread? -= 1
                        }
                        
                        self.alerts.remove(alert)
                        self.updateCurrentView(true)
                    },
                    failure: {
                        error, wasHandled in
                        
                        if self.isWorking {
                            self.loadingMaskViewController.cancelLoadingMask({})
                        }
                    }
                )
            }
            ))
        
        confirmation.addAction(UIAlertAction(
            title: Localization.sharedInstance.getLocalizedString("decline_cancel", table: "Alerts"),
            style: UIAlertActionStyle.Cancel,
            handler: {
                
                (action: UIAlertAction!) in
                // remove the loading mask
                if self.isWorking {
                    self.loadingMaskViewController.cancelLoadingMask({})
                }
            }
            ))
        
        self.presentViewController(confirmation, animated: true, completion: nil)
    }
    
    private func view_chat_upload(alert: Alert) {
        self.setAlertViewed(alert)
    }
    
    private func view_your_post (alert: Alert) {
        
        self.setAlertViewed(alert)
        self.delegate?.viewPost(alert.sourceId)
    }
    
    private func view_their_post (alert: Alert) {
        
        self.setAlertViewed(alert)
        self.delegate?.viewPost(alert.sourceId)
    }
    
    private func view_profile (alert: Alert) {
        if let from_user = alert.from_user {
            self.setAlertViewed(alert)
            self.delegate?.viewProfile(from_user.id)
        }
    }
    
    private func view_guidelines (alert: Alert) {
        self.setAlertViewed(alert)
    }
    
    //END OF RESPONSE ACTIONS
    
    //To be called by each response action, getting the respective alert object and making sure it's valid
    func getAlertObj (rowNum: Int) -> Alert? {
        if let alert = self.items[rowNum] as? Alert {
            if ((alert.alertId > 0) || (alert.inAppAlert)) {
                return alert
            }
        }
        return nil
    }
    
    func markSelectedAsRead() {
        
        let localSelectedAlerts = self.selectedAlerts.values
        
        let inAppAlerts = Set(localSelectedAlerts.filter{$0.inAppAlert == true && $0.alert_viewed == false})
        let standardAlerts = Set(localSelectedAlerts.filter{$0.inAppAlert == false && $0.alert_viewed == false})
        self.showLoadingMaskOnParent()
        
        if standardAlerts.count > 0 {
            
            standardAlerts.forEach{ return $0.alert_viewed = true }

            //Make the service call to change the status in the database
            TreemAlertService.sharedInstance.setAlertRead(
                CurrentTreeSettings.sharedInstance.treeSession,
                alerts: standardAlerts,
                failureCodesHandled: nil,
                success: {
                    data in
                    
                    if inAppAlerts.count > 0 {
                        
                        for inAppAlert in inAppAlerts {
                            
                            // remove it from the global queue
                            if let id = inAppAlert.inAppAlertId {
                                InAppNotifications.sharedInstance.removeInAppAlert(id)
                            }
                            
                            // need to update the counts without making a new counts call
                            self.alertCounts!.totalNonRequestAlerts -= 1
                            self.alertCounts!.totalAlerts -= 1
                            self.currentTotal? -= 1
                            
                            self.alertCounts!.unreadNonRequestAlerts -= 1
                            self.alertCounts!.unreadAlerts -= 1
                            self.currentUnread? -= 1
                            
                            
                            self.alerts.remove(inAppAlert)
                            
                        }
                    }
                    
                    for alert in standardAlerts {
                        
                        self.alerts.getValue(alert)!.alert_viewed = true
                        
                        if !self.branchRequestsOnly && !self.friendRequestsOnly {
                            self.alertCounts!.unreadNonRequestAlerts -= 1
                        }
                        else if self.branchRequestsOnly {
                            self.alertCounts!.unreadBranchAlerts -= 1
                        }
                        else if self.friendRequestsOnly {
                            self.alertCounts!.unreadFriendAlerts -= 1
                        }
                        
                        self.alertCounts!.unreadAlerts -= 1
                        self.currentUnread? -= 1
                    }
                    
                    self.updateCurrentView(true)
                },
                failure: {
                    error, wasHandled in
                    
                    //If there was an error in saving the change, revert back to unread locally
                    for alert in self.selectedAlerts {
                        alert.1.alert_viewed = false
                    }
                }
            )
        }
        else if inAppAlerts.count > 0 {
            
            for inAppAlert in inAppAlerts {
                
                // remove it from the global queue
                if let id = inAppAlert.inAppAlertId {
                    InAppNotifications.sharedInstance.removeInAppAlert(id)
                }
                
                // need to update the counts without making a new counts call
                self.alertCounts!.totalNonRequestAlerts -= 1
                self.alertCounts!.totalAlerts -= 1
                self.currentTotal? -= 1
                
                self.alertCounts!.unreadNonRequestAlerts -= 1
                self.alertCounts!.unreadAlerts -= 1
                self.currentUnread? -= 1
                
                
                self.alerts.remove(inAppAlert)
                
            }
            self.updateCurrentView(true)
        }
        // this means the alerts selected were already read.  Do not reload the table, only uncheck the selection box
        else {
            self.updateCurrentView(false)
        }
    }
    
    /* Change the read/unread status of an alert.
     - If no is_viewed param is passed, assumes that it is to be marked as read.
     - Changes the appearance before making the service call, and reverts if the call failed for some reason.
     - If the current viewed status is the same as the one passed to the function, no service call is made
     */
    private func setAlertViewed(theAlert: Alert, is_viewed: Bool = true) {
        
        if (theAlert.alert_viewed != is_viewed) {
            
            let was_previously_viewed = theAlert.alert_viewed   //Make note of the current viewed status
            theAlert.alert_viewed = is_viewed                   //Change the viewed status to the new status
            
            // if it's an in app alert, clear it
            if(theAlert.inAppAlert){
                
                // remove it from the global queue
                if let id = theAlert.inAppAlertId {
                    InAppNotifications.sharedInstance.removeInAppAlert(id)
                }
                
                // need to update the counts without making a new counts call
                self.alertCounts!.totalNonRequestAlerts -= 1
                self.alertCounts!.totalAlerts -= 1
                self.currentTotal? -= 1
                
                self.alertCounts!.unreadNonRequestAlerts -= 1
                self.alertCounts!.unreadAlerts -= 1
                self.currentUnread? -= 1
                
                
                self.alerts.remove(theAlert)
                self.updateCurrentView(true)
            }
            else {
                //Make the service call to change the status in the database
                TreemAlertService.sharedInstance.setAlertRead(
                    CurrentTreeSettings.sharedInstance.treeSession,
                    alerts: Set(arrayLiteral: theAlert),
                    failureCodesHandled: nil,
                    success: {
                        data in
                        
                        self.alerts.getValue(theAlert)!.alert_viewed = true
                        
                        if !self.branchRequestsOnly && !self.friendRequestsOnly {
                            self.alertCounts!.unreadNonRequestAlerts -= 1
                        }
                        else if self.branchRequestsOnly {
                            self.alertCounts!.unreadBranchAlerts -= 1
                        }
                        else if self.friendRequestsOnly {
                            self.alertCounts!.unreadFriendAlerts -= 1
                        }
                        
                        self.alertCounts!.unreadAlerts -= 1
                        self.currentUnread? -= 1
                        
                        self.updateCurrentView(true)
                        
                    },
                    failure: {
                        error, wasHandled in
                        
                        //If there was an error in saving the change, revert back to unread locally
                        self.alerts.getValue(theAlert)!.alert_viewed = was_previously_viewed
                    }
                )
            }
        }
            // this means the alerts is already read.  Do not reload the table, only uncheck the selection box
        else {
            self.updateCurrentView(false)
        }
    }
    
    func clearSelected() {
        
        let localSelectedAlerts = self.selectedAlerts.values
        
        let inAppAlerts = Set(localSelectedAlerts.filter{$0.inAppAlert == true})
        let standardAlerts = Set(localSelectedAlerts.filter{$0.inAppAlert == false})
        
        self.showLoadingMaskOnParent()
        
        if !self.friendRequestsOnly && !self.branchRequestsOnly {
            
            if standardAlerts.count > 0 {
                //Make the service call to change the status in the database
                TreemAlertService.sharedInstance.clearAlert(
                    CurrentTreeSettings.sharedInstance.treeSession,
                    alerts: standardAlerts,
                    failureCodesHandled: nil,
                    success: {
                        data in
                        
                        if inAppAlerts.count > 0 {
                            
                            for inAppAlert in inAppAlerts {
                                    
                                // remove it from the global queue
                                if let id = inAppAlert.inAppAlertId {
                                    InAppNotifications.sharedInstance.removeInAppAlert(id)
                                }
                                
                                // need to update the counts without making a new counts call
                                self.alertCounts!.totalNonRequestAlerts -= 1
                                self.alertCounts!.totalAlerts -= 1
                                self.currentTotal? -= 1
                                
                                if inAppAlert.alert_viewed == false {
                                    self.alertCounts!.unreadNonRequestAlerts -= 1
                                    self.alertCounts!.unreadAlerts -= 1
                                    self.currentUnread? -= 1
                                }
                                
                                self.alerts.remove(inAppAlert)
                                
                            }
                        }
                        
                        for alertObj in standardAlerts {
                            
                            // need to update the counts without making a new counts call
                            self.alertCounts!.totalNonRequestAlerts -= 1
                            self.alertCounts!.totalAlerts -= 1
                            self.currentTotal? -= 1
                            
                            if alertObj.alert_viewed == false {
                                self.alertCounts!.unreadNonRequestAlerts -= 1
                                self.alertCounts!.unreadAlerts -= 1
                                self.currentUnread? -= 1
                            }
                            
                            self.alerts.remove(alertObj)
                        }
                        
                        // update the badges, clear loading mask, refresh table view
                        self.updateCurrentView(true)
                        
                    },
                    failure: {
                        error, wasHandled in
                        
                        if self.isWorking {
                            self.loadingMaskViewController.cancelLoadingMask({})
                        }
                        
                        if(!wasHandled){
                            CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                        }
                    }
                )
            }
                
            else if inAppAlerts.count > 0 {
                
                for inAppAlert in inAppAlerts {
                        
                    // remove it from the global queue
                    if let id = inAppAlert.inAppAlertId {
                        InAppNotifications.sharedInstance.removeInAppAlert(id)
                    }
                    
                    // need to update the counts without making a new counts call
                    self.alertCounts!.totalNonRequestAlerts -= 1
                    self.alertCounts!.totalAlerts -= 1
                    self.currentTotal? -= 1
                    
                    if inAppAlert.alert_viewed == false {
                        self.alertCounts!.unreadNonRequestAlerts -= 1
                        self.alertCounts!.unreadAlerts -= 1
                        self.currentUnread? -= 1
                    }
                    
                    self.alerts.remove(inAppAlert)
                }
                
                // update the badges, clear loading mask, refresh table view
                self.updateCurrentView(true)
            }
        }
        else if self.friendRequestsOnly || self.branchRequestsOnly {
            
            var confirmation = UIAlertController()
            
            if self.friendRequestsOnly {
                confirmation = UIAlertController(
                    title: Localization.sharedInstance.getLocalizedString("decline_prompt_title", table: "Alerts"),
                    message: Localization.sharedInstance.getLocalizedString("decline_prompt_details", table: "Alerts"),
                    preferredStyle: UIAlertControllerStyle.Alert
                )
            }
            else {
                confirmation = UIAlertController(
                    title: Localization.sharedInstance.getLocalizedString("decline_share_title", table: "Alerts"),
                    message: Localization.sharedInstance.getLocalizedString("decline_share_details", table: "Alerts"),
                    preferredStyle: UIAlertControllerStyle.Alert
                )
            }
            
            confirmation.addAction(UIAlertAction(
                title: Localization.sharedInstance.getLocalizedString("decline_confirm", table: "Alerts")
                , style: UIAlertActionStyle.Destructive
                , handler: {
                    (action: UIAlertAction!) in
                    
                    if self.friendRequestsOnly {
                        TreemSeedingService.sharedInstance.trimUsers(
                            CurrentTreeSettings.sharedInstance.treeSession,
                            branchID: 0,
                            users: standardAlerts.map{UserRemove(user: $0.from_user!)},
                            failureCodesHandled: nil,
                            success: {
                                data in
                                for friendAlert in standardAlerts {
                                    
                                    // need to update the counts without making a new counts call
                                    self.alertCounts!.totalFriendAlerts -= 1
                                    self.alertCounts!.totalAlerts -= 1
                                    self.currentTotal? -= 1
                                    
                                    if friendAlert.alert_viewed == false {
                                        self.alertCounts!.unreadFriendAlerts -= 1
                                        self.alertCounts!.unreadAlerts -= 1
                                        self.currentUnread? -= 1
                                    }
                                    
                                    self.alerts.remove(friendAlert)
                                }
                                
                                // update the badges, clear loading mask, refresh table view
                                self.updateCurrentView(true)
                            },
                            failure: {
                                error, wasHandled in
                                self.loadingMaskViewController.cancelLoadingMask({})
                                if(!wasHandled){
                                    CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                                }
                            }
                        )
                    }
                    if self.branchRequestsOnly {
                        
                        self.isThreadWorking = true
                        TreemBranchService.sharedInstance.declineShare(
                            CurrentTreeSettings.sharedInstance.treeSession,
                            alerts: standardAlerts,
                            success: {
                                data in
                                
                                for branchAlert in standardAlerts {
                                    
                                    // need to update the counts without making a new counts call
                                    self.alertCounts!.totalBranchAlerts -= 1
                                    self.alertCounts!.totalAlerts -= 1
                                    self.currentTotal? -= 1
                                    
                                    if branchAlert.alert_viewed == false {
                                        self.alertCounts!.unreadBranchAlerts -= 1
                                        self.alertCounts!.unreadAlerts -= 1
                                        self.currentUnread? -= 1
                                    }
                                    
                                    self.alerts.remove(branchAlert)
                                }
                                
                                // update the badges, clear loading mask, refresh table view
                                self.updateCurrentView(true)
                            },
                            failure: {
                                error, wasHandled in
                                if(!wasHandled){
                                    self.loadingMaskViewController.cancelLoadingMask({})
                                    CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                                }
                            }
                        )
                    }
            } ))
            
            confirmation.addAction(UIAlertAction(
                title: Localization.sharedInstance.getLocalizedString("decline_cancel", table: "Alerts"),
                style: UIAlertActionStyle.Cancel,
                handler: nil
                ))
            
            self.presentViewController(confirmation, animated: true, completion: nil)
            
        }
    }
    
    private func clearAlert(theAlert: Alert){
        
        let tempAlertSet: Set<Alert> = [theAlert]
    
        
        // if it's an in app alert, clear it
        if(theAlert.inAppAlert){
            
            // remove it from the global queue
            if let id = theAlert.inAppAlertId {
                InAppNotifications.sharedInstance.removeInAppAlert(id)
            }
            
            // need to update the counts without making a new counts call
            self.alertCounts!.totalNonRequestAlerts -= 1
            self.alertCounts!.totalAlerts -= 1
            self.currentTotal? -= 1
            
            self.alertCounts!.unreadNonRequestAlerts -= 1
            self.alertCounts!.unreadAlerts -= 1
            self.currentUnread? -= 1
            
            
            self.alerts.remove(theAlert)
            self.updateCurrentView(true)
        }
            
        else {
            //Make the service call to change the status in the database
            TreemAlertService.sharedInstance.clearAlert(
                CurrentTreeSettings.sharedInstance.treeSession,
                alerts: tempAlertSet,
                failureCodesHandled: nil,
                success: {
                    data in
                    
                    // need to update the counts without making a new counts call
                    self.alertCounts!.totalNonRequestAlerts -= 1
                    self.alertCounts!.totalAlerts -= 1
                    self.currentTotal? -= 1
                    
                    if theAlert.alert_viewed == false {
                        self.alertCounts!.unreadNonRequestAlerts -= 1
                        self.alertCounts!.unreadAlerts -= 1
                        self.currentUnread? -= 1
                    }
                    
                    self.alerts.remove(theAlert)
                    
                    self.updateCurrentView(true)
                    
                },
                failure: {
                    error, wasHandled in
                    
                    if(!wasHandled){
                        CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                    }
                }
            )
        }
    }
    
    //Retrieve the count of unread alerts.  This will return total, as well as broken down into friend requests, branch shares and all others
    func getAlertCounts() {
        TreemAlertService.sharedInstance.getAlertCounts(
            CurrentTreeSettings.sharedInstance.treeSession,
            success: {
                data in
                
            },
            failure: {
                error, wasHandled in
                self.cancelLoadingMask()
            }
        )
    }
    
    func reloadAlertsData() {
        self.clearData()
        self.resetPageIndex()
        self.alerts = []
        self.getAlerts(self.pageIndex, pageSize: self.pageSize)
    }
    
    //Retrieve alerts from the server, populate the appropriate table.
    func getAlerts(page: Int, pageSize: Int) {
        // remove prior error view (if added)
        self.errorViewController.removeErrorView()
        
        //If some alerts have been pre-loaded, show them while retrieving newer ones. If not, show the mask
        if (self.alerts.count == 0) {
            self.showLoadingMask()
        }
        
        var parameters: Dictionary<String, AnyObject>? = nil
        
        // check if viewing friend requests only
        if self.friendRequestsOnly {
            parameters = ["reason" : 0]
        }
        else if self.branchRequestsOnly {
            parameters = ["reason" : 12]
        }
        else {
            // we are using 99 for all other types of alerts
            parameters = ["reason" : 99]
        }
        
        if self.refreshControl?.refreshing == true {
            
            self.selectedAlerts.removeAll()
            
            self.tableViewDelegate?.selectedAlertsUpdated(self.selectedAlerts)
            
        }
        
        TreemAlertService.sharedInstance.getAlertCounts(
            CurrentTreeSettings.sharedInstance.treeSession,
            failureCodesHandled: [TreemServiceResponseCode.InvalidAccessToken],
            success: {
                data in
                
                self.alertCounts = AlertCount(data: data)
                
                let inAppAlerts = InAppNotifications.sharedInstance.getInAppAlerts()
                var inAppCount = 0
                var unreadInAppCount = 0
                
                if inAppAlerts != nil {
                    inAppCount = inAppAlerts!.count
                    unreadInAppCount = (inAppAlerts?.filter{$0.alert_viewed! == true}.count)!
                }
                
                
                self.alertCounts?.totalAlerts += inAppCount
                self.alertCounts?.unreadAlerts += unreadInAppCount
                
                if self.friendRequestsOnly {
                    self.currentTotal =  (self.alertCounts?.totalFriendAlerts > 0 ? self.alertCounts?.totalFriendAlerts : 0)
                    self.currentUnread = (self.alertCounts?.unreadFriendAlerts > 0 ? self.alertCounts?.unreadFriendAlerts : 0)
                }
                else if self.branchRequestsOnly {
                    self.currentTotal = (self.alertCounts?.totalBranchAlerts > 0 ? self.alertCounts?.totalBranchAlerts : 0)
                    self.currentUnread = (self.alertCounts?.unreadBranchAlerts > 0 ? self.alertCounts?.unreadBranchAlerts : 0)
                }
                else {
                    self.currentTotal = (self.alertCounts?.totalNonRequestAlerts > 0 ? (self.alertCounts?.totalNonRequestAlerts)! + inAppCount : 0)
                    self.currentUnread = (self.alertCounts?.unreadNonRequestAlerts > 0 ? (self.alertCounts?.unreadNonRequestAlerts)! + unreadInAppCount : 0)
                }
                
                self.refreshBadges()
                
            },
            failure: {
                error, wasHandled in
            }
        )
        
        TreemAlertService.sharedInstance.getAlerts(
            CurrentTreeSettings.sharedInstance.treeSession,
            page: page,
            pageSize: pageSize,
            parameters: parameters,
            failureCodesHandled: nil,
            success: {
                data in
                
                var alertsFromData : OrderedSet<Alert> = []
                var usersFromData : Dictionary<Int,User> = [:]
                
                if self.friendRequestsOnly || self.branchRequestsOnly {
                    let alertsData = Alert.getAlertsFromData(data, nonRequestAlerts: false)
                    
                    alertsFromData = alertsData.alerts
                    usersFromData = alertsData.users
                }
                else {
                    let alertsData = Alert.getAlertsFromData(data, nonRequestAlerts: true)
                    alertsFromData = alertsData.alerts
                    usersFromData = alertsData.users
                }
                
                self.alerts.append(alertsFromData)
                self.alertUsers.merge(usersFromData)
                
                self.setData(alertsFromData)
                
                self.cancelLoadingMask()
                
                if self.delegate?.currentTableVc?.isWorking == true {
                    self.delegate?.currentTableVc?.loadingMaskViewController.cancelLoadingMask({})
                }
            },
            failure: {
                error, wasHandled in
                
                self.cancelLoadingMask()
            }
        )
    }
    
    private func updateCurrentView(reloadData : Bool) {
        
        if reloadData {
            // set the table items equal to the current alert data and reload
            if self.alerts.count > 0 {
                self.items = self.alerts.map{$0}
                self.tableView.reloadData()
            }
            else {
                self.setData(self.alerts)
            }
        }
        
        // remove all selected alerts and update the checkboxes
        self.selectedAlerts.removeAll()
        self.tableViewDelegate?.selectedAlertsUpdated(self.selectedAlerts)
        
        // remove the loading mask
        if self.isWorking {
            self.loadingMaskViewController.cancelLoadingMask({})
        }
        
        self.refreshBadges()
    }
    
    private func refreshBadges() {
        self.delegate?.delegate?.updateAlertsBadge((self.alertCounts?.unreadAlerts)!)
    }
    
    func showLoadingMaskOnParent(completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.queueLoadingMask((self.delegate?.loadingView)!, loadingViewAlpha: 0.75, showCompletion: completion)
            
            self.isWorking = true
        }
    }
}