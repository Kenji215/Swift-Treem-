//
//  MemberProfileViewController.swift
//  Treem
//
//  Created by Matthew Walker on 11/17/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

class MemberProfileViewController: UIViewController, UITableViewDataSource, UITabBarDelegate {
    
    // set by the whomever is opening this view
    var userId                  : Int? = nil
    var friendChangeCallback    : (() -> ())? = nil
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var divider2: UIView!
    @IBOutlet weak var divider3: UIView!
    @IBOutlet weak var divider4: UIView!
    @IBOutlet weak var divider5: UIView!
    
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var profilePicWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var profilePicHeightConstraint: NSLayoutConstraint!   
    
    @IBOutlet weak var firstLastNameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userNameImageView: UIImageView!
    
    @IBOutlet weak var friendStatusLabel: UILabel!
    @IBOutlet weak var friendActionButton: UIButton!
    @IBOutlet weak var friendIcon: UIImageView!
    
    @IBOutlet weak var branchViewContainer: UIView!
    @IBOutlet weak var branchPathTableView: UITableView!
    @IBOutlet weak var branchViewContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var branchesViewLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var branchViewLabelTopHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var branchViewLableBottomHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var branchPathTableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var branchViewDividerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sharedInfoContainer: UIView!
    
    @IBOutlet weak var residesCityLabel: UILabel!
    @IBOutlet weak var residesStateLabel: UILabel!
    @IBOutlet weak var residesCountryLabel: UILabel!
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var optionsTabBar: UITabBar!
    
