//
//  FadeInAnimatedTransition.swift
//  Treem
//
//  Created by Matthew Walker on 12/23/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class FadeInAnimatedTransition: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate  {
    private var isPresenting = true
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isPresenting = true
        
        return self
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isPresenting = false
        
        return self
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toController    = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let fromView        = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!.view
        let toView          = toController.view
        let containerView   = transitionContext.containerView()!
        
        // hide view by default if presenting
        if (self.isPresenting){
            toView.alpha    = 0
            toView.frame    = transitionContext.finalFrameForViewController(toController)
            
            containerView.addSubview(toView)
        }

        UIView.animateWithDuration(transitionDuration(transitionContext),
            animations: {
                // fade in to view
                if self.isPresenting {
                    toView.alpha = 1
                }
                // fade out from view
                else {
                    fromView.alpha = 0
                }
            },
            completion: {
                _ in

                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            }
        )
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.25
    }
}