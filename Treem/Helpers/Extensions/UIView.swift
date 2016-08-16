//
//  UIView.swift
//  Treem
//
//  Created by Daniel Sorrell on 3/24/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

extension UIView {

    
    func layoutIfNeeded(completion: (Void -> Void)?){
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        layoutIfNeeded()
        CATransaction.commit()
    }
}
