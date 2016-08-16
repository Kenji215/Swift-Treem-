//
//  AlertsViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/12/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class AlertsViewController: UIViewController, AlertsTableViewDelegate {

    @IBOutlet weak var mainView: UIView!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var markReadButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var actionsView: UIView!
    @IBOutlet weak var actionsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var filterSegmentedControl: UISegmentedControl!
    
    @IBAction func filterSegmentedControlValueChanged(sender: UISegmentedControl) {
        for (rowNum, _) in currentTableVc!.selectedAlerts {
            let cell = currentTableVc!.tableView.dequeueReusableCellWithIdentifier("AlertCell", forIndexPath: rowNum) as! AlertTableViewCell
            
            cell.checkboxButton.selected = false
        }
        
        currentTableVc!.selectedAlerts.removeAll()
        self.selectedAlertsUpdated(currentTableVc!.selectedAlerts)
        
        
        if sender.selectedSegmentIndex == 0 {
            
            UIView.performWithoutAnimation({
                self.removeButton.setTitle("Remove", forState: UIControlState.Normal)
                self.removeButton.layoutIfNeeded()
            })
            
            let tableVC = AlertsTableViewController.getStoryboardInstance()
            
            tableVC.tableViewDelegate   = self
            tableVC.delegate = self
            
            currentTableVc = tableVC
            
            self.embeddedNavigationController.pushViewController(tableVC, animated: true)
        }
        else if sender.selectedSegmentIndex == 1 {
            
            UIView.performWithoutAnimation({
                self.removeButton.setTitle("Decline", forState: UIControlState.Normal)
                self.removeButton.layoutIfNeeded()
            })
            
            let tableVC = AlertsTableViewController.getStoryboardInstance()
            
            tableVC.tableViewDelegate   = self
            tableVC.delegate = self
            
            tableVC.friendRequestsOnly  = true
            currentTableVc = tableVC
            
            self.embeddedNavigationController.pushViewController(tableVC, animated: true)
        }
        else if sender.selectedSegmentIndex == 2 {
            
            UIView.performWithoutAnimation({
                self.removeButton.setTitle("Decline", forState: UIControlState.Normal)
                self.removeButton.layoutIfNeeded()
            })
            
            let tableVC = AlertsTableViewController.getStoryboardInstance()
            
            tableVC.tableViewDelegate = self
            tableVC.delegate = self
            
            tableVC.branchRequestsOnly = true
            currentTableVc = tableVC
            
            self.embeddedNavigationController.pushViewController(tableVC, animated: true)
        }
        
        self.toggleActionMenu(currentTableVc?.selectedAlerts.count > 0)
        self.isAllAlertsDirty = false
    }
    @IBAction func markReadTouchUpInside(sender: UIButton) {
        currentTableVc!.markSelectedAsRead()
    }
    @IBAction func removeTouchUpInside(sender: UIButton) {
        currentTableVc!.clearSelected()
    }
    
    var alertDelegate: AlertsAddUserDelegate? = nil
    var branchShareDelegate: BranchShareDelegate? = nil
    
    var isActionMenuOpen: Bool {
        return (self.actionsViewHeightConstraint.constant > 0)
    }
    
    @IBOutlet weak var headerView: UIView!

    private let loadingMaskViewController       = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController             = ErrorViewController.getStoryboardInstance()
    
    // this is used to manage the VC and deselect boxes before initiating the table VC
    var currentTableVc                          : AlertsTableViewController? = nil

    weak var embeddedNavigationController   : UINavigationController!
//    weak var rootAlertsViewController       : AlertsTableViewController!

    private var actionsViewHeight: CGFloat!

    var delegate : MainViewController? = nil
    
    private var isAllAlertsDirty : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.removeButton.setTitle("Remove", forState: .Normal)
        
        let tempImage = UIImage(named:"Alert")
        
        let newImage = tempImage?.resizeImageScaleWithRatio(CGSize(width: tempImage!.size.width * 0.7, height: tempImage!.size.height * 0.7))
    
        self.filterSegmentedControl.setImage(newImage!, forSegmentAtIndex: 0)
        
        self.actionsView.backgroundColor = AppStyles.sharedInstance.darkGrayColor
        
