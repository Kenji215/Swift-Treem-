//
//  DirectionalAnimatedTransition.swift
//  Treem
//
//  Created by Matthew Walker on 8/6/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class DirectionalAnimatedTransition: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    enum AnimationDirection: Int {
        case Left   = 0
        case Right  = 2
        case Up     = 1
        case Down   = 3
    }
    
    private var isPresenting = true
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isPresenting       = true
        self.showFromAnimation  = false
        self.showToAnimation    = true
        
        return self
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isPresenting       = false
        self.showFromAnimation  = true
        self.showToAnimation    = false
        
        return self
    }
    
    private var currentAnimationDirection   : AnimationDirection
    private var showFromAnimation           : Bool
    private var showToAnimation             : Bool
    private var completion                  : (()->())? = nil
    
    init(animationDirection: AnimationDirection, showFromAnimation: Bool, showToAnimation: Bool, completion: (()->())? = nil) {
        self.currentAnimationDirection  = animationDirection
        self.showFromAnimation          = showFromAnimation
        self.showToAnimation            = showToAnimation
        self.completion                 = completion
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return AppStyles.sharedInstance.viewAnimationDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromController  = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let fromView        = fromController.view
        let toController    = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let toView          = toController.view
        let containerView   = transitionContext.containerView()!
        let height          = containerView.bounds.size.height
        let width           = containerView.bounds.size.width
        
        var xShift : CGFloat, yShift: CGFloat
        var animDirection = self.currentAnimationDirection
        
        // position incoming view to slide in
        toView.frame = transitionContext.finalFrameForViewController(toController)

        if !self.isPresenting {
            // switch direction if dismissing
            switch(self.currentAnimationDirection) {
            case .Up:
                animDirection = .Down
            case .Left:
                animDirection = .Right
            case .Right:
                animDirection = .Left
            case .Down:
                animDirection = .Up
            }
        }
        
        switch(animDirection) {
        case .Down:
            xShift = 0
            yShift = -height
        case .Left:
            xShift = width
            yShift = 0
        case .Right:
            xShift = -width
            yShift = 0
        case .Up:
            xShift = 0
            yShift = height
        }
        
        if(self.showToAnimation) {
            toView.center.x += xShift
            toView.center.y += yShift

            containerView.addSubview(toView)
        }
        else {
            containerView.insertSubview(toView, belowSubview: fromView)
        }
        
        UIView.transitionWithView(containerView, duration: transitionDuration(transitionContext), options: .CurveEaseOut, animations: {
            () -> Void in
            
                if(self.showToAnimation) {
                    toView.center.x -= xShift
                    toView.center.y -= yShift
                }

                if(self.showFromAnimation) {
                    fromView.center.x -= xShift
                    fromView.center.y -= yShift
                }
            },
            completion: { (Bool) -> Void in
                self.completion?()
                
                // update internal view - must always be called
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                
                fromView.alpha = 1.0
            }
        )
    }
}
