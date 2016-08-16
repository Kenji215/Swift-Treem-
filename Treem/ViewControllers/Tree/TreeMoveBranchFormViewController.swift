//
//  TreeMoveBranchFormViewController.swift
//  Treem
//
//  Created by Matthew Walker on 9/8/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class TreeMoveBranchFormViewController: UIViewController {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var moveBranchView           : UIView!
    @IBOutlet weak var branchTitleLabel         : UILabel!
    @IBOutlet weak var moveBranchCancelButton   : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // apply styles to sub header view
        AppStyles.sharedInstance.setSubHeaderBarStyles(self.headerView)
        
        self.moveBranchCancelButton.tintColor = AppStyles.sharedInstance.whiteColor
    }
    
    func setBranchBar(branch: Branch) {
        self.branchTitleLabel.backgroundColor   = branch.color
        self.branchTitleLabel.text              = branch.title
    }
}
