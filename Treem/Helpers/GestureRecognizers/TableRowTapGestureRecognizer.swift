//
//  TableRowTapGestureRecognizer.swift
//  Treem
//
//  Created by Kevin Novak on 2/4/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class TableRowTapGestureRecognizer : UITapGestureRecognizer {
    var indexPath: NSIndexPath

    init(target: AnyObject?, action: Selector, indexPath: NSIndexPath) {
        self.indexPath = indexPath

        super.init(target: target, action: action)
    }
}
