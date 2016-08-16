//
//  SignupViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/20/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController, UINavigationControllerDelegate {
    private var nestedNavigationController: UINavigationController!
    
    @IBAction func unwindSignupToMain(segue: UIStoryboardSegue) {
        AppDelegate.getAppDelegate().showMainScreen(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedSignupSegue" {
            self.nestedNavigationController             = segue.destinationViewController as! UINavigationController
            self.nestedNavigationController.delegate    = self
            
            // iOS8 can't embed a storyboard scene directly, add programmatically here
            let rootVC = UIStoryboard(name: "SignupQuestion", bundle: nil).instantiateInitialViewController()!
            
            self.nestedNavigationController.setViewControllers([rootVC], animated: false)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.delegate = self
        
        let signupVC = UIStoryboard(name: "SignupPhoneNumber", bundle: nil).instantiateInitialViewController()!
        
        // check if we can skip to phone view (i.e. after logging out)
        if AppDelegate.getAppDelegate().isDeviceAuthenticated() {
            self.nestedNavigationController.pushViewController(signupVC, animated: false)
        }
    }
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        self.view.endEditing(true)
        self.nestedNavigationController.topViewController?.view.endEditing(true)
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        // Adding sub view to navigation controller
        if (operation == .Push) {
            return AppStyles.directionLeftViewAnimatedTransition
        }
            
            // Removing top view controller from navigation controller
        else if (operation == .Pop) {
            return AppStyles.directionRightViewAnimatedTransition
        }
        
        return nil
    }
}