//
//  LoadingMaskViewController.swift
//  Treem
//
//  Created by Matthew Walker on 10/1/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class LoadingMaskViewController : UIViewController {
    
    @IBOutlet weak var mainActivityIndicator: UIActivityIndicatorView!
    
    // time (seconds) to wait before showing activity indicator
    private var timer                   : NSTimer?          = nil
    private var showCompletion          : (() -> Void)?     = nil
    private var containerView           : UIView?           = nil
    private var loadingViewAlpha        : CGFloat           = 0.75
    private var defaultViewAlpha        : CGFloat           = 0.75
    private var progressView            : UIProgressView?   = nil
    
    var activityColor: UIColor = AppStyles.sharedInstance.darkGrayColor
    
    private func cancelTimer() {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
    private func resetSettings() {
        self.cancelTimer()
        
        self.containerView  = nil
        self.showCompletion = nil
        self.progressView = nil
    }
    
    // return view controller instance with controller's views generated
    static func getStoryboardInstance() -> LoadingMaskViewController {
        // return new instance -> possible to load another view while the previous view has a loading mask
        return UIStoryboard(name: "LoadingMask", bundle: nil).instantiateViewControllerWithIdentifier("LoadingMask") as! LoadingMaskViewController
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // dismiss presented view from parent
        if self.containerView != nil {
            self.view.removeFromSuperview()
        }
        
        // cleanup if mask view gets dismissed elsewhere
        self.resetSettings()
    }
    
    func queueLoadingMask(inView: UIView, timeBeforeShowingMask: NSTimeInterval = 0, loadingViewAlpha: CGFloat? = nil, showCompletion: (() -> Void)?) {
        self.containerView      = inView
        self.showCompletion     = showCompletion
        
        // override alpha value if given
        if let alpha = loadingViewAlpha {
            self.loadingViewAlpha = alpha
        }
        else {
            self.loadingViewAlpha = defaultViewAlpha
        }
        
        // close keyboards if open
        inView.endEditing(true)
        
        // cancel previous timer
        if timeBeforeShowingMask == 0 {
            self.showLoadingMask()
        }
        else if self.timer == nil {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(timeBeforeShowingMask, target: self, selector: #selector(LoadingMaskViewController.showLoadingMask), userInfo: nil, repeats: false)
        }
    }
    
    func queueProgressMask(inView: UIView, timeBeforeShowingMask: NSTimeInterval = 0, loadingViewAlpha: CGFloat? = nil, showCompletion: (() -> Void)?) {
        self.containerView      = inView
        self.showCompletion     = showCompletion
        
        // override alpha value if given
        if let alpha = loadingViewAlpha {
            self.loadingViewAlpha = alpha
        }
        else {
            self.loadingViewAlpha = defaultViewAlpha
        }
        
        // close keyboards if open
        inView.endEditing(true)
        
        // cancel previous timer
        if timeBeforeShowingMask == 0 {
            self.showProgressMask()
        }
        else if self.timer == nil {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(timeBeforeShowingMask, target: self, selector: #selector(LoadingMaskViewController.showProgressMask), userInfo: nil, repeats: false)
        }
    }
    
    func showMaskOnly(inView: UIView, loadingViewAlpha: CGFloat? = nil, showCompletion: (() -> Void)?) {
        self.containerView      = inView
        self.showCompletion     = showCompletion
        self.view.backgroundColor = AppStyles.sharedInstance.midGrayColor
        
        // override alpha value if given
        if let alpha = loadingViewAlpha {
            self.loadingViewAlpha = alpha
        }
        else {
            self.loadingViewAlpha = defaultViewAlpha
        }
        
        // close keyboards if open
        inView.endEditing(true)
        
        dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue(), {
            ()->() in
            self.mainActivityIndicator.stopAnimating()
            self.mainActivityIndicator.hidden = true
            self.showLoadingMask()
        })
    }
    
    func cancelLoadingMask(completion: (() -> Void)?) {
        // dismiss presented view from parent
        if self.containerView != nil {
            self.view.removeFromSuperview()
        }
        
        // reset viewcontroller settings
        self.resetSettings()
        
        // call completion
        if let completion = completion {
            completion()
        }
    }
    
    func updateProgress(progress: CGFloat){
        if let progView = self.progressView {
            #if DEBUG
                print("Updating progress: " + String(progress))
            #endif
            progView.setProgress(Float(progress), animated: true)
        }
    }
    
    func showProgressMask(){
        // cancel in case show is called prior to timer completion
        self.cancelTimer()
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        if let containerView = self.containerView {
            
            // remove the activity indicator
            for view in self.view.subviews{ view.removeFromSuperview() }
            
            self.progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
            self.progressView!.frame = CGRectMake(10, containerView.bounds.height / 2,containerView.bounds.width - 20,10 )
            self.progressView!.progress = 0
            
            self.view.addSubview(progressView!)
            
            self.addSelfToContainerView()
        
        }
        
        self.showCompletion?()
    }
    
    func showLoadingMask() {
        // cancel in case show is called prior to timer completion
        self.cancelTimer()
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        if let containerView = self.containerView {
            // if frame smaller, show smaller loading indicator
            self.mainActivityIndicator.activityIndicatorViewStyle = containerView.frame.height < 60 ? .White : .WhiteLarge
            self.mainActivityIndicator.color = self.activityColor
            
            self.addSelfToContainerView()
        }
        
        self.showCompletion?()
    }
    
    
    private func addSelfToContainerView(){
        if let containerView = self.containerView {
            // add constraints
            let horizontalConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
            let verticalConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)
            let widthConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
            let heightConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
            
            containerView.addSubview(self.view)
            
            containerView.addConstraint(horizontalConstraint)
            containerView.addConstraint(verticalConstraint)
            containerView.addConstraint(widthConstraint)
            containerView.addConstraint(heightConstraint)
            
            if let bgColor = self.view.backgroundColor {
                self.view.backgroundColor = bgColor.colorWithAlphaComponent(self.loadingViewAlpha)
            }
        }
    }
}
