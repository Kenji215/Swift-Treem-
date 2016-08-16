//
//  BranchShareDelegate.swift
//  Treem
//
//  Created by Kevin Novak on 3/21/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

protocol BranchShareDelegate {
    func placeSharedBranch(alertsViewController: AlertsViewController?, completion: ((Branch) -> ())?)

    func reloadTree()
}
