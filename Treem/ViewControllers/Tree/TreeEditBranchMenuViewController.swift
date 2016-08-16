//
//  TreeEditBranchMenuViewController.swift
//  Treem
//
//  Created by Matthew Walker on 9/2/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

class TreeEditBranchMenuViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var optionsCollectionView: UICollectionView!
    
    @IBOutlet weak var optionsCollectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var optionsCollectionViewCenterAlignConstraint: NSLayoutConstraint!
    @IBOutlet weak var optionsCollectionViewWidthConstraint: NSLayoutConstraint!
    
    // important! match these values to the storyboard value
    private let MENU_OPTION_WIDTH: CGFloat   = 80;
    private let MENU_OPTION_SPACER: CGFloat  = 10;
    
    struct menuOption {
        var type        : menuOptionTypes
        var title       : String
        var imageName   : String
        var touchAction : String
        
        init(type: menuOptionTypes, title: String, imageName: String, touchAction: String) {
            self.type           = type
            self.title          = title
            self.imageName      = imageName
            self.touchAction    = touchAction
        }
    }
    
    enum menuOptionTypes: Int {
        case Edit       = 0
        case Move       = 1
        case Delete     = 2
        case Feed       = 3
        case Members    = 4
        case Post       = 5
        case Share      = 6
        case Chat       = 7
        case Explore    = 8
    }
    
    var branchMenuOptions: [menuOption] = []
    
    var isBranchEditable        = false
    var isPublicMode            = false
    var isPublicExplorable      = false
    
    var chatHandler     : (() -> ())? = nil
    var closeHandler    : (() -> ())? = nil
    var deleteHandler   : (() -> ())? = nil
    var editHandler     : (() -> ())? = nil
    var exploreHandler  : (() -> ())? = nil
    var feedHandler     : (() -> ())? = nil
    var membersHandler  : (() -> ())? = nil
    var moveHandler     : (() -> ())? = nil
    var postHandler     : (() -> ())? = nil
    var shareHandler    : (() -> ())? = nil

    var selectedHexagonColor: UIColor? = nil
    
    static func getStoryboardInstance() -> TreeEditBranchMenuViewController {
        return UIStoryboard(name: "TreeEditBranchMenu", bundle: nil).instantiateViewControllerWithIdentifier("TreeEditBranchMenu") as! TreeEditBranchMenuViewController
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.optionsCollectionView.dataSource = self
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("closeTouchUpInside")))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let height  = self.optionsCollectionView.collectionViewLayout.collectionViewContentSize().height
        
        // resize collection view height to fit children
        self.optionsCollectionViewHeightConstraint.constant = height
        
        // position collection view to be in the middle of center and bottom
        let center      = self.view.center.y
        let top         = self.view.bounds.maxY

        // make sure the collection view is fully in view
        if center > (top - height) {
            self.optionsCollectionViewCenterAlignConstraint.constant = (center + height) - top
        }
        else {
            self.optionsCollectionViewCenterAlignConstraint.constant = (top - center) * 0.5 - 10
        }
        
        // adjust width in case of low cell number
        if self.branchMenuOptions.count < 3 {
            var width: CGFloat = self.MENU_OPTION_WIDTH * CGFloat(self.branchMenuOptions.count)
            
            if self.branchMenuOptions.count > 1 {
                width += self.MENU_OPTION_SPACER
            }

            self.optionsCollectionViewWidthConstraint.constant = width
        }
        
        // apply drop shadow to menu options
//        self.optionsCollectionView.clipsToBounds        = false
//        self.optionsCollectionView.layer.shadowOffset   = CGSizeMake(0, 0)
//        self.optionsCollectionView.layer.shadowColor    = AppStyles.sharedInstance.darkGrayColor.CGColor
//        self.optionsCollectionView.layer.shadowRadius   = 1.0
//        self.optionsCollectionView.layer.shadowOpacity  = 0.25
//        self.optionsCollectionView.layer.shadowPath     = UIBezierPath(rect: self.optionsCollectionView.layer.bounds).CGPath
    }
    
    func loadBranchMenuOptions() {
        // check for editable options
        if self.isBranchEditable {
            self.branchMenuOptions =
            [
                menuOption(type: .Edit, title: "Edit", imageName: "Edit", touchAction: "editTouchUpInside"),
                menuOption(type: .Move, title: "Move", imageName: "Move-Tree", touchAction: "moveTouchUpInside"),
                menuOption(type: .Delete, title: "Delete", imageName: "Trash", touchAction: "deleteTouchUpInside")
            ]
        }
        
        // check for navigation options
        if self.isPublicMode {
            if self.isPublicExplorable {
                self.branchMenuOptions.append(menuOption(type: .Explore, title: "Explore", imageName: "Explore", touchAction: "exploreTouchUpInside"))
            }
        }
        else {
            self.branchMenuOptions.append(menuOption(type: .Feed, title: "Feed", imageName: "Feed", touchAction: "feedTouchUpInside"))
            self.branchMenuOptions.append(menuOption(type: .Members, title: "Members", imageName: "Members", touchAction: "membersTouchUpInside"))
            self.branchMenuOptions.append(menuOption(type: .Post, title: "Post", imageName: "Post", touchAction: "postTouchUpInside"))
			if (self.isBranchEditable) {
				self.branchMenuOptions.append(menuOption(type: .Share, title: "Share", imageName: "Share-Feed", touchAction: "shareTouchUpInside"))
			}
            self.branchMenuOptions.append(menuOption(type: .Chat, title: "Chat", imageName: "Chat", touchAction: "chatTouchUpInside"))
        }
        
        self.branchMenuOptions.append(menuOption(type: .Chat, title: "Close", imageName: "Close", touchAction: "closeTouchUpInside"))
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.branchMenuOptions.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("BranchMenuOptionCell", forIndexPath: indexPath) as! BranchMenuCollectionViewCell
        
        if(self.branchMenuOptions.indices.contains(indexPath.row)){
            let option = self.branchMenuOptions[indexPath.row]
            let button = cell.optionButton
            
            button.setTitle(option.title, forState: .Normal)
            button.setImage(UIImage(named: option.imageName), forState: .Normal)

            self.selectedHexagonColor = UIColor.whiteColor()
            
            // set styles based on branch
            button.setTitleColor(self.selectedHexagonColor, forState: .Normal)
            button.tintColor = self.selectedHexagonColor
            
            button.addTarget(self, action: Selector(option.touchAction), forControlEvents: .TouchUpInside)
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if(self.branchMenuOptions.indices.contains(indexPath.row)){
            #if DEBUG
                print(branchMenuOptions[indexPath.row])
            #endif
        }
    }
    
    // MARK: - Buttion Option Action Targets
    
    func chatTouchUpInside() {
        self.chatHandler?()
    }
    
    func closeTouchUpInside() {
        self.closeHandler?()
    }
    
    func deleteTouchUpInside() {
        self.deleteHandler?()
    }
    
    func editTouchUpInside() {
        self.editHandler?()
    }
    
    func exploreTouchUpInside() {
        self.exploreHandler?()
    }
    
    func feedTouchUpInside() {
        self.feedHandler?()
    }
    
    func membersTouchUpInside() {
        self.membersHandler?()
    }
    
    func moveTouchUpInside() {
        self.moveHandler?()
    }
    
    func postTouchUpInside() {
        self.postHandler?()
    }
    
    func shareTouchUpInside() {
        self.shareHandler?()
    }
}
