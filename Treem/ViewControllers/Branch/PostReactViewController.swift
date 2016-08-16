//
//  PostReactViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/1/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class PostReactViewController: UIViewController, PostDelegate {

    var post                : Post? = nil
    var delegate    : PostDelegate? = nil
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var menuWrapperView: UIView!

    @IBOutlet weak var happyButton: UIButton!
    @IBOutlet weak var coolButton: UIButton!
    @IBOutlet weak var angryButton: UIButton!
    @IBOutlet weak var sadButton: UIButton!
    @IBOutlet weak var loveButton: UIButton!
    @IBOutlet weak var sillyButton: UIButton!
    @IBOutlet weak var hilariousButton: UIButton!
    @IBOutlet weak var amazedButton: UIButton!
    @IBOutlet weak var worriedButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var happyCountLabel: UILabel!
    @IBOutlet weak var coolCountLabel: UILabel!
    @IBOutlet weak var angryCountLabel: UILabel!
    @IBOutlet weak var sadCountLabel: UILabel!
    @IBOutlet weak var loveCountLabel: UILabel!
    @IBOutlet weak var sillyCountLabel: UILabel!
    @IBOutlet weak var amazedCountLabel: UILabel!
    @IBOutlet weak var hilariousCountLabel: UILabel!
    
    @IBOutlet weak var worriedCountLabel: UILabel!
    
    @IBAction func happyButtonTouchUpInside(sender: AnyObject)      { self.setReaction(Post.ReactionType.Happy) }
    @IBAction func coolButtonTouchUpInside(sender: AnyObject)       { self.setReaction(Post.ReactionType.Cool) }
    @IBAction func angryButtonTouchUpInside(sender: AnyObject)      { self.setReaction(Post.ReactionType.Angry) }
    @IBAction func sadButtonTouchUpInside(sender: AnyObject)        { self.setReaction(Post.ReactionType.Sad) }
    @IBAction func loveButtonTouchUpInside(sender: AnyObject)       { self.setReaction(Post.ReactionType.Love) }
    @IBAction func sillyButtonTouchUpInside(sender: AnyObject)      { self.setReaction(Post.ReactionType.Silly) }
    @IBAction func hilariousButtonTouchUpInside(sender: AnyObject)  { self.setReaction(Post.ReactionType.Hilarious) }
    @IBAction func amazedButtonTouchUpInside(sender: AnyObject)     { self.setReaction(Post.ReactionType.Amazed) }
    @IBAction func worriedButtonTouchUpInside(sender: AnyObject)    { self.setReaction(Post.ReactionType.Worried) }    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject)      { self.dismissView() }
    
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    
    static func getStoryboardInstance() -> PostReactViewController {
        return UIStoryboard(name: "PostReact", bundle: nil).instantiateViewControllerWithIdentifier("PostReact") as! PostReactViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(post != nil){
            if(post!.reactCounts != nil){
                for(var x = 0; x < post!.reactCounts!.count; x++){
                    switch(post!.reactCounts![x].react){
                        case Post.ReactionType.Happy            : self.happyCountLabel.text         = post!.reactCounts![x].count.description
                        case Post.ReactionType.Cool             : self.coolCountLabel.text          = post!.reactCounts![x].count.description
                        case Post.ReactionType.Angry            : self.angryCountLabel.text         = post!.reactCounts![x].count.description
                        case Post.ReactionType.Sad              : self.sadCountLabel.text           = post!.reactCounts![x].count.description
                        case Post.ReactionType.Love             : self.loveCountLabel.text          = post!.reactCounts![x].count.description
                        case Post.ReactionType.Silly            : self.sillyCountLabel.text         = post!.reactCounts![x].count.description
                        case Post.ReactionType.Hilarious        : self.hilariousCountLabel.text     = post!.reactCounts![x].count.description
                        case Post.ReactionType.Amazed           : self.amazedCountLabel.text        = post!.reactCounts![x].count.description
                        case Post.ReactionType.Worried          : self.worriedCountLabel.text       = post!.reactCounts![x].count.description
                    }
                }
            }
            
            if(post?.selfReact != nil){
                switch(post!.selfReact!){
                    case Post.ReactionType.Happy            : self.setSelected(self.happyButton, emoLabel: self.happyCountLabel)
                    case Post.ReactionType.Cool             : self.setSelected(self.coolButton, emoLabel: self.coolCountLabel)
                    case Post.ReactionType.Angry            : self.setSelected(self.angryButton, emoLabel: self.angryCountLabel)
                    case Post.ReactionType.Sad              : self.setSelected(self.sadButton, emoLabel: self.sadCountLabel)
                    case Post.ReactionType.Love             : self.setSelected(self.loveButton, emoLabel: self.loveCountLabel)
                    case Post.ReactionType.Silly            : self.setSelected(self.sillyButton, emoLabel: self.sillyCountLabel)
                    case Post.ReactionType.Hilarious        : self.setSelected(self.hilariousButton, emoLabel: self.hilariousCountLabel)
                    case Post.ReactionType.Amazed           : self.setSelected(self.amazedButton, emoLabel: self.amazedCountLabel)
                    case Post.ReactionType.Worried          : self.setSelected(self.worriedButton, emoLabel: self.worriedCountLabel)                    
                }
            }
        }
    }
    
    static func getReactionImage(react: Post.ReactionType) -> UIImage {
        switch(react){
            case Post.ReactionType.Happy            : return UIImage(named: "Happy")!
            case Post.ReactionType.Cool             : return UIImage(named: "Cool")!
            case Post.ReactionType.Angry            : return UIImage(named: "Angry")!
            case Post.ReactionType.Sad              : return UIImage(named: "Sad")!
            case Post.ReactionType.Love             : return UIImage(named: "Love")!
            case Post.ReactionType.Silly            : return UIImage(named: "Silly")!
            case Post.ReactionType.Hilarious        : return UIImage(named: "Hilarious")!
            case Post.ReactionType.Amazed           : return UIImage(named: "Amazed")!
            case Post.ReactionType.Worried          : return UIImage(named: "Worried")!
        }
    }

    private func setReaction(reactType: Post.ReactionType){
        
        // loading mask
        self.loadingMaskViewController.queueLoadingMask(self.mainView, loadingViewAlpha: 1.0, showCompletion: nil)

        // click on your current reaction, remove it
        if(post!.selfReact == reactType){
            TreemFeedService.sharedInstance.removePostReaction(
                CurrentTreeSettings.sharedInstance.treeSession,
                postID: self.post!.postId,
                success: {
                    data in
                    
                    self.postWasUpdated()
                    
                },
                failure: {
                    error, wasHandled in
                    
                    // cancel loading mask and return to view with alert
                    self.loadingMaskViewController.cancelLoadingMask({
                        CustomAlertViews.showGeneralErrorAlertView()
                    })
                }
            )
        }
        // else set a new reaction
        else{
            TreemFeedService.sharedInstance.setPostReaction (
                CurrentTreeSettings.sharedInstance.treeSession,
                postID: self.post!.postId,
                reaction: reactType,
                success: {
                    data in
                    
                    self.postWasUpdated()

                },
                failure: {
                    error, wasHandled in
                    
                    // cancel loading mask and return to view with alert
                    self.loadingMaskViewController.cancelLoadingMask({
                        CustomAlertViews.showGeneralErrorAlertView()
                    })
                }
            )
        }
    }
    
    func postWasUpdated() {
        
        if let postData = self.post {
            self.delegate?.postWasUpdated(postData)
        }
        
        self.dismissView()
    }    
    
    private func setSelected(emoButton: UIButton, emoLabel: UILabel){
        emoLabel.font = UIFont.boldSystemFontOfSize(20)
        emoLabel.textColor = AppStyles.sharedInstance.navBarTintColor
        emoLabel.shadowColor = AppStyles.sharedInstance.darkGrayColor
        
        emoButton.layer.shadowColor = AppStyles.sharedInstance.darkGrayColor.CGColor
        emoButton.layer.shadowOffset = CGSizeMake(0,0)
        emoButton.layer.shadowRadius = 10
        emoButton.layer.shadowOpacity = 1.0
    }
    
    private func dismissView(){ self.dismissViewControllerAnimated(true, completion: nil) }
    
    
}