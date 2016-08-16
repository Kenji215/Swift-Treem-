//
//  PostViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/4/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import AssetsLibrary
import AVFoundation
import KMPlaceholderTextView
import MobileCoreServices
import UIKit
import CLImageEditor

class PostViewController : UIViewController, UITextViewDelegate, SeedingMembersTableViewDelegate, CLImageEditorDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate, MediaPickerDelegate {
    
    //# MARK: - View Outlet Views
    
    @IBOutlet weak var actionButtonContainerView        : UIView!
    @IBOutlet weak var cameraButton                     : UIButton!
    @IBOutlet weak var deleteButton                     : UIButton!
    @IBOutlet weak var divider3                         : UIView!
    @IBOutlet weak var divider4                         : UIView!
    @IBOutlet weak var expiresDatePicker                : UIDatePicker!
    @IBOutlet weak var expiresOptionsView               : UIView!
    @IBOutlet weak var oneTimeViewSwitch                : UISwitch!
    @IBOutlet weak var imageAttachedView                : UIView!
    
    @IBOutlet weak var PostUrlPreviewView               : UIView!
    @IBOutlet weak var postButton                       : UIButton!
    @IBOutlet weak var postTextView                     : KMPlaceholderTextView!
    @IBOutlet weak var postMaskView                     : UIView!
    @IBOutlet weak var scrollContentView                : UIView!
    @IBOutlet weak var scrollView                       : UIScrollView!
    @IBOutlet weak var shareableSwitch                  : UISwitch!
    @IBOutlet weak var tagButton                        : UIButton!
    @IBOutlet weak var taggedMembersView                : UIView!
    @IBOutlet weak var expiresSwitch                    : UISwitch!
    
    @IBOutlet weak var taggedLabel: UILabel!

    //# MARK: - View Outlet View Consraints
 
    @IBOutlet weak var deleteButtonTopConstraint        : NSLayoutConstraint!
    @IBOutlet weak var deleteButtonWidthConstraint      : NSLayoutConstraint!
    @IBOutlet weak var deleteButtonBottomConstraint     : NSLayoutConstraint!
    @IBOutlet weak var deleteButtonLeadingConstraint    : NSLayoutConstraint!
    @IBOutlet weak var postButtonLeadingConstraint      : NSLayoutConstraint!
    @IBOutlet weak var actionContainerBottomConstraint  : NSLayoutConstraint!
    @IBOutlet weak var scrollContentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var divider3HeightConstraint         : NSLayoutConstraint!
    @IBOutlet weak var divider4HeightConstraint         : NSLayoutConstraint!
    @IBOutlet weak var expiresOptionsHeightConstraint   : NSLayoutConstraint!
    @IBOutlet weak var imageAttachedViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var taggedMembersViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var PostUrlPreviewViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var attachOptionsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var taggedLabelHeightConstraint: NSLayoutConstraint!
    

    //# MARK: - View Outlet Events
    
