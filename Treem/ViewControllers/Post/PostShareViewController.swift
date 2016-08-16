//
//  PostShareViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/5/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import KMPlaceholderTextView

class PostShareViewController: UIViewController {

    // --------------------------------- //
    // Set from calling controller
    // --------------------------------- //
    
    var post                : Post?                 = nil
    var shareDelegate       : PostShareDelegate?    = nil
    var postDelegate        : PostDelegate?         = nil
    var inNavController     : Bool                  = false
    var isEditPost          : Bool                  = false
    var branchViewDelegate  : BranchViewDelegate?   = nil
    
    // --------------------------------- //
    // Form Variables
    // --------------------------------- //

    @IBOutlet var maskView: UIView!
    @IBOutlet var actionView: UIView!
    @IBOutlet var messageTextView: KMPlaceholderTextView!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var chooseBranchButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!

    @IBOutlet weak var headerBarView: UIView!
    @IBOutlet weak var actionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerBarViewHeightConstraint: NSLayoutConstraint!
    
    // --------------------------------- //
    // Private variables
    // --------------------------------- //
    
    private let loadingMaskViewController           = LoadingMaskViewController.getStoryboardInstance()
    private let loadingMaskOverlayViewController    = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController                 = ErrorViewController.getStoryboardInstance()
    private var timer : NSTimer? = nil
    
    // --------------------------------- //
    // Form Event Handlers
    // --------------------------------- //
    
    @IBAction func deleteButtonTouchUpInside(sender: AnyObject) {
        if let post = self.post {
            CustomAlertViews.showCustomConfirmView(
                title: "Delete Shared Post?",
                message: "Deleting the shared post will also remove all comments and reactions made on it. Are you sure you want to delete it?",
                fromViewController: self,
                yesHandler: {
                    _ in
                    
                    self.showLoadingMask()
                    
                    self.deleteShare(post)
                },
                noHandler: nil
            )
        }
    }
    
    @IBAction func chooseBranchButtonTouchUpInside(sender: AnyObject) {
        if let post = self.post {
        
            let postSubmit: (Int, String) -> () = {
                branchId, _ in
                
                self.showLoadingMask()
                
                self.setPostShare(post, branchId: branchId)
            }
            
            // save existing share
            if self.isEditPost {
                postSubmit(0, "")
            }
            // create new share (select branch)
            else {
                self.shareDelegate?.sharePostSelectBranch(
                    self
                    , completion: postSubmit
                )
            }
        }
    }

    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.dismissShareView()
    }
    
    
    // --------------------------------- //
    // Initializer from outside controller
    // --------------------------------- //
    
    static func getStoryboardInstance() -> PostShareViewController {
        return UIStoryboard(name: "PostShare", bundle: nil).instantiateViewControllerWithIdentifier("PostShare") as! PostShareViewController
    }
    
    // --------------------------------- //
    // Load Overrides
    // --------------------------------- //
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }

    override func prefersStatusBarHidden() -> Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.branchViewDelegate?.toggleBackButton(true, onTouchUpInside: self.dismissShareView)
        
        AppStyles.sharedInstance.setButtonDefaultStyles(self.chooseBranchButton)
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.chooseBranchButton, enabled: true, withAnimation: true)
        
        // update styles depending if nested in nav vc or not
        if self.inNavController {
            self.headerBarViewHeightConstraint.constant = 0
        }
        else {
            self.headerBarView.backgroundColor = AppStyles.sharedInstance.subBarBackgroundColor
        }
        
        self.dividerView.backgroundColor = AppStyles.sharedInstance.dividerColor
        
        if self.isEditPost {
            self.messageTextView.text = post?.share_message
            
            // change button to reflect 'Save'
            UIView.performWithoutAnimation({
                self.chooseBranchButton.setTitle("Save", forState: .Normal)
                self.chooseBranchButton.layoutIfNeeded()
            })
        }
        else {
            // remove delete button
            self.deleteButton.removeFromSuperview()
            
            // add constraint so that button fills parent
            let leadConstraint = NSLayoutConstraint(item: self.chooseBranchButton, attribute: .Leading, relatedBy: .Equal, toItem: self.chooseBranchButton.superview!, attribute: .Leading, multiplier: 1, constant: 0)
            
            
            self.chooseBranchButton.superview!.addConstraint(leadConstraint)
            self.view.layoutIfNeeded()
        }
        
        // show keyboard initially
        self.messageTextView.becomeFirstResponder()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.branchViewDelegate?.toggleBackButton(true, onTouchUpInside: self.dismissShareView)
        
        // add observers for showing/hiding keyboard
        let notifCenter = NSNotificationCenter.defaultCenter()
        
        notifCenter.addObserver(self, selector: #selector(PostShareViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // remove observers
        let notifCenter = NSNotificationCenter.defaultCenter()
        
        notifCenter.removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    // handle moving elements when keyboard is pulled up
    func keyboardWillChangeFrame(notification: NSNotification){
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.actionViewBottomConstraint)
    }
    
    // --------------------------------- //
    // Public Functions
    // --------------------------------- //
    
    func dismissShareView() {
        if let navVC = self.navigationController where self.inNavController {
            navVC.popViewControllerAnimated(true)
        }
        else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        self.branchViewDelegate?.setDefaultTitle?()
    }
    
    // --------------------------------- //
    // Private Functions
    // --------------------------------- //
    
    private func cancelTimer() {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
    private func deleteShare(post: Post) {
        TreemFeedService.sharedInstance.removeShare(
            CurrentTreeSettings.sharedInstance.treeSession,
            shareId: post.share_id,
            success: {
                (data) -> Void in
                
                self.hideLoadingMaskWithMessage("✓ Share removed")

                // fire the post updated delegate
                self.postDelegate?.postWasDeleted(post.postId)
                
                // dismiss view after a second
                self.cancelTimer()
                self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(PostShareViewController.dismissShareView), userInfo: nil, repeats: false)
            },
            failure: {
                (error, wasHandled) -> Void in
                
                if !wasHandled {
                    CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: { self.dismissShareView() })
                }
            }
        )
    }
    
    private func hideLoadingMaskWithMessage(msg: String) {
        self.errorViewController.showErrorMessageView(self.actionView, text: msg)
        self.loadingMaskViewController.cancelLoadingMask(nil)
    }
    
    private func showLoadingMask() {
        self.loadingMaskOverlayViewController.showMaskOnly(self.maskView, showCompletion: nil)
        self.loadingMaskViewController.queueLoadingMask(self.actionView, loadingViewAlpha: 1.0, showCompletion: nil)
    }
    
    private func setPostShare(post: Post, branchId: Int) {
        TreemFeedService.sharedInstance.setPostShare(
            CurrentTreeSettings.sharedInstance.treeSession
            , shareID: post.share_id
            , postID: post.postId
            , message: self.messageTextView.text
            , branchId: (branchId > 0 ? branchId : nil)
            , success: {
                data in
                
                self.hideLoadingMaskWithMessage("✓ " + (self.isEditPost ? "Share Edited" : "Post Shared"))
                
                // fire the post updated delegate
                self.postDelegate?.postWasUpdated(post)
                
                // dismiss view after a second
                self.cancelTimer()
                self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(PostShareViewController.dismissShareView), userInfo: nil, repeats: false)
            }
            , failure: {
                error, wasHandled in
                
                if !wasHandled {
                    CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: { self.dismissShareView() })
                }
            }
        )
    }
}
