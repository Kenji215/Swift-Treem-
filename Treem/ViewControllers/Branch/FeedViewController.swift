//
//  FeedViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/10/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import MediaPlayer
import TTTAttributedLabel

class FeedViewController : PagedTableViewController, PostDelegate, TTTAttributedLabelDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {

    //# MARK: - Variables

    /* react count size constants */
    static let REACT_IMAGE_SIZE    : CGFloat = 20
    static let REACT_FONT_SIZE     : CGFloat = 12
    static let REACT_SPACING       : CGFloat = 10

    /* change reaction view size constants */
    static let SET_REACT_SIZE              : CGFloat = 24
    static let SET_REACT_WIDTH_SPACER      : CGFloat = 15
    static let SET_REACT_HEIGHT_SPACER     : CGFloat = 5
    static let SET_REACT_HEIGHT_PADDING    : CGFloat = 5
    
    /* branch layout size constants */
    private let BRANCH_COLOR_SIZE   : CGFloat = 6
    private let BRANCH_COLOR_SPACER : CGFloat = 4

    // tagging int to designate current user
    private let SELF_USER_ID = -999
    
    // reaction animation duration
    private let REACT_ANIMATION_DURATION = 0.25
    
    lazy var postUsers: Dictionary<Int, User> = [:]
    lazy private var errorViewController = ErrorViewController.getStoryboardInstance()
    
    private let fadeInTransition = FadeInAnimatedTransition()
    
    // delegates
    var delegate            : PostDetailsViewController?    = nil
    var postDelegate        : PostDelegate?                 = nil
    var sharePostDelegate   : PostShareDelegate?            = nil
    var branchViewDelegate  : BranchViewDelegate?           = nil

    //Used for viewing individual posts rather than the entire feed if set to a non-zero value
    var singlePostLoad  : Bool      = false
    
    var singleFeedUserId    : Int?      = nil
    var loadSelfFeed        : Bool      = false
    
    var feedDate        : NSDate?   = nil

    var isShowingPostOptions = false
    
    let downloadOperations = DownloadContentOperations()
    
    static func getStoryboardInstance() -> FeedViewController {
        return UIStoryboard(name: "Feed", bundle: nil).instantiateInitialViewController() as! FeedViewController
    }

    //# MARK: - View Controller Override Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

       /* If a post_id is set, then we wish to view an individual post, rather than a whole feed.
        In that case we have to do some overrides of the standard behaviors.
        */
        if self.singlePostLoad {
            self.useRefreshControl = false
        }
        else {
            self.emptyText = "No posts have been added"

            self.getPosts(self.pageIndex, pageSize: self.pageSize)

            self.useRefreshControl = true

            self.pagedDataCall = self.getPosts
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // dismiss presented post options view if feed view gone
        if self.isShowingPostOptions {
            self.dismissViewControllerAnimated(false, completion: nil)
            self.isShowingPostOptions = false
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (self.items.indices.contains(indexPath.row)){
            if let post = self.items[indexPath.row] as? Post {
                return post.cellHeightLayout
            }
        }
        return 0
    }

    //# MARK: - View Animation Methods

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AppStyles.directionUpViewAnimatedTransition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AppStyles.directionDownViewAnimatedTransition
    }

    //# MARK: - Table View Override Methods

    // perform asynchronous calls and constraint layouts
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> FeedTableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("FeedCell", forIndexPath: indexPath) as! FeedTableViewCell
        
        cell.tag                        = indexPath.row
        cell.layer.shouldRasterize      = true
        cell.layer.rasterizationScale   = Device.sharedInstance.mainScreen.scale
        
        // Need to adjust for the Url preview view
        var containsUrl         = false
        
        // store post options that can alter layout calculations below
        var isSharedPost        = false

