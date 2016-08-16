//
//  WebBrowserViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/28/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import WebKit

class WebBrowserViewController: UIViewController, WKNavigationDelegate {

    // --------------------------------- //
    // Instantiate Variables
    // --------------------------------- //
    
    var webView : WKWebView
    
    var webUrl : String? = nil {
        didSet {
            // preload request prior to view load
            if let urlStr = self.webUrl, url = NSURL (string: urlStr) {
                let requestObj = NSURLRequest(URL: url)
                
                self.webView.loadRequest(requestObj)
            }
        }
    }
    var defaultTitle            : String? = nil
    var isPrivateMode           : Bool = false
    var shareDelegate           : WebBrowserDelegate?    = nil
    
    var branchColor: UIColor = UIColor.lightGrayColor() {
        didSet {
            self.headerFooterColorUpdated()
        }
    }
    
    private let loadingMaskViewController = LoadingMaskViewController.getStoryboardInstance()
    
    // --------------------------------- //
    // Storyboard Outlets
    // --------------------------------- //
 
    @IBOutlet weak var webViewContainer: UIView!
    @IBOutlet weak var headerBarView: UIView!
    @IBOutlet weak var branchTitleLabel: UILabel!
    @IBOutlet weak var closeButton: UIView!

    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var webNavBar: UIView!
    @IBOutlet weak var webNavBackButton: UIButton!
    @IBOutlet weak var webNavForwardButton: UIButton!
    
    // --------------------------------- //
    // Static Functions
    // --------------------------------- //
    
    static func getStoryboardInstance() -> WebBrowserViewController {
        return UIStoryboard(name: "WebBrowser", bundle: nil).instantiateInitialViewController() as! WebBrowserViewController
    }

    required init?(coder aDecoder: NSCoder) {
        self.webView = WKWebView(frame: CGRectZero)
        
        super.init(coder: aDecoder)
    }
    
    // --------------------------------- //
    // Load Overrides
    // --------------------------------- //
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    // Allow landscape view of url
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .LandscapeLeft, .LandscapeRight]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // if web url not passed then dismiss view
        if self.webUrl == nil || NSURL(string: self.webUrl!) == nil {
            self.dismissView()
        }
        
        self.webView.navigationDelegate = self
        
        self.loadingMaskViewController.queueLoadingMask(self.webView, timeBeforeShowingMask: 0.05, showCompletion: nil)
        
        self.branchTitleLabel.textColor = UIColor.whiteColor()
        
        // style bottom nav
        self.webNavBar.backgroundColor = AppStyles.sharedInstance.lightGrayColor
        
        self.addDisableButtonTitleStyles(self.shareButton)
        self.addDisableButtonTitleStyles(self.webNavBackButton)
        self.addDisableButtonTitleStyles(self.webNavForwardButton)
        
        self.shareButton.enabled            = false
        self.webNavBackButton.enabled       = false
        self.webNavForwardButton.enabled    = false
        
        // set the header / footer colors
        self.headerFooterColorUpdated()
        
        // set the title
        self.branchTitleLabel.text = self.defaultTitle
        
        if(self.shareDelegate == nil){
            self.shareButton.hidden = true
        }
        
        self.webViewContainer.addSubview(self.webView)

        self.webView.translatesAutoresizingMaskIntoConstraints = false
        
        let height  = NSLayoutConstraint(item: self.webView, attribute: .Height, relatedBy: .Equal, toItem: self.webViewContainer, attribute: .Height, multiplier: 1, constant: 0)
        let width   = NSLayoutConstraint(item: self.webView, attribute: .Width, relatedBy: .Equal, toItem: self.webViewContainer, attribute: .Width, multiplier: 1, constant: 0)
        let top     = NSLayoutConstraint(item: self.webView, attribute: .Top, relatedBy: .Equal, toItem: self.webViewContainer, attribute: .Top, multiplier: 1, constant: 0)
        
        self.webViewContainer.addConstraints([height, width, top])
    }
    
    // When content has loaded
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        // enable share button
        self.shareButton.enabled            = true
        
        // enable / disabled back and forward buttons
        self.webNavBackButton.enabled       = self.webView.canGoBack
        self.webNavForwardButton.enabled    = self.webView.canGoForward
        
        self.loadingMaskViewController.cancelLoadingMask(nil)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        if let title = self.webView.title where !title.isEmpty {
            self.branchTitleLabel.text = title
        }
        else {
            self.branchTitleLabel.text = "Untitled Document"
        }
    }

    // Error loading content
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        self.loadingMaskViewController.cancelLoadingMask(nil)
    }
    
    // Redirect to another page occurs
    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        self.loadingMaskViewController.cancelLoadingMask(nil)
    }
    
    // --------------------------------- //
    // Storyboard Actions
    // --------------------------------- //
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.dismissView()
    }
    
    @IBAction func shareButtonTouchUpInside(sender: AnyObject) {
        if let currentURL : NSString = (self.webView.URL!.absoluteString) {
            self.shareDelegate?.shareWebLink(
                self
                , webLink: (currentURL as String)
            )
        }
    }
    
    @IBAction func webNavBackButtonTouchUpInside(sender: AnyObject) {
        if(self.webView.canGoBack){
            self.webView.goBack()
        }
    }
    
    @IBAction func webNavForwardButtonTouchUpInside(sender: AnyObject) {
        if(self.webView.canGoForward){
            self.webView.goForward()
        }
    }
  
    // --------------------------------- //
    // Private Functions
    // --------------------------------- //
    private func headerFooterColorUpdated() {
        if self.isViewLoaded() {
            let adjustedColor = self.isPrivateMode ? self.branchColor.lighterColorForColor(0.2) : self.branchColor.darkerColorForColor(0.2)
            
            self.headerBarView.backgroundColor = self.branchColor
            self.closeButton.tintColor = adjustedColor
        }
    }
    
    private func dismissView(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func addDisableButtonTitleStyles(theButton: UIButton) {
        theButton.tintColor = AppStyles.sharedInstance.darkGrayColor
        theButton.setTitleColor(AppStyles.sharedInstance.darkGrayColor, forState: .Normal)
        theButton.setTitleColor(AppStyles.sharedInstance.disabledButtonTitleGray, forState: .Disabled)
    }
}