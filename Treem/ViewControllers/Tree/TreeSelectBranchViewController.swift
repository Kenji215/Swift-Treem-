//
//  TreeSelectBranchViewController.swift
//  Treem
//
//  Created by Kevin Novak on 12/17/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class TreeSelectBranchFormViewController: UIViewController {

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var selectBranchView           : UIView!

    @IBOutlet weak var actionTitleLabel: UILabel!

    @IBOutlet weak var branchTitleLabel           : UILabel!
    @IBOutlet weak var selectBranchCancelButton   : UIButton!

    @IBOutlet var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var subHeaderViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // apply styles to sub header view
        AppStyles.sharedInstance.setSubHeaderBarStyles(self.headerView)
        
        self.selectBranchCancelButton.tintColor = AppStyles.sharedInstance.whiteColor
    }

    func setActionTitle(title: String) {
        self.actionTitleLabel.text              = title
    }

    func setBranchBar(branch: Branch) {
        self.branchTitleLabel.backgroundColor   = branch.color
        self.branchTitleLabel.text              = branch.title
    }
    
    func getViewHeight() -> CGFloat{
        return self.headerViewHeightConstraint.constant + self.subHeaderViewHeightConstraint.constant
    }
}
