//
//  BranchShareViewController.swift
//  Treem
//
//  Created by Kevin Novak on 3/18/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class BranchShareViewController: UIViewController, UINavigationControllerDelegate, SeedingMembersTableViewDelegate {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    static func getStoryboardInstance() -> BranchShareViewController {
        return UIStoryboard(name: "BranchShare", bundle: nil).instantiateInitialViewController() as! BranchShareViewController
    }

    var delegate: TreeViewController? = nil
    var currentBranchID: Int? = nil
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppStyles.sharedInstance.setSubHeaderBarStyles(self.headerView)
        
        self.closeButton.tintColor = AppStyles.sharedInstance.whiteColor
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedSeedingSearchNavigationController" {
            let navVC = segue.destinationViewController as! UINavigationController
            navVC.delegate = self

            let addVC = SeedingSearchViewController.storyboardInstance()

            addVC.currentSearchType = SeedingSearchViewController.SearchType.SharingBranch
            addVC.delegate          = self

            navVC.addChildViewController(addVC)
        }
    }
    
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }

    func saveActionOccurred(addedUsers: OrderedSet<User>, removedUsers: OrderedSet<User>){

        let recipients : [Int] = addedUsers.map({$0.id})

        TreemBranchService.sharedInstance.shareBranch(
            CurrentTreeSettings.sharedInstance.treeSession
            , branchID: self.getBranchID()
            , recipients: recipients
            , success: {
                data in
                //Show something to say that the share was successful



                self.dismissViewControllerAnimated(true, completion: nil)
            }
            , failure: {
                error,wasHandled in
                //Currently the only error code passed back is "INVALID_SHARE" which could be due to having no valid recipients, or the branch not existing, or not belonging to the user who sent it

                if(!wasHandled){
                    CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                }
            }
        )


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
        return false
    }

    func getBranchID() -> Int {
        return self.currentBranchID ?? 0
    }

}