//
//  MemberCountButton.swift
//  Treem
//
//  Created by Matthew Walker on 11/6/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class MemberCountButton: UIButton {
    @IBInspectable
    var count : Int = 0 {
        didSet {
            self.updateCount()
        }
    }

    var sign : String = "+"

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setDefaults()
        self.updateCount()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setDefaults()
        self.updateCount()
    }
    
    private func setDefaults() {
        self.count = 0
        
        self.backgroundColor = UIColor.clearColor()

        self.setTitleColor(UIColor(red: 120/255, green: 122/255, blue: 120/255, alpha: 1.0), forState: .Disabled)

        self.setImage(UIImage(named: "Members")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: .Normal)
        
        self.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0)
    }
    
    private func updateCount() {
        // toggle enabled based on member count
        self.enabled = self.count > 0

        // change title without animating change
        UIView.performWithoutAnimation {
            self.setTitle(self.sign + String(self.count), forState: .Normal)
            self.layoutIfNeeded()
        }
        
        self.setTitleColor(self.tintColor, forState: .Normal)
        
        self.imageView?.tintColor = enabled ?
            self.tintColor :
            UIColor(red: 120/255, green: 122/255, blue: 120/255, alpha: 1.0)
    }
}
