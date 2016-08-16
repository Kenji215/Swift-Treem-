//
//  MediaVideoViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/19/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import AVKit
import AVFoundation
import SwiftyJSON

class MediaVideoViewController: AVPlayerViewController {
    
    var contentId               : Int? = nil
    var contentUrl              : NSURL? = nil
    var contentOwner            : Bool? = nil
    
    private var loadingMaskViewController           = LoadingMaskViewController.getStoryboardInstance()
    
    private var videoData       : NSData? = nil
    
    static func getStoryboardInstance() -> MediaVideoViewController {
        return UIStoryboard(name: "MediaVideo", bundle: nil).instantiateInitialViewController() as! MediaVideoViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = contentUrl {
            self.loadPlayerWithUrl(url)
        }
        else if let cId = contentId {
            self.showLoadingMask()
            TreemContentService.sharedInstance.getVideoDetails(
                cId
                , treeSession: CurrentTreeSettings.sharedInstance.treeSession
                , success:
                {
                    (data:JSON) in
                    
                    self.cancelLoadingMask({
                        let vData : ContentItemDownloadVideo = ContentItemDownloadVideo(data: data)
                        
                        if let url = vData.videoURL { self.loadPlayerWithUrl(url) }
                        else { self.dismissView() }  // no video url to load
                    })
                }
                , failure: {
                    (error, wasHandled) -> Void in
                    
                    self.cancelLoadingMask({
                        if(!wasHandled){
                            CustomAlertViews.showGeneralErrorAlertView()
                        }
                        
                        self.dismissView()
                    })
                }
            )
        }
        else { self.dismissView() } // no video to load
    }
    
    private func loadPlayerWithUrl(url: NSURL){
        let item = AVPlayerItem(URL: url)
        let player = AVPlayer(playerItem: item)
        let playerController = AVPlayerViewController()
        
        playerController.player = player
        self.addChildViewController(playerController)
        self.view.addSubview(playerController.view)
        playerController.view.frame = self.view.frame
        
        player.play()
    }
    
    func dismissView(completion: (() -> ())? = nil){
        self.dismissViewControllerAnimated(true, completion: completion)
    }
    
    private func showLoadingMask(completion: (() -> Void)?=nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.queueLoadingMask(self.view, loadingViewAlpha: 1.0, showCompletion: completion)
        }
    }
    
    private func cancelLoadingMask(completion: (() -> Void)? = nil) {
        dispatch_async(dispatch_get_main_queue()) {
            self.loadingMaskViewController.cancelLoadingMask(completion)
        }
    }
}
