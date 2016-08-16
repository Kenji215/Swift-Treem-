//
//  DiagonalScaleAnimatedTransition.swift
//  Treem
//
//  Created by Matthew Walker on 8/14/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class DiagonalScaleAnimatedTransition: NSObject, UIViewControllerAnimatedTransitioning {
    enum AnimationOrigin: Int {
        case TopLeft     = 0
        case TopRight    = 2
        case BottomLeft  = 1
        case BottomRight = 3
    }
    
    // determine which corner the diagonal scale animation will start from
    private var animationOrigin: AnimationOrigin
    
    // true to contract current view to show prior view (rather than reanimating previous view)
    private var contractCurrentView: Bool
    
    init(animationOrigin: AnimationOrigin, contractCurrentView: Bool) {
        self.animationOrigin        = animationOrigin
        self.contractCurrentView    = contractCurrentView
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return AppStyles.sharedInstance.viewAnimationDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromView        = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!.view
        let toController    = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let toView          = toController.view
        let containerView   = transitionContext.containerView()!
        
        // incoming view default is the current frame size
        toView.frame            = transitionContext.finalFrameForViewController(toController)
        toView.clipsToBounds    = true
        
        var animation: () -> Void
        var origin : CGPoint
        
        let width   = toView.frame.size.width
        let height  = toView.frame.size.height
        
        // if not contracting current view, resize new view to animate
        if(!self.contractCurrentView) {
            switch(self.animationOrigin) {
            case .TopLeft:
                origin = CGPoint(x: 0, y: 0)
            case .TopRight:
                origin = CGPoint(x: width, y: 0)
            case .BottomLeft:
                origin = CGPoint(x: 0, y: height)
            case .BottomRight:
                origin = CGPoint(x: width, y: width)
            }

            toView.frame        = CGRectZero
            toView.frame.origin = origin
            
            containerView.addSubview(toView)
            
            animation = { () -> Void in
                toView.frame = transitionContext.finalFrameForViewController(toController)
            }
        }
        else {
            switch(self.animationOrigin) {
            case .TopLeft:
                origin  = CGPoint(x: width, y: width)
            case .TopRight:
                origin = CGPoint(x: 0, y: height)
            case .BottomLeft:
                origin = CGPoint(x: width, y: 0)
            case .BottomRight:
                origin = CGPoint(x: 0, y: 0)
            }
            
            containerView.insertSubview(toView, atIndex: 0)
            
            animation = { () -> Void in
                fromView.transform = CGAffineTransformMakeScale(0.01, 0.01)
                fromView.frame.origin   = origin
            }
        }
        
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: .CurveEaseOut, animations: animation, completion: { (Bool) -> Void in
                // update internal view - must always be called
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            
                fromView.alpha = 1.0
            }
        )
    }
}
