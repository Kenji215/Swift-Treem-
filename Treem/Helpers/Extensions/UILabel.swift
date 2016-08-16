//
//  UILabel.swift
//  Treem
//
//  Created by Matthew Walker on 3/18/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

extension UILabel {

	//Add attributes to the given substring
	func modifyRange(range: Range<String.Index>, attributes: [String : AnyObject]) {
		if let text = self.attributedText {
			let start = text.string.startIndex.distanceTo(range.startIndex)
			let length = range.startIndex.distanceTo(range.endIndex)
			let attr = NSMutableAttributedString(attributedString: text)

			attr.addAttributes(attributes, range: NSMakeRange(start, length))

			self.attributedText = attr
		}
	}


    func boldSubstring(substr: String, weight: CGFloat) {
        let range = self.text?.rangeOfString(substr)
        
        if let range = range {
			self.modifyRange(range, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(self.font.pointSize, weight: weight)])
        }
    }

	func colorSubstring(substr: String, color: UIColor) {
		let range = self.text?.rangeOfString(substr)

		if let range = range {
			self.modifyRange(range, attributes: [NSForegroundColorAttributeName: color])
		}
	}

}
