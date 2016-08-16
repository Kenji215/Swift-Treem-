//
//  UIButton.swift
//  Treem
//
//  Created by Matthew Walker on 12/18/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

extension UIButton {
    
    // adjust content size to account for button title edge insets
    public override func intrinsicContentSize() -> CGSize {
        let intrinsicContentSize = super.intrinsicContentSize()
        
        let adjustedWidth   = intrinsicContentSize.width + titleEdgeInsets.left + titleEdgeInsets.right
        let adjustedHeight  = intrinsicContentSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom
        
        return CGSize(width: adjustedWidth, height: adjustedHeight)
    }
    
    // selective copy button (not a true deep copy of the object)
    func copyButtonSelective() -> UIButton
    {
        let button = UIButton()
        // produces odd effects: NSKeyedUnarchiver.unarchiveObjectWithData(NSKeyedArchiver.archivedDataWithRootObject(self))! as! UIButton

        button.setTitle(self.titleLabel?.text, forState: .Normal)
        button.setTitleColor(self.titleLabel?.textColor, forState: .Normal)
        button.setImage(self.imageView?.image, forState: .Normal)
        
        button.titleLabel?.font             = self.titleLabel?.font
        button.frame                        = self.frame
        button.titleEdgeInsets              = self.titleEdgeInsets
        button.contentEdgeInsets            = self.contentEdgeInsets
        button.imageEdgeInsets              = self.imageEdgeInsets
        button.contentHorizontalAlignment   = self.contentHorizontalAlignment
        button.contentVerticalAlignment     = self.contentVerticalAlignment
        
        return button //
	}
	
	//Add attributes to the given substring
	func modifyRange(range: Range<String.Index>, attributes: [String : AnyObject]) {
		if let text = self.titleLabel?.attributedText {
			let start = text.string.startIndex.distanceTo(range.startIndex)
			let length = range.startIndex.distanceTo(range.endIndex)
			let attr = NSMutableAttributedString(attributedString: text)

			attr.addAttributes(attributes, range: NSMakeRange(start, length))

			self.titleLabel?.attributedText = attr
		}
	}



	func resizeSubstring(substr: String, size: CGFloat) {
		let range = self.titleLabel?.text?.rangeOfString(substr)

		if let range = range {
			self.modifyRange(range, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(size)])
		}
	}
}