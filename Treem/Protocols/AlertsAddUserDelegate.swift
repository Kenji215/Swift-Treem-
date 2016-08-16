//
//  AlertsAddUserDelegate.swift
//  Treem
//
//  Created by Daniel Sorrell on 1/14/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

protocol AlertsAddUserDelegate {
    func addUserSelectBranch(alertsViewController: AlertsViewController?
        , completion: ((Int,String) -> ())?)
}
