//
//  PostOptionsViewController.swift
//  Treem
//
//  Created by Tracy Merrill on 1/6/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
class PostOptionsViewController : UIViewController {
    enum OptionsType {
        case Post
        case Reply
    }
    
    var indexRow        : Int                   = 0
    var post            : Post?                 = nil
    var reply           : Reply?                = nil
    var sharedSelected  : Bool                  = false
    var delegate        : UIViewController?     = nil
    var postDelegate    : PostDelegate?         = nil
    var optionsType     : OptionsType           = .Post
    var referringButton : UIButton?             = nil
    
    var popoverDelegate : UIPopoverPresentationControllerDelegate? = nil
    
    var postId : Int {
        return self.sharedSelected ? post?.share_id ?? 0 : post?.postId ?? 0
    }
    var replyId: Int {
        return self.reply?.replyId ?? 0
    }

    @IBOutlet weak var optionsView: UIView!
    @IBOutlet weak var postOptionsButton: FeedActionButton!
    
    @IBOutlet weak var membersCanViewButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var reactionsButton: UIButton!
    @IBOutlet weak var reportButton: UIButton!
    
    @IBOutlet weak var deleteButton: UIButton!
    
    // Height Constraints
    @IBOutlet weak var membersCanViewButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reactionsButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var reportButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteButtonHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var postOptionsButtonTopConstraint: NSLayoutConstraint!
    
    private var loadingMaskViewController           = LoadingMaskViewController.getStoryboardInstance()
    
    @IBAction func postOptionsButtonTouchUpInside(sender: AnyObject) {
        self.dismissView()
    }
    
