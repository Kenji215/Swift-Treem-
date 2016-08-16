//
//  NewChatViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/11/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class NewChatViewController: UIViewController, UINavigationControllerDelegate, SeedingMembersTableViewDelegate {

    var chatListDelegate                : ChatListViewController? = nil
    var activeChats                     : Bool = false
    var parentView                      : UIView? = nil
    var branchViewDelegate              : BranchViewDelegate? = nil
    
    private var newChatIds              : [Int]? = nil
    
    private let loadingMaskOverlayViewController    = LoadingMaskViewController.getStoryboardInstance()
    
    static func getStoryboardInstance() -> NewChatViewController {
        return UIStoryboard(name: "NewChat", bundle: nil).instantiateInitialViewController() as! NewChatViewController
    }
    
    private var fadeInTransition = FadeInAnimatedTransition()
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedSeedingSearchNavigationController" {
            let navVC = segue.destinationViewController as! UINavigationController
            navVC.delegate = self
            
            let addVC = SeedingSearchViewController.storyboardInstance()
            
            addVC.currentSearchType = SeedingSearchViewController.SearchType.SelectBranchFriends
            addVC.delegate          = self
            
            navVC.addChildViewController(addVC)
        }
    }
    
    func saveActionOccurred(addedUsers: OrderedSet<User>, removedUsers: OrderedSet<User>){
        var userIds: [Int] = []
        
        // stuff the ids into an array
        for selectedUser in addedUsers {
            userIds.append(selectedUser.id)
        }

        if(userIds.count > 0){
            let nameVC = NewChatNameViewController.getStoryboardInstance()
            
            nameVC.charUserIds              = userIds
            nameVC.nameChatDelegate         = self
            nameVC.transitioningDelegate    = self.fadeInTransition
            
            self.newChatIds = userIds
            
            self.presentViewController(nameVC, animated: true, completion: nil)
        }
    }

    func newChatBackButtonTouchUpInside(sender: UIButton){
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func cancelMask(){
        self.loadingMaskOverlayViewController.cancelLoadingMask(nil)
    }
    
    func newChatWasCreated(sessionId: String, chatName: String?) {
        self.cancelMask()
        
        let chatSessionVC = ChatSessionViewController.getStoryboardInstance()
        
        chatSessionVC.chatSessionId         = sessionId
        chatSessionVC.chatName              = chatName
        chatSessionVC.initializeUserIds     = self.newChatIds
        chatSessionVC.parentView            = self.parentView
        chatSessionVC.branchViewDelegate    = self.branchViewDelegate
        
        self.navigationController?.pushViewController(chatSessionVC, animated: true, completion: {
            // remove prior new chat view controller
            if let navVCs = self.navigationController?.viewControllers where navVCs.count > 1 {
                self.navigationController?.viewControllers.removeAtIndex(navVCs.count - 2)
            }
        })
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        // Adding sub view to navigation controller
        if operation == .Push {
            if toVC.isKindOfClass(SeedingSelectedViewController) || toVC.isKindOfClass(SeedingSearchOptionsViewController) {
                return AppStyles.directionUpViewAnimatedTransition
            }
        }
            // Removing top view controller from navigation controller
        else if operation == .Pop {
            if fromVC.isKindOfClass(SeedingSelectedViewController) || fromVC.isKindOfClass(SeedingSearchOptionsViewController) {
                return AppStyles.directionDownViewAnimatedTransition
            }
        }
        
        return nil
    }
}
