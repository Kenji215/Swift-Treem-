//
//  TreeAddBranchViewController.swift
//  Treem
//
//  Created by Matthew Walker on 8/28/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

class TreeAddBranchViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var branchNameTextField          : UITextField!
    @IBOutlet weak var saveButton                   : UIButton!
    @IBOutlet weak var cancelButton                 : UIButton!
    @IBOutlet weak var addFormView                  : UIView!
    @IBOutlet weak var colorSelectView              : UIScrollView!
    @IBOutlet weak var color1View                   : UIView!
    @IBOutlet weak var color2View                   : UIView!
    @IBOutlet weak var color3View                   : UIView!
    @IBOutlet weak var color4View                   : UIView!
    @IBOutlet weak var color5View                   : UIView!
    @IBOutlet weak var color6View                   : UIView!
    @IBOutlet weak var color7View                   : UIView!
    @IBOutlet weak var color8View                   : UIView!
    @IBOutlet weak var color9View                   : UIView!
    @IBOutlet weak var color10View                  : UIView!
    @IBOutlet weak var color11View                  : UIView!
    @IBOutlet weak var color12View                  : UIView!
    @IBOutlet weak var color13View                  : UIView!
    @IBOutlet weak var color14View                  : UIView!
    @IBOutlet weak var entityView                   : UIView!
    @IBOutlet weak var entityIcon                   : UIImageView!
    @IBOutlet weak var entityTitle                  : UILabel!
    @IBOutlet weak var entityURL                    : UILabel!
    
    @IBOutlet weak var colorSelectHeightConstraint      : NSLayoutConstraint!
    @IBOutlet weak var addFormViewBottomConstraint      : NSLayoutConstraint!
    @IBOutlet weak var entityViewHeightConstraint       : NSLayoutConstraint!
    @IBOutlet weak var branchTextFieldHeightConstraint  : NSLayoutConstraint!
    @IBOutlet weak var entityURLLeadingConstraint       : NSLayoutConstraint!
    
    @IBAction func branchNameTextFieldEditingChanged(sender: UITextField) {
        // check form to see if other view elements need to be updated
        self.checkForm()
        
        self.branchNameChangeHandler?(textField: sender)
    }

    @IBAction func saveButtonTouchUpInside(sender: AnyObject) {
        self.saveBranch()
    }
    
    @IBAction func cancelButtonTouchUpInside(sender: AnyObject) {
        self.cancelTouchHandler?()
    }

    @IBOutlet weak var addFormViewHeightConstraint: NSLayoutConstraint!
    
    private let loadingMaskViewController = LoadingMaskViewController.getStoryboardInstance()
    
    private var colorViews      : [UIView]                  = []
    private var colorGestures   : [UITapGestureRecognizer]  = []
    
    private var branchNameTextFieldInitialCaptialization    : UITextAutocapitalizationType = .None
    private var branchNameTextFieldInitialCorrection        : UITextAutocorrectionType = .No

    var selectedColorView   : UIView?       = nil
    var canSelectColor      : Bool          = true
    var treeSession         : TreeSession?  = nil
    var branch              : Branch?       = nil
    var maskBackground      : UIColor?      = nil
    
    // event handlers
    var branchNameChangeHandler : ((textField: UITextField)->())?   = nil
    var cancelTouchHandler      : (()->())?                         = nil
    var colorChangeHandler      : ((UIColor?) -> ())?               = nil
    var saveTouchHandler        : ((Branch, PublicEntity?)->())?    = nil
    
    static func getStoryboardInstance() -> TreeAddBranchViewController {
        return UIStoryboard(name: "TreeAddBranch", bundle: nil).instantiateViewControllerWithIdentifier("TreeAddBranch") as! TreeAddBranchViewController
    }
    
    override func loadView() {
        super.loadView()
        
        if self.canSelectColor {
        
            // store all color view references
            self.colorViews = [
                color1View,
                color2View,
                color3View,
                color4View,
                color5View,
                color6View,
                color7View,
                color8View,
                color9View,
                color10View,
                color11View,
                color12View,
                color13View,
                color14View
            ]
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // default with keyboard open
        UIView.animateWithDuration(
            AppStyles.sharedInstance.viewAnimationDuration,
            animations: {
                () -> Void in
                
                self.branchNameTextField.becomeFirstResponder()
            }
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadingMaskViewController.view.backgroundColor = self.maskBackground
        
        // update view based on if adding with valid entity
        if let branch = self.branch, url = branch.url {
            if let iconImage = branch.iconImage {
                self.entityIcon.image           = iconImage
                self.entityIcon.backgroundColor = AppStyles.sharedInstance.darkGrayColor
            }
            else {
                self.entityIcon.tintColor = self.entityURL.textColor
            }
            
            self.entityTitle.text       = branch.title
            self.entityURL.text         = url
            
            // if title empty remove leading padding for url
            if branch.title == nil {
                self.entityURLLeadingConstraint.constant = 0
            }
            
            // preload branch name with title
            self.branchNameTextField.text = self.entityTitle.text
            
            // only enable name edit if current user is owner
            self.branchNameTextField.enabled = branch.public_owner
            
            // hide and disable text field if edit not possible
            if !branch.public_owner {
                self.branchTextFieldHeightConstraint.constant = 0
                
                self.branchNameTextField.clearButtonMode    = .Never
                self.branchNameTextField.textColor          = AppStyles.sharedInstance.darkGrayColor
                self.branchNameTextField.backgroundColor    = AppStyles.sharedInstance.midGrayColor
                
                // if cannot select color, nothing to edit
                if branch.id > 0 && !self.canSelectColor {
                    self.saveButton.hidden = true
                    
                    UIView.performWithoutAnimation({
                        self.cancelButton.setTitle("Close", forState: .Normal)
                    })
                }
            }

            // call manually as the text has changed due to entity value
            self.branchNameChangeHandler?(textField: self.branchNameTextField)
        }
        else {
            self.entityViewHeightConstraint.constant = 0
            self.entityView.subviews.forEach({$0.removeFromSuperview()})
            
            // populate name field with branch title
            self.branchNameTextField.text = branch?.title
        }
        
        // update view based on if color picking enabled
        if self.canSelectColor {
            // apply touch gestures to color views
            for view in colorViews {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(TreeAddBranchViewController.tapColorView(_:)))
                view.addGestureRecognizer(tapGesture)
                self.colorGestures.append(tapGesture)
            }
            
            // select appropriate default color
            if let color = self.branch?.color?.toHexString() where self.colorViews.count > 0 {
                for i in 0...self.colorViews.count - 1 {
                    if(self.colorViews[i].backgroundColor?.toHexString() == color) {
                        self.tapColorView(self.colorGestures[i])
                        break
                    }
                }
            }
            else {
                self.tapNonUsedColor(self.treeSession?.currentBranch?.children)
            }
        }
        else {
            self.hideBranchColorSettings()
        }

        // add observers for showing/hiding keyboard in viewDidLoad as the keyboard can be shown initially
        let notifCenter = NSNotificationCenter.defaultCenter()
        notifCenter.addObserver(self, selector: #selector(TreeAddBranchViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
        
        // apply disabled button style if name text field empty
        AppStyles.sharedInstance.setButtonDarkDefaultStyles(self.saveButton)
        self.saveButton.enabled = self.branchNameTextField.text?.characters.count > 0
        
        self.cancelButton.tintColor = AppStyles.sharedInstance.midGrayColor
        
        // we remove these for searching, put back when naming branch
        self.branchNameTextFieldInitialCaptialization   = self.branchNameTextField.autocapitalizationType
        self.branchNameTextFieldInitialCorrection       = self.branchNameTextField.autocorrectionType
        
        self.branchNameTextField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // add observers for showing/hiding keyboard
        let notifCenter = NSNotificationCenter.defaultCenter()
        notifCenter.removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(TreeAddBranchViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // add observers for showing/hiding keyboard
        let notifCenter = NSNotificationCenter.defaultCenter()
        notifCenter.removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    // handle moving elements when keyboard is pulled up
    func keyboardWillChangeFrame(notification: NSNotification){
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.addFormViewBottomConstraint, completion: {
        })
    }
    
    private func checkForm() {
        let enabled = !(self.branchNameTextField.text?.trim() ?? "").isEmpty
        
        self.saveButton.enabled = enabled
    }
    
    func tapColorView(sender: UITapGestureRecognizer) {
        if let selColorView = self.selectedColorView {
            selColorView.layer.borderWidth  = 0
            selColorView.layer.shadowPath   = nil
            selColorView.layer.shadowRadius = 0
            selColorView.layer.shadowOffset = CGSizeZero
        }
        
        self.selectedColorView = sender.view

        let selectBorderColor = AppStyles.sharedInstance.lightGrayColor.CGColor
        let layer = self.selectedColorView!.layer
        
        // add border color
        layer.borderColor   = selectBorderColor
        layer.borderWidth   = 1.0
        
        // add shadow
        layer.masksToBounds = false
        layer.shadowOffset  = CGSizeMake(0, 0)
        layer.shadowRadius  = 1.5
        layer.shadowOpacity = 1
        layer.shadowColor   = UIColor.blackColor().CGColor
        
        self.checkForm()
        
        self.colorChangeHandler?(self.selectedColorView?.backgroundColor)
    }
    
    private func hideBranchColorSettings() {
        self.colorSelectView.hidden = true
        
        // resize the main view when hiding the color row
        self.addFormViewHeightConstraint.constant = (self.addFormViewHeightConstraint.constant
            - self.colorSelectHeightConstraint.constant)
        
        // close gap in auto layout left by constraints
        self.colorSelectHeightConstraint.constant   = 0
    }
    
    private func saveBranch() {
        let newBranch = self.branch ?? Branch()
        
        // validate current form
        
        // check that color is selected
        if self.canSelectColor {
            if self.selectedColorView == nil {
                let alert = UIAlertController(
                    title: nil,
                    message: Localization.sharedInstance.getLocalizedString("branch_error_no_color_selected", table: "TreeGrid"),
                    preferredStyle: UIAlertControllerStyle.Alert
                )
                
                self.presentViewController(alert, animated: true, completion: nil)
                
                return
            }
            
            newBranch.color = self.selectedColorView!.backgroundColor
        }
        
        // check that title is entered
        if let title = self.branchNameTextField.text where title.trim().characters.count > 0 {
            newBranch.title = title.trim()
        }
        else {
            let alert = UIAlertController(
                title: nil,
                message: Localization.sharedInstance.getLocalizedString("branch_error_no_name", table: "TreeGrid"),
                preferredStyle: UIAlertControllerStyle.Alert
            )
            
            self.presentViewController(alert, animated: true, completion: nil)
            
            return
        }
        
        // save branch to sevices
        self.setUserBranchWithEntity(newBranch)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        // fire save handler on return key (text field is single line)
        self.saveBranch()
        
        return true
    }
    
    private func tapNonUsedColor(branches: [Branch]?) {
        if !self.canSelectColor {
            return
        }
        
        var colorWasFound = false
        
        if let branches = branches where branches.count > 0 {
            let count = self.colorViews.count
            
            // check each color view
            for i in 0 ..< count {
                let color = self.colorViews[i].backgroundColor?.toHexString()
                var matchesBranch = false
                
                for branch in branches {
                    if color == branch.color?.toHexString() {
                        matchesBranch = true
                        break
                    }
                }
                
                if !matchesBranch {
                    colorWasFound = true
                    self.tapColorView(self.colorGestures[i])
                    break
                }
            }
        }
        
        if !colorWasFound {
            self.tapColorView(self.colorGestures.first!)
        }
    }

    private func setUserBranchWithEntity(newBranch: Branch) {
        self.loadingMaskViewController.queueLoadingMask(self.view, showCompletion: nil)

        let treeSession = TreeSession(treeID: self.treeSession!.treeID, token: self.treeSession!.token)
        
        // check if entity needs to be saved as well if user created
        if let currentEntity = newBranch.getPublicEntityFromBranchProperties() where currentEntity.owner {
            TreemPublicService.sharedInstance.setEntity(
                treeSession,
                entity: currentEntity,
                success: {
                    (data) -> Void in
                    
                    // updating an existing entity
                    if currentEntity.public_link_id > 0 {
                        // loading mask closed in setUserBranch
                        self.setUserBranch(treeSession, newBranch: newBranch)
                    }
                    // adding a new entity
                    else {
                        // get new id returned from service
                        let returnedEntity = PublicEntity(json: data)
                        
                        if returnedEntity.public_link_id > 0 {
                            newBranch.updateBranchFromEntityProperties(returnedEntity)
                            
                            // loading mask closed in setUserBranch
                            self.setUserBranch(treeSession, newBranch: newBranch)
                        }
                        else {
                            // there was an error in saving the entity
                            self.loadingMaskViewController.cancelLoadingMask({
                                CustomAlertViews.showGeneralErrorAlertView(self)
                            })
                        }
                    }
                },
                failure: {
                    (error, wasHandled) in
                    
                    self.loadingMaskViewController.cancelLoadingMask(nil)
                    
                    if !wasHandled {
                        CustomAlertViews.showGeneralErrorAlertView(self)
                    }
                }
            )
        }
        else {
            self.setUserBranch(treeSession, newBranch: newBranch)
        }
    }
    
    // don't call directly if supporting public tree, call 'setUserBranchWithEntity'
    private func setUserBranch(treeSession: TreeSession, newBranch: Branch) {
        TreemBranchService.sharedInstance.setUserBranch(
            TreeSession(treeID: self.treeSession!.treeID, token: self.treeSession!.token),
            branch: newBranch,
            success: {
                (data) -> Void in
                
                self.loadingMaskViewController.cancelLoadingMask(nil)
                
                // successful save on existing branch
                if (newBranch.id > 0) {
                    self.saveTouchHandler?(newBranch, nil)
                }
                // save on new branch must return new id for success
                else {
                    let newBranchID = NewBranchResponse(json: data).id
                    
                    if newBranchID > 0 {
                        newBranch.id    = newBranchID

                        self.saveTouchHandler?(newBranch, nil)
                    }
                    // general error occurred
                    else {
                        CustomAlertViews.showGeneralErrorAlertView(self)
                    }
                }
            },
            failure: {
                (error) -> Void in
                
                self.loadingMaskViewController.cancelLoadingMask({
                    CustomAlertViews.showCustomAlertView(
                        title: Localization.sharedInstance.getLocalizedString("save_error", table: "Common"),
                        message: Localization.sharedInstance.getLocalizedString("branch_error_add", table: "TreeGrid"),
                        fromViewController: self
                    )
                })
            }
        )
    }
}