//
//  SettingsViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/12/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var headerBarView                : UIView!
    @IBOutlet weak var SettingsLabelLeadConstraint  : NSLayoutConstraint!
    @IBOutlet weak var BackButton                   : UIButton!
    @IBOutlet weak var SettingsLabel                : UILabel!
    
    private var embeddedNavigationViewController : UINavigationController!
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "EmbedSettingsNavigationSegue") {
            self.embeddedNavigationViewController = segue.destinationViewController as! UINavigationController
            self.addChildViewController(self.embeddedNavigationViewController)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // apply styles to sub header bar
        AppStyles.sharedInstance.setSubHeaderBarStyles(headerBarView)
        self.view.backgroundColor = AppStyles.sharedInstance.subBarBackgroundColor        
        
        // override appearance styles
        self.BackButton.tintColor = UIColor.whiteColor().darkerColorForColor()
    }
    
    static func getStoryboardInstance() -> SettingsViewController {
        return UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as! SettingsViewController
    }
}
