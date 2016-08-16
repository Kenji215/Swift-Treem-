//
//  BranchTabBarController.swift
//  Treem
//
//  Created by Matthew Walker on 5/2/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation

class BranchTabBarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
    }
    
    private let animatedLeft    = AppStyles.directionLeftViewAnimatedTransition
    private let animatedRight   = AppStyles.directionRightViewAnimatedTransition
    
    var onSelectDifferentItem   : ((UITabBarItem)->())? = nil
    var onReselectItem          : ((UITabBarItem)->())? = nil
    
    // handle animation changes between view controllers
    func tabBarController(tabBarController: UITabBarController, animationControllerForTransitionFromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        let fromIndex   = self.selectedIndex
        let toIndex     = self.viewControllers?.indexOf(toVC)
        
        if(toIndex > fromIndex) {
            return self.animatedLeft
        }
        else {
            return self.animatedRight
        }
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        // check if selecting current item while open
        if let items = tabBar.items where item == items[self.selectedIndex] {
            self.onReselectItem?(item)
        }
        else {
            self.onSelectDifferentItem?(item)
        }
    }
}