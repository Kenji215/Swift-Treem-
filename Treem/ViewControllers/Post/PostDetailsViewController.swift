//
//  PostDetailsViewController.swift
//  Treem
//
//  Created by Kevin Novak on 1/4/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import KMPlaceholderTextView
import CLImageEditor

class PostDetailsViewController : UIViewController, UITextViewDelegate, MediaPickerDelegate, CLImageEditorDelegate {

    var post                    : Post! {
        didSet {
            self.postId = post.postId
        }
    }
    var postUsers               : Dictionary<Int, User>!
    var postId                  : Int                   = 0
    var parentCommentsButton    : UIButton?             = nil       // used to update the parent button's count
    var inNavController         : Bool                  = false
    var isAddingComment         : Bool                  = false

    @IBOutlet weak var headerBar: UIView!
    @IBOutlet weak var postScrollView: UIScrollView!

    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var postContainerView: UIView!
    @IBOutlet weak var postContainerViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var repliesTableContainer: UIView!
    @IBOutlet weak var repliesTableContainerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var addReplyTextField: KMPlaceholderTextView!
    @IBOutlet weak var addReplyButton: UIButton!

    @IBOutlet weak var addReplyView: UIView!
    
    @IBOutlet weak var addReplyViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var replyImageView: UIView!
    
    @IBOutlet weak var replyImageViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var horizontalDividerTop: UIView!
    
    @IBAction func attachementButtonTouchUpInside(sender: UIButton) {
        
        let mediaPicker = MediaAddOptionsViewController.getStoryboardInstance()
        
        mediaPicker.delegate                = self
        mediaPicker.transitioningDelegate   = self.fadeInTransition
        mediaPicker.referringButton         = sender
        
        self.presentViewController(mediaPicker, animated: true, completion: nil)
    }
    
    private let loadingMaskViewController = LoadingMaskViewController.getStoryboardInstance()
    private let loadingMaskOverlayViewController    = LoadingMaskViewController.getStoryboardInstance()

    private var embeddedFeedViewController              : FeedViewController!
    private var embeddedPostCommentsTableViewController : PostCommentsTableViewController!
    
    // image picker variables
    private let fadeInTransition = FadeInAnimatedTransition()
    private var contentItemExtension: TreemContentService.ContentFileExtensions?
    private var contentMediaUpload : ContentItemUpload? = nil
    private var contentMediaDownload : ContentItemDownload? = nil
    private var replyImagePreview : UIImageView? = nil
    private var imageEditor : CLImageEditor? = nil
    private var selectedImage : UIImage? = nil
    private var uploadInBackground: Bool = false
    
    var stringComment : String = ""
    
    enum MediaType {
        case None
        case Image
        case Video
    }
    
    private var mediaContentType : MediaType = .None
    
    var parentView                  : UIView? = nil
    
    var branchViewDelegate: BranchViewDelegate? = nil
    
    static func getStoryboardInstance() -> PostDetailsViewController {
        return UIStoryboard(name: "PostDetails", bundle: nil).instantiateInitialViewController() as! PostDetailsViewController
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbedFeedSegue" {
            let destVC = segue.destinationViewController as! FeedViewController
            
            destVC.singlePostLoad   = true
            destVC.delegate         = self
            
            self.embeddedFeedViewController = destVC
        }
        else if segue.identifier == "EmbedCommentsSegue" {
            let destVC = segue.destinationViewController as! PostCommentsTableViewController
            
            destVC.postId                   = self.post?.postId ?? self.postId
            destVC.detailsDelegate          = self
            destVC.hasLoadingMask           = self.inNavController // only show loading mask when coming feed
            destVC.onTableViewFrameChange   = self.onTableViewFrameChange
            
            destVC.modalPresentationCapturesStatusBarAppearance = true

            self.embeddedPostCommentsTableViewController = segue.destinationViewController as! PostCommentsTableViewController
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // disable scrolling in post comments vc
        self.embeddedPostCommentsTableViewController.useRefreshControl  = true
        self.embeddedPostCommentsTableViewController.scrollingEnabled   = false
        
        self.addReplyTextField.delegate = self
        
        
        // disable comment button initially
        AppStyles.sharedInstance.setButtonDefaultStyles(self.addReplyButton)
        self.updateReplyButton()
        
        // hide the top divider for the image preview
        self.horizontalDividerTop.backgroundColor = UIColor.clearColor()
        
        // update styles depending if nested in nav vc or not
        if self.inNavController {
            self.headerViewHeightConstraint.constant = 0
            
            self.closeButton.hidden = true
        }
        else {
            self.headerBar.backgroundColor = AppStyles.sharedInstance.subBarBackgroundColor
            
            self.closeButton.tintColor = AppStyles.sharedInstance.whiteColor
            
            self.closeButton.hidden = false
        }
        
        // post identifier passed
        if (self.post != nil) || (self.postId > 0) {
            // object passed already
            if let post = self.post {
                // set postID for comments load
                self.postId = post.postId
                
                self.displayPost()
            }
            // otherwise retrieve individual post details
            else {
                // show loading mask over post area
                self.getIndividualPost(self.postId)
            }
            
            self.addReplyTextField.delegate = self
            self.addReplyTextField.textContainer.lineFragmentPadding = 0
            self.addReplyTextField.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10)
            
            let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(PostDetailsViewController.dismissKeyboard))
            dismissKeyboardGesture.cancelsTouchesInView = false
            
