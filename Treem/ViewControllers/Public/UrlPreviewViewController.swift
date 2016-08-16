//
//  UrlPreviewViewController.swift
//  Treem
//
//  Created by Tracy Merrill on 2/10/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class UrlPreviewViewController : UIViewController {
    
    // UIComponents for the URL Preview
    @IBOutlet weak var PostUrlMainView          : UIView!
    @IBOutlet weak var LinkImageView            : UIImageView!
    @IBOutlet weak var LinkHeaderLabel          : UILabel!
    @IBOutlet weak var LinkDescriptionLabel     : UILabel!

    @IBOutlet weak var linkHeaderLabelTopConstraint             : NSLayoutConstraint!
    @IBOutlet weak var linkHeaderLabelHeightConstraint          : NSLayoutConstraint!
    @IBOutlet weak var linkDescriptionLabelTopConstraint        : NSLayoutConstraint!
    @IBOutlet weak var linkDescriptionLabelHeightConstraint     : NSLayoutConstraint!
    @IBOutlet weak var linkImageViewTopConstraint               : NSLayoutConstraint!
    @IBOutlet weak var linkImageViewHeightConstraint            : NSLayoutConstraint!
    
    //Top constraints for elements
    @IBOutlet weak var HeaderLabelTopConstraint             : NSLayoutConstraint!
    
    //Bottom constraints for elements
    @IBOutlet weak var DescriptionLabelBottomSpacingConstraint  : NSLayoutConstraint!

    var allowRemovePreview          : Bool                  = false
    var pageData                    : WebPageData?          = nil
    var postUrlViewHeightChange     : ((height: CGFloat) -> ())? = nil
    var loadImageSuccess            : (() -> ())?           = nil
    var loadImageFailure            : (() -> ())?           = nil
    var postViewController          : UIViewController?     = nil

    static func getStoryboardInstance() -> UrlPreviewViewController {
        return UIStoryboard(name: "UrlPreviewView", bundle: nil).instantiateInitialViewController() as! UrlPreviewViewController
    }
    
    override func viewDidLoad() {
         super.viewDidLoad()
        
        // add slight shadow to url preview view
        PostUrlMainView.layer.shadowColor   = UIColor.lightGrayColor().CGColor
        PostUrlMainView.layer.shadowOpacity = 1
        PostUrlMainView.layer.shadowOffset  = CGSizeMake(0,0)
        PostUrlMainView.layer.shadowRadius  = 2
        
        // check if showing title
        if let title = pageData?.linkTitle {
            LinkHeaderLabel.text = title
            // title is one line no need to predict height
        }
        else {
            LinkHeaderLabel.hidden = true
            
            self.linkHeaderLabelHeightConstraint.constant   = 0
            self.linkHeaderLabelTopConstraint.constant      = 0
        }
        
        // check if showing description
        if let desc = pageData?.linkDescription {
            LinkDescriptionLabel.text = desc
        }
        else {
            LinkDescriptionLabel.hidden = true
            
            self.linkDescriptionLabelTopConstraint.constant     = 0
            self.linkDescriptionLabelHeightConstraint.constant  = 0
        }
        
        // check if loading image
        if let image = pageData?.linkImage where !image.parseForUrl().isEmpty {
            self.LinkImageView.hidden = false
            
            self.linkImageViewTopConstraint.constant    = 5
            self.linkImageViewHeightConstraint.constant = 200
            
            // load the thumbnail
            ImageLoader.sharedInstance.loadPublicImage(
                image
                , success: {
                    image in
                    
                    self.LinkImageView.image = image
                    
                    self.addDeleteButton()
                },
                failure: {
                    #if DEBUG
                        print("Failed to load image: \(image)")
                    #endif
                    
                    self.loadImageFailure?()
                    
                    self.addDeleteButton()
                }
            )
        }
        else {
            self.addDeleteButton()
        }

        self.view.layoutSubviews()
    }
    
    private func addDeleteButton() {
        if self.allowRemovePreview {
            let containerView: UIView = (self.view)
            
            // add delete button in image
            let deleteButton = UIButton()
            
            deleteButton.setTitle("  X  ", forState: .Normal)
            
            AppStyles.sharedInstance.setImageEditButton(deleteButton)
            
            deleteButton.frame.origin = CGPoint(x: containerView.frame.width - deleteButton.frame.width, y: 0)
            
            // add delete image button target action
            if let postVC = self.postViewController {
                deleteButton.addTarget(postVC, action: #selector(PostViewController.removeLinkFromPostView(_:)), forControlEvents: .TouchUpInside)
            }
            
            containerView.addSubview(deleteButton)
        }
    }
    
    static func getLayoutHeightFromWebData(pageData: WebPageData) -> CGFloat {
        var totalHeight: CGFloat = 0
        
        // if preview has title
        if pageData.linkTitle != nil {
            totalHeight += 25 // (5 top + 20 height)
        }
        
        // if preview has description
        if pageData.linkDescription != nil {
            totalHeight += 20 // (5 top + 15 height)
        }
        
        // if preview has image
        if pageData.linkImage != nil && !pageData.linkImage!.parseForUrl().isEmpty {
            totalHeight += 200 // (5 top + 200 for image)
        }
        
        // bottom padding
        totalHeight += 5
        
        return totalHeight
    }
}
