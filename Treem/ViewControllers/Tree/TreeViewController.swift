//
//  TreeViewController.swift
//  Treem
//
//  Created by Matthew Walker on 7/10/15.
//  Copyright (c) 2015 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

class TreeViewController : HexagonButtonGridViewController, PostShareDelegate, AlertsAddUserDelegate, BranchShareDelegate, WebBrowserDelegate, PostDelegate, EntitySearchDelegate {
    
    // direct sub views
    @IBOutlet weak var gridView                     : UIView!
    @IBOutlet weak var topMenuView                  : UIView!
    
    // brief current profile outlets
    @IBOutlet weak var currentUserButton: UIButton!
    
    // equity view outlets
    
    @IBOutlet weak var equityButton                 : UserProfileButton!
    @IBOutlet weak var equityDayPercentLabel        : StockTickerLabel!
    @IBOutlet weak var topMenuViewHeightConstraint  : NSLayoutConstraint!
    @IBOutlet weak var equityButtonWidthConstraint  : NSLayoutConstraint!
    
    @IBOutlet weak var equityDayPercentLabelLeadingConstraint: NSLayoutConstraint!
    
    @IBAction func unwindToTreeView(segue: UIStoryboardSegue) {}
    
    @IBAction func unwindToSecretTreeView(segue: UIStoryboardSegue) {
        // open secret tree - can only be opened if coming from secret tree login
        if let sourceVC = segue.sourceViewController as? SecretTreeLoginViewController {
            // change tree to secret
            self.treeType = .Secret
            
            // update session token value
            CurrentTreeSettings.sharedInstance.treeSession.token = sourceVC.currentTreeSessionToken
 
            self.loadCurrentTree()
        }
    }
    
    @IBAction func equityButtonTouchUpInside(sender: AnyObject) {
        self.mainDelegate?.selectTabBarRewardsItem()
    }
    
    private var initialTopMenuViewHeightConstant      : CGFloat = 0.0
    
    // child controllers (make sure to clear on tree reset)
    private var addBranchViewController     : TreeAddBranchViewController?          = nil
    private var addBranchLinkViewController : EntitySearchViewController?           = nil
    private var editMenuViewController      : TreeEditBranchMenuViewController?     = nil
    private var moveFormViewController      : TreeMoveBranchFormViewController?     = nil
    private var selectFormViewController    : TreeSelectBranchFormViewController?   = nil
    
    private let maxBranchLevels         = 3
    
    // icons
    private let addIconImageName        = "Add-Tree"
    private let centerIconImageName     = "Feed-Tree"
    private let membersIconImageName    = "Members-Tree"
    private let postIconImageName       = "Post-Tree"
    private let chatIconImageName       = "Chat-Tree"
    private let reverseIconImageName    = "Reverse"
    private let exitIconImageName       = "Exit"
    private let exploreIconImageName    = "Explore"
    private let selectIconImageName     = "AddFriend"
    private let shareTreeIconImageName  = "Share-Tree"
    
    // tree session
    private var currentTree             : TreeSession           = TreeSession()
    private var currentBranchLevel      : Int                   = 1
    private var currentEditButton       : HexagonButton?        = nil {
        didSet(newValue) {
            if (newValue == nil) {
                self.currentEditBranch = nil
            }
        }
    }
    private var isCurrentTopBranchLevel: Bool {
        return (self.currentBranchLevel == 1)
    }
    
    private var currentEditBranch       : Branch?                       = nil
    private var currentBackButton       : HexagonButton?                = nil
    private var currentExitPrivateButton: HexagonButton?                = nil
    private var currentChatButton       : HexagonButton?                = nil
    
    private var currentExploreVC        : TreeViewController?           = nil   // keep track of explore vc
    private var currentWebBrowserVC     : WebBrowserViewController?     = nil   // keep track of the web browser vc
    private var currentPostVC           : PostEditViewController?       = nil   // keep track of post vc
    
    private var activeBranchChats       : [Int:Bool]?                   = nil   // Int = Branch Id, Bool = Unread Chats
    
    private var performBackonShow       : Bool                          = false
    
    private var exploreWillDismiss      : (()->())?                     = nil   // callback for when explore gets dismissed
    
    private var editingInactiveButtonSet: Set<HexagonButton>?           = nil
    private var movingBranchLevelCount  : Int                           = 0
    
    // grid styles
    private var currentGridTheme            : TreeGridTheme!
    private var hexagonSingleCharacterFont  : UIFont = UIFont.systemFontOfSize(52)
    private var hexagonActionFont           : UIFont = UIFont.systemFontOfSize(12)
    private var hexagonTitleFont            : UIFont = UIFont.systemFontOfSize(14.0)
    
    private let loadingMaskViewController           = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController                 = ErrorViewController.getStoryboardInstance()
    
    private var userEarnsEquity : Bool = true
    
    private var treeType: TreeType = .Main

    private var branchViewController    : BranchViewController?     = nil
    var mainDelegate                    : MainViewController?       = nil
    private var webBrowserDelegate      : WebBrowserDelegate?       = nil

    private var overlayView : UIView? = nil

    private enum Actions : Int {
        case NORMAL         = 0     // Standard usage of the Tree view
        case EDIT                   // Adding/Editing a branch
        case SELECTING              // Selecting an existing branch to do an action to (e.g. where to share a post)
        case MOVING                 // Moving an existing branch to a new location
        case PLACING                // Placing a shared branch in an open spot
    }
    
    private var actionMode : Actions = .NORMAL
    
    static func getStoryboardInstance() -> TreeViewController {
        return UIStoryboard(name:"TreeGrid", bundle: nil).instantiateViewControllerWithIdentifier("Tree") as! TreeViewController
    }
    
    // ------------------------------------------- //
    // MARK: Delegates / Outside Calls
    // ------------------------------------------- //
    private var selectingCenterHexIcon          : String? = nil                     // icon for the center "select" hex button
    private var selectedCallback                : ((Int, String) -> ())? = nil      // what you want to have happen when the branch is selected
    private var selectedClose                   : (((() -> ())?) -> ())? = nil      // what to do when we close the view (cancel or select branch)

    private var placedCallback                  : ((Branch) -> ())? = nil
    private var placedClose                     : (((() -> ())?) -> ())? = nil

    func sharePostSelectBranch(shareViewController: PostShareViewController?, completion: ((Int, String) -> ())?) {
        if let _ = shareViewController {
            if let branchVC = self.branchViewController {
                branchVC.navigationController?.popViewControllerAnimated(true)
                
                // on close, reset grid, push branch vc back on and show the share screen
                self.selectedClose = {
                    completeCallback in
                    
                    self.unsetSelectionMode()
                    self.navigationController?.pushViewController(branchVC, animated: true, completion: completeCallback)
                }
            }

            self.actionMode                             = .SELECTING
            self.selectingCenterHexIcon                 = self.shareTreeIconImageName
            self.selectedCallback                       = completion
            
            self.setSelectionMode()
        }
    }
    
    func addUserSelectBranch(alertsViewController: AlertsViewController?, completion:((Int, String) -> ())?) {
        if let alertVC = alertsViewController {
            alertVC.navigationController?.popToRootViewControllerAnimated(true)
            
            self.selectedClose = {
                completeCallback in
                
                self.unsetSelectionMode()
                self.navigationController?.pushViewController(alertVC, animated: true)
                
                completeCallback?()
            }

            self.actionMode                             = .SELECTING
            self.selectingCenterHexIcon                 = self.selectIconImageName
            self.selectedCallback                       = completion
            
            self.setSelectionMode()
        }
    }

    func placeSharedBranch(alertsViewController: AlertsViewController?, completion: ((Branch) -> ())?) {
        if let alertVC = alertsViewController {
            alertVC.navigationController?.popToRootViewControllerAnimated(true)
            self.placedClose = {
                completeCallback in

                self.unsetPlacementMode()
                self.navigationController?.pushViewController(alertVC, animated: true)

                completeCallback?()
            }

            self.actionMode             = .PLACING
            self.placedCallback         = completion

            self.setPlacementMode()
        }
    }

    func shareWebLink(webBrowserController: WebBrowserViewController?, webLink: String){
        if let browserVC = webBrowserController {
            
            self.currentWebBrowserVC = browserVC
            browserVC.dismissViewControllerAnimated(false, completion: nil)
            
            // pop the explore vc if present
            if let exploreVC = self.currentExploreVC { exploreVC.dismissViewControllerAnimated(true, completion: nil) }

            // on close, reset grid, push branch vc back on and show the share screen
            self.selectedClose = {
                completeCallback in
                
                // if closed but no completeCallBack specified it means the user hit cancel so we'll put the views back
                // if the user selected a branch, the "selectedCallback" will fire after this, we'll put the views back then
                if(completeCallback == nil){
                    self.unsetSelectionMode()
                    
                    self.currentWebBrowserVC = nil
                    
                    if let exploreVC = self.currentExploreVC {
                        self.presentViewController(exploreVC, animated: false, completion: {
                            exploreVC.presentViewController(browserVC, animated: true, completion: nil)
                        })
                    }
                    else{
                        self.presentViewController(browserVC, animated: true, completion: nil )
                    }
                }
                else{
                    completeCallback?()
                }
            }

            self.actionMode                             = .SELECTING
            self.selectingCenterHexIcon                 = self.shareTreeIconImageName
            self.selectedCallback = {
                branchId in

                let postVC = PostEditViewController.getStoryboardInstance()
                postVC.delegate = self
                postVC.editTitle = Localization.sharedInstance.getLocalizedString("share_link", table: "TreeGrid")
                postVC.shareLink = webLink
                self.currentPostVC = postVC
                self.presentViewController(postVC, animated: true, completion: nil)
            }
            
            self.setSelectionMode()
        }
    }
    
    func postWasAdded() {
        // dismiss post vc, unset select mode and bring back web browser (and possibly the explore tree if needed)
        if let postVC = self.currentPostVC {
            postVC.dismissViewControllerAnimated(true, completion: {
                if let browserVC = self.currentWebBrowserVC {
                    self.unsetSelectionMode()
                    
                    self.currentWebBrowserVC = nil
                    
                    if let exploreVC = self.currentExploreVC {
                        self.presentViewController(exploreVC, animated: false, completion: {
                            exploreVC.presentViewController(browserVC, animated: true, completion: nil)
                        })
                    }
                    else {
                        self.presentViewController(browserVC, animated: true, completion: nil )
                    }
                }
            })
            
            self.currentPostVC = nil
        }
    }
    
    // MARK: View Controller Methods
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // tie outlet to view to the hexagon grid viewcontroller
        self.hexagonGridView = gridView
        
        self.topMenuView.backgroundColor = AppStyles.sharedInstance.subBarBackgroundColor

        // preload content credentials (call always passes default tree settings due to service design)
        TreemContentService.sharedInstance.checkRepoCreds(TreeSession(treeID: CurrentTreeSettings.mainTreeID, token: nil), complete: nil)
        
        self.initialTopMenuViewHeightConstant = self.topMenuViewHeightConstraint.constant
        
        // hide top buttons initially on first load
        self.currentUserButton.hidden       = true
        self.equityButton.hidden            = true
        self.equityDayPercentLabel.hidden   = true
        
        // load current tree
        self.loadCurrentTree()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // non-public trees data load when view appears
        if self.treeType != .Public {
            // call on non public trees
            self.checkForActiveChats()
            
            // check alerts on non public trees
            self.mainDelegate?.getAlerts(false)
        }

