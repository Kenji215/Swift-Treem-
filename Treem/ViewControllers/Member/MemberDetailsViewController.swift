//
//  MemberDetailsViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/20/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class MemberDetailsViewController: UIViewController, UINavigationControllerDelegate, PostDelegate, BranchViewDelegate {
    
    var userID              : Int? = nil
    var loadType            : DetailType? = nil
    var chatSessionID       : String? = nil
    var chatName            : String? = nil
    var userIsSelf          : Bool = false
    
    enum DetailType: Int {
        case Feed       = 0
        case Photo      = 1
        case Chat       = 3
    }    

    @IBOutlet weak var mainView: UIView!

    @IBOutlet weak var headerBarView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var branchTitleLabel: UILabel!
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) { self.dismissView() }
    
    @IBAction func backButtonTouchUpInside(sender: AnyObject) {
        if let backTouchUpInside = self.backTouchUpInside {
            backTouchUpInside()
            self.backButton.hidden = true
        }
    }
    
    private var feedViewController      : FeedViewController?       = nil
    private var loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    private var backTouchUpInside: (() -> ())? = nil
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // override appearance style for button
        self.branchTitleLabel.textColor = UIColor.whiteColor()
        
        // can't do anythign if we don't have a user id or load type
        if(self.loadType == nil){
            self.dismissView()
        }
        
        // set header / footer color
        self.headerFooterColorUpdated()

        self.setTitle()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.backButton.hidden = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embeddedMemberDetailsSegue" {
            let navVC = segue.destinationViewController as! UINavigationController
            navVC.delegate = self
            
            switch(self.loadType!){
                case DetailType.Feed:
                    let vc = FeedViewController.getStoryboardInstance()
                    
                    // determine if we're load self feed or not
                    if let uID = self.userID {
                        vc.singleFeedUserId = uID
                    }
                    else{
                        vc.loadSelfFeed = true
                    }
                    
                    vc.postDelegate = self
                    vc.branchViewDelegate = self
                    
                    self.feedViewController = vc
                    navVC.addChildViewController(self.feedViewController!)
                    
                    break;
                
                case DetailType.Photo:

                    let vc = MediaGalleryViewController.getStoryboardInstance()
                    vc.userID = self.userID
                    vc.userIsSelf = self.userIsSelf
                    
                    navVC.addChildViewController(vc)
                    
                    break;
                case DetailType.Chat:
                    
                    let vc = ChatListViewController.getStoryboardInstance()
                    vc.existingSessionId = self.chatSessionID
                    vc.existingSessionName = self.chatName
                    vc.initializeUserIds = [self.userID!]
                    vc.parentView = self.mainView
                    
                    navVC.addChildViewController(vc)
                    
                    break;
            }
        }
    }
    
    //# MARK: Branch View Delegate Methods
    func toggleBackButton(show: Bool, onTouchUpInside: (() -> ())?) {
        self.backButton.hidden = !show
        self.backTouchUpInside = onTouchUpInside
    }
    
    static func getStoryboardInstance() -> MemberDetailsViewController {
        return UIStoryboard(name: "MemberDetails", bundle: nil).instantiateInitialViewController() as! MemberDetailsViewController;
    }
    
    private func headerFooterColorUpdated() {
        if self.isViewLoaded() {
            if let branch =  CurrentTreeSettings.sharedInstance.treeSession.currentBranch {
                if let branchColor = branch.color {
                    let adjustedColor = (CurrentTreeSettings.sharedInstance.currentTree == TreeType.Secret) ? branchColor.lighterColorForColor(0.2) : branchColor.darkerColorForColor(0.15)
                    
                    self.headerBarView.backgroundColor = branchColor
                    self.closeButton.tintColor              = adjustedColor
                    self.backButton.tintColor               = adjustedColor
                }
            }
        }
    }
    
    private func setTitle() {
        switch(self.loadType!){
            case DetailType.Feed    : self.branchTitleLabel.text = "Feed"
            case DetailType.Photo   : self.branchTitleLabel.text = "Pictures & Videos"
            case DetailType.Chat    : self.branchTitleLabel.text = self.chatName ?? "Chat"
        }
    }
    
    private func dismissView(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func postWasUpdated(post: Post) {
        self.updateFeedWhenAvailable()
    }
    
    func postWasDeleted(postID: Int) {
        self.updateFeedWhenAvailable()
    }
    
    private func updateFeedWhenAvailable() {
        if let feedVC = self.feedViewController {
            feedVC.refresh(feedVC.refreshControl ?? UIRefreshControl())
        }
    }
    
}