//
//  ErrorViewController.swift
//  Treem
//
//  Created by Matthew Walker on 10/1/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class ErrorViewController : UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet var retryButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet var retryButtonTopConstraint: NSLayoutConstraint!
    
    @IBAction func retryButtonTouchUpInside(sender: AnyObject) {
        if let recover = self.recover {
            // remove no connection view
            if self.removeViewOnRecover {
                self.removeErrorView()
            }
            
            // retry same action
            recover()
        }
    }
    
    // closure to call on retry load attempt when no connection present
    private var recover : (() -> ())? = nil
    
    private var removeViewOnRecover: Bool = true
    
    private var bottomErrorLabelConstraint: NSLayoutConstraint? = nil
    
    // closure to call when the alert view is being dismissed
    private var willDismissAlertView: (() -> ())? = nil
    
    private var defaultRetryButtonFontSize: CGFloat = 14
    
    // return view controller instance with controller's views generated
    static func getStoryboardInstance() -> ErrorViewController {
        // return new instance -> possible to load another view while the previous view has a loading mask
        return UIStoryboard(name: "Error", bundle: nil).instantiateViewControllerWithIdentifier("Error") as! ErrorViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // store default button font size
        self.defaultRetryButtonFontSize = self.retryButton.titleLabel?.font.pointSize ?? 14
    }
    
    func removeErrorView() {
        // remove no connection view
        self.view.removeFromSuperview()
    }
    
    func showErrorMessageView(inView: UIView, text: String, recoverButtonTitle: String? = nil, removeViewOnRecover: Bool = true, recoverButtonFontSize: CGFloat? = nil, recover: (() -> Void)? = nil) {
        
        self.view.removeFromSuperview()
        self.removeViewOnRecover = removeViewOnRecover
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        // add constraints
        let horizontalConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: inView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: inView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: inView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: inView, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        
        self.errorLabel.text    = text
        self.recover            = recover

        if recover == nil {
            // deactivate retry button constraints
            NSLayoutConstraint.deactivateConstraints([self.retryButtonHeightConstraint, self.retryButtonTopConstraint])

            self.retryButton.hidden = true
            
            // add lower constraint
            if self.bottomErrorLabelConstraint == nil {
                self.bottomErrorLabelConstraint = NSLayoutConstraint(item: self.errorLabel, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
            }
            
            self.contentView.addConstraint(self.bottomErrorLabelConstraint!)
        }
        else {
            // activate retry button constraints
            NSLayoutConstraint.activateConstraints([self.retryButtonHeightConstraint, self.retryButtonTopConstraint])
            
            // deactive bottom constraint if previously added
            if let bottomConstraint = self.bottomErrorLabelConstraint {
                NSLayoutConstraint.deactivateConstraints([bottomConstraint])
            }
            
            self.retryButton.hidden = false
            self.retryButton.titleLabel?.font = UIFont.systemFontOfSize(recoverButtonFontSize ?? self.defaultRetryButtonFontSize)

            // change title without animating change
            UIView.performWithoutAnimation {
                self.retryButton.setTitle(recoverButtonTitle ?? "Retry", forState: .Normal)
                self.retryButton.layoutIfNeeded()
            }
        }
        
        inView.addSubview(self.view)
        
        inView.addConstraint(horizontalConstraint)
        inView.addConstraint(verticalConstraint)
        inView.addConstraint(widthConstraint)
        inView.addConstraint(heightConstraint)
    }
    
    func showGeneralErrorView(inView: UIView, recover: (() -> Void)? = nil) {
        self.showErrorMessageView(inView, text: Localization.sharedInstance.getLocalizedString("error_general", table: "Common"), recover: recover)
    }
    
    static func showLabelInView(inView: UIView, text: String) {
        let label = UILabel()
        
        label.text = text
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.baselineAdjustment = .AlignCenters
        
        // add constraints
        let horizontalConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: inView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: inView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: inView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: inView, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        
        inView.addSubview(label)
        
        inView.addConstraint(horizontalConstraint)
        inView.addConstraint(verticalConstraint)
        inView.addConstraint(widthConstraint)
        inView.addConstraint(heightConstraint)
    }
    
    func showNoNetworkView(inView: UIView, recover: (() -> Void)? = nil) {
        self.showErrorMessageView(inView, text: Localization.sharedInstance.getLocalizedString("aDN-9l-NDg.text", table: "Error"), recover: recover)
    }
    
    func showLockedOutView(inView: UIView, recover: (() -> Void)? = nil) {
        self.showErrorMessageView(inView, text: Localization.sharedInstance.getLocalizedString("locked_out", table: "Error"), recover: recover)
    }
    
    func showInvalidDeviceView(inView: UIView, recover: (() -> Void)? = nil) {
        self.showErrorMessageView(inView, text: Localization.sharedInstance.getLocalizedString("device_error", table: "Error"), recover: recover)
    }
    
    func showDeviceDisabledView(inView: UIView, recover: (() -> Void)? = nil) {
        self.showErrorMessageView(inView, text: Localization.sharedInstance.getLocalizedString("device_disabled", table: "Error"), recover: recover)
    }
    
    func showSimulatorNotSupportedView(inView: UIView) {
        self.showErrorMessageView(inView, text: Localization.sharedInstance.getLocalizedString("no_simulator_support", table: "Error"))
    }
}