        // update from post data
        if (self.items.indices.contains(indexPath.row)){
            
            if let  post = self.items[indexPath.row] as? Post,
                    user = self.postUsers[post.userId]
            {
                containsUrl     = post.containsUrl
                isSharedPost    = post.isSharedPost
                
                // get avatar image
                if let avatarURL = user.avatar, downloader = DownloadContentOperation(url: avatarURL, cacheKey: user.avatarId) {
                    
                    downloader.completionBlock = {
                        if let image = downloader.image where !downloader.cancelled {
                            // perform UI changes back on the main thread
                            dispatch_async(dispatch_get_main_queue(), {
                                
                                // check that the cell hasn't been reused
                                if (cell.tag == indexPath.row) {
                                    
                                    // if cell in view then animate, otherwise add it to load once the cell is visible                                    
                                    if tableView.visibleCells.contains(cell) {
                                        UIView.transitionWithView(
                                            cell.avatarImageView,
                                            duration: 0.1,
                                            options: UIViewAnimationOptions.TransitionCrossDissolve,
                                            animations: {
                                                
                                                cell.avatarImageView.image = image
                                                
                                            },
                                            completion: nil
                                        )
                                    }
                                    else {
                                        cell.avatarImageView.image = image
                                    }
                                }
                            })
                        }
                    }
                    
                    self.downloadOperations.startDownload(indexPath, downloadContentOperation: downloader)
                }
                
                cell.postUrlPreviewView.subviews.forEach({ $0.removeFromSuperview() })
            
                // show preview if url contained in the post
                if containsUrl {
                    // add preview via frame placement
                    let previewController   = UrlPreviewViewController.getStoryboardInstance()
                    
                    previewController.pageData          = post.postUrlData!
                    previewController.view.frame        = CGRectMake(0, 0, Device.sharedInstance.mainScreen.bounds.width - 20, post.urlPreviewHeight)
                    
                    cell.postUrlPreviewView.addGestureRecognizer(UrlPreviewTapGestureRecognizer(target: self, action: #selector(FeedViewController.loadUrl(_:)), data: post.postUrlData!))                    
                    
                    self.addChildViewController(previewController)

                    cell.postUrlPreviewView.addSubview(previewController.view)
                }
                
                // get attached content items
                if  let contentItems    = post.contentItems where post.contentItems?.count > 0,
                    let contentItem     = contentItems[0] as? ContentItemDownload,
                    let contentURL      = contentItem.contentURL
                {
                    let contentSize = post.getContentSize(contentItem)

                    // clear previously added views
                    cell.mediaContainerView.subviews.forEach({ $0.removeFromSuperview() })
                    
                    if let downloader = DownloadContentOperation(url: contentURL, cacheKey: contentItem.contentURLId) {
                        downloader.completionBlock = {
                            if let image = downloader.image where !downloader.cancelled {
                                // check that cell hasn't been reused
                                if (cell.tag == indexPath.row) {
                                
                                    // perform UI changes back on the main thread
                                    dispatch_async(dispatch_get_main_queue(), {

                                        let imageView = UIImageView(image: image)
                                        
                                        // if image exceeds the size of the viewing area scale it
                                        if image.size.width > contentSize.width || image.size.height > contentSize.height {
                                            imageView.contentMode = .ScaleAspectFit
                                        }
                                        // else show it centered
                                        else {
                                            imageView.contentMode = .Center
                                        }
                                        
                                        // if imageview is a thumbnail for a video add an action
                                        imageView.userInteractionEnabled = true
                                        imageView.addGestureRecognizer(
                                            MediaTapGestureRecognizer(
                                                target          : self,
                                                action          : #selector(FeedViewController.mediaThumbnailTap(_:)),
                                                contentURL      : contentURL,
                                                contentURLId    : contentItem.contentURLId,
                                                contentID       : contentItem.contentID,
                                                contentType     : contentItem.contentType,
                                                contentOwner    : false
                                            )
                                        )
                                        
                                        var xPos: CGFloat = 0
                                        
                                        if contentSize.width < cell.mediaContainerView.bounds.width {
                                            xPos = (cell.mediaContainerView.bounds.width * 0.5) - (contentSize.width * 0.5)
                                        }
                                        
                                        imageView.frame = CGRectMake(xPos,0,contentSize.width,contentSize.height)
                                        
                                        // if cell in view then animate, otherwise add if in table but not visible
                                        if !self.singlePostLoad && tableView.visibleCells.contains(cell) {
                                            imageView.alpha = 0
                                            
                                            // add image view to parent
                                            cell.mediaContainerView.addSubview(imageView)
                                            
                                            UIView.transitionWithView(
                                                cell.mediaContainerView,
                                                duration: 0.1,
                                                options: .TransitionCrossDissolve,
                                                animations: {
                                                    imageView.alpha = 1.0
                                                },
                                                completion: nil
                                            )
                                        }
                                        else {
                                            // add image view to parent
                                            cell.mediaContainerView.addSubview(imageView)
                                        }
                                    })
                                }
                            }
                        }
                        
                        self.downloadOperations.startDownload(indexPath, downloadContentOperation: downloader)
                    }
                }

                if let post_user = self.postUsers[post.share_user_id] where isSharedPost, let url = post_user.avatar, downloader = DownloadContentOperation(url: url, cacheKey: post_user.avatarId) {
                    downloader.completionBlock = {
                        if let image = downloader.image where !downloader.cancelled {
                            // perform UI changes back on the main thread
                            dispatch_async(dispatch_get_main_queue(), {
                                // check that cell hasn't been reused and is visible
                                if (cell.tag == indexPath.row) {
                                    // if cell in view then animate, otherwise add if in table but not visible
                                    if tableView.visibleCells.contains(cell) {
                                        UIView.transitionWithView(
                                            cell.avatarImageView,
                                            duration: 0.1,
                                            options: UIViewAnimationOptions.TransitionCrossDissolve,
                                            animations: {
                                                cell.shareAvatarImageView.image = image
                                            },
                                            completion: nil
                                        )
                                    }
                                    else {
                                        cell.shareAvatarImageView.image = image
                                    }
                                }
                            })
                        }
                    }
                    
                    self.downloadOperations.startDownload(indexPath, downloadContentOperation: downloader)
                }
                
                var branchHexColors: [String] = []
                
                // set color if post from current user (if made in particular branch)
                if let color = post.color {
                    branchHexColors.append(color)
                }
                // set color if post from another user (user can be on multiple branches)
                else if let colors = user.colors {
                    for color in colors {
                        branchHexColors.append(color)
                    }
                }

                let container           = isSharedPost ? cell.shareBranchesContainer : cell.branchesContainer
                container.addBranches(branchHexColors)

                /*
                    Height Constraint Properties
                */
              
                // share layout properties
                cell.sharePostContainerTopConstraint.constant       = post.sharePosterTopMargin
                cell.sharePosterContainerHeightConstraint.constant  = post.sharePosterHeight
                cell.shareMessageTopConstraint.constant             = post.shareMessageTopMargin
                cell.shareMessageHeightConstraint.constant          = post.shareMessageHeight
                cell.shareMessageBottomConstraint.constant          = post.shareMessageBottomMargin

                // regular post layout properties
                cell.posterContainerTopConstraint.constant          = post.posterTopMargin
                cell.posterContainerHeightConstraint.constant       = post.posterHeight
                
                // tag button
                cell.taggedButtonTopConstraint.constant             = post.taggedTopMargin
                cell.taggedButtonHeightShowConstraint.constant      = post.taggedHeight
                cell.taggedButtonBottomConstraint.constant          = post.messageTopMargin
                
                // message
                cell.messageHeightConstraint.constant               = post.messageHeight
                cell.messageTextBottomConstraint.constant           = post.messageBottomMargin
                
                // Url preview layout properties
                cell.postUrlPreviewViewHeightConstraint.constant    = post.urlPreviewHeight
                cell.postUrlPreviewBottomConstraint.constant        = post.urlPreviewBottomMargin
                
                // content attachments
                cell.mediaContainerViewHeightConstraint.constant    = post.contentHeight
                cell.mediaContainerBottomConstraint.constant        = post.contentBottomMargin
                
                // reactions
                self.checkPostReactionCounts(cell, post: post) // constants set in function
                
                // post action height
                cell.actionViewHeightConstraint.constant            = post.actionViewHeight
                
                // bottom options
                cell.postBottomOptionsHeightConstraint.constant     = post.postOptionsHeight
                cell.lowerGapHeightConstraint.constant              = post.bottomShadeBarHeight
            }
        }

        return cell
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)

        let cell = cell as! FeedTableViewCell
        
        // store post options that can alter layout calculations below
        var isShareable         = false
        var isSharedPost        = false
        var hasTaggedMembers    = false
        var hasMessage          = false
        
        // clear/reset values
        cell.resetActionView()
        
        // default color/state of post options
        cell.commentsButton.active          = false
        cell.reactButton.active             = false
        cell.shareButton.active             = false
        cell.postOptionsButton.active       = false
        cell.sharePostOptionsButton.active  = false
        
        if (self.items.indices.contains(indexPath.row)){
            if let post = self.items[indexPath.row] as? Post, user = self.postUsers[post.userId] {
                hasTaggedMembers    = post.currentUserTagged
                hasMessage          = post.hasMessage
                isShareable         = post.shareable
                isSharedPost        = post.isSharedPost
                
                if(self.sharePostDelegate == nil) { isShareable = false }            
                
                // tap on avatar to view profile
                let profileSelector = #selector(FeedViewController.profileTouchUpInside(_:))
                let userId = user.isCurrentUser ? self.SELF_USER_ID : user.id
                
                cell.avatarImageView.tag = userId
                cell.avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: profileSelector))
                
                // tap on name label to view profile
                cell.nameLabel.tag = userId
                cell.nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: profileSelector))
                
                // main post details
                cell.nameLabel.text         = user.getFullName()
                cell.dateLabel.text         = post.postDate?.getRelativeDateFormattedString()
                
                // check for url links (call made before text applied)
                if post.hasMessage {
                    cell.messageTextLabel.delegate = self
                    AppStyles.sharedInstance.setURLAttributedLabelStyling(cell.messageTextLabel)
                }
                
                cell.messageTextLabel.text  = post.message

                // if shared post
                if let post_user = self.postUsers[post.share_user_id] where isSharedPost {
                    let shareUserId = post_user.isCurrentUser ? self.SELF_USER_ID : post.share_user_id

                    // tap on shared avatar to view profile
                    cell.shareAvatarImageView.tag = shareUserId
                    cell.shareAvatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: profileSelector))
                    
                    // tap on shared name label to view profile
                    cell.shareNameLabel.tag = shareUserId
                    cell.shareNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: profileSelector))
                    
                    cell.shareNameLabel.text    = post_user.getFullName() + " shared " + user.getFullName() + "'s post"
                    cell.shareDateLabel.text    = post.share_date?.getRelativeDateFormattedString()
                    
                    if post.hasSharedMessage {
                        cell.shareMessage.delegate = self
                        AppStyles.sharedInstance.setURLAttributedLabelStyling(cell.shareMessage)
                    }
                    
                    cell.shareMessage.text      = post.share_message
                }

                // update comment button
                self.setButtonCount(cell.commentsButton, count: post.commentCount, text: "Comment")

                cell.commentsButton.tag = indexPath.row
                cell.commentsButton.addTarget(self, action: #selector(FeedViewController.commentsTouchUpInside(_:)), forControlEvents: .TouchUpInside)
                
                // update react button
                cell.reactButton.tag = indexPath.row
                cell.reactButton.addTarget(self, action: #selector(FeedViewController.reactTouchUpInside(_:)), forControlEvents: .TouchUpInside)
                
                // update shareable button
                if post.shareable {
                    self.setButtonCount(cell.shareButton, count: post.shareCount, text: "Share")
                    
                    // add share button handler
                    cell.shareButton.tag = indexPath.row
                    cell.shareButton.addTarget(self, action: #selector(FeedViewController.shareTouchUpInside(_:)), forControlEvents: .TouchUpInside)
                }
                
                // update post options button
                if post.isSharedPost {
                    cell.sharePostOptionsButton.tag = indexPath.row
                    cell.sharePostOptionsButton.addTarget(self, action: #selector(FeedViewController.viewPostOptionsShared(_:)), forControlEvents: .TouchUpInside)
                }
                
                cell.postOptionsButton.tag = indexPath.row
                cell.postOptionsButton.addTarget(self, action: #selector(FeedViewController.viewPostOptions(_:)), forControlEvents: .TouchUpInside)

                // if view once call services to denote it has been seen
                if post.viewOnce && !post.wasViewed {
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), {
                        TreemFeedService.sharedInstance.setViewPost(
                            CurrentTreeSettings.sharedInstance.treeSession,
                            postId: post.postId,
                            success: {
                                data in

                                post.wasViewed = true
                            },
                            failure: {
                                _ in

                                // do nothing
                            }
                        )
                    })
                }
            }
            
            var postBackgroundColor: UIColor
            
            if !isSharedPost {
                postBackgroundColor = UIColor.whiteColor()
                
                cell.shareMessage.text          = nil
                cell.postView.layer.borderWidth = 0
            }
            else {
                postBackgroundColor = AppStyles.sharedInstance.lightGrayColor
                
                cell.postView.layer.borderWidth = 1.0
                cell.postView.layer.borderColor = AppStyles.sharedInstance.dividerColor.CGColor
            }
            
            // assign background based on shared/original post
            cell.postView.backgroundColor               = postBackgroundColor
            cell.nameLabel.backgroundColor              = postBackgroundColor
            cell.messageTextLabel.backgroundColor       = postBackgroundColor
            cell.postOptionsButton.backgroundColor      = postBackgroundColor
            cell.taggedButton.backgroundColor           = postBackgroundColor
            cell.dateLabel.backgroundColor              = postBackgroundColor
            cell.branchesContainer.backgroundColor      = postBackgroundColor
            cell.mediaContainerView.backgroundColor     = postBackgroundColor
            cell.avatarImageView.backgroundColor        = postBackgroundColor
            cell.postUrlPreviewView.backgroundColor     = postBackgroundColor
            
            cell.messageTextLabel.hidden = !hasMessage

            // share button
            cell.shareMessage.hidden            = !isSharedPost
            cell.sharePosterContainer.hidden    = !isSharedPost
            
            // show share option if post is shareable
            cell.shareButton.hidden                     = !isShareable
            
            if !hasMessage {
                cell.messageTextLabel.text = nil
            }
            
            cell.taggedButton.hidden = !hasTaggedMembers
            
            if hasTaggedMembers {
                cell.taggedButton.tintColor = cell.taggedButton.titleColorForState(.Normal)
            }
        }
    }
    
    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // close action view if open
        if (self.items.indices.contains(indexPath.row)){
            if let post = self.items[indexPath.row] as? Post {
                post.actionViewHeight = 0
            }
        }
        
        // check if cell at indexpath no longer visible
        if tableView.indexPathsForVisibleRows?.indexOf(indexPath) == nil {

            #if DEBUG
                print("Cancel content loading for row: \(indexPath.row)")
            #endif

            // cancel the current download operations in the cell
            self.downloadOperations.cancelDownloads(indexPath)
        }
    }

    //# MARK: - Feed Methods

    func viewPostOptionsShared(sender: UIButton) {
        self.viewPostOptionsSelected(sender, sharedOptionsSelected: true)
    }
    
    func viewPostOptions(sender: UIButton){
        self.viewPostOptionsSelected(sender, sharedOptionsSelected: false)
    }
    
    private func viewPostOptionsSelected(sender: UIButton, sharedOptionsSelected: Bool) {
        if sender.tag < self.items.count {
            if let post = self.items[sender.tag] as? Post {
                // animate cell to top of view (if not already)
                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: sender.tag, inSection: 0), atScrollPosition: .Top, animated: true)
                
                //The size of the popover is being set when creating the instance.
                let postOptionsVC = PostOptionsViewController.getStoryboardInstance()
                
                postOptionsVC.post                  = post
                postOptionsVC.sharedSelected        = sharedOptionsSelected
                postOptionsVC.delegate              = self
                postOptionsVC.postDelegate          = self
                postOptionsVC.transitioningDelegate = self.fadeInTransition
                postOptionsVC.popoverDelegate       = self
                postOptionsVC.referringButton       = sender
                
                self.presentViewController(postOptionsVC, animated: true, completion: nil)
                
                self.isShowingPostOptions = true
            }
        }
    }

    func commentsTouchUpInside(sender: UIButton) {
        if sender.tag < self.items.count {
            if self.singlePostLoad {
                // if viewing an individual post already, tap the comments button to move focus into the Add Reply textbox
                self.delegate?.focusAddReplyTextField()
            }
            else {
                // if viewing from the feed, "Comments" button will pop into the individual post view screen
                let indexPath = NSIndexPath(forRow: sender.tag, inSection: 0)
                
                if let post = self.items[sender.tag] as? Post, cell = self.tableView.cellForRowAtIndexPath(indexPath) as? FeedTableViewCell {
                    let vc = PostDetailsViewController.getStoryboardInstance()
                    
                    // close react view if open
                    if post.actionViewHeight > 0 {
                        self.checkReactionSetView(post, cell: cell, indexPath: indexPath)
                    }
                    
                    vc.post                     = post
                    vc.postUsers                = self.postUsers
                    vc.transitioningDelegate    = self
                    vc.inNavController          = true
                    vc.branchViewDelegate       = self.branchViewDelegate
                    vc.parentCommentsButton     = sender
                    
                    self.navigationController?.pushViewController(vc, animated: true)
                    
                    self.branchViewDelegate?.setTemporaryTitle?("Comments")
                }
            }
        }
    }
    
    private func getPosts(page: Int, pageSize: Int) {
        self.showLoadingMask()
        
        var f_date: NSDate? = nil
        
        // if first page, generate new feed date
        if page <= self.initialPageIndex {
            f_date = NSDate()
            
            self.feedDate = f_date
        }
        else if let date = self.feedDate {
            f_date = date
        }
        
        if ((self.singleFeedUserId != nil) || (self.loadSelfFeed == true)) {

            if(self.loadSelfFeed) { self.singleFeedUserId = nil }
            
            // get view size
            TreemFeedService.sharedInstance.getUserPosts(
                CurrentTreeSettings.sharedInstance.treeSession,
                userId: self.singleFeedUserId,
                page: page,
                pageSize: pageSize,
                date: f_date,
                viewSize: UIScreen.mainScreen().bounds.width,
                failureCodesHandled: nil,
                success: {
                    data in
                    
                    let postData = Post.getPostsFromData(data)
                    
                    self.postUsers.merge(postData.users)
                    
                    self.setData(postData.posts)
                    
                    self.cancelLoadingMask()
                },
                failure: {
                    error, wasHandled in

                    self.cancelLoadingMask()
                }
            )
        }
        else{
        
            // get view size
            TreemFeedService.sharedInstance.getPosts(
                CurrentTreeSettings.sharedInstance.treeSession,
                page: page,
                pageSize: pageSize,
                date: f_date,
                viewSize: UIScreen.mainScreen().bounds.width,
                failureCodesHandled: nil,
                success: {
                    data in

                    let postData = Post.getPostsFromData(data)

                    self.postUsers.merge(postData.users)

                    self.setData(postData.posts)
                    
                    self.cancelLoadingMask()
                },
                failure: {
                    error, wasHandled in
                    
                    self.cancelLoadingMask()
                }
            )
        }
    }

    func mediaThumbnailTap(sender: MediaTapGestureRecognizer) {
        if let cType = sender.contentType {
            if(cType == .Video){                
                let vc = MediaVideoViewController.getStoryboardInstance()
                
                vc.contentId = sender.contentID
                
                self.navigationController?.presentViewController(vc, animated: true, completion: nil)
            }
            else{
                
                let vc = MediaImageViewController.getStoryboardInstance()
                if let cUrl = sender.contentURL{
                    vc.contentUrl = cUrl
                }
                else{
                    vc.contentId = sender.contentID
                }
                
                self.navigationController?.presentViewController(vc, animated: true, completion: nil)
            }
        }
    }
    
    func profileTouchUpInside(sender: UITapGestureRecognizer) {
        if let tag = sender.view?.tag {
            // assume current user
            if tag == self.SELF_USER_ID {
                let vc = ProfileViewController.getStoryboardInstance()
                
                vc.isPresenting = true
                
                self.presentViewController(vc, animated: true, completion: nil)
            }
            else {
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
    }
    
    // used on the details page, the replys vc calls this to update the button count
    func setCommentCount(postID: Int, count: Int){        
        if let postItems = self.items as? [Post] {
            if let index = postItems.indexOf({ $0.postId == postID}) {
                (self.items[index] as! Post).commentCount = count
                self.tableView.reloadData()
            }
        }
    }
    
    private func setButtonCount(button: UIButton, count: Int, text: String) {
        var countText: String
        
        if(count > 0){
            countText = " (" + count.description + ")"
        }
        else {
            countText = ""
        }
        
        UIView.performWithoutAnimation({
            button.setTitle(text + countText, forState: .Normal)
            button.layoutIfNeeded()
        })
    }
    
    private func updateCellHeight(cell: FeedTableViewCell, post: Post, animationOptions: UIViewAnimationOptions? = nil, completion: ((Bool)->())? = nil) {
        self.delegate?.postContainerHeightUpdated(post.cellHeightLayout, animationDuration: self.REACT_ANIMATION_DURATION)
        
        if animationOptions != nil {
            if animationOptions! == UIViewAnimationOptions.TransitionNone
            {
                cell.contentView.layoutIfNeeded()
            }
            else {
                // update cell content layout with animation options defined
                UIView.animateWithDuration(
                    self.REACT_ANIMATION_DURATION,
                    delay: 0.0,
                    options: animationOptions!,
                    animations: {
                        cell.contentView.layoutIfNeeded()
                    },
                    completion: completion
                )
            }
        }
        else {
            // update cell content layout
            UIView.animateWithDuration(
                self.REACT_ANIMATION_DURATION,
                animations: {
                    cell.contentView.layoutIfNeeded()
                },
                completion: completion
            )
        }
        
        // update table layout
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }

    //# MARK: - Post Share Methods
    
    func shareTouchUpInside(sender: UIButton){
        let indexPath = NSIndexPath(forRow: sender.tag, inSection: 0)
        
        if let post = self.items[sender.tag] as? Post, cell = self.tableView.cellForRowAtIndexPath(indexPath) as? FeedTableViewCell {
            let vc = PostShareViewController.getStoryboardInstance()
            
            // close action view if open
            if post.actionViewHeight > 0 {
                self.checkReactionSetView(post, cell: cell, indexPath: indexPath)
            }
            
            vc.post                     = post
            vc.shareDelegate            = self.sharePostDelegate
            vc.postDelegate             = self
            vc.transitioningDelegate    = self
            vc.inNavController          = true
            vc.branchViewDelegate       = self.branchViewDelegate
            
            self.navigationController?.pushViewController(vc, animated: true)
            
            self.branchViewDelegate?.setTemporaryTitle?("Share")
        }
    }
    
    //# MARK: - Post Reaction Methods
    
    private func checkPostReactionCounts(cell: FeedTableViewCell, post: Post) {
        var xPos        = CGFloat(0)
        
        // clear existing subview / gestures
        cell.reactContainerView.subviews.forEach({ $0.removeFromSuperview() })
        cell.reactContainerView.gestureRecognizers?.forEach(cell.reactContainerView.removeGestureRecognizer)
        
        // check for reactions
        if let reacts = post.reactCounts {
            let rCnt        = reacts.count
            let labelFont   = UIFont.systemFontOfSize(FeedViewController.REACT_FONT_SIZE)
            
            // check to see if this is your own post
            if let user = self.postUsers[post.userId] where user.isCurrentUser {

                cell.reactContainerView.tag = post.postId
                cell.reactContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(FeedViewController.reactionViewTouchUpInside(_:))))
            }
            
            for x in 0 ..< rCnt {
                let reaction    = reacts[x]
                let text        = reaction.count.description
                
                if (x > 0) {
                    xPos += FeedViewController.REACT_SPACING
                }
                
                // add react smiley imageview
                let reactFrame      = CGRectMake(xPos,0,FeedViewController.REACT_IMAGE_SIZE,FeedViewController.REACT_IMAGE_SIZE)
                let reactImageView  = UIImageView(frame: reactFrame)
                
                reactImageView.contentMode  = .ScaleAspectFit
                reactImageView.image        = Post.getReactionImage(reaction.react)
                reactImageView.opaque       = false
                
                cell.reactContainerView.addSubview(reactImageView)
                
                xPos += (FeedViewController.REACT_IMAGE_SIZE + 2)
                
                // add react smiley number count
                let reactLabelFrame = CGRectMake(xPos, 0, text.widthWithConstrainedHeight(FeedViewController.REACT_IMAGE_SIZE, font: labelFont), FeedViewController.REACT_IMAGE_SIZE)
                let reactLabel      = UILabel(frame: reactLabelFrame)
                
                reactLabel.textAlignment    = NSTextAlignment.Left
                reactLabel.text             = text
                reactLabel.font             = labelFont
                reactLabel.textColor        = FeedViewController.getReactionColor(reaction.react)
                reactLabel.opaque           = false
                reactLabel.backgroundColor  = UIColor.clearColor()
                                
                cell.reactContainerView.addSubview(reactLabel)
                
                xPos += reactLabelFrame.width
            }
        }

        // set react container height
        cell.reactContainerViewTopConstraint.constant       = post.reactTopMargin
        cell.reactContainerViewWidthConstraint.constant     = xPos
        cell.reactContainerViewHeightConstraint.constant    = post.reactHeight
        cell.reactContainerViewBottomConstraint.constant    = post.reactBottomMargin
    }
    
    static func getReactionColor(react: Post.ReactionType) -> UIColor {
        var color: UIColor
        
        switch(react) {
        case Post.ReactionType.Neutral          : color =  UIColor(red: 61/255.0, green: 67/255.0, blue: 60/255.0, alpha: 1)
        case Post.ReactionType.Happy            : color =  UIColor(red: 120/255.0, green: 160/255.0, blue: 40/255.0, alpha: 1)
        case Post.ReactionType.Angry            : color =  UIColor(red: 162/255.0, green: 32/255.0, blue: 34/255.0, alpha: 1)
        case Post.ReactionType.Sad              : color =  UIColor(red: 114/255.0, green: 182/255.0, blue: 219/255.0, alpha: 1)
        case Post.ReactionType.Hilarious        : color =  UIColor(red: 243/255.0, green: 112/255.0, blue: 50/255.0, alpha: 1)
        case Post.ReactionType.Amazed           : color =  UIColor(red: 149/255.0, green: 142/255.0, blue: 192/255.0, alpha: 1)
        case Post.ReactionType.Worried          : color =  UIColor(red: 104/255.0, green: 67/255.0, blue: 25/255.0, alpha: 1)
        }
        
        return color
    }
    
    func reactTouchUpInside(sender: UIButton){
        let indexPath = NSIndexPath(forRow: sender.tag, inSection: 0)
        
        if let post = self.items[sender.tag] as? Post, cell = self.tableView.cellForRowAtIndexPath(indexPath) as? FeedTableViewCell {
            
            // show/hide action view
            self.checkReactionSetView(post, cell: cell, indexPath: indexPath)
        }
    }
    
    func checkReactionSetView(post: Post, cell: FeedTableViewCell, indexPath: NSIndexPath) {
        var actionViewHeight: CGFloat = 0
        
        // if react button already selected close react action view
        if cell.reactButton.active {
            cell.resetActionView()
        }
        // show react action items
        else {
            // check if another action view open
            if cell.shareButton.active {
                cell.shareButton.active = false
                
                cell.resetActionView()
            }
            
            // action view references
            let actionViewWidth         : CGFloat = cell.actionView.frame.width
            
            var xPos: CGFloat = cell.contentView.center.x - 0.5 * ((CGFloat(Post.ReactionType.allOrderedValues.count) * (
                FeedViewController.SET_REACT_SIZE + FeedViewController.SET_REACT_WIDTH_SPACER)))
            var yPos: CGFloat = 0
            var rows: CGFloat = 1
            
            // precalculate some of the values used in each loop iteration
            let doubleHeightSpacer  = FeedViewController.SET_REACT_HEIGHT_SPACER * 2
            let halfWidthSpacer     = FeedViewController.SET_REACT_WIDTH_SPACER * 0.5
            let widthPerButton      = FeedViewController.SET_REACT_SIZE + FeedViewController.SET_REACT_WIDTH_SPACER
            let heightPerButton     = FeedViewController.SET_REACT_SIZE + doubleHeightSpacer
            let reactFrame          = CGRectMake(halfWidthSpacer
                                ,FeedViewController.SET_REACT_HEIGHT_SPACER
                                ,FeedViewController.SET_REACT_SIZE
                                ,FeedViewController.SET_REACT_SIZE)
            
            let noCurrentReaction   = (post.selfReact == nil)
            
            // add each reaction type image, check for additional rows as needed
            for reaction in Post.ReactionType.allOrderedValues {
                
                // check if moving to next row
                if (xPos + widthPerButton) > actionViewWidth - FeedViewController.SET_REACT_HEIGHT_SPACER {
                    yPos += heightPerButton
                    xPos = 0
                    
                    ++rows
                }
                // else adding to same row
                
                let reactButton         = ReactionButton()
                reactButton.frame       = CGRectMake(xPos, yPos, widthPerButton, heightPerButton)
                reactButton.reaction    = reaction
                reactButton.tag         = indexPath.row
                
                // check if selected
                if (noCurrentReaction && reaction == .Neutral) || (!noCurrentReaction && reaction == post.selfReact) {
                    reactButton.selected        = true
                    cell.selectedReactionButton = reactButton
                }
                
                reactButton.addTarget(self, action: #selector(FeedViewController.reactionTypeTouchUpInside(_:)), forControlEvents: .TouchUpInside)
                
                let reactImageView          = UIImageView(frame: reactFrame)
                reactImageView.image        = Post.getReactionImage(reaction)
                reactImageView.contentMode  = .ScaleAspectFit
                
                reactButton.addSubview(reactImageView)
                
                cell.actionView.addSubview(reactButton)
                
                xPos += widthPerButton
            }

            actionViewHeight = (rows * heightPerButton)

        }
        
        cell.reactButton.active = !cell.reactButton.active
        
        // update height
        post.actionViewHeight                       = actionViewHeight
        cell.actionViewHeightConstraint.constant    = actionViewHeight
        
        self.updateCellHeight(cell, post: post)
    }
    
    func reactionViewTouchUpInside(sender: UITapGestureRecognizer){
        
        if let reactView = sender.view where reactView.tag > 0 {
            
            
            let loadMaskVC = LoadingMaskViewController.getStoryboardInstance()
            
            loadMaskVC.queueLoadingMask(reactView, timeBeforeShowingMask: 0.1, loadingViewAlpha: 0.05, showCompletion: nil)
            
            TreemFeedService.sharedInstance.getPostReactions(
                CurrentTreeSettings.sharedInstance.treeSession
                , postID: reactView.tag
                , success: {
                    data in
                    
                    loadMaskVC.cancelLoadingMask({
                        if let users = Post.getUserReactions(data) {
                            
                            let popover = MembersListPopoverViewController.getStoryboardInstance()
                            
                            popover.users = users
                            
                            let sender = reactView
                            
                            if let popoverMenuView = popover.popoverPresentationController {
                                popoverMenuView.permittedArrowDirections    = .Up
                                popoverMenuView.delegate                    = self
                                popoverMenuView.sourceView                  = sender
                                popoverMenuView.sourceRect                  = CGRect(x: reactView.bounds.width * 0.5, y: reactView.bounds.height * 0.5, width: 0, height: 0)
                                popoverMenuView.backgroundColor             = UIColor.whiteColor()
                                
                                self.presentViewController(popover, animated: true, completion: nil)
                            }
                        }
                    })
                    
                }
                , failure: {
                    error, wasHandled in
                    
                    if !wasHandled {
                        loadMaskVC.cancelLoadingMask({
                            CustomAlertViews.showGeneralErrorAlertView()
                        })
                    }
                }
            )
        }
    }
    
    // touch on emoji to react to post
    func reactionTypeTouchUpInside(sender: ReactionButton) {
        // get post/cell for index
        let indexPath = NSIndexPath(forRow: sender.tag, inSection: 0)
        
        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? FeedTableViewCell,
            post = self.items[sender.tag] as? Post
        {
            // ignore if selecting the already selected reaction
            if let reaction = sender.reaction where sender.reaction != cell.selectedReactionButton?.reaction {
                // deselect other button if selected
                if let previousReaction = cell.selectedReactionButton {
                    previousReaction.selected = false
                }
                
                // select current button
                sender.selected = true
                
                // assign new selected button
                cell.selectedReactionButton = sender
                
                // if removing any post reaction
                if (reaction == .Neutral) {
                    self.removeReaction(cell, post: post, indexPath: indexPath)
                }
                // else if setting/changing post reaction
                else {
                    self.setReaction(cell, post: post, indexPath: indexPath, reaction: sender.reaction!)
                }
            }
            // reaction is same and no reaction entered
            else if sender.reaction == nil {
                sender.selected = true
                
                cell.resetActionView()
                cell.actionViewHeightConstraint.constant = 0
                post.actionViewHeight = 0
                
                // close reaction view (no service calls needed)
                self.updateCellHeight(cell, post: post, completion: {
                    _ in
                    sender.selected = false
                })
            }
        }
    }
    
    private func removeReaction(cell: FeedTableViewCell, post: Post, indexPath: NSIndexPath) {
        let loadMaskVC = LoadingMaskViewController.getStoryboardInstance()
        
        loadMaskVC.queueLoadingMask(cell.actionView, timeBeforeShowingMask: 0.1, showCompletion: nil)
        loadMaskVC.view.backgroundColor = AppStyles.sharedInstance.lightGrayColor
        loadMaskVC.activityColor        = AppStyles.sharedInstance.darkGrayColor

        TreemFeedService.sharedInstance.removePostReaction(
            CurrentTreeSettings.sharedInstance.treeSession,
            postID: post.postId,
            success: {
                data in

                // update reaction counts in post
                post.changeSelfReaction(nil)

                cell.resetActionView()
                cell.actionViewHeightConstraint.constant = 0
                post.actionViewHeight = 0

                // check that cell hasn't been reused
                if (cell.tag == indexPath.row) {
                    self.checkPostReactionCounts(cell, post: post)

                    self.updateCellHeight(cell, post: post, completion: {
                        _ in
                        
                        cell.reactButton.active = false
                    })
                }
            },
            failure: {
                error, wasHandled in

                if !wasHandled {
                    // cancel loading mask and return to view with alert
                    loadMaskVC.cancelLoadingMask({
                        CustomAlertViews.showGeneralErrorAlertView()
                    })
                }
            }
        )
    }
    
    private func setReaction(cell: FeedTableViewCell, post: Post, indexPath: NSIndexPath, reaction: Post.ReactionType) {
        let loadMaskVC = LoadingMaskViewController.getStoryboardInstance()

        loadMaskVC.queueLoadingMask(cell.actionView, timeBeforeShowingMask: 0.1, showCompletion: nil)
        loadMaskVC.view.backgroundColor = AppStyles.sharedInstance.lightGrayColor
        loadMaskVC.activityColor        = AppStyles.sharedInstance.darkGrayColor
        
        TreemFeedService.sharedInstance.setPostReaction (
            CurrentTreeSettings.sharedInstance.treeSession,
            postID: post.postId,
            reaction: reaction,
            success: {
                data in
                
                // update reaction counts in post
                post.changeSelfReaction(reaction)
                
                cell.resetActionView()
                cell.actionViewHeightConstraint.constant = 0
                post.actionViewHeight = 0
                
                // check that cell hasn't been reused
                if (cell.tag == indexPath.row) {
                    self.checkPostReactionCounts(cell, post: post)

                    self.updateCellHeight(cell, post: post, completion: {
                        _ in
                        
                        cell.reactButton.active = false
                    })
                }
            },
            failure: {
                error, wasHandled in
                
                if !wasHandled {
                    // cancel loading mask and return to view with alert
                    loadMaskVC.cancelLoadingMask({
                        CustomAlertViews.showGeneralErrorAlertView()
                    })
                }
            }
        )
    }
    
    //# MARK: - Post Delegate Methods
    
    func postWasDeleted(postID: Int) {
        self.postDelegate?.postWasDeleted(postID)
    }
    
    func postWasUpdated(post: Post) {
        self.postDelegate?.postWasUpdated(post)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    func loadUrl(sender: UrlPreviewTapGestureRecognizer) {
        if let linkData = sender.linkData {
            if linkData.linkUrl == nil && linkData.linkDescription == nil && linkData.linkImage != nil {
                let vc = MediaImageViewController.getStoryboardInstance()
                
                if let cUrl = linkData.linkImage {
                    vc.contentUrl = NSURL(string: cUrl)
                    
                    self.navigationController?.presentViewController(vc, animated: true, completion: nil)
                }
            }
            else if let linkUrl = linkData.linkUrl {
                self.showWebBrowser(linkUrl, defaultTitle: linkData.linkTitle)
            }
        }
    }
    
    // get's called by outside VCs
    func scrollToTop(){
        // make sure we have a row at 0 to scroll to (make sure the feed isn't empty)
        if (self.items.indices.contains(0)){
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true, completion: ({
                self.refresh(self.refreshControl!)
            }))
        }
    }
    
    //# MARK: Attributed Label Delegate Functions
    func attributedLabel(label: TTTAttributedLabel, didSelectLinkWithURL url: NSURL!) {
        self.showWebBrowser(url.absoluteString)
    }
    
    private func showWebBrowser(url: String, defaultTitle: String? = nil) {
        let vc = WebBrowserViewController.getStoryboardInstance()
        
        vc.webUrl           = url
        vc.defaultTitle     = defaultTitle
        vc.branchColor      = CurrentTreeSettings.sharedInstance.treeSession.currentBranch?.color ?? AppStyles.sharedInstance.darkGrayColor
        vc.isPrivateMode    = CurrentTreeSettings.sharedInstance.currentTree == TreeType.Public
        vc.transitioningDelegate = AppStyles.directionUpViewAnimatedTransition
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
}