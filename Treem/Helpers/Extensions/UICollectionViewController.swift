//
//  UICollectionViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 3/8/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//
//  Notes:  There is a documented bug with Apple that causes the image picker to crash when
//          you use "3D" touch (force press or press and hold). It's caused by one of their
//          events trying to call a private method it doesn't have access to in their sdk.
//          This is a work around (eventually we could do something with it) which is to override those
//          properties with nothing.


extension UICollectionViewController: UIViewControllerPreviewingDelegate {
    public func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        return nil;
    }
    public func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        
    }
}
