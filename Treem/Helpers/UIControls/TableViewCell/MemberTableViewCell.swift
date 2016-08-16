//
//  MemberTableViewCell.swift
//  Treem
//
//  Created by Matthew Walker on 10/28/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class MemberTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView      : UIImageView!
    @IBOutlet weak var primaryLabel         : UILabel!
    @IBOutlet weak var contactNameLabel     : UILabel!
    @IBOutlet weak var secondaryLabel       : UILabel!
    @IBOutlet weak var usernameLabel        : UILabel!
    @IBOutlet weak var checkboxButton       : CheckboxButton!

    @IBOutlet weak var userNameIconImageView: UIImageView!
    @IBOutlet weak var detailsContainer: UIView!
    @IBOutlet weak var branchesContainer: BranchContainer!
    @IBOutlet weak var branchesContainerWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var statusIconImageView          : UIImageView!
    @IBOutlet weak var statusIconWidthConstraint    : NSLayoutConstraint!
    @IBOutlet weak var checkboxButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var cellLeadingConstraint        : NSLayoutConstraint!

    @IBOutlet weak var usernameIconWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var usernameLabelLeadingConstraint: NSLayoutConstraint!



    func setSelectedStyles(isSelected: Bool) {

        if (isSelected) {
            self.checkboxButton.checked             = true
            self.checkboxButton.backgroundColor     = AppStyles.sharedInstance.tintColor.colorWithAlphaComponent(0.15)
            self.detailsContainer.backgroundColor   = AppStyles.sharedInstance.tintColor.colorWithAlphaComponent(0.15)
        }
        else {
            self.checkboxButton.checked             = false
            self.checkboxButton.backgroundColor     = UIColor.whiteColor()
            self.detailsContainer.backgroundColor   = UIColor.whiteColor()
        }
    }
}