    @IBAction func addMediaTouchUpInside(sender: UIButton) {
        
        let mediaPicker = MediaAddOptionsViewController.getStoryboardInstance()

        mediaPicker.delegate                = self
        mediaPicker.transitioningDelegate   = self.fadeInTransition
        mediaPicker.referringButton         = sender
        
        self.presentViewController(mediaPicker, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    @IBAction func deleteButtonTouchUpInside(sender: AnyObject) {
        CustomAlertViews.showCustomConfirmView(
            title: "Delete Post?",
            message: "Deleting the post will also remove all comments, shares, and reactions made on the post. Are you sure you want to delete it?",
            fromViewController: self,
            yesHandler: {
                _ in
                
                self.loadingDataViewChanges()

                self.deletePost()
            },
            noHandler: nil
        )
    }
    
    @IBAction func expiresSwitchValueChanged(sender: UISwitch) {
        self.toggleExpiresDatePicker(sender.on, showAnimation: true)
    }
    
    @IBAction func switchTouchUpInside(sender: AnyObject) {
        // ios bug? doesn't dismiss keyboard on switch tap
        self.dismissKeyboard()
    }
    
    
    @IBAction func postButtonTouchUpInside(sender: AnyObject) {
        self.loadingDataViewChanges(true)
        
        let existingPost = (self.editPostId > 0)
        let post = self.editPost ?? Post()
        
        // this will trim and remove empty line breaks at the beginning and end of the text entered
        let message = (self.postTextView.text ?? "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if message.characters.count > 0 {
            post.message = message
        }
        
        var isNewContent = (self.attachedItems?.count > 0)
        
        // this will be hit when the post has been edited and we are changing images
        if (post.contentItems != nil) && (isNewContent) {
            isNewContent = (self.attachedItems![0].contentID != postOriginalContentId)
        }
        
        post.branchID    = CurrentTreeSettings.sharedInstance.currentBranchID
        post.viewOnce    = self.oneTimeViewSwitch.on
        post.shareable   = self.shareableSwitch.on
        
        if self.expiresSwitch.on {
            post.expires = expiresDatePicker.date
        }
        
        post.postUrlData = postData
        self.editPost?.postUrlData = postData
        
        // disable fields
        self.postTextView.editable = false
        
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.postButton, enabled: false, withAnimation: false, showDisabledOutline: false)
        
        post.taggedUsers = self.taggedIDs
        
        // if the image was edited
        if ((self.imageEdited == true) && (self.selectedImage != nil)) {
            
            let assetsLibrary = ALAssetsLibrary()
            
            assetsLibrary.writeImageToSavedPhotosAlbum(self.selectedImage!.CGImage!, orientation: ALAssetOrientation(rawValue: self.selectedImage!.imageOrientation.rawValue)!,
                completionBlock: { (referenceUrl, error) -> Void in
                    
                    #if DEBUG
                        print("photo saved to asset")
                        print(referenceUrl)   // assets-library://asset/asset.JPG?id=CCC70B9F-748A-43F2-AC61-8755C974EE15&ext=JPG
                    #endif
                    
                    assetsLibrary.assetForURL(referenceUrl,
                        
                        resultBlock: {
                            asset in
                            
                            let fileName = asset.defaultRepresentation().filename()
                            
                            #if DEBUG
                                print("Selected file:\(fileName)")
                            #endif
                            
                            
                            let fileExtension = TreemContentService.ContentFileExtensions.fromString(fileName.getPathNameExtension())
                            
                            // single select for the time being
                            self.attachedItems = [ContentItemUploadImage(fileExtension: fileExtension, image: self.selectedImage!)!]
                            
                            // if adding new content
                            if self.attachedItems?.count > 0 {
                                // need to upload contentfirst
                                if let contentItemUpload = self.attachedItems![0] as? ContentItemUpload {
                                    let contentType = contentItemUpload.contentType
                                    
                                    let contentUploadManager = TreemContentServiceUploadManager(
                                        treeSession         : CurrentTreeSettings.sharedInstance.treeSession,
                                        contentItemUpload   : contentItemUpload,
                                        success : {
                                            (data) in
                                            
                                            var contentItem: ContentItemDownload
                                            
                                            if contentType == .Video {
                                                contentItem = ContentItemDownloadVideo(data: data)
                                                contentItem.contentType = .Video // not passed back explicitly in response
                                            }
                                            else if contentType == .Image {
                                                contentItem = ContentItemDownloadImage(data: data)
                                                contentItem.contentType = .Image // not passed back explicitly in response
                                            }
                                            else {
                                                contentItem = ContentItemDownload(data: data)
                                            }
                                            
                                            post.contentItems = [contentItem]
                                            
                                            self.setPost(existingPost, post: post)
                                        },
                                        failure : {
                                            (error, wasHandled) in
                                            
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
                                            
                                            self.cancelLoadingDataViewChanges()
                                        },
                                        progress : {
                                            // TODO: show progress bar over upload item
                                            (percentComplete, wasCancelled) in
                                            
                                            // update the progress mask
                                            self.loadingMaskViewController.updateProgress(percentComplete)
                                        },
                                        multiStarted : {
                                            self.multiUploadStarted(existingPost)
                                        }
                                    )
                                    
                                    contentUploadManager.startUpload()
                                }
                            }
                        },
                        failureBlock: {
                            _ in
                            
                            self.dismissViewControllerAnimated(true, completion: nil)
                    })
                    if let error = error { print(error.description) }
            })
        }
            // if there is new content
        else if ((self.attachedItems?.count > 0) && (isNewContent)) {
            
            // need to upload contentfirst
            if let contentItemUpload = self.attachedItems![0] as? ContentItemUpload {
                let contentType = contentItemUpload.contentType
                
                let contentUploadManager = TreemContentServiceUploadManager(
                    treeSession         : CurrentTreeSettings.sharedInstance.treeSession,
                    contentItemUpload   : contentItemUpload,
                    success : {
                        (data) in
                        
                        var contentItem: ContentItemDownload
                        
                        if contentType == .Video {
                            contentItem = ContentItemDownloadVideo(data: data)
                            contentItem.contentType = .Video // not passed back explicitly in response
                        }
                        else if contentType == .Image {
                            contentItem = ContentItemDownloadImage(data: data)
                            contentItem.contentType = .Image // not passed back explicitly in response
                        }
                        else {
                            contentItem = ContentItemDownload(data: data)
                        }
                        
                        post.contentItems = [contentItem]
                        
                        self.setPost(existingPost, post: post)
                    },
                    failure : {
                        (error, wasHandled) in
                        
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
                        
                        self.cancelLoadingDataViewChanges()
                    },
                    progress : {
                        // TODO: show progress bar over upload item
                        (percentComplete, wasCancelled) in
                        
                        // update the progress mask
                        self.loadingMaskViewController.updateProgress(percentComplete)
                    },
                    multiStarted : {
                        self.multiUploadStarted(existingPost)
                    }
                )
                
                contentUploadManager.startUpload()
            }
        }
        // just a text post
        else {
            self.setPost(existingPost, post: post)
        }
    }

    
    @IBAction func tagMembersButtonTouchUpInside(sender: AnyObject) {
        let tagVC = PostTagViewController.getStoryboardInstance()
        tagVC.delegate = self
        
        self.presentViewController(tagVC, animated: true, completion: nil)
    }
    
    //# MARK: - View Controller Variables
    
    private let loadingMaskViewController           = LoadingMaskViewController.getStoryboardInstance()
    private let loadingMaskOverlayViewController    = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController                 = ErrorViewController.getStoryboardInstance()
    
    private var imagePickerController: ImagePickerController!
    
    private var timer : NSTimer? = nil
    
    private var attachedItems: [ContentItemDelegate]? = nil
    
    private var initialExpiresOptionHeight: CGFloat = 0

    private var editPost: Post? = nil

    private var imageEditor : ImageEditor?
    
    private var postImageView : UIImageView?
    private var selectedImage : UIImage?
    private var imageEdited : Bool? = false
    private var uploadInBackground: Bool = false
    
    private var fadeInTransition = FadeInAnimatedTransition()
    
    // this needs to be stored because once the photo is removed from the post, the ID is set to zero.
    private var postOriginalContentId : Int?
    
    private var originalTagButtonText : String? = nil
    private var originalTagLabelHeight : CGFloat = 0
    
    var editPostId      : Int = 0
    var delegate        : PostDelegate?    = nil
    var parentView      : UIView?          = nil
    var shareLink       : String? = nil
    
    var taggedIDs       : [Int] = []
    var taggedNames     : [String] = []
    
    var postTextTimer             : NSTimer?
    var postTextTimerDelay        : NSTimeInterval = 1
    var postUrl                   : String = ""
    var postData                  = WebPageData()
    var checkUrlData              : Bool = true
    
    @IBOutlet weak var PostUrlPreviewHeightConstraint: NSLayoutConstraint!
    
        //# MARK: - View Controller Override Methods
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        self.dismissKeyboard()
        super.touchesBegan(touches, withEvent: event)
    }
    
