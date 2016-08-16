//
//  InfoMessageViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 3/8/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
class InfoMessageViewController : UIViewController, UIViewControllerTransitioningDelegate {

    var infoMessage         : String? = nil
    var onDismiss           : (() -> ())? = nil
    
    // icon outlets
    @IBOutlet weak var infoIcon: UIImageView!
    @IBOutlet weak var infoIconLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoIconRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoIconWidthConstraint: NSLayoutConstraint!
    
    // label outlets
    @IBOutlet weak var infoMessageLabel: UILabel!
    @IBOutlet weak var infoMessageLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoMessageLabelRightConstraint: NSLayoutConstraint!
    
    private var infoMessageFont        : UIFont    = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)
    
    static func getStoryboardInstance() -> InfoMessageViewController {
        return UIStoryboard(name: "InfoMessage", bundle: nil).instantiateInitialViewController() as! InfoMessageViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = AppStyles.overlayColor
        
        if let message = self.infoMessage {
            
            // dismiss the view when the "dark" area is tapped
            self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(InfoMessageViewController.dismissView)))
            
            // set styles for label / icon
            self.infoIcon.tintColor = AppStyles.sharedInstance.whiteColor
            self.infoMessageLabel.font = self.infoMessageFont
            self.infoMessageLabel.textColor = AppStyles.sharedInstance.whiteColor
            self.infoMessageLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
            self.infoMessageLabel.numberOfLines = 0
            self.infoMessageLabel.textAlignment = NSTextAlignment.Left
            self.infoMessageLabel.sizeToFit()
            self.infoMessageLabel.text = message
            
            
            // figure out the height of the label based on the text
            let variance = CGFloat(1)
     
            let msgLabelWidth = UIScreen.mainScreen().bounds.width -
                            (self.infoIconLeftConstraint.constant +
                                self.infoIconRightConstraint.constant +
                                self.infoIconWidthConstraint.constant +
                                self.infoMessageLabelRightConstraint.constant)
            
            let labelHeight = message.labelHeightWithConstrainedWidth(msgLabelWidth, font: self.infoMessageFont) + variance
            
            if(labelHeight > self.infoMessageLabelHeightConstraint.constant){
                self.infoMessageLabelHeightConstraint.constant = labelHeight
            }
            
        }
        else { self.dismissView() }

    }
    
    
    func dismissView() {
        self.dismissViewControllerAnimated(true, completion: { self.onDismiss?() })
    }
    
}
