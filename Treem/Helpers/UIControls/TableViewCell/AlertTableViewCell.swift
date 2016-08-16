//
//  AlertTableViewCell.swift
//  Treem
//
//  Created by Kevin Novak on 12/4/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation

import UIKit

class AlertTableViewCell: UITableViewCell {

    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var unreadIndicator: UILabel!
    @IBOutlet weak var ButtonContainer: UIView!
    @IBOutlet weak var Response1Button: UIButton!
    @IBOutlet weak var Response2Button: UIButton!
    @IBOutlet weak var checkboxButton: CheckboxButton!
    
    @IBOutlet weak var avatarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var lowerGapHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonContainerHeightConstraint: NSLayoutConstraint!
    
    // set when cell has been viewed
    var cellWasViewed = false
    
    override func prepareForReuse() {
        // clear changed avatar image
        self.avatar.image = UIImage(named: "Avatar")
    }
}