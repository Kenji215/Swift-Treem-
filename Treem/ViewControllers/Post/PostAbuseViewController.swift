//
//  PostAbuseViewController.swift
//  Treem
//
//  Created by Tracy Merrill on 1/8/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class PostAbuseViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var abuseOptionsTableView: UITableView!
    
    @IBAction func close(sender: AnyObject) {
        dismissView()
    }
    
    @IBAction func reportPost(sender: AnyObject) {
        if tempAbuse?.reason != nil {
            setAbuse(tempAbuse!)
        }
    }
    
    var delegate : PostOptionsViewController? = nil
    var abusePostId                                 : Int = 0
    var abuseCallback                               : ((abuse: Abuse?) -> ())? = nil
    var timer : NSTimer                             = NSTimer()
    private let errorViewController                 = ErrorViewController.getStoryboardInstance()
    
    var tempAbuse : Abuse? = Abuse()
    
    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    static func getStoryboardInstance() -> PostAbuseViewController {
        let pvc = UIStoryboard(name: "PostAbuse", bundle: nil).instantiateInitialViewController() as! PostAbuseViewController
        
        pvc.modalPresentationStyle = UIModalPresentationStyle.Custom
        
        return pvc
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppStyles.sharedInstance.setSubHeaderBarStyles(self.headerView)
        
        self.closeButton.tintColor = AppStyles.sharedInstance.whiteColor
        
        self.abuseOptionsTableView.delegate = self
        self.abuseOptionsTableView.dataSource = self
        self.abuseOptionsTableView.separatorColor = AppStyles.sharedInstance.dividerColor
    }
    
    private func setAbuse(abuseType: Abuse){
        // else set a new reaction
        TreemFeedService.sharedInstance.setPostAbuse(
            CurrentTreeSettings.sharedInstance.treeSession,
            postID: self.abusePostId,
            abuse: abuseType,
            success: {
                data in

                self.errorViewController.showErrorMessageView(self.view, text: "The post has been reported.")
                
                self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(PostAbuseViewController.dismissView), userInfo: nil, repeats: false)
            },
            failure: {
                error, wasHandled in
                
                // cancel loading mask and return to view with alert
                self.loadingMaskViewController.cancelLoadingMask({
                    CustomAlertViews.showGeneralErrorAlertView()
                })
            }
        )
    }
    
    func dismissView() {
        self.errorViewController.dismissViewControllerAnimated(false, completion: nil)
        self.dismissViewControllerAnimated(false, completion: nil)
        self.delegate?.dismissViewTapHandler()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Abuse.AbuseReasons.allValues.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AbuseTableViewCell") as! AbuseTableViewCell
        
        if let abuse = Abuse.AbuseReasons(rawValue: indexPath.row){
            cell.abuseTypeLabel.text  = String(abuse.description)
            cell.tag = abuse.rawValue
        }
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let abuse = Abuse.AbuseReasons(rawValue: indexPath.row){
            tempAbuse?.reason = abuse
        }
    }
}

