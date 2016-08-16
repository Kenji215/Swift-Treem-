//
//  PostShareDelegate.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/6/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

protocol PostShareDelegate {
    func sharePostSelectBranch(shareViewController: PostShareViewController?, completion: ((Int,String) -> ())?)           // branchID and branchTitle are passed on post select
}

/*
extension PostShareDelegate {
    // default empty implementations
    func sharePostSelectBranch(shareViewController: UIViewController?, completion: ((Int,String) -> ())?) {}
}
*/
