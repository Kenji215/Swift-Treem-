//
//  BranchViewDelegate.swift
//  Treem
//
//  Created by Matthew Walker on 3/19/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation

@objc protocol BranchViewDelegate {
    optional func setDefaultTitle()
    optional func setTemporaryTitle(title: String?)
    func toggleBackButton(show: Bool, onTouchUpInside: (() -> ())?)
}