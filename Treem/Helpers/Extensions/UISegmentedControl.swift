//
//  UISegmentedControl.swift
//  Treem
//
//  Created by Tracy Merrill on 4/19/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation

extension UISegmentedControl {
    
    func addImageAndText(segment : Int, image : UIImage, text : String) {
        
        let label = UILabel(frame: CGRectMake(15,0,30,image.size.height))
        let segment = self.subviews[2]
        let viewForImage = UIImageView(image: image)
        let viewForDisplay = UIView(frame: CGRectMake(self.intrinsicContentSize().height / 2,self.intrinsicContentSize().width / 2, self.intrinsicContentSize().height, self.intrinsicContentSize().width))
        
        label.textAlignment = .Center
        label.textColor = self.tintColor
        label.backgroundColor = self.backgroundColor
        label.text = text
        
        viewForDisplay.contentMode = .Center
        viewForDisplay.addSubview(label)
        viewForDisplay.addSubview(viewForImage)
        
        segment.contentMode = .Center
        
        segment.addSubview(viewForDisplay)
    }
}