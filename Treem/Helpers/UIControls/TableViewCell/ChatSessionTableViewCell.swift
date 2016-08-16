//
//  ChatSessionOtherMemberTableViewCell
//  Treem
//
//  Created by Daniel Sorrell on 2/12/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class ChatSessionOtherMemberTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel    : UILabel!
    @IBOutlet weak var avatar       : UIImageView!
    @IBOutlet weak var dateLabel    : UILabel!
    @IBOutlet weak var messageView  : UIView!

    @IBOutlet weak var messageViewHeightConstraint  : NSLayoutConstraint!
    @IBOutlet weak var messageViewWidthConstraint   : NSLayoutConstraint!
}