    static func getStoryboardInstance() -> PostOptionsViewController {
        return UIStoryboard(name: "PostOptions", bundle: nil).instantiateInitialViewController() as! PostOptionsViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor                           = AppStyles.overlayColor
        self.loadingMaskViewController.activityColor        = UIColor.whiteColor()
        self.loadingMaskViewController.view.backgroundColor = AppStyles.overlayColor
        
        let white = AppStyles.sharedInstance.whiteColor
        
        self.reportButton.tintColor         = white
        self.membersCanViewButton.tintColor = white
        self.editButton.tintColor           = white
        self.deleteButton.tintColor         = white
        self.reactionsButton.tintColor      = white
        
        self.postOptionsButton.active = false
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PostOptionsViewController.dismissViewTapHandler)))
        
        if reply != nil {
            self.optionsType = .Reply
        }
        
        // if it's a reply or it's a post that doesn't belong to the current user, hide some stuff...
        if (
            !((self.optionsType == .Post) && ((!self.sharedSelected && self.post?.editable == true) || (self.sharedSelected && self.post?.share_editable == true)))
            ||
            (self.optionsType == .Reply)
            )
        {
            self.editButtonHeightConstraint.constant                = 0
            self.editButton.hidden = true
            
            if(self.optionsType == .Reply){
                self.membersCanViewButtonHeightConstraint.constant  = 0
                self.reportButtonHeightConstraint.constant          = 0
                
                self.membersCanViewButton.hidden = true
                self.reportButton.hidden = true
                
                self.deleteButton.setTitle("Delete this comment", forState: .Normal)
                
                if(self.reply?.reactCounts == nil) { self.hideReactions() }
            }
            else{
                self.hideReactions()
                
                self.deleteButtonHeightConstraint.constant                = 0
                self.deleteButton.hidden = true
            }
        }
        // it is a post and it belongs to you
        else{
            // hide reactions option if there aren't any yet
            if(self.post?.reactCounts == nil){ self.hideReactions() }
            
            // can't report your own post, that's just silly
            self.reportButtonHeightConstraint.constant          = 0
            self.reportButton.hidden = true
        }
    }
    
    @IBAction func abuseTouchUpInside(sender: AnyObject) {
        let pvc = PostAbuseViewController.getStoryboardInstance()
        
        pvc.abusePostId             = self.postId
        pvc.delegate                = self
        
        self.dismissView({
            self.delegate?.presentViewController(pvc, animated: true, completion: nil)
        })
    }
    
    @IBAction func editTouchUpInside(sender: AnyObject) {
        if self.sharedSelected {
            let sharePostVC = PostShareViewController.getStoryboardInstance()
            
            sharePostVC.isEditPost              = true
            sharePostVC.post                    = self.post
            sharePostVC.postDelegate            = self.postDelegate

            self.dismissView({
                self.delegate?.presentViewController(sharePostVC, animated: true, completion: nil)
            })
        }
        else {
            let postVC  = PostEditViewController.getStoryboardInstance()

            postVC.editPostId               = self.postId
            postVC.delegate                 = self.postDelegate

            self.dismissView({
                self.delegate?.presentViewController(postVC, animated: true, completion: nil)
            })
        }
    }
    
    @IBAction func reactionsButtonTouchUpInside(sender: AnyObject) {
        if let sView = self.referringButton, popDelegate = self.popoverDelegate {
            self.showLoadingMask()
            
            if(self.optionsType == .Post){
                TreemFeedService.sharedInstance.getPostReactions(
                    CurrentTreeSettings.sharedInstance.treeSession
                    , postID: self.postId
                    , success: {
                        data in
                        
                        if let users = Post.getUserReactions(data) {
                            
                            let popover = MembersListPopoverViewController.getStoryboardInstance()
                            
                            popover.users = users
                            
                            if let popoverMenuView = popover.popoverPresentationController {
                                popoverMenuView.permittedArrowDirections    = .Up
                                popoverMenuView.delegate                    = popDelegate
                                popoverMenuView.sourceView                  = sView
                                popoverMenuView.sourceRect                  = CGRect(x: sView.bounds.width * 0.5, y: sView.bounds.height * 0.5, width: 0, height: 0)
                                popoverMenuView.backgroundColor             = UIColor.whiteColor()
                                
                                self.dismissView({
                                    self.delegate?.presentViewController(popover, animated: true, completion: nil)
                                })
                            }
                        }
                        
                        self.cancelLoadingMask()
                        
                    }
                    , failure: {
                        error, wasHandled in
                        
                        if !wasHandled {
                            self.cancelLoadingMask({
                                CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                            })
                        }
                    }
                )
            }
            else{
                TreemFeedService.sharedInstance.getReplyReactions(
                    CurrentTreeSettings.sharedInstance.treeSession
                    , replyID: self.replyId
                    , success: {
                        data in
                        
                        if let users = Post.getUserReactions(data) {
                            
                            let popover = MembersListPopoverViewController.getStoryboardInstance()
                            
                            popover.users = users
                            
                            if let popoverMenuView = popover.popoverPresentationController {
                                popoverMenuView.permittedArrowDirections    = .Up
                                popoverMenuView.delegate                    = popDelegate
                                popoverMenuView.sourceView                  = sView
                                popoverMenuView.sourceRect                  = CGRect(x: sView.bounds.width * 0.5, y: sView.bounds.height * 0.5, width: 0, height: 0)
                                popoverMenuView.backgroundColor             = UIColor.whiteColor()
                                
                                self.dismissView({
                                    self.delegate?.presentViewController(popover, animated: true, completion: nil)
                                })
                            }
                        }
                        
                        self.cancelLoadingMask()
                        
                    }
                    , failure: {
                        error, wasHandled in
                        
                        if !wasHandled {
                            self.cancelLoadingMask({
                                CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                            })
                        }
                    }
                )
            }
        }
    }
    
    @IBAction func deleteButtonTouchUpInside(sender: AnyObject) {
        CustomAlertViews.showCustomConfirmView(
            title: "Are you sure?"
            , message: "Are you sure you want to delete this " + ((self.optionsType == .Reply) ? "reply?" : "post?")
            , fromViewController: self
            , yesHandler: {
                action in
                
                self.showLoadingMask()
                
                if(self.optionsType == .Reply) {
                    TreemFeedService.sharedInstance.removeReply(
                        CurrentTreeSettings.sharedInstance.treeSession,
                        replyID: self.replyId,
                        success: {
                            data in
                            
                            // postdelegate reply was deleted
                            self.postDelegate?.replyWasDeleted(self.indexRow)
                            self.dismissView()
                            self.cancelLoadingMask()
                        },
                        failure: {
                            error, wasHandled in
                            
                            self.cancelLoadingMask({
                                if(!wasHandled){
                                    CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                                }
                            })
                        }
                    )
                }
                else {
                    TreemFeedService.sharedInstance.removePost(
                        CurrentTreeSettings.sharedInstance.treeSession,
                        postID: ((self.optionsType == .Reply) ? self.replyId : self.postId),
                        success: {
                            data in

                            self.postDelegate?.postWasDeleted(self.postId)
                            self.dismissView()
                            self.cancelLoadingMask()
                        },
                        failure: {
                            error, wasHandled in
                            
                            self.cancelLoadingMask({
                                if(!wasHandled){
                                    CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                                }
                            })
                        }
                    )
                }
                
            }
            , noHandler: {
                action in
                
                // do nothing
            })
    }
    
    @IBAction func membersButtonTouchUpInside(sender: AnyObject) {

        if let sView = self.referringButton, popDelegate = self.popoverDelegate {
            self.showLoadingMask()
            
            TreemFeedService.sharedInstance.getPostUsers(
                CurrentTreeSettings.sharedInstance.treeSession
                , postID: self.postId
                , success: {
                    data in

                    if let postUsers = Post.getPostUsers(data) {
                        if let userCount = postUsers.count {
                            let infoVC = InfoMessageViewController.getStoryboardInstance()
                            infoVC.infoMessage = String(userCount) + " members can see this post"
                            
                            self.dismissView({
                                self.delegate?.presentViewController(infoVC, animated: true, completion: nil)
                            })
                        }
                        else if let users = postUsers.users {
                            
                            let popover = MembersListPopoverViewController.getStoryboardInstance()
                            popover.users = users
                            
                            if let popoverMenuView = popover.popoverPresentationController {
                                popoverMenuView.permittedArrowDirections    = .Up
                                popoverMenuView.delegate                    = popDelegate
                                popoverMenuView.sourceView                  = sView
                                popoverMenuView.sourceRect                  = CGRect(x: sView.bounds.width * 0.5, y: sView.bounds.height * 0.5, width: 0, height: 0)
                                popoverMenuView.backgroundColor             = UIColor.whiteColor()
                                
                                self.dismissView({
                                    self.delegate?.presentViewController(popover, animated: true, completion: nil)
                                })
                            }
                        }
                    }
                    
                    self.cancelLoadingMask()
                }
                , failure: {
                    error, wasHandled in
                    
                    self.cancelLoadingMask({
                        if(!wasHandled){
                            CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                        }
                    })
                }
            )
        }
    }
    
    func dismissViewTapHandler() {
        self.dismissView(nil)
    }
    
    private func dismissView(completion: (()->())? = nil) {
        self.dismissViewControllerAnimated(true, completion: completion)
    }
    
    private func showLoadingMask(completion: (() -> Void)?=nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.queueLoadingMask(self.optionsView, loadingViewAlpha: 0.5, showCompletion: completion)
        }
    }
    
    private func cancelLoadingMask(completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.cancelLoadingMask(completion)
        }
    }
    
    private func hideReactions(){
        self.reactionsButtonHeightConstraint.constant           = 0
        self.reactionsButton.hidden                             = true
    }
}