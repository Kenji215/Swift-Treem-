//
//  FeedTableViewCell.swift
//  Treem
//
//  Created by Matthew Walker on 12/2/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class FeedTableViewCell: UITableViewCell {

    // share views
    @IBOutlet weak var shareBranchesContainer   : BranchContainer!
    @IBOutlet weak var shareButton              : FeedActionButton!
    @IBOutlet weak var shareAvatarImageView     : UIImageView!
    @IBOutlet weak var shareNameLabel           : UILabel!
    @IBOutlet weak var shareDateLabel           : UILabel!
    @IBOutlet weak var shareMessage             : CopyableLabel!
    @IBOutlet weak var sharePostOptionsButton   : FeedActionButton!
    @IBOutlet weak var sharePosterContainer     : UIView!

    // share constraints
    @IBOutlet weak var sharePostContainerTopConstraint      : NSLayoutConstraint!
    @IBOutlet weak var sharePosterContainerHeightConstraint : NSLayoutConstraint!
    @IBOutlet weak var shareMessageTopConstraint            : NSLayoutConstraint!
    @IBOutlet weak var shareMessageBottomConstraint         : NSLayoutConstraint!
    @IBOutlet weak var shareMessageHeightConstraint         : NSLayoutConstraint!
    
    // regular post views
    @IBOutlet weak var nameLabel                    : UILabel!
    @IBOutlet weak var messageTextLabel             : CopyableLabel!
    @IBOutlet weak var dateLabel                    : UILabel!
    @IBOutlet weak var avatarImageView              : UIImageView!
    @IBOutlet weak var commentsButton               : FeedActionButton!
    @IBOutlet weak var reactButton                  : FeedActionButton!
    @IBOutlet weak var postOptionsButton            : FeedActionButton!
    @IBOutlet weak var taggedButton                 : UIButton!
    @IBOutlet weak var mediaContainerView           : UIView!
    @IBOutlet weak var reactContainerView           : UIView!
    @IBOutlet weak var postView                     : UIView!
    @IBOutlet weak var branchesContainer            : BranchContainer!
    @IBOutlet weak var actionView                   : UIView!
    @IBOutlet weak var postUrlPreviewView           : UIView!
    @IBOutlet weak var commentCountLabel: UILabel!
    
    // action view references
    let actionViewFontSize      : CGFloat = 12
    var selectedReactionButton  : ReactionButton? = nil

    // regular post constraints
    @IBOutlet weak var posterContainerTopConstraint         : NSLayoutConstraint!
    @IBOutlet weak var posterContainerHeightConstraint      : NSLayoutConstraint!
    @IBOutlet weak var taggedButtonTopConstraint            : NSLayoutConstraint!
    @IBOutlet weak var taggedButtonHeightShowConstraint     : NSLayoutConstraint!
    @IBOutlet weak var taggedButtonBottomConstraint         : NSLayoutConstraint!
    @IBOutlet weak var messageTextBottomConstraint          : NSLayoutConstraint!
    @IBOutlet weak var mediaContainerViewHeightConstraint   : NSLayoutConstraint!
    @IBOutlet weak var mediaContainerBottomConstraint       : NSLayoutConstraint!
    @IBOutlet weak var reactContainerViewTopConstraint      : NSLayoutConstraint!
    @IBOutlet weak var reactContainerViewHeightConstraint   : NSLayoutConstraint!
    @IBOutlet weak var reactContainerViewWidthConstraint    : NSLayoutConstraint!
    @IBOutlet weak var reactContainerViewBottomConstraint   : NSLayoutConstraint!
    @IBOutlet weak var actionViewHeightConstraint           : NSLayoutConstraint!
    @IBOutlet weak var postBottomOptionsHeightConstraint    : NSLayoutConstraint!
    @IBOutlet weak var lowerGapHeightConstraint             : NSLayoutConstraint!
    @IBOutlet weak var messageHeightConstraint              : NSLayoutConstraint!
    @IBOutlet weak var postUrlPreviewViewHeightConstraint   : NSLayoutConstraint!
    @IBOutlet weak var postUrlPreviewBottomConstraint       : NSLayoutConstraint!
    
    override func prepareForReuse() {
        // clear changed avatar image
        self.avatarImageView.image = UIImage(named: "Avatar")
    }

    // default to not show
    func resetActionView() {
        self.actionView.subviews.forEach({ $0.removeFromSuperview() })
        self.selectedReactionButton = nil
    }
}