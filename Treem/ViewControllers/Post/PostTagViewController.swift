//
//  PostTagViewController.swift
//  Treem
//
//  Created by Matthew Walker on 12/10/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class PostTagViewController: UIViewController, UINavigationControllerDelegate, SeedingMembersTableViewDelegate {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    static func getStoryboardInstance() -> PostTagViewController {
        return UIStoryboard(name: "PostTag", bundle: nil).instantiateInitialViewController() as! PostTagViewController
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    var delegate: SeedingMembersTableViewDelegate? = nil
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedSeedingSearchNavigationController" {
            let navVC = segue.destinationViewController as! UINavigationController
            navVC.delegate = self
            
            let addVC = SeedingSearchViewController.storyboardInstance()
            
            addVC.currentSearchType = SeedingSearchViewController.SearchType.Tagging
            addVC.delegate          = self
            
            navVC.addChildViewController(addVC)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppStyles.sharedInstance.setSubHeaderBarStyles(headerView)
        
        // override appearance style
        self.closeButton.tintColor = AppStyles.sharedInstance.whiteColor
    }

    func saveActionOccurred(addedUsers: OrderedSet<User>, removedUsers: OrderedSet<User>){

        self.delegate?.selectedUsersUpdated(addedUsers)
        self.delegate?.deselectedUsersUpdated(removedUsers)

        self.dismissViewControllerAnimated(true, completion: nil)
    }

    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        // Adding sub view to navigation controller
        if operation == .Push {
            return AppStyles.directionUpViewAnimatedTransition
        }
            // Removing top view controller from navigation controller
        else if operation == .Pop {
            return AppStyles.directionDownViewAnimatedTransition
        }
        
        return nil
    }


    func initiallyHighlighted(user: User) -> Bool {
        return (self.delegate?.initiallyHighlighted(user) == true)
    }

    func getBranchID() -> Int {
        return (self.delegate?.getBranchID())!
    }

    func giveWarningMessage() {
        let warningTitle = "Removing a tag"
        let warningMessage = "Unselecting a user here means they will no longer be tagged in this post."

        CustomAlertViews.showCustomAlertView(
            title: warningTitle
            , message: warningMessage
            , fromViewController: self
        )
    }
}