        if (self.performBackonShow) {
            self.branchBackTouchUpInside()
            self.performBackonShow = false
        }
    }

    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    private func loadCurrentTree() {
        switch(self.treeType) {
        case .Main  : self.loadMainTreeGrid()
        case .Public: self.loadPublicTreeGrid()
        case .Secret: self.loadSecretTreeGrid(CurrentTreeSettings.sharedInstance.treeSession.token)
        }
    }
    
    private func resetTreeGrid() {
        // clear hexagon grid
        self.clearGrid()
        
        // clear status data
        self.currentBackButton              = nil
        self.currentTree.currentBranch      = nil
        self.currentBranchLevel             = 1
        self.currentEditBranch              = nil
        self.currentEditButton              = nil
        self.currentExitPrivateButton       = nil
        self.currentChatButton              = nil
        self.movingBranchLevelCount         = 0
        self.editingInactiveButtonSet       = nil
        self.performBackonShow              = false
        self.actionMode                     = .NORMAL
        
        self.currentUserButton.hidden       = true
        self.equityButton.hidden            = true
        self.equityDayPercentLabel.hidden   = true
        
        // load background
        self.gridView.backgroundColor       = self.currentGridTheme.backgroundColor

        // public opens in separate view
        if self.treeType == .Public {
            // add background image view behind grid view
            if let imageName = self.currentGridTheme.backgroundImage {
                let imageView = UIImageView()
                
                imageView.image = UIImage(named: imageName)
                imageView.frame = self.view.frame
                
                self.view.insertSubview(imageView, belowSubview: self.gridView)
            }
        }
        else if let image = self.currentGridTheme.backgroundImage, mainDelegate = self.mainDelegate, imageView = mainDelegate.homeBackgroundImageView {
            
            UIView.transitionWithView(
                imageView,
                duration: 0.4,
                options: .TransitionCrossDissolve,
                animations: {
                    imageView.image = UIImage(named: image)
                },
                completion: nil
            )
        }
        
        self.view.backgroundColor                           = self.currentGridTheme.backgroundColor
        self.loadingMaskViewController.view.backgroundColor = self.currentGridTheme.backgroundColor
        self.loadingMaskViewController.activityColor        = AppStyles.sharedInstance.lightGrayColor
        
        self.lineWidth = self.currentGridTheme.hexagonLineWidth
        
        self.equityButtonWidthConstraint.constant = 0
        
        // equity bar present in main tree only
        if self.treeType == .Main {
            // reload equity data
            self.loadEquityRewardsData()
        }
        
        // show profile button on member trees
        if self.treeType == .Main || self.treeType == .Secret {
            self.loadUserProfileButton()
        }
        else {
            self.currentUserButton.hidden = true
        }
    }
    
    private func checkForActiveChats(){
        // no chatting in the public tree currently
        if(self.treeType != .Public){
            // do this in the background, don't hold up the ui
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                
                // get the branches that have chats
                TreemChatService.sharedInstance.getBranchChats(
                    CurrentTreeSettings.sharedInstance.treeSession,
                    failureCodesHandled: [
                        // don't show an error for this since it's in the background
                        TreemServiceResponseCode.DisabledConsumerKey,
                        TreemServiceResponseCode.InternalServerError,
                        TreemServiceResponseCode.InvalidAccessToken,
                        TreemServiceResponseCode.InvalidHeader,
                        TreemServiceResponseCode.InvalidSignature,
                        TreemServiceResponseCode.LockedOut,
                        TreemServiceResponseCode.NetworkError,
                        TreemServiceResponseCode.OtherError
                    ],
                    success: {
                        data in
                        
                        self.activeBranchChats = ChatSession.loadBranchChats(data)
                        
                        self.setCurrentChatButtonIndicator()
                        
                    },
                    failure: {
                        error, wasHandled in
                        
                        // do nothing failed quietly
                    }
                )
            }
        }
    }
    
    // load data into equity rewards status bar
    private func loadEquityRewardsData() {
        TreemEquityService.sharedInstance.getUserRollout(
            parameters: nil,
            failureCodesHandled: [
                // fail silently
                TreemServiceResponseCode.DisabledConsumerKey,
                TreemServiceResponseCode.InternalServerError,
                TreemServiceResponseCode.InvalidAccessToken,
                TreemServiceResponseCode.InvalidHeader,
                TreemServiceResponseCode.InvalidSignature,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.OtherError
            ],
            success: {
                (data:JSON) in

                self.userEarnsEquity = data["earns_equity"].boolValue
                
                if (self.userEarnsEquity) {
                    //Show percent change from yesterday - making sure to avoid dividing by 0.
                    self.equityDayPercentLabel.points = data["change_today"].intValue
                    
                    // if no text for change, remove extra right padding
                    if (self.equityDayPercentLabel.text ?? "").isEmpty {
                        self.equityDayPercentLabelLeadingConstraint.constant = 0
                    }
                    
                    //Percentile of all users
                    UIView.performWithoutAnimation({
                        self.equityButton.setTitle(String(format: "%.0f", (data["percentile"].doubleValue * 100)) + "%, " + String(data["points"].intValue) + " points", forState: .Normal)
                        self.equityButton.sizeToFit()
                        self.equityButtonWidthConstraint.constant = self.equityButton.frame.width
                        self.equityButton.layoutIfNeeded()
                    })

                    self.equityButton.tintColor = UIColor.whiteColor()
                    
                    // show equity
                    self.showHideEquity(true)
                }
                else {
                    self.showHideEquity(false)
                }
            },
            failure: {
                error,wasHandled in
                
                // do nothing
                self.showHideEquity(false)
            }
        )
    }
    
    func loadUserProfile() {
        let vc = ProfileViewController.getStoryboardInstance()
        
        vc.isPresenting = true
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    private func loadUserProfileButton() {
        self.currentUserButton.hidden = true
        
        TreemProfileService.sharedInstance.getSelfProfileAvatarName(
            [
                // fail silently
                TreemServiceResponseCode.DisabledConsumerKey,
                TreemServiceResponseCode.InternalServerError,
                TreemServiceResponseCode.InvalidAccessToken,
                TreemServiceResponseCode.InvalidHeader,
                TreemServiceResponseCode.InvalidSignature,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.OtherError
            ],
            success: {
                (data:JSON) in
                
                self.currentUserButton.hidden    = false
                
                let profile = Profile(json: data)
                
                // add button target
                self.currentUserButton.addTarget(self, action: #selector(TreeViewController.loadUserProfile), forControlEvents: UIControlEvents.TouchUpInside)
                
                // load user profile name
                UIView.performWithoutAnimation({
                    self.currentUserButton.setTitle(profile.getFullName(), forState: .Normal)
                    self.currentUserButton.layoutIfNeeded()
                })
                
                // load user avatar image
                if let avatar = profile.avatar, url = NSURL(string: avatar) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        TreemContentService.sharedInstance.getContentRepositoryFile(url, cacheKey: profile.avatarId, success: {
                            (image) -> () in
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                _ in
                                
                                // load the profile image
                                self.currentUserButton.setImage(image ?? UIImage(named: "Avatar"), forState: .Normal)
                                self.currentUserButton.imageView?.contentMode = .ScaleAspectFit
                                
                                let imageframe = self.currentUserButton.imageView!.frame
                                
                                self.currentUserButton.imageView?.frame = CGRectMake(imageframe.origin.x, imageframe.origin.y, imageframe.height, imageframe.height)
                            })
                        })
                    })
                }
                else {
                    self.currentUserButton.setImage(UIImage(named: "Avatar"), forState: .Normal)
                }
            },
            failure: {
                _ in
                
                // do nothing
            }
        )
    }
    
    private func showHideEquity(showEquity: Bool){
        // if the user actually earns equity and we are showing it
        let showEquity = (showEquity) && (self.userEarnsEquity)
        
        self.equityButton.hidden            = !showEquity
        self.equityDayPercentLabel.hidden   = !showEquity
        
        self.mainDelegate?.showHideEquityButton(showEquity)
    }
    
    private func getUserBranches() {
        TreemBranchService.sharedInstance.getUserBranches(
            self.currentTree,
            parameters: nil,
            responseCodesHandled: [
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.DisabledConsumerKey
            ],
            success: {
                (data:JSON) in
                
                // add initial branches
                self.setInitialBranch(data)
                
                // draw initial branches
                self.loadTreeGrid()
                
                // cancel loading mask
                self.loadingMaskViewController.cancelLoadingMask(nil)
            },
            failure: {
                error,wasHandled in
                // cancel loading mask
                self.loadingMaskViewController.cancelLoadingMask({
                    if !wasHandled {
                        // if network error
                        if (error == TreemServiceResponseCode.NetworkError) {
                            self.errorViewController.showNoNetworkView(self.view, recover: self.getUserBranches)
                        }
                        else if (error == TreemServiceResponseCode.LockedOut) {
                            self.errorViewController.showLockedOutView(self.view, recover: self.getUserBranches)
                        }
                        else if (error == TreemServiceResponseCode.DisabledConsumerKey) {
                            self.errorViewController.showDeviceDisabledView(self.view, recover: self.getUserBranches)
                        }
                    }
                })
            }
        )
    }
    
    private func loadTreeGrid() {
        // determine size of hexagon based on outer frame/device
        var maxHexagonHeight    : CGFloat = 142
        let maxFontSize         : CGFloat = 17.0
        
        let device = Device.sharedInstance
        
        if device.isResolutionSmallerThaniPhone5() {
            maxHexagonHeight = 100
        }
        else if (device.isResolutionSmallerThaniPhone6()) {
            maxHexagonHeight = 114
        }
        else if (device.isResolutionSmallerThaniPhone6Plus()) {
            maxHexagonHeight = 130
        }
        else if (device.isiPad()) {
            maxHexagonHeight = 166
        }
        // else use default
        
        // get radius for the height
        var hexagonHeight = (self.gridView.frame.height) / 4 - self.lineWidth
        
        if(hexagonHeight > maxHexagonHeight) {
            hexagonHeight = maxHexagonHeight
        }
        
        var fontSize = round(hexagonHeight / 6.5)
        
        if fontSize > maxFontSize {
            fontSize = maxFontSize
        }
        
        self.hexagonActionFont = UIFont.systemFontOfSize(fontSize - 4)
        
        self.hexagonRadius = round(hexagonHeight / 2)
        
        // determine font size
        self.hexagonTitleFont = UIFont.systemFontOfSize(fontSize)
        
        // create default center hexagon
        let defaultCenterButton = HexagonButton()
        
        defaultCenterButton.gridPosition    = self.defaultGridCenterPosition
        
        // add default hexagon to layout
        self.setHexagonButton(defaultCenterButton)
        self.setHexButtonInViewCenter(defaultCenterButton)

        // set center icon (set after adding default hexagon to layout)
        defaultCenterButton.strokeColor = self.currentGridTheme.buttonStrokeColor
        
        self.setCenterHexagonButtonProperties(defaultCenterButton)
        
        defaultCenterButton.type = .BRANCH
        
        // load initial active branches (load with initial properties)
        self.setHexagonButtonsInitialActiveButtons()
        
        // load outer inactive branches
        self.setHexagonButtonsForInactiveBranches()
        
        // load initial hexagon buttons into view
        self.drawHexagonButtonsInViewCenter(Set([HexagonButton](self.hexagonButtons.values)))
        
        // load initial branch styles (after hexagons added to grid)
        self.setHexagonButtonInitialBranchProperties(self.currentTree.currentBranch!.children)
        
        // animate buttons into view
        self.animateExpandNeighborHexagonsIntoPosition(delay: AppStyles.sharedInstance.viewAnimationDuration)
        
        // show branch action buttons
        self.showBranchActionHexagonButtons()
        
        // show private exit button (if applicable)
        self.showExitPrivateHexagonButton()
        
        // show public exit button (if applicable)
        self.showExitPublicHexagonButton()

        // If we're selecting a branch to add new users, this is where the setup gets kicked off, once the main initialization is done
        if (self.actionMode == .SELECTING) {
            self.setSelectionMode()
        }
    }

    // reload the current tree
    func reloadTree() {
        // clear child view controllers
        self.addBranchViewController        = nil
        self.addBranchLinkViewController    = nil
        self.editMenuViewController         = nil
        self.moveFormViewController         = nil
        self.selectFormViewController       = nil

        // clear extra viewcontrollers
        self.childViewControllers.forEach({
            $0.view.removeFromSuperview()
            $0.removeFromParentViewController()
        })

        self.loadCurrentTree()
    }
    
    private func loadMainTreeGrid() {
        self.topMenuViewHeightConstraint.constant = self.initialTopMenuViewHeightConstant
        
        // update session tree
        self.currentTree = CurrentTreeSettings.sharedInstance.treeSession
        
        // initial tree does not require tree session token
        self.currentTree.token = nil
        
        self.currentTree.treeID = CurrentTreeSettings.mainTreeID

        // change theme to initial
        self.currentGridTheme = TreeGridTheme.membersTheme
        
        // clear current tree grid data
        self.resetTreeGrid()
        
        self.loadingMaskViewController.queueLoadingMask(self.gridView, loadingViewAlpha: 0, showCompletion: nil)
        
        self.getUserBranches()
    }
    
    private func loadSecretTreeGrid(treeSessionToken: String?) {
        self.topMenuViewHeightConstraint.constant = self.initialTopMenuViewHeightConstant
        
        self.currentTree = CurrentTreeSettings.sharedInstance.treeSession
        
        // change theme to private
        self.currentGridTheme = TreeGridTheme.secretTheme
        
        self.currentTree.treeID = CurrentTreeSettings.secretTreeID
        
        // no equity in private tree
        self.showHideEquity(false)
        
        // clear current tree grid data
        self.resetTreeGrid()

        // queue loading mask on view until tree has been loaded
        self.loadingMaskViewController.queueLoadingMask(self.gridView, loadingViewAlpha: 0, showCompletion: nil)
        
        self.getUserBranches()
    }
    
    private func loadPublicTreeGrid() {
        self.topMenuViewHeightConstraint.constant = AppDelegate.getStatusBarDefaultHeight()
        
        // load tree branches
        self.currentTree.treeID = CurrentTreeSettings.publicTreeID
        
        // no equity in public tree
        self.showHideEquity(false)
        
        // change theme to initial
        self.currentGridTheme = TreeGridTheme.exploreTheme
        
        // clear current tree grid data
        self.resetTreeGrid()
        
        self.loadingMaskViewController.queueLoadingMask(self.gridView, loadingViewAlpha: 0, showCompletion: nil)
        
        self.getUserBranches()
    }
    
    private func checkBranchViewControllerLoaded() {
        let branchVC = BranchViewController.getStoryboardInstance()
        
        branchVC.currentBranch              = self.currentTree.currentBranch!
        branchVC.branchBarTitleColor        = self.currentGridTheme.branchBarTitleColor
        branchVC.isPrivateMode              = self.treeType == .Secret
        branchVC.sharePostDelegate          = self
        
        self.branchViewController = branchVC
    }

    private func showChatView() {
        self.checkBranchViewControllerLoaded()

        if let branchVC = self.branchViewController {
            branchVC.activeBranchViewType   = BranchViewController.BranchSubAreaType.Chat
            
            self.navigationController?.pushViewController(branchVC, animated: true)
        }
    }
    
    private func showExploreView(){
        let vc = TreeViewController.getStoryboardInstance()

        vc.treeType             = .Public
        vc.webBrowserDelegate   = self        // we want the initial tree to be the web browser's delegate, not the explore tree
        vc.exploreWillDismiss   = { self.currentExploreVC = nil }
        
        self.currentExploreVC   = vc
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    private func centerBranchNonSelectAction(){
        // public tree, load url
        if let branch = self.currentTree.currentBranch where branch.url != nil {
            self.showExploreWebBrowser(branch)
        }
        // default & secret tree
        else {
            self.showFeedView()
        }
    }
    
    // check if branch is public branch without an entity (url)
    private func isPublicBranchWithoutEntity(branch: Branch?) -> Bool {
        return self.treeType == .Public && branch != nil && branch!.id > 0 && branch!.url == nil
    }
    
    private func showCurrentEditExploreWebBrowser() {
        if let branch = self.currentEditBranch {
            self.showExploreWebBrowser(branch)
        }
    }
    
    private func showExploreWebBrowser(branch: Branch){
        let vc = WebBrowserViewController.getStoryboardInstance()
        
        vc.webUrl           = branch.url
        vc.defaultTitle     = branch.title
        vc.branchColor      = branch.color!
        vc.shareDelegate    = self.webBrowserDelegate
        vc.isPrivateMode    = self.treeType == .Secret
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    // show feed
    private func showFeedView() {
        self.checkBranchViewControllerLoaded()
        
        if let branchVC = self.branchViewController {
            branchVC.activeBranchViewType   = BranchViewController.BranchSubAreaType.Feed
            
            self.navigationController?.pushViewController(branchVC, animated: true)
        }
    }
    
    // show members
    private func showMembersView() {
        self.checkBranchViewControllerLoaded()
        
        if let branchVC = self.branchViewController {
            branchVC.activeBranchViewType   = BranchViewController.BranchSubAreaType.Members
            
            self.navigationController?.pushViewController(branchVC, animated: true)
        }
    }
    
    func forceShowAllMembersView() {
        let branchVC = BranchViewController.getStoryboardInstance()
        
        branchVC.currentBranch              = self.getInitialBranch(nil)
        branchVC.branchBarTitleColor        = self.currentGridTheme.branchBarTitleColor
        
        branchVC.activeBranchViewType   = BranchViewController.BranchSubAreaType.Members
        
        self.navigationController?.pushViewController(branchVC, animated: true)
    }
    
    // show post
    private func showPostView() {
        self.checkBranchViewControllerLoaded()
        
        if let branchVC = self.branchViewController {
            branchVC.activeBranchViewType   = BranchViewController.BranchSubAreaType.Post
            
            self.navigationController?.pushViewController(branchVC, animated: true)
        }
    }

    private func showShareView() {
        self.checkBranchViewControllerLoaded()

        //make sure to pass self.currentTree.currentBranch! in.
        let shareVC = BranchShareViewController.getStoryboardInstance()
        shareVC.delegate = self
        shareVC.currentBranchID = self.currentTree.currentBranchID

        self.presentViewController(shareVC, animated: true, completion: nil)
    }
    
    // load add form
    private func addEditBranchHandler(isNewBranch: Bool, branch: Branch? = nil, entity: PublicEntity? = nil) {
        let hexButton   = self.currentEditButton!
        
        // if creating a new branch on public tree (and not coming from entity selection menu)
        if isNewBranch && self.treeType == .Public && entity == nil {
            // show list of sites first
            let entitySearchVC = EntitySearchViewController.getStoryboardInstance()
            
            entitySearchVC.delegate = self
            
            self.addBranchLinkViewController = entitySearchVC
            
            // add view to current view
            self.presentViewController(entitySearchVC, animated: true, completion: nil)
        }
        // adding or editing an existing branch
        else {
            let addBranchVC = TreeAddBranchViewController.getStoryboardInstance()
            
            self.addBranchViewController = addBranchVC
            
            // if new branch clear hex button values
            if isNewBranch {
                hexButton.setTitle(nil, forState: .Normal)
                hexButton.removeIconImages()
            }
            
            // pass tree information
            addBranchVC.treeSession = self.currentTree
            
            // check to enable color selection (only on top level)
            addBranchVC.canSelectColor = self.isCurrentTopBranchLevel
            
            // tie add/edit branch handlers
            addBranchVC.colorChangeHandler          = self.addEditBranchColorChange
            addBranchVC.saveTouchHandler            = self.addEditBranchSave
            addBranchVC.cancelTouchHandler          = self.addEditBranchDismiss
            addBranchVC.branchNameChangeHandler     = self.addEditBranchNameChange
            
            addBranchVC.maskBackground              = self.loadingMaskViewController.view.backgroundColor
            
            var addEditBranch: Branch
            
            // check if branch exists
            if let branch = self.currentEditBranch {
                addEditBranch = branch
            }
            // otherwise create branch and assign tree positioning properties for save (other properties in add vc)
            else {
                addEditBranch = Branch()
                
                addEditBranch.id        = 0
                addEditBranch.position  = self.getBranchPositionFromHexagonGridLocation(hexButton.gridPosition!, fromCenterGridPosition: self.hexButtonInViewCenter.gridPosition)!
                addEditBranch.parent    = self.currentTree.currentBranch
            }
            
            // add public entity details if provided
            if let entity = entity {
                addEditBranch.updateBranchFromEntityProperties(entity)
            }
            
            if isNewBranch {
                hexButton.updateFavIconImage(addEditBranch)
            }
            
            // add branch data to vc
            addBranchVC.branch = addEditBranch
            
            // add view to current view
            addBranchVC.view.frame = self.view.frame
            addBranchVC.view.alpha = 0
            
            self.view.addSubview(addBranchVC.view)
            self.addChildViewController(addBranchVC)
            
            // if colors can't be selected
            if !addBranchVC.canSelectColor {
                // assign color to hexagon since it can't be updated from add/edit view color handler
                self.setBranchColorHexagonButtonProperties(hexButton, branchColor: self.getBranchColor(nil, parent: self.currentTree.currentBranch!))
            }
            
            self.setEditMode(hexButton)
            
            // if not already in edit mode
            if self.actionMode != .EDIT {
                self.setHexButtonInViewCenter(hexButton, offsetAnimation: {
                    (xOffset: CGFloat, yOffset: CGFloat) in
                    
                    addBranchVC.view.alpha = 1.0
                    
                    self.gridView.bounds.origin.y += self.getAddEditExtraViewOffset(hexButton)
                })
                
                self.actionMode = .EDIT
            }
            else {
                // show add branch view in current edit
                addBranchVC.view.alpha = 1.0
            }
            
            // update tree grid view (handles whether or not currently in edit mode)
            self.showEditOverlay(hexButton)
        }
    }

    private func addEditBranchSave(branch: Branch, entity: PublicEntity? = nil) {
        // update hexagon
        if let hexButton = self.currentEditButton {
            // update hexagon with new branch ID
            hexButton.id = branch.id
            
            // add new branch to tree
            if let _ = self.currentTree.currentBranch?.children {
                self.currentTree.currentBranch!.children!.append(branch)
            }
            else {
                self.currentTree.currentBranch?.children = [branch]
            }
        }
        
        // dismiss add view
        self.addEditBranchDismiss()
    }
    
    // MARK: Branch Menu Functions
    
    private func addEditBranchNameChange(sender: UITextField) {
        if let button = self.currentEditButton {
            if let titleLabel = button.titleLabel {
                titleLabel.lineBreakMode                = NSLineBreakMode.ByClipping
                titleLabel.textAlignment                = NSTextAlignment.Center
                titleLabel.numberOfLines                = 3
                titleLabel.adjustsFontSizeToFitWidth    = true
            }
            
            let text = sender.text
            
            if text?.composedCount == 1 {
                button.titleFont = self.hexagonSingleCharacterFont
            }
            else {
                button.titleFont = self.hexagonTitleFont
            }
            
            button.setTitle(text, forState: UIControlState.Normal)
            
            sender.text = text
        }
    }
    
    func branchMenuExploreTouchUpInside() {
        // navigating outside edit menu
        self.actionMode = .NORMAL
        
        if let currentBranch = self.currentEditBranch ?? self.currentTree.currentBranch {
            self.showExploreWebBrowser(currentBranch)
        }
        
        self.dismissEditMenuView()
    }
    
    func branchMenuFeedTouchUpInside(){
        // navigating outside edit menu
        self.actionMode = .NORMAL
        
        self.openSubView(self.centerBranchNonSelectAction)
    }
    
    func branchMenuMembersTouchUpInside(){
        // navigating outside edit menu
        self.actionMode = .NORMAL
        
        self.openSubView(self.showMembersView)
    }
    
    func branchMenuPostTouchUpInside(){
        // navigating outside edit menu
        self.actionMode = .NORMAL
        
        self.openSubView(self.showPostView)
    }

    func branchMenuChatTouchUpInside() {
        // navigating outside edit menu
        self.actionMode = .NORMAL
        
        self.openSubView(self.showChatView)
    }

    func branchMenuShareTouchUpInside() {
        // navigating outside edit menu
        self.actionMode = .NORMAL
        
        self.openSubView(self.showShareView)
    }

    private func removeEditOverlay() {
        // remove overlay
        if let overlay = self.overlayView {
            overlay.removeFromSuperview()
            self.overlayView = nil
        }
    }
    
    private func showEditOverlay(editHexagonButton: HexagonButton, withAnimation: (()->())? = nil) {
        // check if overlay already being shown
        if self.overlayView == nil {
            // add overlay
            let overlay         = UIView()
            let centerOffset    = getHexButtonToCenterOffset(editHexagonButton)
            
            overlay.backgroundColor = AppStyles.overlayColor
            
            overlay.frame           = self.gridView.bounds
            overlay.alpha           = 0
            
            overlay.frame.origin.x  += centerOffset.0
            overlay.frame.origin.y  += centerOffset.1
            
            self.gridView.addSubview(overlay)
            self.gridView.bringSubviewToFront(overlay)
            self.gridView.bringSubviewToFront(editHexagonButton)
            
            UIView.animateWithDuration(self.animDuration * 0.5, animations: {
                withAnimation?()
                overlay.alpha       = 1
            })
            
            self.overlayView = overlay
        }
        else {
            UIView.animateWithDuration(self.animDuration * 0.5, animations: {
                withAnimation?()
            })
        }
    }
    
    private func openSubView(menuFunction: (() -> Void)!) {
        if let currentButton = self.currentEditButton {
            self.dismissEditMenuView(onViewShift: {
                shifted in

                if(currentButton != self.hexButtonInViewCenter) {
                    self.branchTouchUpInside(currentButton)
                }

                menuFunction()
            })
        }
    }
    
    func branchMenuCancelTouchUpInside() {
        self.actionMode = .NORMAL
        
        self.dismissEditMenuView()
    }
    
    func branchMenuEditTouchUpInside() {
        // cache before calling dismiss
        let previousCenter = self.getPreviousHexagonCenter()
        
        self.dismissEditMenuView()
        
        if let currentButton = self.currentEditButton {
            let branch = self.getBranchAtGridLocation(currentButton.gridPosition!, fromCenter: previousCenter)
            
            self.addEditBranchHandler(false, branch: branch)
        }
    }
    
    func branchMenuMoveTouchUpInside() {
        // initialize the add form controller to load into view
        let vc              = UIStoryboard(name: "TreeMoveBranchForm", bundle: nil).instantiateViewControllerWithIdentifier("TreeMoveBranchForm") as! TreeMoveBranchFormViewController
        let moveFormView    = vc.view
        let hexButton       = self.currentEditButton!
        let previousCenter  = self.getPreviousHexagonCenter()
        let branch          = self.getBranchAtGridLocation(hexButton.gridPosition!, fromCenter: previousCenter)
        
        // store current add form view for action handlers
        self.moveFormViewController = vc
        
        //  add form into view
        moveFormView.frame = CGRectMake(0, 0, moveFormView.frame.width, vc.moveBranchView.frame.height)
        moveFormView.alpha = 0
        
        self.view.addSubview(moveFormView)
        self.addChildViewController(vc)
        
        // check if color has been assigned to branch
        if(branch!.color == nil) {
            branch!.color = hexButton.fillColorInitial
        }
        
        // update form based on branch settings
        vc.setBranchBar(branch!)
        
        // hook up move form events
        vc.moveBranchCancelButton.addTarget(self, action: #selector(TreeViewController.moveBranchCancelTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)
        
        // get number of branch levels for current moving branch
        let branchLevelCount = self.getBranchLevelCount(branch)

        self.actionMode             = .MOVING
        self.movingBranchLevelCount = branchLevelCount
        
        // update the prior center hex button in view
        self.setEditInactiveBranchHexagonButtonProperties(previousCenter)
        
        // update empty neighbors to reflect move instead of add
        let neighbors = self.getHexButtonNeighbors(previousCenter)
        
        for button in neighbors {
            if(button.id < 1) {
                self.setEmptyBranchHexagonButtonProperties(button)
            }
        }
        
        self.setMoveMode(hexButton)
        
        // dismiss the edit view and undo menu view hexagon settings
        self.dismissEditMenuView()
        
        UIView.animateWithDuration(self.animDuration * 0.5, animations: {
            moveFormView.alpha = 1
        })
    }
    
    func branchMenuDeleteTouchUpInside() {
        // show confirmation alert
        let alert = UIAlertController(
            title: Localization.sharedInstance.getLocalizedString("branch_delete_confirm_title", table: "TreeGrid"), message: Localization.sharedInstance.getLocalizedString("branch_delete_confirm", table: "TreeGrid"),
            preferredStyle: UIAlertControllerStyle.Alert
        )
        
        alert.addAction(UIAlertAction(
            title: Localization.sharedInstance.getLocalizedString("yes", table: "Common"),
            style: UIAlertActionStyle.Default,
            handler: self.branchMenuDeleteYes
            ))
        
        alert.addAction(UIAlertAction(
            title: Localization.sharedInstance.getLocalizedString("no", table: "Common"),
            style: UIAlertActionStyle.Cancel,
            handler: nil
            ))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func branchMenuDeleteYes(action: UIAlertAction) {
        if let currentBranch = self.currentEditBranch, currentButton = self.currentEditButton {
            self.deleteUserBranch(currentBranch, hexButton: currentButton)
        }
    }
    
    func branchPressHoldHandler(sender: HexagonButton, isBranchEditable: Bool = true) {
        if(self.editMenuViewController == nil) {
            // create action menu
            let vc          = TreeEditBranchMenuViewController.getStoryboardInstance()
            let menuView    = vc.view
            
            self.actionMode = .EDIT
            
            self.editMenuViewController = vc
            self.currentEditButton      = sender
            self.currentEditBranch      = self.getBranchAtGridLocation(sender.gridPosition!, fromCenter: self.hexButtonInViewCenter)
            
            vc.selectedHexagonColor = self.currentEditBranch?.color
            vc.isPublicMode         = self.treeType == .Public
            vc.isBranchEditable     = isBranchEditable
            
            vc.closeHandler     = self.branchMenuCancelTouchUpInside
            vc.editHandler      = self.branchMenuEditTouchUpInside
            vc.moveHandler      = self.branchMenuMoveTouchUpInside
            vc.deleteHandler    = self.branchMenuDeleteTouchUpInside
            
            if(vc.isPublicMode){
                if let curEditBranch = self.currentEditBranch {
                    vc.isPublicExplorable = (curEditBranch.url != nil)
                }
                else if (!isBranchEditable){
                    vc.isPublicExplorable = true
                }
                
                vc.exploreHandler   = self.showCurrentEditExploreWebBrowser
            }
            else {
                vc.chatHandler      = self.branchMenuChatTouchUpInside
                vc.feedHandler      = self.branchMenuFeedTouchUpInside
                vc.membersHandler   = self.branchMenuMembersTouchUpInside
                vc.postHandler      = self.branchMenuPostTouchUpInside

				if (self.currentEditBranch!.id != 0) {
					vc.shareHandler   = self.branchMenuShareTouchUpInside
				}
            }
            
            vc.loadBranchMenuOptions()
            
            let menuOriginOffset = self.view.frame.maxY - menuView.frame.height
            
            // animate add form into view
            menuView.frame = CGRectMake(0, menuOriginOffset, menuView.frame.width, menuView.frame.height)
            menuView.alpha = 0
            
            self.view.addSubview(menuView)
            self.addChildViewController(vc)
            
            self.setHexButtonInViewCenter(sender,
                offsetAnimation: {
                    (xOffset: CGFloat, yOffset: CGFloat) in

                    self.gridView.bounds.origin.y += self.getAddEditExtraViewOffset(sender)
                }
            )
            
            // add overlay
            self.showEditOverlay(sender, withAnimation: {
                menuView.alpha = 1
            })
        }
        else {
            self.editMenuViewController?.isBranchEditable = isBranchEditable
            self.editMenuViewController?.loadBranchMenuOptions()
        }
    }
    
    // call dimissess add edit view and updates current edit button accordingly
    private func addEditBranchDismiss() {
        // dismiss add form
        if let addFormVC = self.addBranchViewController, currentButton = self.currentEditButton {
            self.removeEditOverlay()
            
            // check if branch exists at location
            let branch      = self.getBranchAtGridLocation(currentButton.gridPosition!, fromCenter: self.getPreviousHexagonCenter())
            let addFormView = addFormVC.view
            
            // todo replace with smarter check for how large add form is
            let yExtraOffset = self.getAddEditExtraViewOffset(currentButton)
            
            if(branch != nil) {
                self.setBranchHexagonButtonProperties(currentButton, branch: branch!)
            }
            else {
                self.setEmptyBranchHexagonButtonProperties(currentButton)
            }
            
            self.unsetEditCurrentPropertiesHexagonButton(currentButton)
            self.unsetEditMode()
            
            // perform offset animation
            self.setPreviousHexButtonCenter(true,
                offsetAnimation: {
                    (xOffset: CGFloat, yOffset: CGFloat) in
                    
                    self.gridView.bounds.origin.y   -= yExtraOffset
                    
                    addFormView.alpha = 0
                    
                    addFormVC.branchNameTextField.resignFirstResponder()
                },
                completion: {
                    _ in
                    
                    self.addBranchViewController    = nil
                    self.currentEditButton          = nil

                    // dismiss menu from view hierarchy
                    addFormView.removeFromSuperview()
                    addFormVC.removeFromParentViewController()
                }
            )
            
            self.actionMode = .NORMAL
        }
    }
    
    // if cancelling branch link prior to selection of link
    private func addEditBranchLinkCancel() {
        // dismiss add branch link view
        if let addBranchLinkVC = self.addBranchLinkViewController {
            addBranchLinkVC.view.removeFromSuperview()
            addBranchLinkVC.removeFromParentViewController()
        }
        
        self.addBranchLinkViewController = nil
    }
    
    // if selecting link for branch (current link select view removed and add branch view shown)
    private func addEditBranchLinkSelected() {
        // dismiss add branch link view
        if let addBranchLinkVC = self.addBranchLinkViewController {
            addBranchLinkVC.view.removeFromSuperview()
            addBranchLinkVC.removeFromParentViewController()
        }
        
        self.addBranchLinkViewController = nil
    }
    
    private func dismissEditMenuView(onMenuDismiss: ((Bool) -> ())? = nil, onViewShift: ((Bool) -> ())? = nil) {
        // dismiss the edit menu form
        if let editMenuVC = self.editMenuViewController {
            let editMenuView = editMenuVC.view

            self.unsetEditMode()
            
            if self.actionMode != .EDIT {
                self.removeEditOverlay()
            }
            
            // start fade out of menu first
            UIView.animateWithDuration(self.animDuration * 0.5,
                animations: {
                    editMenuView.alpha = 0
                },
                completion: {
                    _ in
                    
                    if self.actionMode != .EDIT {
                    
                        // perform offset animation
                        self.setPreviousHexButtonCenter(true,
                            offsetAnimation: {
                                _ in
                                
                                self.gridView.bounds.origin.y -= self.getAddEditExtraViewOffset(self.currentEditButton!)
                            },
                            completion: {
                                _ in
                                
                                editMenuView.removeFromSuperview()
                                editMenuVC.removeFromParentViewController()

                                if let dismiss = onMenuDismiss {
                                    dismiss(true)
                                }
                                
                                self.editMenuViewController = nil
                                
                                if let viewShift = onViewShift {
                                    viewShift(true)
                                }
                            }
                        )
                    }
                    else {
                        if let dismiss = onMenuDismiss {
                            dismiss(true)
                        }
                        
                        editMenuView.removeFromSuperview()
                        editMenuVC.removeFromParentViewController()
                        
                        self.editMenuViewController = nil
                    }
                }
            )
        }
    }
    
    private func dismissMoveView(completion: ((Bool) -> ())? = nil) {
        if let moveFormVC = self.moveFormViewController {
            let moveFormView = moveFormVC.view
            
            self.actionMode             = .NORMAL
            self.movingBranchLevelCount = 0
            
            self.setHexagonButtonsForActiveBranches(self.currentTree.currentBranch!.children)
            
            self.setEditActiveBranchHexagonButtonProperties(self.hexButtonInViewCenter)
            
            self.unsetMoveMode()
            
            UIView.animateWithDuration(self.animDuration,
                animations: {
                    moveFormView.alpha = 0
                },
                completion: {
                    _ in
                    
                    moveFormView.removeFromSuperview()
                    moveFormVC.removeFromParentViewController()
                    
                    self.currentEditButton = nil
                }
            )
        }
    }
    
    private func setInitialBranch (data: JSON?) {
        self.currentTree.currentBranch = getInitialBranch(data)
    }
    
    private func getInitialBranch(data: JSON?) -> Branch {
        let branch      = Branch()
        let isPublic    = self.treeType == .Public
        
        branch.id       = 0
        branch.position = BranchPosition.Center
        branch.color    = self.currentGridTheme.initialBranchColor
        branch.title    = isPublic ? Localization.sharedInstance.getLocalizedString("trending", table: "TreeGrid") : Localization.sharedInstance.getLocalizedString("main_branch_name", table: "TreeGrid")
        branch.parent   = nil
        
        if isPublic {
            branch.url = AppSettings.public_tree_trending_site
        }
        
        if let children = data {
            branch.children = branch.loadBranches(children, parent: branch)
        }
        
        return branch
    }
    
    // update buttons for active branches (create buttons if they don't current exist)
    private func setHexagonButtonsForActiveBranches(activeBranches: [Branch]?) {
        // add hexagon buttons with initial properties
        self.setHexagonButtonsInitialActiveButtons()
        
        // update buttons based on branch properties
        self.setHexagonButtonInitialBranchProperties(activeBranches)
    }
    
    private func setHexagonButtonsInitialActiveButtons() {
        let activeHexagons = self.getHexButtonNeighbors(self.hexButtonInViewCenter)
        
        // default all active branches in view to initial active styles
        for hexagon in activeHexagons {
            self.setEmptyBranchHexagonButtonProperties(hexagon)
            self.setHexagonButton(hexagon)
        }
    }
    
    private func setHexagonButtonsForInactiveBranches() {
        let secondNeighbors = self.getHexButtonNeighbors(self.hexButtonInViewCenter, distance: 2, newNeighborsOnly: true, defaultStyleHandler: self.setInactiveBranchHexagonButtonProperties)
        
        self.setHexagonButtons(secondNeighbors)
    }

    private func setHexagonButtonInitialBranchProperties(activeBranches: [Branch]?) {
        // add branches specific updates (if current branch has child branches)
        if let activeBranches = activeBranches {
            for branch in activeBranches {
                if let button = self.hexagonButtons[self.getHexagonGridLocationForBranch(branch.position)] {
                    self.setBranchHexagonButtonProperties(button, branch: branch)
                }
            }
        }
    }
    
    // get extra view shift offset when adding/editing a hexagon
    private func getAddEditExtraViewOffset(button: HexagonButton) -> CGFloat {
        return Device.sharedInstance.isResolutionSmallerThaniPhone6() ? (self.treeType == .Public ? 200 : 170) : 160
    }
    
    private func getHexagonGridLocationForBranch(branchPosition : BranchPosition) -> HexagonGridPosition {
        var gridPosition: HexagonGridPosition
        
        let currentGridPosition = self.hexButtonInViewCenter.gridPosition ?? self.defaultGridCenterPosition
        let x = currentGridPosition.x
        let y = currentGridPosition.y
        
        let even            = (y % 2 == 0)
        let evenOffset      = (even ? 1 : 0)
        let oddOffset       = (even ? 0 : 1)
        
        switch branchPosition {
        case .BottomLeft:
            gridPosition = HexagonGridPosition(x: x - oddOffset, y: y + 1)
        case .BottomRight:
            gridPosition = HexagonGridPosition(x: x + evenOffset, y: y + 1)
        case .Left:
            gridPosition = HexagonGridPosition(x: x + -1, y: y)
        case .Right:
            gridPosition = HexagonGridPosition(x: x + 1, y: y)
        case .TopLeft:
            gridPosition = HexagonGridPosition(x: x - oddOffset, y: y + -1)
        case .TopRight:
            gridPosition = HexagonGridPosition(x: x + evenOffset, y: y + -1)
        default:
            gridPosition = HexagonGridPosition(x: x, y: y)
        }
        
        return gridPosition
    }
    
    // determine how many branch levels are nested in current branch
    func getBranchLevelCount(branch: Branch?) -> Int {
        // base condition
        if(branch == nil || branch?.id == 0) {
            return 0
        }
        
        // set one for current branch
        let branchLevel = 1
        
        // determine largest child sub branch level
        var subBranchLevel          = 0
        var largestSubBranchLevel   = 0
        
        // iterate through children
        if let children = branch?.children {
            for branch in children {
                subBranchLevel = getBranchLevelCount(branch)
                
                if subBranchLevel > largestSubBranchLevel {
                    largestSubBranchLevel = subBranchLevel
                }
            }
        }
        
        return branchLevel + largestSubBranchLevel
    }
    
    func getBranchPositionFromHexagonGridLocation(gridPosition: HexagonGridPosition, fromCenterGridPosition: HexagonGridPosition? = nil) -> BranchPosition? {
        let centerGridPosition  = fromCenterGridPosition ?? self.hexButtonInViewCenter.gridPosition ?? self.defaultGridCenterPosition
        let centerX             = centerGridPosition.x
        let centerY             = centerGridPosition.y
        let xDiff               = gridPosition.x - centerX
        let yDiff               = gridPosition.y - centerY
        let even                = (centerY % 2 == 0)
        let evenOffset          = (even ? 1 : 0)
        let oddOffset           = (even ? 0 : 1)
        
        var branchPosition: BranchPosition?
        
        // bottom left
        switch (xDiff, yDiff) {
        case (0, 0):
            branchPosition = BranchPosition.Center
        case (1, 0):
            branchPosition = BranchPosition.Right
        case (-1, 0):
            branchPosition = BranchPosition.Left
        case (-oddOffset, 1):
            branchPosition = BranchPosition.BottomLeft
        case (evenOffset, 1):
            branchPosition = BranchPosition.BottomRight
        case (-oddOffset, -1):
            branchPosition = BranchPosition.TopLeft
        case (evenOffset, -1):
            branchPosition = BranchPosition.TopRight
        default:
            branchPosition = nil
        }
        
        return branchPosition
    }
    
    func branchExistsInHexagonButton(button: HexagonButton) -> Bool {
        return button.id > 0
    }
    
    //Upon tapping on one of the branch buttons (Including "Add" and the center button)
    func branchTouchUpInside(hexButton:HexagonButton) {
        
        // touch feed button in center
        if(hexButton == self.hexButtonInViewCenter) {
            // selecting a branch to add a new friend to
            if (self.actionMode == .SELECTING && hexButton.type != .EMPTYBRANCH) {
                
                let selId = hexButton.id
                let selTitle = hexButton.titleLabel!.text!
                
                // close the view and fire our callback
                self.selectedClose?({
                    self.selectedCallback?(selId, selTitle)
                })
                
            }
            else{
                self.centerBranchNonSelectAction()
            }
        }
            // touch branch
        else {
            let branchExists = branchExistsAtLocation(self.getBranchPositionFromHexagonGridLocation(hexButton.gridPosition!)!)
            
            // if branch already exists, open/show branch
            if(branchExists) {
                self.currentBranchLevel += 1
                
                let oldHexagonNeighbors         = self.getHexButtonNeighbors(self.hexButtonInViewCenter)
                let oldHexagonSecondNeighbors   = self.getHexButtonNeighbors(self.hexButtonInViewCenter, distance: 2)
                let newHexagonNeighbors         = self.getHexButtonNeighbors(hexButton)
                let newSecondNeighbors          = self.getHexButtonNeighbors(hexButton, distance: 2, newNeighborsOnly: true, defaultStyleHandler: self.setInactiveBranchHexagonButtonProperties)
                let isMaxLevel                  = (self.currentBranchLevel > self.maxBranchLevels)
                
                var disableHexButtons           = oldHexagonNeighbors.union(oldHexagonSecondNeighbors)
                
                // if max level reached, disable current children as well
                if(isMaxLevel) {
                    disableHexButtons = disableHexButtons.union(newHexagonNeighbors)
                }
                else {
                    disableHexButtons = disableHexButtons.subtract(newHexagonNeighbors)
                }
                
                disableHexButtons.remove(hexButton)
                
                // disable buttons no longer in focus (out of view and not going to change for new center)
                for button in disableHexButtons {
                    self.setInactiveBranchHexagonButtonProperties(button)
                }
                
                // remove current chat button
                if let chatButton = self.currentChatButton {
                    self.setInactiveBranchHexagonButtonProperties(chatButton)
                    self.currentChatButton = nil
                }

                // remove current back button
                if let backButton = self.currentBackButton {
                    self.setInactiveBranchHexagonButtonProperties(backButton)
                    self.currentBackButton = nil
                }
                
                // remove current exit private button
                if let privateButton = self.currentExitPrivateButton {
                    self.setInactiveBranchHexagonButtonProperties(privateButton)
                    self.currentExitPrivateButton = nil
                }
                
                // update current hex button in center
                self.setHexButtonInViewCenter(hexButton)
                
                // Add colored backdrop
                self.setTreeBackDropOverlay()
                
                self.setHexagonButtons(newSecondNeighbors)
                
                self.drawHexagonButtonsInViewCenter(newSecondNeighbors, fromCenterButton: hexButton)
                
                self.animateExpandHexagonsIntoPositionFromCenter(newSecondNeighbors)
                
                // store color for branch if not previously assigned
                self.setBranchColorIfNeeded(self.currentTree.currentBranch!)
                
                // update children if max depth hasn't been exceeded
                if !isMaxLevel {
                    self.setHexagonButtonsForActiveBranches(self.currentTree.currentBranch!.children)
                }

				// add back button
				self.showBackHexagonButton()
                
                // show branch action hexagon buttons
                self.showBranchActionHexagonButtons()
                
                // show exit private button
                self.showExitPrivateHexagonButton()
                
                // show public exit button (if applicable)
                self.showExitPublicHexagonButton()
                
                // if moving, check center
                if(self.actionMode == .MOVING) {
                    self.setMoveModeForCurrentBranchLevel()
                    self.setEditInactiveBranchHexagonButtonProperties(self.hexButtonInViewCenter)
                }

                // apply specific customizations for center hexagon
                self.setCenterHexagonButtonProperties(hexButton)
                
                // if in selection mode, make sure to properly enable/disable buttons

                if (self.actionMode != .NORMAL) {
                    self.setEnabledDisabledButtons(hexButton)
                }
            }
                // check if branch is getting moved
            else if(self.actionMode == .MOVING && self.currentEditBranch != nil) {
                if let toBranchPosition = self.getBranchPositionFromHexagonGridLocation(hexButton.gridPosition!) {
                    
                    self.loadingMaskViewController.queueLoadingMask(self.view, showCompletion: {
                        // move request
                        TreemBranchService.sharedInstance.moveUserBranch(
                            TreeSession(treeID: self.currentTree.treeID, token: self.currentTree.token),
                            branch: self.currentEditBranch!,
                            toParentID          : self.currentTree.currentBranch!.id,
                            toBranchPosition    : toBranchPosition,
                            success: {
                                (data) -> Void in
                                self.actionMode             = .NORMAL
                                self.movingBranchLevelCount = 0
                                
                                let branch          = self.currentEditBranch!
                                let index           = branch.parent!.children!.indexOf(branch)
                                
                                // remove from data
                                self.currentEditBranch!.parent!.children?.removeAtIndex(index!)
                                
                                // update the button being moved if currently in view
                                let neighbors = self.getHexButtonNeighbors(self.hexButtonInViewCenter)
                                
                                for button in neighbors {
                                    if(button.id == self.currentEditBranch?.id) {
                                        self.setEmptyBranchHexagonButtonProperties(button)
                                        break
                                    }
                                }
                                
                                self.unsetMoveMode()
                                
                                // update to new position
                                self.currentEditBranch!.position    = toBranchPosition
                                self.currentEditBranch!.parent      = self.currentTree.currentBranch
                                
                                // check if color needs to be updated
                                self.setBranchColorIfNeeded(self.currentEditBranch!)
                                
                                // add updated branch information
                                if(self.currentTree.currentBranch!.children != nil) {
                                    self.currentTree.currentBranch!.children?.append(self.currentEditBranch!)
                                }
                                else {
                                    self.currentTree.currentBranch!.children = [self.currentEditBranch!]
                                }
                                
                                self.loadingMaskViewController.cancelLoadingMask({
                                    self.dismissMoveView()
                                })
                            },
                            failure: {
                                (error) -> Void in
                                
                                CustomAlertViews.showCustomAlertView(
                                    title: Localization.sharedInstance.getLocalizedString("error", table: "Common"),
                                    message: Localization.sharedInstance.getLocalizedString("branch_error_move", table: "TreeGrid")
                                )
                            }
                        )
                    })
                }
                else {
                    CustomAlertViews.showNoNetworkAlertView()
                }
            }
            //If we're selecting a spot to place a shared branch
            else if (self.actionMode == .PLACING) {

                let placedBranch = Branch()
                
                placedBranch.parent     = self.currentTree.currentBranch
                placedBranch.position   = self.getBranchPositionFromHexagonGridLocation(hexButton.gridPosition!)!

                self.placedClose?({
                    self.placedCallback?(placedBranch)
                })
            }
            // if branch does not exist at location, fire add branch handler
            else {
                // store currently editing button
                self.currentEditButton = hexButton
                self.currentEditBranch = self.getBranchAtGridLocation(hexButton.gridPosition!, fromCenter: self.hexButtonInViewCenter)
                
                self.addEditBranchHandler(true, branch: nil)
            }
        }
    }
    
    func branchPrivateTouchUpInside() {
        // load pin set form
        let vc = UIStoryboard(name: "SecretTreeLogin", bundle: nil).instantiateViewControllerWithIdentifier("SecretTreeLogin")
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func branchPrivateExitTouchUpInside() {
        // go back to main tree without reloading view controller
        self.treeType = .Main
        
        self.loadCurrentTree()

        // check chats
        self.checkForActiveChats()
        
        // check alerts
        self.mainDelegate?.getAlerts(false)
    }
    
    private func addEditBranchColorChange(color: UIColor?) {
        if let currentEditBtn = self.currentEditButton, fillColor = color {
            self.setBranchColorHexagonButtonProperties(currentEditBtn, branchColor: fillColor)
        }
    }
    
    func branchChatsTouchUpInside() {
        self.showChatView()
    }
    
    func branchExploreTouchUpInside(){
        self.showExploreView()
    }
    
    func branchPublicExitTouchUpInside(){
        self.dismissViewControllerAnimated(true, completion: { self.exploreWillDismiss?() })
    }
    
    func branchMembersTouchUpInside() {
        self.showMembersView()
    }
    
    func branchPostTouchUpInside() {
        self.showPostView()
    }
    
    func branchBackTouchUpInside() {
        self.currentBranchLevel -= 1 // do first
        
        let newCenter                  = self.getPreviousHexagonCenter()
        let newHexagonNeighbors        = self.getHexButtonNeighbors(newCenter)
        let newHexagonSecondNeighbors  = self.getHexButtonNeighbors(newCenter, distance: 2)
        let lastHexagonSecondNeighbors = self.getHexButtonNeighbors(self.hexButtonInViewCenter, distance: 2)
        let lastRemoveSecondNeighbors  = lastHexagonSecondNeighbors.subtract(newHexagonNeighbors).subtract(newHexagonSecondNeighbors)

        // contract last outer hexagons into current center
        self.animateContractHexagonsIntoCenterFromPosition(lastRemoveSecondNeighbors)

        // move to last hexagon center
        self.setPreviousHexButtonCenter(true)
        
        // move to previous branch
        self.currentTree.currentBranch = self.currentTree.currentBranch!.parent
        
        // Set colored backdrop
        self.setTreeBackDropOverlay()
        
        // reset current outer hexagons
        for hexagon in newHexagonSecondNeighbors {
            self.setInactiveBranchHexagonButtonProperties(hexagon)
        }
        
        // reset inner hexagons
        self.setHexagonButtonsForActiveBranches(self.currentTree.currentBranch!.children)
        
        self.setCenterHexagonButtonProperties(newCenter)
        
        // create new second neighbors and animate into view
        let newSecondNeighbors = self.getHexButtonNeighbors(newCenter, distance: 2, newNeighborsOnly: true, defaultStyleHandler: self.setInactiveBranchHexagonButtonProperties)
        
        self.setHexagonButtons(newSecondNeighbors)
        
        self.drawHexagonButtonsInViewCenter(newSecondNeighbors, fromCenterButton: self.hexButtonInViewCenter)
        
        self.animateExpandHexagonsIntoPositionFromCenter(newSecondNeighbors)

		// add back button if not at top
		if(self.currentTree.currentBranch!.parent != nil) {
			self.showBackHexagonButton()
		}
		else {
			self.currentBackButton = nil
		}

        // if moving, check center
        if(self.actionMode == .MOVING) {
            self.setMoveModeForCurrentBranchLevel()
            self.setEditInactiveBranchHexagonButtonProperties(self.hexButtonInViewCenter)
        }
        
        // show branch action hexagon buttons
        self.showBranchActionHexagonButtons()
        
        // show exit private button
        self.showExitPrivateHexagonButton()
        
        // show public exit button (if applicable)
        self.showExitPublicHexagonButton()
        
        // if in selection mode, make sure to properly enable/disable buttons
        if (self.actionMode != .NORMAL) {
            self.setEnabledDisabledButtons(newCenter)
        }
    }

    func branchPressHold(gesture: UILongPressGestureRecognizer) {

		//Only make use of this gesture if there isn't already a special action occurring (moving, sharing, placing)
        if(self.actionMode == .NORMAL){
            if let hexButton = gesture.view as? HexagonButton {
                if gesture.state == .Began && (hexButton.id > 0 || hexButton == self.hexButtonInViewCenter) {
                    // store currently editing button
                    self.currentEditButton = hexButton
                    self.currentEditBranch = self.getBranchAtGridLocation(hexButton.gridPosition!, fromCenter: self.getPreviousHexagonCenter())
                    
                    self.setEditMode(hexButton)
                    
                    self.branchPressHoldHandler(hexButton, isBranchEditable: hexButton.id > 0 && hexButton != self.hexButtonInViewCenter)
                }
            }
        }
    }
    
    func branchSwipeUp(gesture: UISwipeGestureRecognizer){
        // ignore gesture when using a special mode or while in public mode on a branch not tied to a url
        if self.actionMode == .NORMAL && gesture.state == .Ended {
            if let hexButton = gesture.view as? HexagonButton {
                
                // if in the center already, fire the center action
                if(hexButton == self.hexButtonInViewCenter){
                    self.centerBranchNonSelectAction()
                }
                // else move grid to button and fire center action
                else{
                    self.branchTouchUpInside(hexButton)
                    self.centerBranchNonSelectAction()
                    self.performBackonShow = true   // move back to current branch when we return
                }
            }
        }
    }
    
    func moveBranchCancelTouchUpInside() {
        self.dismissMoveView()
    }
    
    func branchExistsAtLocation(branchPosition: BranchPosition) -> Bool {
        var branchExists: Bool = false
        
        // get direct child branches for selected branch
        let childBranches: [Branch]? = self.currentTree.currentBranch!.children
        
        // check if branch already exists at location
        if(childBranches != nil) {
            for branch in childBranches! {
                if(branch.position == branchPosition) {
                    self.currentTree.currentBranch = branch
                    branchExists = true
                    break
                }
            }
        }
        
        return branchExists
    }
    
    func getBranchAtGridLocation(gridPosition: HexagonGridPosition, fromCenter: HexagonButton) -> Branch? {
        var branch: Branch? = nil
        
        // get branch position from grid position
        let branchPosition = self.getBranchPositionFromHexagonGridLocation(gridPosition, fromCenterGridPosition: fromCenter.gridPosition)
        
        if (branchPosition == .Center) {
            // return current branch if center position
            branch = self.currentTree.currentBranch!
        }
        // else get direct child branches for selected branch
        else if let childBranches = self.currentTree.currentBranch!.children {
            if childBranches.count > 0 {
                for i in 0...childBranches.count -  1 {
                    if(childBranches[i].position == branchPosition) {
                        branch = childBranches[i]
                        break
                    }
                }
            }
        }
        
        return branch
    }
    
    // check if branch has a color assigned and if not assigns appropriate color to branch
    private func setBranchColorIfNeeded(branch: Branch)
    {
        if let parent = branch.parent where parent.id > 0 {
            branch.color = self.getBranchColor(branch, parent: parent)
        }
    }
    
    private func getBranchColor(branch: Branch?, parent: Branch) -> UIColor? {
        var color: UIColor? = branch?.color ?? nil
        
        if parent.id > 0 {
            if (self.treeType == .Secret) {
                color = parent.color?.darkerColorForColor()
            }
            else {
                color = parent.color?.lighterColorForColor()
            }
        }
        
        return color
    }
    
    func removeBranchAtGridLocation(gridPosition: HexagonGridPosition, fromCenter: HexagonButton) -> Bool {
        var returnBranch: Bool = false
        
        // check if branch already exists at location
        if let children = self.currentTree.currentBranch!.children {
            
            // get branch position from grid position
            let branchPosition = self.getBranchPositionFromHexagonGridLocation(gridPosition, fromCenterGridPosition: fromCenter.gridPosition)
            
            if children.count > 0 {
                for i in 0...children.count -  1 {
                    if(children[i].position == branchPosition) {
                        self.currentTree.currentBranch!.children!.removeAtIndex(i)
                        
                        // if removing last branch nil the children value
                        if self.currentTree.currentBranch!.children!.count < 1 {
                            self.currentTree.currentBranch!.children = nil
                        }
                        
                        returnBranch = true
                        break
                    }
                }
            }
        }
        
        return returnBranch
    }
    
    private func setActiveHexagonButtonProperties(button: HexagonButton) {
        if let titleLabel = button.titleLabel {
            titleLabel.lineBreakMode                = NSLineBreakMode.ByClipping
            titleLabel.textAlignment                = NSTextAlignment.Center
            titleLabel.numberOfLines                = 3
            titleLabel.adjustsFontSizeToFitWidth    = true
        }
        
        button.removeTarget(nil, action: nil, forControlEvents: UIControlEvents.TouchUpInside)
        button.gestureRecognizers?.removeAll()
        
        button.addTarget(self, action: #selector(TreeViewController.branchTouchUpInside(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        button.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(TreeViewController.branchPressHold(_:))))
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(TreeViewController.branchSwipeUp(_:)))
        swipeUp.direction = UISwipeGestureRecognizerDirection.Up
        button.addGestureRecognizer(swipeUp)

        button.enabled = true
        button.alpha   = 1.0
        button.hidden  = false
    }
    
    private func setActionHexagonButtonProperties(button: HexagonButton, iconImageName: String? = nil, title: String? = nil) {
        let color = self.currentGridTheme.actionTitleColor
        
        button.enabled                  = true
        button.hidden                   = false
        
        button.iconImageDarkens         = self.treeType != .Secret
        button.iconImageName            = iconImageName
        
        button.iconImageColor           = color
        button.titleFont                = hexagonActionFont
        button.titleColor               = color
        button.tintColor                = color
        
        button.type = .ACTION
        
        button.setTitle(title, forState: .Normal)
        
        button.removeTarget(nil, action: nil, forControlEvents: UIControlEvents.TouchUpInside)
        button.gestureRecognizers?.removeAll()
        
        button.fillColorInitial = self.currentGridTheme.actionFillColor
        
        button.id = 0
    }
    
    private func setCenterHexagonButtonProperties(button: HexagonButton) {
        var centerImageStr: String? = nil
        
        let currentBranch   = self.currentTree.currentBranch
        let color           = currentBranch?.color ?? self.currentGridTheme.initialBranchColor
        
        // set default active hexagon properties
        self.setActiveHexagonButtonProperties(button)
        
        if let branch = currentBranch {
            self.setBranchHexagonButtonProperties(button, branch: branch)
        }

        // if in branch selection mode
        if let selectingCenterIcon = self.selectingCenterHexIcon {
            centerImageStr = selectingCenterIcon
        }
        // else if in public mode
        else if self.treeType == .Public {
            // default branch shows trending
            if currentBranch?.id == 0 {
                centerImageStr = "Trending"
            }
            // non-entity branches don't have an associated view to open
            else if self.isPublicBranchWithoutEntity(currentBranch) {
                button.enabled = false
            }
            // double check that a url was passed
            else if currentBranch?.url != nil {
                centerImageStr = self.exploreIconImageName
            }
        }
        else {
            centerImageStr = self.centerIconImageName
        }

        button.iconImageDarkens         = self.treeType != .Secret
        button.iconImageName            = centerImageStr
        button.useGradientBackground    = false
        
        if centerImageStr == nil && currentBranch?.title?.composedCount == 1 {
            button.titleFont = self.hexagonSingleCharacterFont
        }
        else {
            button.titleFont = self.hexagonActionFont
        }
        
        button.fillColorInitial         = self.currentGridTheme.centerBranchFillColor
        button.iconImageColor           = color
        button.strokeColor              = self.currentGridTheme.buttonStrokeColor
        button.titleColor               = color
        button.tintColor                = color
        
        // move branch title to one line to avoid icon conflict
        button.titleLabel?.numberOfLines                = 2
        button.titleLabel?.lineBreakMode                = .ByTruncatingTail
        button.titleLabel?.adjustsFontSizeToFitWidth    = false
    }
    
    // set button styles for an active empty branch
    func setEmptyBranchHexagonButtonProperties(button: HexagonButton) {
        self.setActiveHexagonButtonProperties(button)
        
        button.fillColorInitial         = self.currentGridTheme.addFillColor
        button.titleFont                = self.hexagonActionFont
        button.titleColor               = self.currentGridTheme.addTitleColor
        button.tintColor                = self.currentGridTheme.addTitleColor
        button.strokeColor              = self.currentGridTheme.buttonStrokeColor
        button.useGradientBackground    = false
        
        button.removeIconImages()
        
        button.type = .EMPTYBRANCH
        
        var emptyTitle: String
        
        if(self.actionMode == .MOVING) {
            // check if branch can be moved here
            if(self.movingBranchLevelCount - 1 > (self.maxBranchLevels - self.currentBranchLevel)) {
                emptyTitle      = Localization.sharedInstance.getLocalizedString("branch_error_too_many_levels", table: "TreeGrid")
                button.enabled  = false
            }
            else {
                emptyTitle = Localization.sharedInstance.getLocalizedString("branch_move", table: "TreeGrid")
            }
        }
        else if (self.actionMode == .PLACING) {
            emptyTitle = Localization.sharedInstance.getLocalizedString("branch_place", table: "TreeGrid")
        }
        else {
            emptyTitle = Localization.sharedInstance.getLocalizedString("branch_add", table: "TreeGrid")
            button.iconImageName = self.addIconImageName
            button.iconImageColor = self.currentGridTheme.addTitleColor
        }
        
        button.setTitle(emptyTitle, forState: .Normal)
        
        button.id       = 0
        button.hidden   = false
    }
    
    private func setTreeBackDropOverlay() {
        if let currentBranch = self.currentTree.currentBranch {
            // set overlay for sub branches only
            if currentBranch.id > 0 {
                super.setBackDropOverlay(currentBranch.color)
            }
            else {
                super.setBackDropOverlay(nil)
            }
        }
        else {
            super.setBackDropOverlay(nil)
        }
    }
    
    private func setBranchHexagonButtonProperties(button: HexagonButton, branch: Branch) {
        var fillColor: UIColor?
        
        // set ID first in case of dependencies in other functions
        button.id = branch.id
        
        self.setActiveHexagonButtonProperties(button)
        
        button.useGradientBackground = true
        
        // color assigned to top branches only
        if(branch.parent == nil || branch.parent!.id == 0) {
            if(branch.color != nil) {
                fillColor = branch.color!
            }
        }
            // otherwise it is based of off parent color level
        else {
            self.setBranchColorIfNeeded(branch)
            
            fillColor = branch.color
        }
        
        self.setBranchColorHexagonButtonProperties(button, branchColor: fillColor)
        
        if(button.gridPosition == nil) {
            button.gridPosition = self.getHexagonGridLocationForBranch(branch.position)
        }
        
        button.setTitle(branch.title, forState: .Normal)
        
        if let bTitle = branch.title {
            if(bTitle.composedCount == 1) {
                button.titleFont = self.hexagonSingleCharacterFont
            }
            else {
                button.titleFont = self.hexagonTitleFont
            }
        }
        
        button.removeIconImages()
        
        if self.treeType == .Public && branch.id > 0 {
            button.updateFavIconImage(branch)
        }
        
        button.type = .BRANCH
        
        // prevent moving onto same hexagon
        if(self.actionMode == .MOVING && button.id == self.currentEditBranch?.id) {
            self.setEditInactiveBranchHexagonButtonProperties(button)
        }
    }
    
    private func setBranchColorHexagonButtonProperties(button: HexagonButton, branchColor: UIColor?) {
        // in secret tree, only border is colored
        if self.treeType == .Secret {
            if let fill = branchColor {
                button.strokeColor = fill
                
                button.useGradientBackground = false
                
                // if top feed button
                if self.currentTree.currentBranch!.parent == nil && button.id == 0 && self.currentEditButton == nil {
                    button.fillColorInitial = self.currentGridTheme.initialBranchColor
                    button.titleColor       = self.currentGridTheme.addTitleColor
                    button.tintColor        = self.currentGridTheme.addTitleColor
                }
                    // if center
                else {
                    button.fillColorInitial = self.currentGridTheme.addFillColor
                    button.titleColor       = fill.lighterColorForColor()
                    button.tintColor        = self.currentGridTheme.addTitleColor
                }
            }
        }
            // in initial tree, fill is colored with branch color
        else {
            button.useGradientBackground = true
            
            if let fill = branchColor?.colorWithAlphaComponent(1.0) {
                button.fillColorInitial = fill
            }
            
            button.titleColor   = UIColor.whiteColor()
            button.tintColor    = UIColor.whiteColor()
        }
    }
    
    private func setInactiveBranchHexagonButtonProperties(button: HexagonButton) {
        button.fillColorInitial         = self.currentGridTheme.defaultBranchFillColor
        button.strokeColor              = self.currentGridTheme.buttonStrokeColor
        button.enabled                  = false
        button.titleFont                = self.hexagonTitleFont
        button.id                       = 0
        button.hidden                   = false
        button.useGradientBackground    = false
        
        button.titleLabel?.lineBreakMode                = NSLineBreakMode.ByClipping
        button.titleLabel?.textAlignment                = NSTextAlignment.Center
        button.titleLabel?.numberOfLines                = 3
        button.titleLabel?.adjustsFontSizeToFitWidth    = true
        button.setTitle(nil, forState: .Normal)
        button.titleLabel?.text = nil
        button.removeTarget(nil, action: nil, forControlEvents: UIControlEvents.TouchUpInside)
        button.gestureRecognizers?.removeAll()
        
        button.removeIconImages()
        
        // check to add private branch event
        if(self.treeType == .Main && self.isCurrentTopBranchLevel && button.gridPosition! == (0,2)) {
            button.addTarget(self, action: #selector(TreeViewController.branchPrivateTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)
            button.enabled = true
        }
    }
    
    private func setEditInactiveBranchHexagonButtonProperties(button: UIButton) {
        button.alpha    = self.currentGridTheme.editBranchAlpha
        button.enabled  = false
    }
    
    private func setEditMode(editButton: HexagonButton) {
        // disable all hexagons outside of the one currently being edited
        for (_,button) in self.hexagonButtons {
            if(button != editButton) {
                self.setEditInactiveBranchHexagonButtonProperties(button)
            }
        }
    }
    
    /* Moving branches */
    private func setMoveMode(moveButton: HexagonButton) {
        // cannot move to current position
        self.setEditInactiveBranchHexagonButtonProperties(moveButton)
        
        // set move mode settings for the current branch level
        self.setMoveModeForCurrentBranchLevel()
    }
    
    private func setMoveModeForCurrentBranchLevel() {
        // check if still in edit mode (current center hexagon is the edit button)
        let centerHexagon = (self.currentEditButton == self.hexButtonInViewCenter) ? self.getPreviousHexagonCenter() : self.hexButtonInViewCenter

        var secondNeighbors = self.getHexButtonNeighbors(centerHexagon, distance: 2)

		if let backButton = self.currentBackButton {
            secondNeighbors.remove(backButton)
            self.setEditActiveBranchHexagonButtonProperties(backButton)
        }

		// disable inner hexagons if on last level
        if self.currentBranchLevel >= self.maxBranchLevels {
            let neighbors = self.getHexButtonNeighbors(self.hexButtonInViewCenter)
            
            for button in neighbors where button.id > 0 {
                self.setEditInactiveBranchHexagonButtonProperties(button)
            }
        }
        
        // disable all outer hexagons
        for button in secondNeighbors {
            self.setEditInactiveBranchHexagonButtonProperties(button)
        }

		self.mainDelegate?.mainTabBar.userInteractionEnabled = false
    }

    private func unsetMoveMode() {
        // re-enable all hexagon buttons
        for (_,button) in self.hexagonButtons {
            self.setEditActiveBranchHexagonButtonProperties(button)
        }

		self.mainDelegate?.mainTabBar.userInteractionEnabled = true
    }
    /* End moving branches */

    /* Shared branch placement functions */
    private func setPlacementMode () {
        let vc              = UIStoryboard(name: "TreeSelectBranchForm", bundle: nil).instantiateViewControllerWithIdentifier("TreeSelectBranchForm") as! TreeSelectBranchFormViewController
        let selectFormView  = vc.view

        self.selectFormViewController = vc
        self.selectFormViewController?.setActionTitle("Place Branch")

        selectFormView.frame = CGRectMake(0,0,selectFormView.frame.width, vc.getViewHeight())

        self.view.addSubview(selectFormView)
        self.addChildViewController(vc)

        vc.selectBranchCancelButton.addTarget(self, action: #selector(TreeViewController.placeShareCancelTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)

		self.setHexagonButtonsForActiveBranches(self.currentTree.currentBranch!.children)
        self.setEnabledDisabledButtons(self.hexButtonInViewCenter)

        self.hexButtonInViewCenter.iconImageName = (self.selectingCenterHexIcon != nil ? self.selectingCenterHexIcon : self.centerIconImageName)

        self.mainDelegate?.mainTabBar.userInteractionEnabled = false
    }

    private func unsetPlacementMode() {
        self.actionMode = .NORMAL
        self.selectingCenterHexIcon = nil
        self.placedClose = nil

        self.hexButtonInViewCenter.iconImageName = self.centerIconImageName

		self.setHexagonButtonsForActiveBranches(self.currentTree.currentBranch!.children)
		
        for (_,button) in self.hexagonButtons {
            self.setEditActiveBranchHexagonButtonProperties(button)
        }

        if let selectFormVC = self.selectFormViewController {
            let selectFormView = selectFormVC.view

            UIView.animateWithDuration(self.animDuration,
                animations: {
                    selectFormView.frame.origin.y -= selectFormVC.selectBranchView.frame.height
                },
                completion: {
                    _ in

                    selectFormView.removeFromSuperview()
                    selectFormVC.removeFromParentViewController()

                }
            )
        }

        self.mainDelegate?.mainTabBar.userInteractionEnabled = true
    }
    /* End placing shared branches */

	//Enable or disable hexes while in a special mode
    func setEnabledDisabledButtons (hexButton: HexagonButton) {
        self.updateBranchBar(hexButton)

        for (_,button) in self.hexagonButtons {

			//Selecting a branch to place things on -- Only enable the Back button, and an existing branch
			if (self.actionMode == .SELECTING) {
				if (button.type == .BRANCH ||  button == self.currentBackButton) {
					self.setEditActiveBranchHexagonButtonProperties(button)
				}
				else {
					self.setEditInactiveBranchHexagonButtonProperties(button)
				}
			}

			//Placing a shared branch -- Only enable the back button, empty spots, and existing branches (to navigate downward).
			else if (self.actionMode == .PLACING) {
				if ((button.type == .BRANCH || button.type == .EMPTYBRANCH || button == self.currentBackButton) && button != self.hexButtonInViewCenter) {

					self.setEditActiveBranchHexagonButtonProperties(button)
				}
				else {
					self.setEditInactiveBranchHexagonButtonProperties(button)
				}
			}

			//Moving an existing branch -- Only enable the back button, empty spots, and existing branches (to navigate downward). Also make sure to disable the branch being moved, to prevent it from being its own parent
			else if (self.actionMode == .MOVING) {
				if ((button.type == .BRANCH || button.type == .EMPTYBRANCH || button == self.currentBackButton) && button != self.hexButtonInViewCenter && button.id != self.currentEditBranch!.id) {
					self.setEditActiveBranchHexagonButtonProperties(button)
				}
				else {
					self.setEditInactiveBranchHexagonButtonProperties(button)
				}
			}
        }
    }

    private func setEditCurrentPropertiesHexagonButton (button: HexagonButton) {
        button.enabled = false
    }
    
    func unsetEditCurrentPropertiesHexagonButton (button: HexagonButton) {
        button.enabled = true
    }
    
    private func setEditActiveBranchHexagonButtonProperties(button: UIButton) {
        button.alpha    = 1.0
        button.enabled  = true
    }
    
    func unsetEditMode() {
        // re-enable all hexagon buttons
        for (_,button) in self.hexagonButtons {
            if self.actionMode != .MOVING || button.id > 0 && button.id != self.currentEditBranch?.id {
                self.setEditActiveBranchHexagonButtonProperties(button)
            }
        }
    }
    
    private func showBackHexagonButton() {
        let centerPosition  = self.hexButtonInViewCenter.gridPosition
        let button          = self.hexagonButtons[HexagonGridPosition(x: centerPosition!.x, y: centerPosition!.y + 2)]!
        
        self.setInactiveBranchHexagonButtonProperties(button)
        self.setActionHexagonButtonProperties(button, iconImageName: self.reverseIconImageName, title: Localization.sharedInstance.getLocalizedString("back", table: "Common"))
        
        button.addTarget(self, action: #selector(TreeViewController.branchBackTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)
        
        button.iconImageColor   = self.currentGridTheme.backFillColor
        button.titleColor       = self.currentGridTheme.backFillColor
        button.tintColor        = self.currentGridTheme.backFillColor
        
		// update current back button
        self.currentBackButton = button
    }
    
    private func showBranchActionHexagonButtons() {
        // we don't show these in public mode
        if(self.treeType != .Public){
            self.showChatHexagonButton()
            self.showExploreHexagonButton()
            self.showMembersHexagonButton()
            self.showPostHexagonButton()
        }
    }
    
    private func showChatHexagonButton() {
        let centerPosition  = self.hexButtonInViewCenter.gridPosition
        let button          = self.hexagonButtons[HexagonGridPosition(x: centerPosition!.x + 1, y: centerPosition!.y - 2)]!
        
        self.setInactiveBranchHexagonButtonProperties(button)
        self.setActionHexagonButtonProperties(button, iconImageName: self.chatIconImageName, title: Localization.sharedInstance.getLocalizedString("chat", table: "TreeGrid"))
        
        button.addTarget(self, action: #selector(TreeViewController.branchChatsTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.currentChatButton = button
        self.setCurrentChatButtonIndicator()
    }
    
    private func showExploreHexagonButton() {
        let centerPosition  = self.hexButtonInViewCenter.gridPosition
        let button          = self.hexagonButtons[HexagonGridPosition(x: centerPosition!.x - 1, y: centerPosition!.y - 2)]!
        
        self.setInactiveBranchHexagonButtonProperties(button)
        self.setActionHexagonButtonProperties(button, iconImageName: self.exploreIconImageName, title: Localization.sharedInstance.getLocalizedString("Explore", table: "TreeGrid"))
        
        button.addTarget(self, action: #selector(TreeViewController.branchExploreTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    private func showMembersHexagonButton() {
        let centerPosition  = self.hexButtonInViewCenter.gridPosition
        let button          = self.hexagonButtons[HexagonGridPosition(x: centerPosition!.x - 1, y: centerPosition!.y + 2)]!
        
        self.setInactiveBranchHexagonButtonProperties(button)
        self.setActionHexagonButtonProperties(button, iconImageName: self.membersIconImageName, title: Localization.sharedInstance.getLocalizedString("members", table: "TreeGrid"))
        
        button.addTarget(self, action: #selector(TreeViewController.branchMembersTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    private func showPostHexagonButton() {
        let centerPosition  = self.hexButtonInViewCenter.gridPosition
        let button          = self.hexagonButtons[HexagonGridPosition(x: centerPosition!.x + 1, y: centerPosition!.y + 2)]!
        
        self.setInactiveBranchHexagonButtonProperties(button)
        self.setActionHexagonButtonProperties(button, iconImageName: self.postIconImageName, title: Localization.sharedInstance.getLocalizedString("post", table: "TreeGrid"))
        
        button.addTarget(self, action: #selector(TreeViewController.branchPostTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    private func showExitPrivateHexagonButton() {
        if(self.treeType == .Secret) {
            let centerPosition  = self.hexButtonInViewCenter.gridPosition
            let button          = self.hexagonButtons[HexagonGridPosition(x: centerPosition!.x, y: centerPosition!.y - 2)]!
            
            self.setInactiveBranchHexagonButtonProperties(button)
            self.setActionHexagonButtonProperties(button, iconImageName: self.exitIconImageName, title: Localization.sharedInstance.getLocalizedString("exit", table: "TreeGrid"))
            
            button.addTarget(self, action: #selector(TreeViewController.branchPrivateExitTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)
            
            self.currentExitPrivateButton = button
        }
    }
    
    private func showExitPublicHexagonButton(){
        if(self.treeType == .Public){
            let centerPosition  = self.hexButtonInViewCenter.gridPosition
            let button          = self.hexagonButtons[HexagonGridPosition(x: centerPosition!.x, y: centerPosition!.y - 2)]!
            
            self.setInactiveBranchHexagonButtonProperties(button)
            self.setActionHexagonButtonProperties(button, iconImageName: self.exitIconImageName, title: Localization.sharedInstance.getLocalizedString("exit", table: "TreeGrid"))
            
            button.addTarget(self, action: #selector(TreeViewController.branchPublicExitTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)
            
            self.currentExitPrivateButton = button
        }
    }
    
    private func setCurrentChatButtonIndicator(){
        if let chatButton = self.currentChatButton {
            var bIndicator  = false
            var bActive     = false
            
            if let chats = self.activeBranchChats {
                var curId = CurrentTreeSettings.sharedInstance.currentBranchID
                
                if(curId < 1) { curId = 0 }
                
                if(chats[curId] != nil){
                    bIndicator = true
                    
                    bActive = chats[curId]!
                }
            }
            
            chatButton.setIndicatorIcon(bIndicator, active: bActive)
        }
    }
    
    func removEditBranchButtion() {
        // convert current button to default and remove branch from tree
        if let currentButton = self.currentEditButton {
            self.setEmptyBranchHexagonButtonProperties(currentButton)
            
            // remove branch
            self.removeBranchAtGridLocation(currentButton.gridPosition!, fromCenter: self.getPreviousHexagonCenter())
        }
    }
    
    /* 
    If the screen is being use to select a branch to add users, this is the main function that sets up functionality.
    TreeSelectBranchForm is the view that gets added to the top of the screen, with a cancel button as well as the currently-selected Branch's name.
    The only on-screen hex buttons that are enbled during this phase are branches (excluding empty ones) and the Back button.
    */
    func setSelectionMode() {
        
        // initialize the add form controller to load into view
        let vc              = UIStoryboard(name: "TreeSelectBranchForm", bundle: nil).instantiateViewControllerWithIdentifier("TreeSelectBranchForm") as! TreeSelectBranchFormViewController
        let selectFormView      = vc.view
        
        // store current add form view for action handlers
        self.selectFormViewController = vc
        
        // size the view to only the size needed
        selectFormView.frame = CGRectMake(0,AppDelegate.getStatusBarDefaultHeight() ,selectFormView.frame.width, vc.getViewHeight())
        
        // add view to the current view
        self.view.addSubview(selectFormView)
//        self.addChildViewController(vc) causes problems when called concurrently with branch view pop
        
        vc.selectBranchCancelButton.addTarget(self, action: #selector(TreeViewController.selectBranchCancelTouchUpInside), forControlEvents: UIControlEvents.TouchUpInside)
        
        self.setEnabledDisabledButtons(self.hexButtonInViewCenter)
        
        // set current center button
        self.hexButtonInViewCenter.iconImageName = (self.selectingCenterHexIcon != nil ? self.selectingCenterHexIcon : self.centerIconImageName)
        
        self.mainDelegate?.mainTabBar.userInteractionEnabled = false
    }
    
    // Upon moving to a different branch while selecting, update the bar at the top.
    func updateBranchBar(hexButton: HexagonButton) {
        
        let branch = Branch()
        branch.title = hexButton.id == 0 ? Localization.sharedInstance.getLocalizedString("trunk_name", table: "TreeGrid") : (hexButton.titleLabel?.text)!    // No branch button text is "All", which is ambiguous, so override it
        branch.color = self.currentTree.currentBranch?.color
        
        self.selectFormViewController?.setBranchBar(branch)
    }
    
    // cancel event
    func selectBranchCancelTouchUpInside() {
        self.selectedClose?(nil)
    }

    func placeShareCancelTouchUpInside() {
        self.placedClose?(nil)
    }
    
    // reset the grid back to non select branch mode... this needs to be the last thing that get's fired (best to place in "selectedPostCallback")
    func unsetSelectionMode() {
        self.actionMode = .NORMAL
        self.selectingCenterHexIcon = nil
        self.selectedClose = nil
        
        self.hexButtonInViewCenter.iconImageName    = self.centerIconImageName
        
        for (_,button) in self.hexagonButtons {
            self.setEditActiveBranchHexagonButtonProperties(button)
        }
        
        if let selectFormVC = self.selectFormViewController {
            let selectFormView = selectFormVC.view
            
            UIView.animateWithDuration(self.animDuration,
                animations: {
                    selectFormView.frame.origin.y -= selectFormVC.selectBranchView.frame.height
                },
                completion: {
                    _ in
                    
                    selectFormView.removeFromSuperview()
//                    selectFormVC.removeFromParentViewController()
                }
            )
        }
        
        self.mainDelegate?.mainTabBar.userInteractionEnabled = true
    }
    
    private func deleteUserBranch(deleteBranch: Branch, hexButton: HexagonButton) {
        // convert current button to default and remove branch from tree
        self.loadingMaskViewController.queueLoadingMask(
            self.view,
            showCompletion: {
                TreemBranchService.sharedInstance.deleteUserBranch(
                    TreeSession(treeID: self.currentTree.treeID, token: self.currentTree.token),
                    deleteBranchID: deleteBranch.id,
                    success: {
                        data in

                        self.actionMode = .NORMAL
                        
                        self.setEmptyBranchHexagonButtonProperties(hexButton)
                        self.removeBranchAtGridLocation(hexButton.gridPosition!, fromCenter: self.getPreviousHexagonCenter())

                        self.dismissEditMenuView({
                            (Bool) in

                            self.loadingMaskViewController.cancelLoadingMask(nil)
                        })
                    },
                    failure: {
                        error in

                        self.loadingMaskViewController.cancelLoadingMask({
                            CustomAlertViews.showCustomAlertView(
                                title: Localization.sharedInstance.getLocalizedString("error", table: "Common"),
                                message: Localization.sharedInstance.getLocalizedString("branch_error_delete", table: "TreeGrid")
                            )
                        })
                    }
                )
            }
        )
    }
    
    // MARK: Entity Search Delegate Functions
    
    func selectedEntity(entity: PublicEntity) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        // load edit mode for current branch
        self.addEditBranchHandler(true, branch: nil, entity: entity)
    }
}