//
//  MainViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/11/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UINavigationControllerDelegate, UITabBarDelegate, EquityRewardsDelegate {
    
    @IBOutlet weak var homeBackgroundImageView: UIImageView!
    
    @IBOutlet weak var mainTabBar           : UITabBar!
    @IBOutlet weak var treeTabBarItem       : UITabBarItem!
    @IBOutlet weak var equityTabBarItem     : UITabBarItem!
    @IBOutlet weak var alertsTabBarItem     : UITabBarItem!
    @IBOutlet weak var settingsTabBarItem   : UITabBarItem!
    
    @IBOutlet weak var mainTabBarHeightConstraint   : NSLayoutConstraint!
    private weak var embeddedNavigationController   : UINavigationController!
    private weak var embeddedTreeViewController     : TreeViewController!
    
    private var lastSelectedTag: Int = 0
    private var initialTabBarHeightConstraint: CGFloat = 0
    private var postViewController    : PostViewController?    = nil
    private let fadeInTransition = FadeInAnimatedTransition()
    
    private var equityCurrentlyActive       = true
    private var alertsActive                = true
    private var initialEquityTabBarItem     : UITabBarItem? = nil
    private var initialAlertsTabBarItem     : UITabBarItem? = nil
    
    var alertsDatas : (alerts: OrderedSet<Alert>, users: Dictionary<Int,User>)? = nil
    var alertCounts : AlertCount? = nil
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    static func getStoryboardInstance() -> MainViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as! MainViewController
    }
    
    override func presentViewController(viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        
        // fix Apple bug with WKWebView wanting to present action sheet on rootViewController
        if let presentedVC = self.presentedViewController {
            if let secondPresentedVC = presentedVC.presentedViewController {
                secondPresentedVC.presentViewController(viewControllerToPresent, animated: flag, completion: completion)
            }
            else {
                self.presentedViewController?.presentViewController(viewControllerToPresent, animated: flag, completion: completion)
            }
        }
        else {
            super.presentViewController(viewControllerToPresent, animated: flag, completion: completion)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.embeddedTreeViewController.mainDelegate = self
        
        // Tab bar appearance
        AppStyles.sharedInstance.setMainTabBarAppearance(self.mainTabBar)
        
        // set self as delegate for the tab bar
        self.mainTabBar.delegate = self
        
        // set default tab option
        self.mainTabBar.selectedItem = self.mainTabBar.items?.first
        
        self.initialTabBarHeightConstraint = self.mainTabBarHeightConstraint.constant
        
        // store for later when adding / removing
        self.initialEquityTabBarItem = self.equityTabBarItem
        self.initialAlertsTabBarItem = self.alertsTabBarItem
        
        // add swipe left/right to general view
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(MainViewController.leftRightSwipeGesture(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(MainViewController.leftRightSwipeGesture(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbedTreeGridSegue" {
            // store nav controller and set self as delegate for views in child container
            if let embedNavC = segue.destinationViewController as? UINavigationController {
                self.embeddedNavigationController           = embedNavC
                self.embeddedNavigationController.delegate  = self
                
                self.embeddedTreeViewController = embedNavC.viewControllers.first as! TreeViewController
            }
        }
    }
    
    //# MARK: Navigation Delegate Methods
    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        // Adding sub view to navigation controller
        if (operation == .Push) {
            // branch (likely most common use case)
            if(toVC.isKindOfClass(BranchViewController)) {
                self.mainTabBarHeightConstraint.constant = 0
                self.mainTabBar.hidden = true
                
                return AppStyles.directionUpViewAnimatedTransition
            }
                // secret tree login
            else if(toVC.isKindOfClass(SecretTreeLoginViewController)) {
                return AppStyles.directionUpViewAnimatedTransition
            }
                // secret tree signup
            else if(toVC.isKindOfClass(SecretTreeSignupViewController)) {
                return AppStyles.directionLeftViewAnimatedTransition
            }
            else {
                let currentIndex    = self.lastSelectedTag
                let newIndex        = self.mainTabBar.selectedItem?.tag ?? 0
                
                if(newIndex < currentIndex) {
                    return AppStyles.directionRightViewAnimatedTransition
                }
                else if (newIndex == currentIndex) {
                    return self.fadeInTransition
                }
                else {
                    return AppStyles.directionLeftViewAnimatedTransition
                }
            }
        }
            // Removing top view controller from navigation controller
        else if (operation == .Pop) {
            // branch
            if(fromVC.isKindOfClass(BranchViewController)) {
                self.mainTabBarHeightConstraint.constant = self.initialTabBarHeightConstraint
                self.mainTabBar.hidden = false
                
                return AppStyles.directionDownViewAnimatedTransition
            }
                // secret tree login
            else if(fromVC.isKindOfClass(SecretTreeLoginViewController)) {
                return AppStyles.directionDownViewAnimatedTransition
            }
                // secret tree signup
            else if(fromVC.isKindOfClass(SecretTreeSignupViewController)) {
                return AppStyles.directionRightViewAnimatedTransition
            }
            else {
                return AppStyles.directionRightViewAnimatedTransition
            }
        }
        
        return nil
    }
    
    private func showTopBarViewController(viewController: UIViewController, viewControllerClass: AnyClass) {
        // make sure not already open
        if !self.embeddedNavigationController.topViewController!.isKindOfClass(viewControllerClass) {

            self.embeddedNavigationController.pushViewController(viewController, animated: true)
        }
    }
    
    func showAddMembers() {
        self.embeddedTreeViewController.forceShowAllMembersView()
    }
    
    //Some users are not allowed to earn equity. In that case, hide and disable the button that goes to the equity screen
    func showHideEquityButton(bEnable: Bool) {        
        if let eTabBar = self.initialEquityTabBarItem {
            
            if ((bEnable) && (!self.equityCurrentlyActive)) {
                self.mainTabBar.items!.insert(eTabBar, atIndex: eTabBar.tag)
                self.equityCurrentlyActive = true
            }
            else if((!bEnable) && (self.equityCurrentlyActive)) {
                if (eTabBar.tag < self.mainTabBar.items?.count){
                    self.mainTabBar.items!.removeAtIndex(eTabBar.tag)
                    self.equityCurrentlyActive = false
                }
            }
        }
    }
    
    func showHideAlertsButton(enabled: Bool) {
        if let alertsBarItem = self.initialAlertsTabBarItem {
            let index = self.equityCurrentlyActive ? 2 : 1 // position alerts to the right of equity
            
            if enabled && !self.alertsActive {
                self.mainTabBar.items!.insert(alertsBarItem, atIndex: index)
                self.alertsActive = true
            }
            else if !enabled && self.alertsActive {
                self.mainTabBar.items!.removeAtIndex(index)
                self.alertsActive = false
            }
        }
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        
        switch(item) {
            
        case self.equityTabBarItem:
            let vc = EquityRewardsViewController.getStoryboardInstance()
            
            vc.delegate = self
            
            self.showTopBarViewController(vc, viewControllerClass: EquityRewardsViewController.self)
            
        case self.alertsTabBarItem:
            
            // if already on tree
            if self.lastSelectedTag == item.tag {
                let alertVC = self.embeddedNavigationController.topViewController! as! AlertsViewController
                alertVC.currentTableVc!.reloadAlertsData()
            }
            else {
                let vc = AlertsViewController.getStoryboardInstance()
            
                vc.delegate = self
                vc.alertDelegate = self.embeddedTreeViewController
                vc.branchShareDelegate = self.embeddedTreeViewController
            
                self.showTopBarViewController(vc, viewControllerClass: AlertsViewController.self)
            }
            
        case self.settingsTabBarItem:
            self.showTopBarViewController(SettingsViewController.getStoryboardInstance(), viewControllerClass: SettingsViewController.self)

            
        default: // tree
            
            // if already on tree
            if self.lastSelectedTag == item.tag {
                if let treeVC = self.embeddedNavigationController.viewControllers.first as? TreeViewController {
                    treeVC.reloadTree()
                }
            }
            else {
                self.embeddedNavigationController.popToRootViewControllerAnimated(true)
            }
        }
        
        self.lastSelectedTag = item.tag
    }
    
    func selectTabBarRewardsItem() {
        self.mainTabBar.selectedItem = self.equityTabBarItem
        self.tabBar(self.mainTabBar, didSelectItem: self.equityTabBarItem)
    }
    
    //Get the first page of alerts, to check if there are any unread, as well as to pre-load the Alerts view
    func getAlerts(clearBadgeFirst: Bool) {
        
        if(clearBadgeFirst){
            self.alertsTabBarItem.badgeValue = nil
        }
        
        // run in the background...
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            
            TreemAlertService.sharedInstance.getAlertCounts(
                CurrentTreeSettings.sharedInstance.treeSession,
                failureCodesHandled: [TreemServiceResponseCode.InvalidAccessToken],
                success: {
                    data in
                    
                    self.alertCounts = AlertCount(data: data)
                    
                    if self.alertCounts!.unreadAlerts > 0 {
                        
                        let inAppAlertsCount = InAppNotifications.sharedInstance.getInAppAlerts()?.count
                        
                        if (inAppAlertsCount != nil) {
                            self.alertCounts!.unreadAlerts += inAppAlertsCount!
                            self.alertCounts!.totalAlerts += inAppAlertsCount!
                            
                            self.alertCounts!.totalNonRequestAlerts += inAppAlertsCount!
                            self.alertCounts!.unreadNonRequestAlerts += inAppAlertsCount!
                        }
                        
                        
                        self.alertsTabBarItem.badgeValue = String(self.alertCounts!.unreadAlerts)
                    }
                    else {
                        self.alertsTabBarItem.badgeValue = nil
                    }
                },
                failure: {
                    error, wasHandled in
                }
            )
        }
    }
    func updateAlertsBadge(count: Int) {
        
        if count > 0 {
            self.alertsTabBarItem.badgeValue = String(count)
        }
        else {
            self.alertsTabBarItem.badgeValue = nil
        }
        
    }
    
    func leftRightSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer, selectedItem = self.mainTabBar.selectedItem, var selectedIndex = self.mainTabBar.items?.indexOf(selectedItem) {
            let lastIndex   = self.mainTabBar.items!.count - 1
            var setItem: Bool = false
            
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.Right:
                
                if selectedIndex == 0 {
                    selectedIndex = lastIndex
                }
                else {
                    selectedIndex -= 1
                }
                
                setItem = true
                
            case UISwipeGestureRecognizerDirection.Left:
                
                if selectedIndex == lastIndex {
                    selectedIndex = 0
                }
                else {
                    selectedIndex += 1
                }
                
                setItem = true
                
            default:
                break
            }
            
            if setItem {
                let selectedItem = self.mainTabBar.items![selectedIndex]
                
                self.mainTabBar.selectedItem = selectedItem
                self.tabBar(self.mainTabBar, didSelectItem: selectedItem)
            }
        }
    }
}