            self.view.addGestureRecognizer(dismissKeyboardGesture)
        }
        else {
            self.closeDetailsView()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.branchViewDelegate?.toggleBackButton(true, onTouchUpInside: self.toggleBackButton)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // add observers for showing/hiding keyboard
        let notifCenter = NSNotificationCenter.defaultCenter()
        
        notifCenter.addObserver(self, selector: #selector(PostDetailsViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // remove observers
        let notifCenter = NSNotificationCenter.defaultCenter()
        notifCenter.removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    //Display the post in the container at the top
    func displayPost() {
        let vc = self.embeddedFeedViewController

        // add users
        vc.postUsers = self.postUsers
        
        // set post object directly
        vc.setData([self.post])

        // adjust height constraint
        self.postContainerViewHeightConstraint.constant = post.cellHeightLayout
    }

    // handle moving elements when keyboard is pulled up
    func keyboardWillChangeFrame(notification: NSNotification){
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.addReplyViewBottomConstraint)
        
        // scroll to bottom while adjusting for keyboard
        self.scrollToBottom()
    }
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.closeDetailsView()
    }

    //Tapping the "Post" button for adding a reply - attempt to add the reply.
    //On success, reload the replies table. On error, leave the message there and alert that something went wrong
    @IBAction func postReplyTouchUpInside(sender: AnyObject) {
        
        self.stringComment = (self.addReplyTextField.text ?? "").trim()
        
        if self.mediaContentType != .None {
            self.uploadContentItem()
        }
        else {
            self.buildReply()
        }
    }
    
    private func buildReply() {
        
        if (self.stringComment.characters.count > 0 || self.mediaContentType != .None) {
            self.addReplyButton.enabled = false
            
            if !self.loadingMaskViewController.isViewLoaded() {
                // show loading mask over post area
                self.loadingMaskViewController.queueLoadingMask(self.addReplyView, showCompletion: nil)
            }
            
            let replyUrl = self.stringComment.parseForUrl()
            
            if !replyUrl.isEmpty {
                TreemFeedService.sharedInstance.getUrlParse(
                    CurrentTreeSettings.sharedInstance.treeSession,
                    postUrl: replyUrl,
                    success: {
                        data in
                        
                        let urlData = WebPageData.init(data: data)
                        
                        if urlData.linkUrl != nil || urlData.linkImage != nil {
                            self.setReply(urlData)
                        }
                        else {
                            self.setReply()
                        }
                    },
                    failure: {
                        _ in
                        
                        self.setReply()
                    }
                )
                
            }
            else {
                self.setReply()
            }
        }
    }
    
    private func onTableViewFrameChange(repliesTable: UITableView) {
        repliesTable.layoutIfNeeded()               // call before to ensure accurate content size height
        
        let contentSize = repliesTable.contentSize.height
        
        self.repliesTableContainerHeightConstraint.constant = contentSize > 0 ? contentSize : repliesTable.frame.height

        self.repliesTableContainer.layoutIfNeeded({
            if self.isAddingComment {
                self.scrollToBottom()
            }
        })
    }

    private func setReply(urlData: WebPageData? = nil) {
        let reply = Reply()
        
        reply.comment = self.stringComment
        
        if self.mediaContentType != .None {
            reply.contentItems = [self.contentMediaDownload!]
        }
        
        if let urlData = urlData {
            reply.replyUrlData = urlData
        }
        
        TreemFeedService.sharedInstance.setReply(
            CurrentTreeSettings.sharedInstance.treeSession,
            postID: self.post.postId,
            reply: reply,
            failureCodesHandled: nil,
            success: {
                data in
                
                // Clear the textbox
                self.addReplyTextField.text = ""
                self.addReplyButton.enabled = true
                
                // clear all content details
                if self.mediaContentType != .None {
                    self.contentMediaUpload = nil
                    self.contentMediaDownload = nil
                    self.mediaContentType = .None
                    self.replyImagePreview!.image = nil
                    self.replyImageViewHeightConstraint.constant = 0
                    // re-hide the separator
                    self.horizontalDividerTop.backgroundColor = UIColor.clearColor()
                    
                    self.addReplyView.layoutIfNeeded()
                }
                
                self.stringComment = ""
                
                // Reload comments
                self.isAddingComment = true
                self.embeddedPostCommentsTableViewController.refresh(self.embeddedPostCommentsTableViewController.refreshControl!)
                
                self.updateReplyButton()
                
                self.loadingMaskViewController.cancelLoadingMask(nil)
                
                if self.uploadInBackground {
                    
                    if let _ = data["r_id"].int {
                        InAppNotifications.sharedInstance.addInAppAlert(Alert.Reasons.REPLY_UPLOAD_FINISHED, id: self.postId)
                        
                    }
                }
                
                // on success increment comment count
                self.updateCurrentCommentCount(1)
            },
            failure: {
                error, wasHandled in
                
                self.loadingMaskViewController.cancelLoadingMask({
                    // show alert
                    CustomAlertViews.showCustomAlertView(
                        title: Localization.sharedInstance.getLocalizedString("comment_error_title", table: "PostDetails")
                        , message: Localization.sharedInstance.getLocalizedString("comment_error_message", table: "PostDetails")
                        , fromViewController: self
                    )
                })
                
                // Re-enable commenting
                self.addReplyButton.enabled = true
            }
        )
    }
    
    func toggleBackButton(){
        self.closeDetailsView()
    }
    
    func closeDetailsView(completion: (()->())? = nil) {
        if let navVC = self.navigationController where self.inNavController {
            navVC.popViewControllerAnimated(true, completion: completion)
        }
        else {
            self.dismissViewControllerAnimated(true, completion: completion)
        }
        
        self.branchViewDelegate?.setDefaultTitle?()
    }

    func dismissKeyboard() {
        self.view.endEditing(true)
        self.addReplyTextField.resignFirstResponder()
    }

    // Upon tapping the "Add comment" button, scroll down to the textfield and focus on it (bringing up the keyboard).
    func focusAddReplyTextField() {
        self.addReplyTextField.becomeFirstResponder()
    }
    
    func replyWasRemoved() {
        self.updateCurrentCommentCount(-1)
        
        self.isAddingComment = false
    }
    
    func postContainerHeightUpdated(height: CGFloat, animationDuration: NSTimeInterval) {
        self.postContainerViewHeightConstraint.constant = height
        
        self.view.setNeedsLayout()
        
        UIView.animateWithDuration(animationDuration, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    private func getIndividualPost(post_id: Int) {
        let vc = self.embeddedFeedViewController
        
        vc.showLoadingMask()
        
        TreemFeedService.sharedInstance.getPostDetails(
            CurrentTreeSettings.sharedInstance.treeSession,
            postID: post_id,
            success: {
                data in
                
                if (data.count > 0) {
                    let postDetails = Post.getPostDetailsFromData(data)

                    // store post object
                    self.post           = postDetails.post
                    self.post.postId    = post_id
                    
                    // add details to embedded feed
                    vc.postUsers = postDetails.users
                    vc.setData([postDetails.post])
                    
                    // adjust height constraint
                    self.postContainerViewHeightConstraint.constant = postDetails.post.cellHeightLayout

                    vc.cancelLoadingMask()
                }
                else {
                    //The post ID passed was invalid (or we otherwise got no data), so back out of the view
                    self.closeDetailsView()
                }
            },
            failure: {
                error, wasHandled in
                
                vc.cancelLoadingMask()
            }
        )
    }
    
    func textViewDidChange(textView: UITextView) {
        
        self.updateReplyButton()
        
        self.addReplyView.layoutIfNeeded()
    }
    
    func updateCurrentCommentCount(countAdjustment: Int){
        if let post = self.post {
            post.commentCount += countAdjustment
            
            self.embeddedFeedViewController?.setCommentCount(post.postId, count: post.commentCount)
         
            // if we have a parent button from the feed, update the count
            if let button = self.parentCommentsButton {
                var countText: String
                
                if(post.commentCount > 0){
                    countText = " (" + post.commentCount.description + ")"
                }
                else {
                    countText = ""
                }
                
                UIView.performWithoutAnimation({
                    button.setTitle("Comment" + countText, forState: .Normal)
                    button.layoutIfNeeded()
                })
            }
        }
    }
    
    private func scrollToBottom(){
        // only scroll when there is something to scroll
        if(self.postScrollView.contentSize.height > self.postScrollView.bounds.size.height){
            self.postScrollView.setContentOffset(CGPointMake(0, self.postScrollView.contentSize.height - self.postScrollView.bounds.size.height), animated: true)
        }
    }
    
    private func showLoadingMask(maskActionView: Bool=false, completion: (() -> Void)?=nil) {
        dispatch_async(dispatch_get_main_queue()) {
            // if we're masking the send chat view it means we're uploading, show the progress mask instead
            if(maskActionView){
                var viewToMask = self.view
                if (self.parentView != nil) { viewToMask = self.parentView! }
                self.loadingMaskViewController.queueProgressMask(viewToMask, showCompletion: completion)
            }
            else{
                let vc : UIView = self.view
                self.loadingMaskViewController.queueLoadingMask(vc, loadingViewAlpha: 1.0, showCompletion: completion)
            }
        }
    }
    
    private func cancelLoadingMask(completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.cancelLoadingMask({
                self.loadingMaskOverlayViewController.cancelLoadingMask(completion)
            })
        }
    }
    
    private func uploadContentItem(){
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            
            self.showLoadingMask(true)
            
            let contentUploadManager = TreemContentServiceUploadManager(
                treeSession         : CurrentTreeSettings.sharedInstance.treeSession,
                contentItemUpload   : self.contentMediaUpload!,
                success : {
                    (data) in
                    
                    self.cancelLoadingMask({
                        var contentItem: ContentItemDownload
                        
                        if self.mediaContentType == .Video {
                            contentItem = ContentItemDownload(videoObj: ContentItemDownloadVideo(data: data))
                        }
                        else if self.mediaContentType == .Image {
                            contentItem = ContentItemDownload(imageObj: ContentItemDownloadImage(data: data))
                        }
                        else {
                            contentItem = ContentItemDownload(data: data)
                        }
                        
                        self.contentMediaDownload = contentItem
                        
                        self.buildReply()
                    })
                },
                failure : {
                    (error, wasHandled) in
                    
                    self.cancelLoadingMask({
                        // unsupported content type
                        if error == TreemServiceResponseCode.GenericResponseCode2 {
                            self.showUnsupportedTypeAlert()
                        }
                            // attachment too large
                        else if error == TreemServiceResponseCode.GenericResponseCode3 {
                            CustomAlertViews.showCustomAlertView(title: "File too large", message: "Maximum upload size is " + String(TreemContentServiceUploadManager.maxContentGigaBytes) + " gb.")
                        }
                        else if !wasHandled {
                            CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                        }
                    })
                    
                },
                progress : {
                    // TODO: show progress bar over upload item
                    (percentComplete, wasCancelled) in
                    
                    self.loadingMaskViewController.updateProgress(percentComplete)
                },
                multiStarted: {self.multiUploadStarted()}
            )
            
            contentUploadManager.startUpload()
        }
    }
    
    private func showUnsupportedTypeAlert() {
        var typesList = ""
        
        for type in TreemContentService.ContentFileExtensions.cases {
            typesList += "-" + type
        }
        
        CustomAlertViews.showCustomAlertView(title: "Unsupported type"
            , message: "Image/video uploaded is not a supported type. Supported types include:" + typesList
            , fromViewController: self
            , willDismiss: nil)
    }
    
    // --------------------------------- //
    //# Mark: Media Picker Delegate Functions
    // --------------------------------- //
    
    func cancelSelected() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imageSelected(image: UIImage, fileExtension: TreemContentService.ContentFileExtensions, picker: UIImagePickerController) {
        
        self.contentItemExtension = fileExtension
        self.selectedImage = image
        self.mediaContentType = .Image
        
        
        self.loadReplyImage(image)
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func videoSelected(fileURL: NSURL, orientation: ContentItemOrientation, fileExtension: TreemContentService.ContentFileExtensions, picker: UIImagePickerController) {
        
        let itemUpload = ContentItemUpload(fileExtension: fileExtension, fileURL: fileURL)
        itemUpload.contentType = .Video
        itemUpload.orientation = orientation
        
        // generate thumbnail from video file URL
        let asset           = AVURLAsset(URL: fileURL, options: nil)
        let imgGenerator    = AVAssetImageGenerator(asset: asset)
        
        imgGenerator.appliesPreferredTrackTransform = true  // create the thumbnail using the video's orientation
        
        self.contentMediaUpload = itemUpload
        self.mediaContentType = .Video
        
        do {
            let cgImage = try imgGenerator.copyCGImageAtTime(CMTimeMake(0, 1), actualTime: nil)
            
            self.loadReplyImage(UIImage(CGImage: cgImage), isVideoThumbnail: true)
        }
        catch {
            // create blank image just to show something if thumbnail could not be created
            self.loadReplyImage(UIImage().getImageWithColor(UIColor.whiteColor()), isVideoThumbnail: true)
        }

        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imageEditor(editor: CLImageEditor!, didFinishEdittingWithImage image: UIImage!){
        
        let tempImage = image.rotateCameraImageToOrientation(image, maxResolution: AppSettings.max_post_image_resolution)
        
        self.dismissViewControllerAnimated(false, completion: nil)
        
        self.loadReplyImage(tempImage)
    }
    
    private func loadReplyImage(image: UIImage, isVideoThumbnail: Bool = false) {
        // scale the image to fit the view
        let size = UIImage.getResizeImageScaleSize(CGSize(width: self.view.frame.width, height: self.view.frame.height * 0.3), oldSize: image.size)
        
        replyImagePreview = UIImageView(image: image)
        replyImagePreview!.contentMode   = .ScaleAspectFit
        replyImagePreview!.frame         = CGRectMake((self.view.frame.width / 2) - (size.width / 2), 0, size.width, size.height)
        
        // add delete button in image
        let deleteButton = AppStyles.sharedInstance.getEditImageButton(nil, image: "Close")
        
        let height : CGFloat = 30
        let width = 10 + (deleteButton.imageView?.frame.width ?? 0)
        
        deleteButton.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        deleteButton.frame = CGRectMake(replyImagePreview!.frame.width - width, 0, width, height)
        
        // add delete image button target action
        deleteButton.addTarget(self, action: #selector(PostDetailsViewController.removeImageFromReplyView(_:)), forControlEvents: .TouchUpInside)
        
        if !isVideoThumbnail {
            let editImageButton = AppStyles.sharedInstance.getEditImageButton("Edit", image: "Edit")
            
            editImageButton.setNeedsLayout()
            editImageButton.layoutIfNeeded()
            
            // TODO: Calculate width of text on layout subviews instead
            let editWidth = 34 + (editImageButton.imageView?.frame.width ?? 0) + (editImageButton.titleLabel?.frame.width ?? 0)
            
            editImageButton.frame = CGRectMake(replyImagePreview!.frame.width - editWidth, replyImagePreview!.frame.height - height, editWidth, height)
            
            editImageButton.addTarget(self, action: #selector(PostViewController.editImageOnPost(_:)), forControlEvents: .TouchUpInside)
            
            replyImagePreview!.addSubview(editImageButton)
        }
        
        // if a thumbnail add the video icon overlay to indicate so
        if isVideoThumbnail {
            let image                   = UIImage(named: "Video")
            
            let videoOverlayImageView   = UIImageView(image: image)
            
            videoOverlayImageView.contentMode       = .ScaleAspectFit
            videoOverlayImageView.tintColor         = UIColor.whiteColor().colorWithAlphaComponent(0.25)
            videoOverlayImageView.backgroundColor   = UIColor.darkGrayColor().colorWithAlphaComponent(0.5)
            videoOverlayImageView.frame             = CGRectMake(0,0,size.width,size.height)
            
            replyImagePreview!.addSubview(videoOverlayImageView)
        }
        
        replyImagePreview!.userInteractionEnabled = true // imageView has disabled by default
        replyImagePreview!.addSubview(deleteButton)
        
        self.selectedImage = image
        
        if self.mediaContentType == .Image  {
            self.contentMediaUpload = ContentItemUploadImage(fileExtension: self.contentItemExtension!, image: image )
        }
        
        // add imageview
        
        self.replyImageViewHeightConstraint.constant = size.height
        
        self.horizontalDividerTop.backgroundColor = UIColor.lightGrayColor()
        
        self.replyImageView.addSubview(replyImagePreview!)
        
        self.updateReplyButton()
        
        self.replyImageView.layoutIfNeeded()
        
        self.view.layoutIfNeeded()
    }
    
    func removeImageFromReplyView(sender: UIButton) {
        // get imageview in parent
        if let superview = sender.superview {
            // adjust height constraint of attachments (currently only one attachment allowed)
            self.replyImageViewHeightConstraint.constant = 0
            
            UIView.animateWithDuration(
                AppStyles.sharedInstance.viewAnimationDuration,
                animations: {
                    () -> Void in
                    
                    self.replyImageView!.layoutIfNeeded()
                },
                completion: {
                    (Bool) -> Void in
                    
                    self.contentMediaUpload = nil
                    
                    self.contentMediaDownload = nil
                    
                    self.mediaContentType = .None
                    self.replyImagePreview!.image = nil
                    // re-hide the separator
                    self.horizontalDividerTop.backgroundColor = UIColor.clearColor()
                    
                    self.addReplyView.layoutIfNeeded()
                    
                    self.updateReplyButton()
                }
            )
        }
    }
    
    func updateReplyButton(){
        let enabled = ((self.addReplyTextField.text ?? "").trim().characters.count > 0) || self.mediaContentType != .None
        
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.addReplyButton, enabled: enabled, withAnimation: true, showDisabledOutline: true)
    }
    
    func editImageOnPost(sender: UIButton) {
        
        self.imageEditor = ImageEditor(image: self.selectedImage!.rotateCameraImageToOrientation(self.selectedImage!, maxResolution: AppSettings.max_post_image_resolution), delegate: self)
        
        self.presentViewController(imageEditor!, animated: true, completion: nil)
    }
    
    private func multiUploadStarted(){
        
        // multi upload is now running in the back ground, free up the mask so the user can do something else
        self.uploadInBackground = true
        
        self.addReplyTextField.text = ""

        self.replyImagePreview!.image = nil
        self.replyImageViewHeightConstraint.constant = 0
        // re-hide the separator
        self.horizontalDividerTop.backgroundColor = UIColor.clearColor()
        
        // set the reply button back up
        
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.addReplyButton, enabled: false, withAnimation: false, showDisabledOutline: true)
        
        self.loadingMaskViewController.cancelLoadingMask({
            let infoVC = InfoMessageViewController.getStoryboardInstance()
            infoVC.infoMessage = "Your reply is now uploading, we'll send a notification when it's ready."
            infoVC.onDismiss = nil
            
            self.presentViewController(infoVC, animated: true, completion: nil)
        })
        
        self.embeddedPostCommentsTableViewController.refresh(self.embeddedPostCommentsTableViewController.refreshControl!)
    }
}
