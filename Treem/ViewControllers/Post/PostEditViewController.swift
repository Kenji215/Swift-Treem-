//
//  PostEditViewController.swift
//  Treem
//
//  Created by Matthew Walker on 12/8/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class PostEditViewController : UIViewController, PostDelegate {
    
    @IBOutlet weak var editPostTitle: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var editPostId  : Int = 0
    var delegate    : PostDelegate? = nil
    var editTitle   : String? = nil
    var shareLink   : String? = nil
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedPostSegue" {
            if let vc = segue.destinationViewController as? PostViewController {
                vc.editPostId   = self.editPostId
                vc.delegate     = self
                vc.shareLink    = self.shareLink
            }
        }
    }
    
    static func getStoryboardInstance() -> PostEditViewController {
        return UIStoryboard(name: "PostEdit", bundle: nil).instantiateInitialViewController() as! PostEditViewController
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.closeButton.tintColor = AppStyles.sharedInstance.whiteColor
        
        AppStyles.sharedInstance.setSubHeaderBarStyles(self.headerView)
        
        if let title = self.editTitle {
            self.editPostTitle.text = title
        }
    }
    
    func postWasAdded() {
        self.delegate?.postWasAdded()
    }
    
    func postWasUpdated(post: Post) {
        self.delegate?.postWasUpdated(post)
    }
    
    func postWasDeleted(postID: Int) {
        self.delegate?.postWasDeleted(postID)
    }
    
}
