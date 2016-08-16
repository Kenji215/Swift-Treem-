//
//  MediaImageViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/18/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

class MediaImageViewController: UIViewController, UIScrollViewDelegate {

    var contentId               : Int?          = nil
    var contentUrl              : NSURL?        = nil
    var contentUrlId            : String?       = nil
    var contentOwner            : Bool?         = nil
    var deletedCallback         : (() -> ())?   = nil
    
    private var loadingMaskViewController = LoadingMaskViewController.getStoryboardInstance()
    
    @IBOutlet weak var scrollView       : UIScrollView!
    @IBOutlet weak var imageView        : UIImageView!
    @IBOutlet weak var closeButton      : UIButton!
    @IBOutlet weak var trashButton      : UIButton!
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.dismissView()
    }
    
    @IBAction func trashButtonTouchUpInside(sender: AnyObject) {
        
        CustomAlertViews.showCustomConfirmView(title: Localization.sharedInstance.getLocalizedString("delete_confirm_title", table: "MediaImage")
            , message: Localization.sharedInstance.getLocalizedString("delete_confirm_message", table: "MediaImage")
            , fromViewController: self
            , yesHandler: {
                alertAction in
                
                self.showLoadingMask()
                
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                    TreemContentService.sharedInstance.removeImage(
                        self.contentId!
                        , treeSession: CurrentTreeSettings.sharedInstance.treeSession
                        , success: {
                            data in
                            
                            self.cancelLoadingMask({
                                self.dismissView({ self.deletedCallback?() })
                            })
                            
                        }
                        , failure: {
                            error, wasHandled in
                            
                            self.cancelLoadingMask({
                                CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                            })
                        }
                    )
                }
                
            }
            , noHandler: {
                alertAction in
                
            })
    }
    
    static func getStoryboardInstance() -> MediaImageViewController {
        return UIStoryboard(name: "MediaImage", bundle: nil).instantiateInitialViewController() as! MediaImageViewController
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.minimumZoomScale = 1.0          // can't be smaller than the original
        self.scrollView.maximumZoomScale = 10.0         // up to 10x the original

        if let url = self.contentUrl {
            self.loadImageWithUrl(url, cacheKey: self.contentUrlId)
        }
        else if let cId = contentId {
            TreemContentService.sharedInstance.getImageDetails(
                cId
                , treeSession: CurrentTreeSettings.sharedInstance.treeSession
                , success:
                {
                    (data:JSON) in
                    
                    let iData : ContentItemDownloadImage = ContentItemDownloadImage(data: data)
                    
                    if let url = iData.url{
                        self.loadImageWithUrl(url, cacheKey: self.contentUrlId)
                    }
                    else {
                        self.dismissView()
                    }
                }
                , failure: {
                    (error, wasHandled) -> Void in
                    
                    if(!wasHandled){
                        CustomAlertViews.showGeneralErrorAlertView()
                    }
                    
                    self.dismissView()
                }
            )
        }
        else { self.dismissView() } // no content to show
        
        let actionTintColor = self.view.backgroundColor?.lighterColorForColor(0.5)
        
        if (self.contentId == nil || self.contentOwner != true){
            self.trashButton.hidden = true
        }
        else{
            self.trashButton.tintColor = actionTintColor
        }
        
        self.closeButton.tintColor = actionTintColor
    }
    
    private func loadImageWithUrl(url: NSURL, cacheKey: String?){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            TreemContentService.sharedInstance.getContentRepositoryFile(url, cacheKey: cacheKey, success: {
                (image) -> () in
                
                dispatch_async(dispatch_get_main_queue(), {
                    _ in
                    
                    self.imageView.image = image
                })
            })
        })
    }
    
    private func dismissView(completion: (() -> ())?=nil){
        self.dismissViewControllerAnimated(true, completion: completion)
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    private func showLoadingMask(completion: (() -> Void)?=nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.queueLoadingMask(self.scrollView, loadingViewAlpha: 1.0, showCompletion: completion)
        }
    }
    
    private func cancelLoadingMask(completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.cancelLoadingMask(completion)
        }
    }
}