    @IBOutlet weak var actionView: UIView!
    @IBOutlet weak var actionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionViewBottomConstraint: NSLayoutConstraint!
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.dismissView()
    }
    
    @IBAction func friendActionButtonTouchUpInside(sender: AnyObject) {
        // UF, PC, PA

        switch(self.actionMode){
            
            // unfriend or cancel pending friendship
            case self.ACTION_UNFRIEND , self.ACTION_PENDING_CANCEL:
                
                CustomAlertViews.showCustomConfirmView(
                    title: Localization.sharedInstance.getLocalizedString("remove_confirm_title", table: "MemberProfile")
                    , message: (self.actionMode == self.ACTION_UNFRIEND) ? Localization.sharedInstance.getLocalizedString("remove_confirm_message_friends", table: "MemberProfile") : Localization.sharedInstance.getLocalizedString("remove_confirm_message_pending", table: "MemberProfile")
                    , fromViewController: self
                    , yesHandler:{
                        _ in
                        
                        let usr = UserRemove.init()
                        usr.id = self.userId!
                        
                        self.showLoadingMask()
                        
                        TreemSeedingService.sharedInstance.trimUsers(
                            CurrentTreeSettings.sharedInstance.treeSession,
                            branchID: 0,
                            users: [usr],
                            success:
                            {
                                (data:JSON) in
                                
                                // on success, reload the profile
                                self.loadUserProfile()
                                
                                // mark that the friendship changed
                                self.friendshipChanged = true
                            },
                            failure: {
                                (error) -> Void in
                                
                                // cancel loading mask and return to view with alert
                                self.cancelLoadingMask({
                                    CustomAlertViews.showGeneralErrorAlertView()
                                })
                            }
                        )

                    }
                    , noHandler: nil
                )
            //add friend
            case self.ACTION_FRIEND:
                
                CustomAlertViews.showCustomConfirmView (
                    title: Localization.sharedInstance.getLocalizedString("remove_confirm_title", table: "MemberProfile")
                    , message: Localization.sharedInstance.getLocalizedString("add_friend_confirm_message", table: "MemberProfile")
                    , fromViewController: self
                    , yesHandler:{
                        _ in
                        
                        let usr = UserAdd.init()
                        usr.id = self.userId!
                        
                        self.showLoadingMask()
                        
                        TreemSeedingService.sharedInstance.setUsers(
                            CurrentTreeSettings.sharedInstance.treeSession,
                            branchID: 0,
                            users: [usr],
                            success:
                            {
                                (data:JSON) in
                                
                                // on success, reload the profile
                                self.loadUserProfile()

                                self.toggleExtendedProfileOptions(true)
                                
                            },
                            failure: {
                                (error) -> Void in
                                
                                // cancel loading mask and return to view with alert
                                self.cancelLoadingMask({
                                    CustomAlertViews.showGeneralErrorAlertView()
                                })
                            }
                        )
                        
                    }
                    , noHandler: nil
            )

            default: break             // do nothing...
        }
    }
    
    
    
    // --------------------------------- //
    // Private Variables
    // --------------------------------- //
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController         = ErrorViewController.getStoryboardInstance()
    
    private var branchPaths: [BranchPath] = []
    private var actionMode: String = ""

    private var ACTION_UNFRIEND             : String = "UF"
    private var ACTION_PENDING_CANCEL       : String = "PC"
    private var ACTION_PENDING_ACCEPT       : String = "PA"
    private var ACTION_FRIEND               : String = "FR"
    
    private var EMPTY_PROFILE_WIDTH         : CGFloat = 100
    private var EMPTY_PROFILE_HEIGHT        : CGFloat = 100
    
    private var friendshipChanged           : Bool = false
    
    private var actionViewHeight            : CGFloat = 0
    
    static func getStoryboardInstance() -> MemberProfileViewController {
        return UIStoryboard(name: "MemberProfile", bundle: nil).instantiateInitialViewController() as! MemberProfileViewController
    }
    
    // --------------------------------- //
    // Load Overrides
    // --------------------------------- //
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
     
        self.showLoadingMask()
        
        // update username icon color
        self.userNameImageView.image = self.userNameImageView.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.userNameImageView.tintColor = UIColor.darkGrayColor()
        
        // update tab bar background (to none)
        self.optionsTabBar.shadowImage = UIImage()
        self.optionsTabBar.backgroundImage = UIImage()
        
        // set divider colors
        self.divider2.backgroundColor = AppStyles.sharedInstance.dividerColor
        self.divider3.backgroundColor = AppStyles.sharedInstance.dividerColor
        self.divider4.backgroundColor = AppStyles.sharedInstance.dividerColor
        self.divider5.backgroundColor = AppStyles.sharedInstance.dividerColor
        
        // set icon color
        self.friendIcon.tintColor = AppStyles.sharedInstance.midGrayColor
        self.closeButton.tintColor = AppStyles.sharedInstance.whiteColor
        
        // branch path view
        self.branchPathTableView.dataSource = self
        self.branchPathTableView.separatorColor = AppStyles.sharedInstance.dividerColor
        
        // apply styles to sub header bar
        AppStyles.sharedInstance.setSubHeaderBarStyles(headerView)
        
        // swipe down on header to dismiss it
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(MemberProfileViewController.headerViewSwipeDown(_:)))
        swipeDown.direction = UISwipeGestureRecognizerDirection.Down
        self.headerView.addGestureRecognizer(swipeDown)
        
        
        // change the color ot he tab items to match our button colors
        for item in self.optionsTabBar!.items! as [UITabBarItem] {
            if let image = item.image {
                item.image = image.fillTemplateImageWithColor(AppStyles.sharedInstance.tintColor).imageWithRenderingMode(.AlwaysOriginal)
            }
            item.setTitleTextAttributes([NSForegroundColorAttributeName : AppStyles.sharedInstance.tintColor], forState: .Normal)
            item.title = Localization.sharedInstance.getLocalizedString("options_tab_bar_" + String(item.tag), table: "MemberProfile")
        }
        
        self.optionsTabBar.delegate = self
        self.actionViewHeight = self.actionViewHeightConstraint.constant
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if(self.userId != nil){
            self.loadUserProfile()
        }
        else {
            // in theory this should never happen
            self.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    func headerViewSwipeDown(gesture: UISwipeGestureRecognizer){ self.dismissView() }
    
    
    // --------------------------------- //
    // Server Calls
    // --------------------------------- //
    
    private func loadUserProfile(){
        
        TreemProfileService.sharedInstance.getProfile(
            self.userId!,
            treeSession: CurrentTreeSettings.sharedInstance.treeSession,
            success:
            {
                (data:JSON) in
                
                let pData : Profile = Profile(json: data)

                // load profile pic
                if let profilePicUrl = pData.profilePic, url = NSURL(string: profilePicUrl) {
                    // show placeholder color
                    self.profilePic.image = UIImage().getImageWithColor(AppStyles.sharedInstance.lightGrayColor)
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                        TreemContentService.sharedInstance.getContentRepositoryFile(url, cacheKey: pData.profilePicId, success: {
                            (image) -> () in
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                _ in
                                
                                // load the profile image
                                if let image = image {
                                    let size = UIImage.getResizeImageScaleSize(CGSize(width: self.profilePicHeightConstraint.constant * 2, height: self.profilePicHeightConstraint.constant), oldSize: image.size)

                                    // update constraints
                                    self.profilePicWidthConstraint.constant     = size.width
                                    self.profilePicHeightConstraint.constant    = size.height
                                    
                                    // apply new image
                                    UIView.transitionWithView(
                                        self.profilePic,
                                        duration: 0.1,
                                        options: UIViewAnimationOptions.TransitionCrossDissolve,
                                        animations: {
                                            self.profilePic.image = image
                                        },
                                        completion: nil
                                    )
                                }
                            })
                        })
                    })
                    
                    // add a tap handler to open the profile pic in a bigger view
                    self.profilePic.userInteractionEnabled = true
                    self.profilePic.addGestureRecognizer(
                        MediaTapGestureRecognizer(
                            target          : self,
                            action          : #selector(MemberProfileViewController.profilePicTap(_:)),
                            contentURL      : url,
                            contentURLId    : pData.profilePicId,
                            contentID       : nil,
                            contentType     : TreemContentService.ContentTypes.Image,
                            contentOwner    : false
                        )
                    )
                }
                else {
                    self.profilePic.image = UIImage(named: "Avatar-Profile")
                    
                    // reset avatar image to default size to save on space
                    self.profilePicWidthConstraint.constant     = self.EMPTY_PROFILE_WIDTH
                    self.profilePicHeightConstraint.constant    = self.EMPTY_PROFILE_HEIGHT
                }

                self.firstLastNameLabel.text = (self.truncateFirstLastName(pData.firstName ?? "") ?? "")! + " " + (self.truncateFirstLastName(pData.lastName ?? "") ?? "")!
                self.userNameLabel.text = self.truncateUserName(pData.username ?? "")
                
                if((pData.frStatus != nil) && (pData.frStatus != Profile.FriendStatus.NotFriends)) {
                    if(pData.frStatus == Profile.FriendStatus.Friends){
                        self.friendStatusLabel.text = Localization.sharedInstance.getLocalizedString("friend_status_friends", table: "MemberProfile")

                        self.actionMode = self.ACTION_UNFRIEND
                        UIView.performWithoutAnimation({
                            self.friendActionButton.setTitle(Localization.sharedInstance.getLocalizedString("action_unfriend", table: "MemberProfile"), forState: UIControlState.Normal)
                            self.friendActionButton.layoutIfNeeded()
                        })
                        
                        self.friendIcon.image = UIImage(named: "Friend")
                    }
                    else{
                        self.friendStatusLabel.text = Localization.sharedInstance.getLocalizedString("friend_status_pending", table: "MemberProfile")
                        
                        if(pData.lastAction == true){
                            self.actionMode = self.ACTION_PENDING_CANCEL
                            
                            UIView.performWithoutAnimation({
                               self.friendActionButton.setTitle(Localization.sharedInstance.getLocalizedString("action_cancel", table: "MemberProfile"), forState: UIControlState.Normal)
                               self.friendActionButton.layoutIfNeeded()
                            })

                        }
                        else{
                            self.actionMode = ""
                            self.friendActionButton.hidden = true;
                        }
                        
                        self.friendIcon.image = UIImage(named: "Invited")
                        
                        self.toggleExtendedProfileOptions(false)
                    }
                }
                else{
                    self.actionMode = ""
                    self.friendStatusLabel.text = Localization.sharedInstance.getLocalizedString("friend_status_not_friends", table: "MemberProfile")

                    self.actionMode = ""
                    self.friendActionButton.hidden = true;
                    
                    self.friendIcon.hidden = true
                    
                    if (self.friendIcon.hidden){
                       self.toggleExtendedProfileOptions(false)
                    }

                    //add friend option
                    if (pData.frStatus == Profile.FriendStatus.NotFriends){
                        self.actionMode = self.ACTION_FRIEND
                        
                        UIView.performWithoutAnimation({
                           self.friendActionButton.setTitle(Localization.sharedInstance.getLocalizedString("action_add_friend", table: "MemberProfile"), forState: UIControlState.Normal)
                            self.friendActionButton.layoutIfNeeded()
                        })
                        self.friendActionButton.hidden = false
                        
                        self.friendIcon.hidden = false
                        self.friendIcon.image = UIImage(named: "AddFriend")
                    }
                }
                
                // get the data for the table, reload it
                if let branchPaths = pData.branches {
                    self.branchPaths = branchPaths
                    
                    self.bindTableView()
                }
                else {
                    // sub branch view container constraints
                    self.branchViewLabelTopHeightConstraint.constant    = 0
                    self.branchesViewLabelHeightConstraint.constant     = 0
                    self.branchViewLableBottomHeightConstraint.constant = 0
                    self.branchPathTableViewBottomConstraint.constant   = 0
                    self.branchViewDividerHeightConstraint.constant     = 0
                    
                    // branch view container height constraint
                    self.branchViewContainerHeightConstraint.constant   = 0
                }
     
                self.residesCityLabel.text      = pData.residesLocality ?? "-"
                self.residesStateLabel.text     = pData.residesProvince ?? "-"
                self.residesCountryLabel.text   = pData.residesCountry ?? "-"
                
                if self.residesCityLabel.text != "-" {
                    self.residesCityLabel.text = self.truncateLocationString(self.residesCityLabel.text!)
                }
                if self.residesStateLabel.text != "-" {
                    self.residesStateLabel.text = self.truncateLocationString(self.residesStateLabel.text!)
                }
                if self.residesCountryLabel.text != "-" {
                    self.residesCountryLabel.text = self.truncateLocationString(self.residesCountryLabel.text!)
                }
                
                self.cancelLoadingMask()
            },
            failure: {
                (error) -> Void in
                
                // cancel loading mask and return to view with alert
                self.cancelLoadingMask({
                    CustomAlertViews.showGeneralErrorAlertView()
                })
                
            }
        )
    }
    
    func profilePicTap(sender: MediaTapGestureRecognizer) {
        let vc = MediaImageViewController.getStoryboardInstance()
        vc.contentUrl = sender.contentURL

        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    private func dismissView(){
        // fire the friendship changed callback if needed
        if(self.friendshipChanged){
            self.friendChangeCallback?()
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func showLoadingMask(completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.queueLoadingMask(self.scrollView, loadingViewAlpha: 1.0, showCompletion: completion)
        }
    }
    
    private func cancelLoadingMask(completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.cancelLoadingMask(completion)
        }
    }
    
    private func toggleExtendedProfileOptions(show : Bool){
        if (show){
            self.actionView.hidden = false
            self.actionViewHeightConstraint.constant = self.actionViewHeight
            self.actionViewBottomConstraint.constant = 0
        }
        else {
            self.actionView.hidden = true
            self.actionViewHeightConstraint.constant = 0
            self.actionViewBottomConstraint.constant = 0
        }
    }
    
    func bindTableView(){
        // resize the branch container
        self.branchViewContainerHeightConstraint.constant =
            self.branchViewLabelTopHeightConstraint.constant +
            self.branchesViewLabelHeightConstraint.constant +
            self.branchViewLableBottomHeightConstraint.constant +
            (self.branchPathTableView.rowHeight * CGFloat(self.branchPaths.count)) +
            self.branchPathTableViewBottomConstraint.constant
        
        // load the data
        self.branchPathTableView.reloadData()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.branchPaths.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("BranchPathTableViewCell") as! BranchPathTableViewCell
        
        if (self.branchPaths.indices.contains(indexPath.row)){
            if let color = self.branchPaths[indexPath.row].color {
                cell.branchColorView.backgroundColor = UIColor(hex: color)
            }
            
            if let path = self.branchPaths[indexPath.row].path {
                cell.branchPathLabel.text = path.joinWithSeparator(" > ")
            }
            else {
                cell.branchPathLabel.hidden = true
            }
        }
        
        return cell
    }
    
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        
        switch(item.tag) {
            case 0:
                self.loadMemberDetails(MemberDetailsViewController.DetailType.Feed)
            case 1:
                self.loadMemberDetails(MemberDetailsViewController.DetailType.Photo)
            case 2:
                self.startNewChatSession()
            default:
                self.loadMemberDetails(MemberDetailsViewController.DetailType.Feed)
        }
        
        // deselect after tap
        self.optionsTabBar.selectedItem = nil
    }
    
    private func loadMemberDetails(loadType: MemberDetailsViewController.DetailType){
        let vc = MemberDetailsViewController.getStoryboardInstance()
        vc.userID = self.userId
        vc.loadType = loadType
        vc.userIsSelf = false
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    private func startNewChatSession(){
        
        CustomAlertViews.showCustomConfirmView(title: Localization.sharedInstance.getLocalizedString("chat_confirm_title", table: "MemberProfile")
            , message: Localization.sharedInstance.getLocalizedString("chat_confirm_message", table: "MemberProfile")
            , fromViewController: self
            , yesHandler: {
                alertAction in
                
                let chatSessObj = ChatSession()
                chatSessObj.chatUserIds = [self.userId!]
                chatSessObj.chatName    = (self.firstLastNameLabel.text != nil) ? self.firstLastNameLabel.text! + " Chat" : ""
                
                self.showLoadingMask()
                
                TreemChatService.sharedInstance.initializeChatSession(
                    CurrentTreeSettings.sharedInstance.treeSession,
                    chatSession: chatSessObj,
                    success: {
                        data in
                        
                        self.cancelLoadingMask({
                            
                            let newSession = ChatSession.init(json: data)
                            
                            if let newId = newSession.sessionId {
                                
                                let vc = MemberDetailsViewController.getStoryboardInstance()
                                vc.userID = self.userId
                                vc.chatSessionID = newId
                                vc.chatName = chatSessObj.chatName
                                vc.loadType = MemberDetailsViewController.DetailType.Chat
                                
                                self.presentViewController(vc, animated: true, completion: nil)
                            }
                            else {
                                CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                            }
                            
                        })
                        
                    },
                    failure: {
                        error, wasHandled in
                        
                        self.cancelLoadingMask()
                })
                
            }
            , noHandler: {
                alertAction in
                
                // do nothing
            }
        )
        
    }
    
    private func truncateFirstLastName(longName: String) -> String {
        var shortenedName = ""
        var stringLength = 0
        var appendString = ""
        
        let tempTitle = longName
        
        if Device.sharedInstance.isResolutionSmallerThaniPhone5() || Device.sharedInstance.isResolutionSmallerThaniPhone6(){
            stringLength = 10
        }
        else if Device.sharedInstance.isResolutionSmallerThaniPhone6Plus() {
            stringLength = 13
        }
        else {
            stringLength = 15
        }
        
        if tempTitle.characters.count < stringLength {
            stringLength = tempTitle.characters.count
        }
        else {
            appendString = "..."
        }
        
        shortenedName = (tempTitle.substringWithRange(Range<String.Index>(start: tempTitle.startIndex, end: tempTitle.startIndex.advancedBy(stringLength)))) + appendString
        
        return shortenedName
    }
    
    private func truncateUserName(longName: String) -> String {
        var shortenedName = ""
        var stringLength = 0
        var appendString = ""
        
        let tempTitle = longName
        
        if Device.sharedInstance.isResolutionSmallerThaniPhone5() || Device.sharedInstance.isResolutionSmallerThaniPhone6(){
            stringLength = 20
        }
        else if Device.sharedInstance.isResolutionSmallerThaniPhone6Plus() {
            stringLength = 25
        }
        else {
            stringLength = 30
        }
        
        if tempTitle.characters.count < stringLength {
            stringLength = tempTitle.characters.count
        }
        else {
            appendString = "..."
        }
        
        shortenedName = (tempTitle.substringWithRange(Range<String.Index>(start: tempTitle.startIndex, end: tempTitle.startIndex.advancedBy(stringLength)))) + appendString
        
        return shortenedName
    }
    
    private func truncateLocationString(longString: String) -> String {
        var shortString = ""
        var stringLength = 0
        var appendString = ""
        
        let tempTitle = longString
        
        if Device.sharedInstance.isResolutionSmallerThaniPhone5() || Device.sharedInstance.isResolutionSmallerThaniPhone6() {
            stringLength = 30
        }
        else if Device.sharedInstance.isResolutionSmallerThaniPhone6Plus() {
            stringLength = 35
        }
        else {
            stringLength = 40
        }
        
        if tempTitle.characters.count < stringLength {
            stringLength = tempTitle.characters.count
        }
        else {
            appendString = "..."
        }
        
        shortString = (tempTitle.substringWithRange(Range<String.Index>(start: tempTitle.startIndex, end: tempTitle.startIndex.advancedBy(stringLength)))) + appendString
        
        return shortString
    }
}
