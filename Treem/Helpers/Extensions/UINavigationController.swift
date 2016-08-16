//
//  UINavigationController.swift
//  Treem
//
//  Created by Matthew Walker on 2/9/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

extension UINavigationController {
    func pushViewController(viewController: UIViewController, animated: Bool, completion: (Void -> Void)?) {
        self.pushViewController(viewController, animated: animated)
        
        if let coordinator = transitionCoordinator() where animated {
            coordinator.animateAlongsideTransition(nil) {
                _ in
                
                completion?()
            }
        }
        else {
            completion?()
        }
    }
    
    func popViewControllerAnimated(animated: Bool, completion: (Void -> Void)?){
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        popViewControllerAnimated(animated)
        CATransaction.commit()
    }

    // default auto rotate value to visible view controller
    public override func shouldAutorotate() -> Bool {
        return self.visibleViewController?.shouldAutorotate() ?? false
    }
    
    // default supported interface orientations to visible view controller
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return self.visibleViewController?.supportedInterfaceOrientations() ?? [.Portrait]
    }
}