    // handle moving elements when keyboard is pulled up or down
    func keyboardWillChangeFrame(notification: NSNotification){
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.actionContainerBottomConstraint)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.postTextView.delegate = self
        self.postTextView.textContainer.lineFragmentPadding = 0
        self.postTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10)

        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PostViewController.dismissKeyboard)))
        
        if CurrentTreeSettings.sharedInstance.currentBranchID < 1 {
            self.postTextView.placeholder = "Write to all members in the tree"
        }
        else {
            self.postTextView.placeholder = "Write to all members in this branch"
        }
        
        // disable post button initially
        AppStyles.sharedInstance.setButtonDefaultStyles(self.postButton)
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.postButton, enabled: false, showDisabledOutline: false)
        
        // set divider colors
        divider3.backgroundColor = AppStyles.sharedInstance.dividerColor
        divider4.backgroundColor = AppStyles.sharedInstance.dividerColor
        
        // expires options not shown initially
        self.initialExpiresOptionHeight = self.expiresOptionsHeightConstraint.constant
        self.expiresOptionsHeightConstraint.constant = 0
        
        // tagged, attachments and post URL items not showing initially
        self.imageAttachedViewHeightConstraint.constant = 0
        self.PostUrlPreviewViewHeightConstraint.constant = 0
        
        self.taggedMembersViewHeightConstraint.constant = 0
        
        // fractional heights not allowed to be set in storyboard
        self.divider3HeightConstraint.constant = 1.0
        self.divider4HeightConstraint.constant = 1.0

        // save the original text from the tag button
        if let buttonTitle = self.tagButton.titleLabel, buttonText = buttonTitle.text {
            self.originalTagButtonText = buttonText
        }
                
        // store the original height of the label for later
        self.originalTagLabelHeight = self.taggedLabelHeightConstraint.constant
        
        // if editing an existing post
        if (self.editPostId > 0) {
            self.loadingMaskViewController.queueLoadingMask(self.view, loadingViewAlpha: 1.0, showCompletion: {
                TreemFeedService.sharedInstance.getPostDetails(
                    CurrentTreeSettings.sharedInstance.treeSession,
                    postID: self.editPostId,
                    success: {
                        data in

                        self.editPost = Post(data: data, postId: self.editPostId)
                        
                        if self.editPost?.postUrlData != nil {
                            self.checkUrlData = false
                            self.shareLink = self.editPost?.postUrlData?.linkUrl
                        }
                        
                        self.loadPost(self.editPost!)
                    },
                    failure: {
                        error, wasHandled in
                        
                        self.errorViewController.showErrorMessageView(self.view, text: "An error occurred while loading the post.")
                        
                        self.loadingMaskViewController.cancelLoadingMask(nil)
                    }
                )
            })
        }
        else {
            
            // TODO: instead of just adding this to the text field, it will need to make a request and build our the external link
            if let share = self.shareLink {
                self.postUrl = share
                self.parseUrl()
                self.checkPostButtonEnabled()
            }
            
            self.hideDeleteButton()            
            self.hideTaggedLabel()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // set expiration date defaults
        self.setDatePickerDefaults()
        
        // in case reopening app from background
        let notifCenter = NSNotificationCenter.defaultCenter()
        
        notifCenter.addObserver(self, selector: #selector(PostViewController.setDatePickerDefaults), name:UIApplicationDidBecomeActiveNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(PostViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        let notifCenter = NSNotificationCenter.defaultCenter()
            
        notifCenter.removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        notifCenter.removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }

    static func getStoryboardInstance() -> PostViewController {
        return UIStoryboard(name: "Post", bundle: nil).instantiateInitialViewController() as! PostViewController
    }
    
    // ---------------------------------------- //
    //# Mark: Media Picker Delegate Functions
    // ---------------------------------------- //
    
    func cancelSelected() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imageSelected(image: UIImage, fileExtension: TreemContentService.ContentFileExtensions, picker: UIImagePickerController) {
        self.selectedImage = image
        
        // single select for the time being
        self.attachedItems = [ContentItemUploadImage(fileExtension: fileExtension, image: image)!]
        
        self.loadPostImage(image)
        
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.postButton, enabled: true, withAnimation: true, showDisabledOutline: false)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func videoSelected(fileURL: NSURL, orientation: ContentItemOrientation, fileExtension: TreemContentService.ContentFileExtensions, picker: UIImagePickerController) {
        // single select for the time being
        let itemUpload = ContentItemUpload(fileExtension: fileExtension, fileURL: fileURL)
        
        itemUpload.contentType = .Video
        itemUpload.orientation = orientation
        
        self.attachedItems = [itemUpload]
        
        // generate thumbnail from video file URL
        let asset           = AVURLAsset(URL: fileURL, options: nil)
        let imgGenerator    = AVAssetImageGenerator(asset: asset)
        
        imgGenerator.appliesPreferredTrackTransform = true  // create the thumbnail using the video's orientation
        
        do {
            let cgImage = try imgGenerator.copyCGImageAtTime(CMTimeMake(0, 1), actualTime: nil)
            
            self.loadPostImage(UIImage(CGImage: cgImage), isVideoThumbnail: true)
        }
        catch {
            // create blank image just to show something if thumbnail could not be created
            self.loadPostImage(UIImage().getImageWithColor(UIColor.whiteColor()), isVideoThumbnail: true)
        }
        
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.postButton, enabled: true, withAnimation: true, showDisabledOutline: false)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //# MARK: - View Helper Methods
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return AppStyles.directionUpViewAnimatedTransition
    }
    
    // view changes that occur when a service call is loading/performing
    private func cancelLoadingDataViewChanges() {
        self.loadingMaskViewController.cancelLoadingMask(nil)
        self.loadingMaskOverlayViewController.cancelLoadingMask(nil)
        
        if let parentVC = self.parentViewController as? PostEditViewController {
            parentVC.closeButton.enabled = true
        }
    }
    
    private func cancelTimer() {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
    private func checkPostButtonEnabled() {
        var enabled = false

        // if at least one image attached
        if self.attachedItems?.count > 0 {
            enabled = true
        }
        // this will trim and remove empty line breaks at the beginning and end of the text entered
        else if (self.postTextView.text ?? "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).characters.count > 0 {
            // check if message entered
            enabled = true
        }
        
        else if !((self.postUrl ?? "").isEmpty) {
            enabled = true
        }
        
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.postButton, enabled: enabled, withAnimation: true, showDisabledOutline: false)
    }
    
    func dismissEditPost() {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    // clear open keyboards on tap
    func dismissKeyboard() {
        self.view.endEditing(true)
        self.postTextView.resignFirstResponder()
    }

    func dismissNewPostSuccessMessage() {
        self.delegate?.postWasAdded()
    }
    
    private func hideDeleteButton() {
        // hide delete button and resize the post button
        let screenWidth: CGFloat                      = UIScreen.mainScreen().bounds.width
        self.postButtonLeadingConstraint.constant    -= screenWidth
        self.deleteButtonTopConstraint.constant       = 0
        self.deleteButtonWidthConstraint.constant     = 0
        self.deleteButtonBottomConstraint.constant    = 0
        self.deleteButtonLeadingConstraint.constant   = 0
        self.deleteButton.hidden                      = true
    }
    
    private func hideTaggedLabel(){
        // check to make sure the label isn't already hidden
        if(!self.taggedLabel.hidden){
            self.taggedLabel.hidden=true
            
            // resize the view the label sits in
            self.attachOptionsViewHeightConstraint.constant = (self.attachOptionsViewHeightConstraint.constant -
                                    self.taggedLabelHeightConstraint.constant)
            
            // remove the height it takes up
            self.taggedLabelHeightConstraint.constant = 0
        }
    }
    
    private func showTaggedLabel(){
        
        // check to make sure the label isn't already shown
        if(self.taggedLabel.hidden){
            self.taggedLabel.hidden=false
            
            // resize the view the label sits in
            self.attachOptionsViewHeightConstraint.constant = (self.attachOptionsViewHeightConstraint.constant +
                self.originalTagLabelHeight)
            
            // add the height back
            self.taggedLabelHeightConstraint.constant = self.originalTagLabelHeight
        }
    }
    
    private func loadPost(post: Post) {
        let expires = post.expires != nil
        
        self.postTextView.text      = post.message ?? ""
        self.oneTimeViewSwitch.on   = post.viewOnce
        self.expiresSwitch.on       = expires
        self.shareableSwitch.on     = post.shareable
        
        // show expires date picker as needed
        self.toggleExpiresDatePicker(expires, showAnimation: false)
        
        // set expires date
        if expires {
            self.expiresDatePicker.setDate(post.expires!, animated: false)
        }
        
        // change post button to reflect editing
        UIView.performWithoutAnimation({
            self.postButton.setTitle("Save", forState: .Normal)
            self.postButton.layoutIfNeeded()
        })
        
        // load the URL data that we already have
        if post.containsUrl {
            self.postData           = post.postUrlData!
            checkUrlData            = false
            self.LayoutPostUrlPreview(self.postData)
        }
        
        // check if there is any content
        if let contentItems = post.contentItems {
            if let item = contentItems[0] as? ContentItemDownload, contentURL = item.contentURL {
                // retrieve and load image
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    TreemContentService.sharedInstance.getContentRepositoryFile(contentURL, cacheKey: item.contentURLId, success: {
                        (image) -> () in
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            _ in
                            
                            if let image = image {
                                
                                if item.contentType != .Video {
                                    self.selectedImage = image
                                }
                                self.loadPostImage(image, isVideoThumbnail: item.contentType == .Video)
                            }
                            
                            self.loadingMaskViewController.cancelLoadingMask(nil)
                        })
                    })
                })
            }
            else {
                self.loadingMaskViewController.cancelLoadingMask(nil)
            }
        }
        else {
            self.loadingMaskViewController.cancelLoadingMask(nil)
        }

        // set the tag button and labels
        self.setTagButtonText(post.taggedUsers)
        self.setTagLabel(post.taggedNames)
        
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.postButton, enabled: true, withAnimation: false, showDisabledOutline: false)
    }
    
    private func loadPostImage(image: UIImage, isVideoThumbnail: Bool = false) {
        // scale the image to fit the view
        let size = UIImage.getResizeImageScaleSize(CGSize(width: self.view.frame.width, height: 400), oldSize: image.size)
        
        postImageView = UIImageView(image: image)
        postImageView!.contentMode   = .ScaleAspectFit
        postImageView!.frame         = CGRectMake(0, 0, size.width, size.height)
        
        // add delete button in image
        let deleteButton = AppStyles.sharedInstance.getEditImageButton(nil, image: "Close")
        
        let height : CGFloat = 30
        let width = 10 + (deleteButton.imageView?.frame.width ?? 0)

        deleteButton.contentEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        deleteButton.frame = CGRectMake(postImageView!.frame.width - width, 0, width, height)

        // add delete image button target action
        deleteButton.addTarget(self, action: #selector(PostViewController.removeImageFromPostView(_:)), forControlEvents: .TouchUpInside)
        
        if !isVideoThumbnail {
            let editImageButton = AppStyles.sharedInstance.getEditImageButton("Edit", image: "Edit")
            
            editImageButton.setNeedsLayout()
            editImageButton.layoutIfNeeded()
            
            // TODO: Calculate width of text on layout subviews instead
            let editWidth = 34 + (editImageButton.imageView?.frame.width ?? 0) + (editImageButton.titleLabel?.frame.width ?? 0)
            
            editImageButton.frame = CGRectMake(postImageView!.frame.width - editWidth, postImageView!.frame.height - height, editWidth, height)
            
            editImageButton.addTarget(self, action: #selector(PostViewController.editImageOnPost(_:)), forControlEvents: .TouchUpInside)
            
            postImageView!.addSubview(editImageButton)
        }
        
        // if a thumbnail add the video icon overlay to indicate so
        if isVideoThumbnail {
            let image                   = UIImage(named: "Video")

            let videoOverlayImageView   = UIImageView(image: image)

            videoOverlayImageView.contentMode       = .ScaleAspectFit
            videoOverlayImageView.tintColor         = UIColor.whiteColor().colorWithAlphaComponent(0.25)
            videoOverlayImageView.backgroundColor   = UIColor.darkGrayColor().colorWithAlphaComponent(0.5)
            videoOverlayImageView.frame             = CGRectMake(0,0,size.width,size.height)
            
            postImageView!.addSubview(videoOverlayImageView)
        }
        
        postImageView!.userInteractionEnabled = true // imageView has disabled by default
        postImageView!.addSubview(deleteButton)
        
        
        
        // add imageview
        self.imageAttachedViewHeightConstraint.constant = size.height
        
        self.imageAttachedView.addSubview(postImageView!)
        
        self.view.layoutIfNeeded()
    }
    
    // view changes that occur when a service call is loading/performing
    private func loadingDataViewChanges(showProgress: Bool=false) {
        if self.editPostId > 0 {
            if let parentVC = self.parentViewController as? PostEditViewController {
                parentVC.closeButton.enabled = false
            }
        }

        if(showProgress){
            var viewToMask = self.view
            if (self.parentView != nil) { viewToMask = self.parentView! }            
            self.loadingMaskViewController.queueProgressMask(viewToMask, showCompletion: nil)
        }
        else{
            self.loadingMaskOverlayViewController.showMaskOnly(self.postMaskView, showCompletion: nil)
            self.loadingMaskViewController.queueLoadingMask(self.actionButtonContainerView, loadingViewAlpha: 1.0, showCompletion: nil)
        }
    }
    
    func removeImageFromPostView(sender: UIButton) {
        // get imageview in parent
        if let superview = sender.superview {
            // adjust height constraint of attachments (currently only one attachment allowed)
            self.imageAttachedViewHeightConstraint.constant = 0
            
            UIView.animateWithDuration(
                AppStyles.sharedInstance.viewAnimationDuration,
                animations: {
                    () -> Void in
                    
                    self.imageAttachedView.layoutIfNeeded()
                    self.scrollContentView.layoutIfNeeded()
                    self.scrollView.layoutIfNeeded()
                },
                completion: {
                    (Bool) -> Void in
                    
                    // remove image from superview
                    superview.removeFromSuperview()
                    
                    self.postOriginalContentId = self.editPost?.contentItems?.first?.contentID
                    self.attachedItems          = []    // clear attached item (single for now)
                    self.editPost?.contentItems?.first?.contentID = 0   //set the ID = 0 to clear the contents in the db
                    self.editPost?.contentItems?.first?.contentType = nil
                    self.selectedImage = nil
                }
            )
        }
    }
    
    func editImageOnPost(sender: UIButton) {
        
        self.imageEditor = ImageEditor(image: self.selectedImage!.rotateCameraImageToOrientation(self.selectedImage!, maxResolution: AppSettings.max_post_image_resolution), delegate: self)
        
        self.presentViewController(imageEditor!, animated: true, completion: nil)
    }
    
    func imageEditor(editor: CLImageEditor!, didFinishEdittingWithImage image: UIImage!){

       for view in imageAttachedView.subviews {
        view.removeFromSuperview()
       }
            
        var tempImage = image
        
        tempImage = image.rotateCameraImageToOrientation(image, maxResolution: AppSettings.max_post_image_resolution)

        self.loadPostImage(tempImage)
        self.selectedImage = tempImage
        self.imageEdited = true
        
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.postButton, enabled: true, withAnimation: true, showDisabledOutline: false)
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    private func toggleExpiresDatePicker(show: Bool, showAnimation: Bool) {
        self.expiresOptionsHeightConstraint.constant = show ? self.initialExpiresOptionHeight : 0
        
        if showAnimation {
            UIView.animateWithDuration(0.25,
                animations: {
                    self.expiresOptionsView.layoutIfNeeded()
                    self.expiresDatePicker.hidden = !show
                }
            )
        }
    }


    func initiallyHighlighted(user: User) -> Bool {
        return self.taggedIDs.contains(user.id)
    }
    
    func selectedUsersUpdated(users: OrderedSet<User>) {
        for user in users {
            let fullName = user.getFullName()
            if (!self.taggedIDs.contains(user.id)) {
                self.taggedIDs.append(user.id)
            }
            if(!self.taggedNames.contains(fullName)){
                self.taggedNames.append(fullName)
            }
        }
        
        self.setTagButtonText()
        self.setTagLabel()
    }

    func deselectedUsersUpdated(users: OrderedSet<User>) {
        for user in users {
            let fullName = user.getFullName()
            if let userIndex = self.taggedIDs.indexOf(user.id) {
                self.taggedIDs.removeAtIndex(userIndex)
            }
            if let userIndex = self.taggedNames.indexOf(fullName) {
                self.taggedNames.removeAtIndex(userIndex)
            }
        }
        
        self.setTagButtonText()
        self.setTagLabel()
    }

    /* Get the branch on which the Post either was made, or is about to be made.
        There are cases in which you can edit a post from a  different branch than it was initially made (e.g. make it in Coworkers->Treem, but then edit it in just the Coworkers top-level branch). 
        In situations like that, you need information about the branch it was made on ("Treem"), not really the branch you're coming from ("Coworkers")
    */
    func getBranchID() -> Int {
        
        if (self.editPost != nil && self.editPost!.branchID != 0) {
            return self.editPost!.branchID
        }
        else {
            return CurrentTreeSettings.sharedInstance.currentBranchID
        }

    }
    
    func setDatePickerDefaults() {
        // set minimum date
        let calendar = NSCalendar.currentCalendar()
        let date = NSDate()
        
        self.expiresDatePicker.minimumDate = calendar.dateByAddingUnit(.Minute, value: 15, toDate: date, options: [])
        
        // set maximum date
        self.expiresDatePicker.maximumDate = calendar.dateByAddingUnit(.Year, value: 1, toDate: date, options: [])
    }
    
    func textViewDidChange(textView: UITextView) {
        self.postButton.setTitle(self.editPostId > 0 ? "Save" : "Post", forState: .Normal)
        
        self.checkPostButtonEnabled()
    }
    
    //# MARK: - Service Methods
    
    private func deletePost() {
        TreemFeedService.sharedInstance.removePost(
            CurrentTreeSettings.sharedInstance.treeSession,
            postID: self.editPostId,
            success: {
                data in

                self.errorViewController.showErrorMessageView(self.actionButtonContainerView, text: "✓ Post Deleted")
                
                self.loadingMaskViewController.cancelLoadingMask(nil)
                
                if self.editPostId > 0 {
                    self.delegate?.postWasDeleted(self.editPostId)
                    
                    self.cancelTimer()
                    
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(PostViewController.dismissEditPost), userInfo: nil, repeats: false)
                }
            },
            failure: {
                error, wasHandled in
                
                if !wasHandled {
                    CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                }

                self.errorViewController.removeErrorView()
                self.cancelLoadingDataViewChanges()
            }
        )
    }
    
    private func showUnsupportedTypeAlert() {
        var typesList = ""
        
        for type in TreemContentService.ContentFileExtensions.cases {
            typesList += "-" + type
        }
        
        CustomAlertViews.showCustomAlertView(title: "Unsupported type", message: "Image/video uploaded is not a supported type. Supported types include:" + typesList)
    }
    
    private func multiUploadStarted(existingPost: Bool){
        
        // multi upload is now running in the back ground, free up the mask so the user can do something else
        self.uploadInBackground = true
        
        self.loadingMaskViewController.cancelLoadingMask({
            let infoVC = InfoMessageViewController.getStoryboardInstance()
            infoVC.infoMessage = "Your post is now uploading, we'll send a notification when it's ready."
            infoVC.onDismiss = {
                if existingPost { self.dismissEditPost() }
                else{ self.dismissNewPostSuccessMessage() }
            }
            
            self.presentViewController(infoVC, animated: true, completion: nil)
        })
    }
    
    private func setPost(existingPost: Bool, post: Post) {
        let isPostEdit = self.editPostId > 0
        
        TreemFeedService.sharedInstance.setPost(
            CurrentTreeSettings.sharedInstance.treeSession,
            post: post,
            success: {
                data in

                self.delegate?.postWasUpdated(post)
                
                if(!self.uploadInBackground){
                    
                    self.errorViewController.showErrorMessageView(self.actionButtonContainerView, text: "✓ Post " + (existingPost ? "Changed" : "Added"))
                    self.loadingMaskViewController.cancelLoadingMask(nil)
                    
                    let selector: Selector
                    
                    if isPostEdit {
                        self.cancelTimer()
                        
                        selector = #selector(PostViewController.dismissEditPost)
                    }
                    else {
                        selector = #selector(PostViewController.dismissNewPostSuccessMessage)
                    }
                    
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: selector, userInfo: nil, repeats: false)
                }
                else{
                    if let postId = data["p_id"].int {
                        InAppNotifications.sharedInstance.addInAppAlert(Alert.Reasons.POST_UPLOAD_FINISHED, id: postId)
                    }
                }
                
                self.uploadInBackground = false
            },
            failure: {
                error, wasHandled in
                
                if(!self.uploadInBackground){
                    if (error == TreemServiceResponseCode.GenericResponseCode4) {
                        // past date
                        CustomAlertViews.showCustomAlertView(title: "Past Expiration Date", message: "Expiration date cannot be in the past")
                    }
                    
                    self.cancelLoadingDataViewChanges()
                }
                self.uploadInBackground = false
            }
        )
    }
    
    func textViewDidChangeSelection(textView: UITextView) {
        
        if let timer = self.postTextTimer {
                timer.invalidate()
        }
        
        let tempUrl = textView.text.parseForUrl()
        
        if tempUrl != "" {
                
            if postUrl != tempUrl && self.shareLink == nil {
                for view in PostUrlPreviewView.subviews {
                    view.removeFromSuperview()
                }
                self.postData = WebPageData()
                PostUrlPreviewHeightConstraint.constant = 0
                self.checkUrlData = true
            }
            
            postUrl = tempUrl
            
            if checkUrlData {
                
                if self.postData.linkUrl == nil {
                    self.postTextTimer = NSTimer.scheduledTimerWithTimeInterval(postTextView.text.isEmpty ? 0 : self.postTextTimerDelay,
                        target: self,
                        selector: #selector(PostViewController.parseUrl),
                        userInfo: nil,
                        repeats: false)
                    
                }
            }
        }
        
            //Clean the view because the user has deleted the URL.  We want to make sure that they had previously entered a valid url though.
        else if self.postData.linkUrl != nil && self.shareLink == nil {
            
            for view in PostUrlPreviewView.subviews {
                view.removeFromSuperview()
            }
            self.postData = WebPageData()
            PostUrlPreviewHeightConstraint.constant = 1
            self.checkUrlData = true
            self.postUrl = ""
        }
    }
    func parseUrl() {
        //This should load the view for a url thumbnail.  
        
        TreemFeedService.sharedInstance.getUrlParse(CurrentTreeSettings.sharedInstance.treeSession, postUrl: postUrl, success: {
            data in
            let urlData = WebPageData.init(data: data)
            
            if urlData.linkUrl != nil || urlData.linkImage != nil {
                self.postData = urlData
                self.LayoutPostUrlPreview(urlData)
            }
            
            }, failure: {
                error, wasHandled in
        })
    }
    
    func LayoutPostUrlPreview(pageData: WebPageData) {
        
        let urlPreviewController = UrlPreviewViewController.getStoryboardInstance()
        
        urlPreviewController.pageData           = pageData
        urlPreviewController.postViewController = self
        
        let height = UrlPreviewViewController.getLayoutHeightFromWebData(pageData)
        
        urlPreviewController.view.frame = CGRectMake(0, 0, PostUrlPreviewView.frame.size.width, height)
        
        if self.editPost != nil || self.shareLink != nil {
            urlPreviewController.allowRemovePreview = true
        }
        
        PostUrlPreviewHeightConstraint.constant = height
        
        self.addChildViewController(urlPreviewController)
        PostUrlPreviewView.addSubview(urlPreviewController.view)
        
        self.scrollContentView.layoutIfNeeded()
    }
    
    func removeLinkFromPostView(sender: UIButton) {
        // get imageview in parent
        if let _ = sender.superview {
            // adjust height constraint of the Url Preview (currently only one url preview allowed)
            self.PostUrlPreviewHeightConstraint.constant = 0
            
            UIView.animateWithDuration(
                AppStyles.sharedInstance.viewAnimationDuration,
                animations: {
                    () -> Void in
                    
                    self.PostUrlPreviewView.layoutIfNeeded()
                    self.scrollContentView.layoutIfNeeded()
                    self.scrollView.layoutIfNeeded()
                },
                completion: {
                    (Bool) -> Void in
                    
                    // remove image from superview
                    
                    self.PostUrlPreviewView!.subviews.forEach({ $0.removeFromSuperview() })

                    self.editPost?.postUrlData = WebPageData()
                    
                    self.postUrl            = ""    // clear the post url item (single for now)
                    self.postData           = WebPageData()
                    self.checkUrlData       = true
                    
                    self.checkPostButtonEnabled()
                }
            )
        }
    }
    
    private func setTagButtonText(taggedIds: [Int]? = nil){
        
        if let ids = taggedIds{
            self.taggedIDs = ids
        }
        
        if let buttonText = self.originalTagButtonText {
            UIView.performWithoutAnimation({
                if(self.taggedIDs.count > 0){
                    self.tagButton.setTitle(buttonText + " (" + String(self.taggedIDs.count) + ")", forState: .Normal)
                }
                else{
                    self.tagButton.setTitle(buttonText, forState: .Normal)
                }
                self.tagButton.layoutIfNeeded()
            })
        }
    }
    
    private func setTagLabel(tagNamesString: String? = nil){
        if let tagNames = tagNamesString {
            
            self.taggedLabel.text = "Tagged: " + tagNames
            self.showTaggedLabel()
            
            self.taggedNames = []
            for name in tagNames.characters.split(",").map(String.init){
                self.taggedNames.append(name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
            }
        }
        else if self.taggedNames.count > 0 {
            var labelText = ""
            
            for name in self.taggedNames {
                labelText = (labelText == "") ? "" : labelText + ", "
                labelText += name
            }
            
            self.taggedLabel.text = "Tagged: " + labelText
            self.showTaggedLabel()
        }
        else{
            self.hideTaggedLabel()
        }
    }
}