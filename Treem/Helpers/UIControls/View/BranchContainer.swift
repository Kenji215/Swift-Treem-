//
//  BranchContainer.swift
//  Treem
//
//  Created by Kevin Novak on 2/2/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class BranchContainer : UIView {


    var BOX_SIZE            : CGFloat   = 6
    var SPACER_SIZE         : CGFloat   = 4
    private var branches    : Int       = 0

    // Whether the boxes begin at the left or right end of the container
    enum justify : Int {
        case LEFT = 0
        case RIGHT = 1
    }
    var justification = justify.LEFT

    func addBranches (branchHexColors: [String]?) {

        self.subviews.forEach({ $0.removeFromSuperview() })

        self.branches = (branchHexColors != nil) ? branchHexColors!.count : 0

        if (branchHexColors != nil && branchHexColors!.count > 0) {

            var xOrigin: CGFloat    = self.SPACER_SIZE
            var frame               = CGRectMake(0,floor(self.bounds.height / 2 - self.BOX_SIZE / 2),self.BOX_SIZE,self.BOX_SIZE)

            if (self.justification == .LEFT) { //The first box will be flush with the left side of the container
                xOrigin = self.SPACER_SIZE
            }
            else if (self.justification == .RIGHT) { //The last box will be flush with the right side of the container
                xOrigin = self.frame.width - ((self.BOX_SIZE + self.SPACER_SIZE) * CGFloat(branchHexColors!.count) - self.SPACER_SIZE)
            }

            // clear show/update branches
            self.subviews.forEach({ $0.removeFromSuperview() })
            self.hidden = false

            for hex in branchHexColors! {
                // adjust frame for new origin
                frame.origin.x = xOrigin

                let view = UIView(frame: frame)
                view.backgroundColor    = UIColor(hex: hex)
                view.opaque             = true

                self.addSubview(view)


                xOrigin += (self.BOX_SIZE + self.SPACER_SIZE)
            }
        }
    }

    //In case the branch container has to be resized, calculate what width is needed based on how many branches are shown.
    func getWidth() -> CGFloat {
        return (CGFloat(self.branches) * (self.SPACER_SIZE + self.BOX_SIZE) + self.SPACER_SIZE)
    }
}