//        self.filterSegmentedControl.addImageAndText(self.filterSegmentedControl.selectedSegmentIndex, image: newImage!, text: String(self.delegate!.alertCounts!["unread_nonrequest"]!))

        // apply styles to sub header bar
        AppStyles.sharedInstance.setSubHeaderBarStyles(self.headerView)
        self.view.backgroundColor = AppStyles.sharedInstance.subBarBackgroundColor        
        
        // store height
        self.actionsViewHeight = self.actionsViewHeightConstraint.constant
        
        // default closed
        self.toggleActionMenu(false, animate: false)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedAlertsNavigationControllerSegue" {
            self.embeddedNavigationController = segue.destinationViewController as! UINavigationController
            
            if let rootVC = self.embeddedNavigationController.viewControllers.first as? AlertsTableViewController {
                rootVC.tableViewDelegate = self
                rootVC.delegate = self
                
                currentTableVc = rootVC
            }
        }
    }

    static func getStoryboardInstance() -> AlertsViewController {
        return UIStoryboard(name: "Alerts", bundle: nil).instantiateInitialViewController() as! AlertsViewController
    }
    
    func selectedAlertsUpdated(alerts: Dictionary<NSIndexPath,Alert>) {
        let count   = alerts.count
        let showing = self.isActionMenuOpen
        
        // show menu if selected greater than zero
        if count > 0 {
            // if menu not already showing
            if !showing {
                self.toggleActionMenu(true)
            }
        }
        // else hide menu (if showing)
        else if showing {
            self.toggleActionMenu(false)
        }
    }
    
    private func toggleActionMenu(show: Bool, animate: Bool = true) {
        // update constraint
        if show {
            self.actionsViewHeightConstraint.constant = self.actionsViewHeight
            self.actionsView.hidden = false
        }
        else {
            self.actionsViewHeightConstraint.constant = 0
        }

        if animate {
            UIView.animateWithDuration(
                AppStyles.sharedInstance.viewAnimationDuration,
                animations: {
                    self.containerView.layoutIfNeeded()
                    self.actionsView.layoutIfNeeded()
                },
                completion: {
                    _ in
                    
                    if !show {
                        self.actionsView.hidden = true
                    }
                }
            )
        }
        else if !show {
            self.actionsView.hidden = true
        }
    }

    func viewEquity () {
        if let navVC = self.navigationController {
            let vc = EquityRewardsViewController.getStoryboardInstance()
            navVC.pushViewController(vc, animated: true)
        }
    }

    func viewPost(postID: Int) {
        let vc = PostDetailsViewController.getStoryboardInstance()
        vc.postId = postID
        vc.modalPresentationCapturesStatusBarAppearance = true

        self.presentViewController(vc, animated: true, completion: nil)
    }

    func viewBranchSelection(userID: Int, success: (() -> ())?=nil) {

        let newUser = User()
        newUser.id = userID

        self.alertDelegate?.addUserSelectBranch(
            self
            , completion: {
                branchID, branchTitle in

                self.loadingMaskViewController.queueLoadingMask(self.mainView, loadingViewAlpha: 1.0, showCompletion: nil)

                TreemSeedingService.sharedInstance.setUsers(
                    CurrentTreeSettings.sharedInstance.treeSession,
                    branchID: branchID,
                    users: [UserAdd(user: newUser)],
                    failureCodesHandled: nil,
                    success: {
                        data in
                        
                        self.loadingMaskViewController.cancelLoadingMask({
                            
                            // show alert
                            CustomAlertViews.showCustomAlertView(
                                title: Localization.sharedInstance.getLocalizedString("success_prompt_title", table: "Alerts")
                                , message: String (
                                    format: Localization.sharedInstance.getLocalizedString("success_prompt_details", table: "Alerts"),
                                    branchTitle
                                )
                                , fromViewController: self)
                            
                            success?()
                        })
                    },
                    failure: {
                        error, wasHandled in

                        self.loadingMaskViewController.cancelLoadingMask({
                            if(!wasHandled){
                                // show alert
                                CustomAlertViews.showCustomAlertView(
                                    title: Localization.sharedInstance.getLocalizedString("failure_prompt_title", table: "Alerts")
                                    , message: String (
                                        format: Localization.sharedInstance.getLocalizedString("failure_prompt_details", table: "Alerts"),
                                        branchTitle
                                    )
                                    , fromViewController: self)
                            }
                        })
                    }
                )
        })
    }

    func acceptBranchShare (shareID: Int, success: (() -> ())?=nil) {
        self.branchShareDelegate?.placeSharedBranch(
            self
            , completion: {
                branchPlacement in

                self.loadingMaskViewController.queueLoadingMask(self.mainView, loadingViewAlpha: 1.0, showCompletion: nil)

                TreemBranchService.sharedInstance.acceptShare(CurrentTreeSettings.sharedInstance.treeSession,
                    shareID: shareID,
                    placementInfo: branchPlacement,
                    success: {
                        data in

                        self.loadingMaskViewController.cancelLoadingMask({

                            self.branchShareDelegate?.reloadTree()

                            CustomAlertViews.showCustomAlertView(
                                title: Localization.sharedInstance.getLocalizedString("branch_accept_success_title", table: "Alerts")
                                , message: String(format: Localization.sharedInstance.getLocalizedString("branch_accept_success_details", table: "Alerts"), branchPlacement.parent!.title!)
                                , fromViewController: self
                            )
                            success?()
                        })

                    },
                    failure: {
                        error, wasHandled in

                        let errorValue = error.rawValue
                        self.loadingMaskViewController.cancelLoadingMask({
                            if (!wasHandled) {
                                CustomAlertViews.showCustomAlertView(
                                    title: Localization.sharedInstance.getLocalizedString("branch_accept_failure_title", table: "Alerts")
                                    , message: Localization.sharedInstance.getLocalizedString(("branch_accept_failure" + String(errorValue)), table: "Alerts")
                                    , fromViewController: self
                                )
                            }
                        })
                    }
                )
            }
        )
    }

    func viewProfile(userID: Int) {
        let vc = MemberProfileViewController.getStoryboardInstance()
        
        // only one user can be send to the profile page
        vc.userId = userID
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
}
