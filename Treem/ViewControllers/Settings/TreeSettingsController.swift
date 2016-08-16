//
//  TreeSettingsController.swift
//  Treem
//
//  Created by Daniel Sorrell on 12/4/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

class TreeSettingsController: UIViewController {
    
    @IBOutlet var scrollView: UIView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var notificationsSwitch: UISwitch!

    private let loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController         = ErrorViewController.getStoryboardInstance()
    
    
    @IBAction func notificationSwitchChange(sender: AnyObject) {
        
        let trSettings = TreeSettings(_push_notif: notificationsSwitch.on)
        
        TreemProfileService.sharedInstance.setTreeSettings(
            CurrentTreeSettings.sharedInstance.treeSession,
            treeSettings: trSettings,
            failureCodesHandled: [
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.DisabledConsumerKey
            ],
            success:
            {
                (data:JSON) in
                // do nothing...
                
            },
            failure: {
                error,wasHandled in
                self.loadingMaskViewController.cancelLoadingMask({
                    if !wasHandled {
                        // if network error
                        if (error == TreemServiceResponseCode.NetworkError) {
                            self.errorViewController.showNoNetworkView(self.view, recover: {
                                self.getUserTreeSettings()
                            })
                        }
                        else if (error == TreemServiceResponseCode.LockedOut) {
                            self.errorViewController.showLockedOutView(self.view, recover: {
                                self.getUserTreeSettings()
                            })
                        }
                        else if (error == TreemServiceResponseCode.DisabledConsumerKey) {
                            self.errorViewController.showDeviceDisabledView(self.view, recover: {
                                self.getUserTreeSettings()
                            })
                        }
                    }
                })
            }
        )

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadingMaskViewController.queueLoadingMask(self.scrollContentView, loadingViewAlpha: 1.0, showCompletion: nil)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.getUserTreeSettings()
    
    }
    
    private func getUserTreeSettings() {

        TreemProfileService.sharedInstance.getTreeSettings(
            CurrentTreeSettings.sharedInstance.treeSession,
            failureCodesHandled: [
                TreemServiceResponseCode.NetworkError,
                TreemServiceResponseCode.LockedOut,
                TreemServiceResponseCode.DisabledConsumerKey
            ],
            success:
            {
                (data:JSON) in
                
                
                //Parse the json data and turn it into a Rollout object to be used
                let tree_settings : TreeSettings = TreeSettings(json: data)
                
                self.notificationsSwitch.on = tree_settings.push_notif
                
                self.loadingMaskViewController.cancelLoadingMask(nil)
                
            },
            failure: {
                error,wasHandled in
                self.loadingMaskViewController.cancelLoadingMask({
                    if !wasHandled {
                        // if network error
                        if (error == TreemServiceResponseCode.NetworkError) {
                            self.errorViewController.showNoNetworkView(self.view, recover: {
                                self.getUserTreeSettings()
                            })
                        }
                        else if (error == TreemServiceResponseCode.LockedOut) {
                            self.errorViewController.showLockedOutView(self.view, recover: {
                                self.getUserTreeSettings()
                            })
                        }
                        else if (error == TreemServiceResponseCode.DisabledConsumerKey) {
                            self.errorViewController.showDeviceDisabledView(self.view, recover: {
                                self.getUserTreeSettings()
                            })
                        }
                    }
                })
            }
        )
       
        
        
    }
}
