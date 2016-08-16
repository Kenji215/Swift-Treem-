//
//  BranchViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/10/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class BranchViewController : UIViewController, UINavigationControllerDelegate, UITabBarDelegate, PostDelegate, BranchViewDelegate {
    
    @IBOutlet weak var mainView         : UIView!
    @IBOutlet weak var branchContainer  : UIView!
    @IBOutlet weak var branchTitleBar   : UIView!
    @IBOutlet weak var branchTitleLabel : UILabel!
    @IBOutlet weak var backButton       : UIButton!
    @IBOutlet weak var closeButton      : UIButton!
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.closeBranch()
    }
    
    @IBAction func backButtonTouchUpInside(sender: AnyObject) {
        if let backTouchUpInside = self.backTouchUpInside {
            backTouchUpInside()
            
            self.backButton.hidden = true
        }
    }
    
    enum BranchSubAreaType: Int {
        case Feed      = 0
        case Members   = 1
        case Post      = 2
        case Chat      = 3
    }
    
    var currentBranch: Branch = Branch() {
        willSet (newValue) {
            self.branchBarColor = newValue.color!
            self.branchBarTitle = newValue.title
        }
    }
    
    var branchBarColor: UIColor = UIColor.lightGrayColor() {
        didSet {
            self.branchBarColorUpdated()
        }
    }
    
    var branchBarTitleColor: UIColor = UIColor.whiteColor() {
        didSet {
            if self.isViewLoaded() {
                self.branchTitleLabel.textColor = self.branchBarTitleColor
            }
        }
    }

    var branchBarTitle: String? {
        didSet {
            if self.isViewLoaded() {
                self.setBranchBarTitle()
            }
        }
    }
    
    var activeBranchViewType: BranchSubAreaType = .Feed

    var isPrivateMode : Bool = false {
        didSet {
            self.branchBarColorUpdated()
        }
    }
    
    var sharePostDelegate   : PostShareDelegate?    = nil
    
    private var doTransitionAnimation = false
    
    private weak var embeddedNavigationController   : UINavigationController!
    private weak var embeddedTabBarController       : BranchTabBarController!

    private var feedViewController          : FeedViewController?           = nil
    private var postViewController          : PostViewController?           = nil
    private var membersViewController       : SeedingSearchViewController?  = nil
    private var chatsViewController         : ChatListViewController?       = nil
    
    private var forceFeedReload     = false
    private var forcePostReload     = false

    private let fadeInTransition = FadeInAnimatedTransition()
    
    private var backTouchUpInside: (() -> ())? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = AppStyles.sharedInstance.subBarBackgroundColor
        
        self.branchBarColorUpdated()

        self.setBranchBarTitle()
        
        self.branchTitleLabel.textColor = self.branchBarTitleColor
        
        // add swipe left/right to general view
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(BranchViewController.leftSwipeGesture(_:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.Left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(BranchViewController.rightSwipeGesture(_:)))
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        self.view.addGestureRecognizer(swipeRight)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.backButton.hidden = true
    }
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbedBranchNavigationConrollerSegue" {
            // store nav controller and set self as delegate for views in child container
            self.embeddedNavigationController           = segue.destinationViewController as! UINavigationController
            self.embeddedNavigationController.delegate  = self
            
            self.addChildViewController(self.embeddedNavigationController)
            
            // store and setup tab controller
            if let rootTabController = self.embeddedNavigationController.viewControllers.first as? BranchTabBarController {
                self.embeddedTabBarController = rootTabController
                
                self.resetCurrentViewControllers()
            }
        }
    }
    
    private func resetCurrentViewControllers() {
        // apply styling
        AppStyles.sharedInstance.setBranchTabBarAppearance(self.embeddedTabBarController.tabBar)
        
        // feed
        if self.feedViewController == nil || self.forceFeedReload {
            let feedVC = FeedViewController.getStoryboardInstance()
            feedVC.tabBarItem           = UITabBarItem(title: "Feed", image: UIImage(named: "Feed"), tag: 0)
            feedVC.branchViewDelegate   = self
            feedVC.postDelegate         = self
            feedVC.sharePostDelegate    = self.sharePostDelegate
            feedVC.branchViewDelegate   = self
            
            self.feedViewController = feedVC
            
            self.forceFeedReload = false
        }
        
        // members
        if self.membersViewController == nil {
            let membersVC = SeedingSearchViewController.storyboardInstance()
            membersVC.tabBarItem = UITabBarItem(title: "Members", image: UIImage(named: "Members"), tag: 1)
        
            self.membersViewController = membersVC
        }
        
        // post
        if self.postViewController == nil || self.forcePostReload {
            let postVC = PostViewController.getStoryboardInstance()
            postVC.tabBarItem   = UITabBarItem(title: "Post", image: UIImage(named: "Post"), tag: 2)
            postVC.delegate     = self
            postVC.parentView   = self.mainView
            
            self.postViewController = postVC
            
            self.forcePostReload = false
        }
        
        // chat
        if self.chatsViewController == nil {
            let chatVC = ChatListViewController.getStoryboardInstance()
            chatVC.tabBarItem           = UITabBarItem(title: "Chat", image: UIImage(named: "Chat"), tag: 3)
            chatVC.parentView           = self.mainView
            chatVC.branchViewDelegate   = self

            self.chatsViewController = chatVC
        }
        
        var initialIndex: Int!
        var initialVC   : UIViewController!
        
        switch(self.activeBranchViewType) {
        case BranchSubAreaType.Members  :
            initialIndex    = 1
            initialVC       = self.membersViewController
        case BranchSubAreaType.Post     :
            initialIndex    = 2
            initialVC       = self.postViewController
        case BranchSubAreaType.Chat     :
            initialIndex    = 3
            initialVC       = self.chatsViewController
        default                         :
            initialIndex    = 0 // Feed = default
            initialVC       = self.feedViewController
        }
        
        // trigger view load for only the currently selected vc
        self.embeddedTabBarController.viewControllers = [initialVC]
        
        // set again for all vcs
        self.embeddedTabBarController.viewControllers = [
            self.feedViewController!,
            self.membersViewController!,
            self.postViewController!,
            self.chatsViewController!
        ]
        
        // handle tap on a different tab bar item than the currently selected
        self.embeddedTabBarController.onSelectDifferentItem = {
            (item: UITabBarItem) in
            
            // update active view type based on item selected
            switch(item.tag) {
            case 3  : self.activeBranchViewType = .Chat
            case 2  : self.activeBranchViewType = .Post
            case 1  : self.activeBranchViewType = .Members
            default : self.activeBranchViewType = .Feed
            }
        }
        
        // handle tap on already selected tab bar item
        self.embeddedTabBarController.onReselectItem = {
            (item: UITabBarItem) in
            
            if (item.tag == 0) {
                self.feedViewController!.scrollToTop()
            }
        }
        
        // load with initial index
        self.embeddedTabBarController.selectedIndex = initialIndex
    }
    
    static func getStoryboardInstance() -> BranchViewController {
        return UIStoryboard(name: "Branch", bundle: nil).instantiateViewControllerWithIdentifier("Branch") as! BranchViewController
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        // Adding sub view to navigation controller
        if operation == .Push {
            if toVC.isKindOfClass(PostDetailsViewController) || toVC.isKindOfClass(PostShareViewController) || toVC.isKindOfClass(NewChatViewController) || toVC.isKindOfClass(ChatSessionViewController) {
                return AppStyles.directionLeftViewAnimatedTransition
            }
            else if toVC.isKindOfClass(SeedingSelectedViewController) || toVC.isKindOfClass(SeedingSearchOptionsViewController) {
                return AppStyles.directionUpViewAnimatedTransition
            }

            return AppStyles.directionRightViewAnimatedTransition
        }
            // Removing top view controller from navigation controller
        else if operation == .Pop {
            if fromVC.isKindOfClass(PostDetailsViewController) || fromVC.isKindOfClass(PostShareViewController) || fromVC.isKindOfClass(NewChatViewController) || fromVC.isKindOfClass(ChatSessionViewController) {
                return AppStyles.directionRightViewAnimatedTransition
            }
            else if fromVC.isKindOfClass(SeedingSelectedViewController) || fromVC.isKindOfClass(SeedingSearchOptionsViewController) {
                return AppStyles.directionDownViewAnimatedTransition
            }
            
            return AppStyles.directionLeftViewAnimatedTransition
        }
        
        return nil
    }
    
    func closeBranch() {
        // pop back to tree
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    private func removeInactiveView(inactiveView: UIView?) {
        if let inActiveV = inactiveView {
            // call before removing child view controller's view from hierarchy
            inActiveV.removeFromSuperview()
        }
    }
    
    func leftSwipeGesture(gesture: UIGestureRecognizer) {
        var currentIndex    = self.embeddedTabBarController.selectedIndex
        let lastIndex       = self.embeddedTabBarController.tabBar.items!.count - 1

        if currentIndex == lastIndex {
            currentIndex = 0
        }
        else {
            currentIndex += 1
        }
        
        self.embeddedTabBarController.selectedIndex = currentIndex
    }
    
    func rightSwipeGesture(gesture: UIGestureRecognizer) {
        var currentIndex = self.embeddedTabBarController.selectedIndex
        
        if currentIndex == 0 {
            let lastIndex = self.embeddedTabBarController.tabBar.items!.count - 1
            
            currentIndex = lastIndex
        }
        else {
            currentIndex -= 1
        }
        
        self.embeddedTabBarController.selectedIndex = currentIndex
    }
    
    func postWasAdded() {
        self.forcePostReload = true
        
        self.resetCurrentViewControllers()

        self.doTransitionAnimation = true
        
        self.updateFeedWhenAvailable()
    }
    
    func postWasUpdated(post: Post) {
        self.resetCurrentViewControllers()
        
        self.updateFeedWhenAvailable()
    }
    
    func postWasDeleted(postID: Int) {
        self.updateFeedWhenAvailable()
    }
    
    private func branchBarColorUpdated() {
        if self.isViewLoaded() {
            let adjustedColor = self.isPrivateMode ? self.branchBarColor.lighterColorForColor(0.2) : self.branchBarColor.darkerColorForColor(0.2)

            self.closeButton.tintColor          = adjustedColor
            self.backButton.tintColor           = adjustedColor
            self.branchTitleBar.backgroundColor = self.branchBarColor
        }
    }
    
    private func setBranchBarTitle() {
        self.branchTitleLabel.text = self.branchBarTitle
    }
    
    private func updateFeedWhenAvailable() {
        if let feedVC = self.feedViewController {
            feedVC.refresh(feedVC.refreshControl ?? UIRefreshControl())
        }
        else {
            self.forceFeedReload = true
        }
    }
    
    //# MARK: BranchViewDelegate methods
    
    func setDefaultTitle() {
        self.branchTitleLabel.text = self.branchBarTitle
    }
    
    func setTemporaryTitle(title: String?) {
        self.branchTitleLabel.text = title
    }
    
    func toggleBackButton(show: Bool, onTouchUpInside: (() -> ())?) {
        self.backButton.hidden = !show
        self.backTouchUpInside = onTouchUpInside
    }
}