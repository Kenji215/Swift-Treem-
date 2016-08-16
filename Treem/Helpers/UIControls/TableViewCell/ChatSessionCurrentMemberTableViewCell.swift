//
//  ChatSessionCurrentMemberTableViewCell.swift
//  Treem
//
//  Created by Matthew Walker on 4/21/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class ChatSessionCurrentMemberTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel    : UILabel!
    @IBOutlet weak var avatar       : UIImageView!
    @IBOutlet weak var dateLabel    : UILabel!
    @IBOutlet weak var messageView  : UIView!

    @IBOutlet weak var messageViewHeightConstraint  : NSLayoutConstraint!
    @IBOutlet weak var messageViewWidthConstraint   : NSLayoutConstraint!
}