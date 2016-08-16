//
//  ReplyTableViewCell.swift
//  Treem
//
//  Created by Kevin Novak on 12/30/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

import UIKit

class ReplyTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel        : UILabel!
    @IBOutlet weak var dateLabel        : UILabel!
    @IBOutlet weak var replyTextLabel   : CopyableLabel!
    
    @IBOutlet weak var postOptionsButton: FeedActionButton!
    
    @IBOutlet weak var messageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var UrlPreviewView   : UIView!
    @IBOutlet weak var UrlPreviewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var UrlPreviewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var mediaContainerView: UIView!
    @IBOutlet weak var mediaContainerViewHeightConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var reactButton: FeedActionButton!
    
    @IBOutlet weak var actionView: UIView!
    @IBOutlet weak var actionViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var reactView: UIView!
    
    @IBOutlet weak var reactCountsView: UIView!
    @IBOutlet weak var reactCountsViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var reactCountsViewRightConstraint: NSLayoutConstraint!
    
    var contentItems    : [ContentItemDelegate]? = nil
    
    var selectedReactionButton  : ReactionButton? = nil
    
    // default to not show
    func resetActionView() {
        self.actionView.subviews.forEach({ $0.removeFromSuperview() })
        self.selectedReactionButton = nil
    }
    
}