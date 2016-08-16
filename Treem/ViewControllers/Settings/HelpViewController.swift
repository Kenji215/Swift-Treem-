//
//  HelpViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/14/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import WebKit

class HelpViewController: UIViewController, UIWebViewDelegate, WKNavigationDelegate {
    
    private let loadingMaskViewController       = LoadingMaskViewController.getStoryboardInstance()
    
    private var webView : WKWebView
    
    required init?(coder aDecoder: NSCoder) {
        let config = WKWebViewConfiguration()
        let preferences = WKPreferences()
        
        preferences.minimumFontSize = 16
        config.preferences = preferences
        
        self.webView = WKWebView(frame: CGRectZero, configuration: config)
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadingMaskViewController.queueLoadingMask(self.view, timeBeforeShowingMask: 0.15, showCompletion: nil)
        
        // load the help url
        if let url = NSURL (string: AppSettings.treem_help_site) {
            let requestObj = NSURLRequest(URL: url, cachePolicy: .ReloadIgnoringCacheData, timeoutInterval: 300) // 5 minutes
        
            self.webView.loadRequest(requestObj)
        }
        
        self.webView.navigationDelegate = self
        
        self.view.addSubview(self.webView)
        
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        
        let height = NSLayoutConstraint(item: self.webView, attribute: .Height, relatedBy: .Equal, toItem: self.view, attribute: .Height, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: self.webView, attribute: .Width, relatedBy: .Equal, toItem: self.view, attribute: .Width, multiplier: 1, constant: 0)
        let top = NSLayoutConstraint(item: self.webView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1, constant: 0)
        
        self.view.addConstraints([height, width, top])
    }
    
    // When some content has loaded
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        self.loadingMaskViewController.cancelLoadingMask(nil)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        self.loadingMaskViewController.cancelLoadingMask(nil)
    }
}
