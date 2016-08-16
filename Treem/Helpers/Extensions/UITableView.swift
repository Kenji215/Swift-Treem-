//
//  UITableView.swift
//  Treem
//
//  Created by Daniel Sorrell on 3/24/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

extension UITableView {    
    func scrollToRowAtIndexPath(indexPath: NSIndexPath, atScrollPosition: UITableViewScrollPosition, animated: Bool, completion: (Void -> Void)?){
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        scrollToRowAtIndexPath(indexPath, atScrollPosition: atScrollPosition, animated: animated)
        CATransaction.commit()
    }
}

