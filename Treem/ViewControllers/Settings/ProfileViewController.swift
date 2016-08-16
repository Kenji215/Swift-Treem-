//
//  ProfileViewController.swift
//  Treem
//
//  Created by Matthew Walker on 10/26/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON
import AssetsLibrary
import MobileCoreServices
import CLImageEditor

class ProfileViewController: UIViewController, UITextViewDelegate, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate, MediaPickerDelegate, CLImageEditorDelegate {
    
    // --------------------------------- //
    // Form Objects
    // --------------------------------- //
    
    @IBOutlet weak var scrollView                         : UIScrollView!
    @IBOutlet weak var actionView                         : UIView!
    @IBOutlet weak var scrollContentView                  : UIView!
    @IBOutlet weak var headerView                         : UIView!
    
    @IBOutlet weak var profilePic                         : UIImageView!
    @IBOutlet weak var cameraButton                       : UIButton!
    
    @IBOutlet weak var userNameTextBox                    : RectangleTextField!
    @IBOutlet weak var firstNameTextBox                   : RectangleTextField!
    @IBOutlet weak var lastNameTextBox                    : RectangleTextField!
    @IBOutlet weak var emailTextBox                       : RectangleTextField!
    @IBOutlet weak var dobBox                             : RectangleTextField!
    @IBOutlet weak var phoneLabel                         : UILabel!
    
    @IBOutlet weak var nonFriendAccessSwitch              : UISwitch!
    
    @IBOutlet weak var residesCityTextBox                 : RectangleTextField!
    @IBOutlet weak var residesStateTextBox                : RectangleTextField!
    @IBOutlet weak var residesCountryTextBox              : RectangleTextField!
    
    @IBOutlet weak var saveButton                         : UIButton!
    @IBOutlet weak var closeButton                        : UIButton!
    
    // error labels
    @IBOutlet weak var userNameErrorLabel                 : UILabel!
    @IBOutlet weak var firstNameErrorLabel                : UILabel!
    @IBOutlet weak var lastNameErrorLabel                 : UILabel!
    @IBOutlet weak var emailErrorLabel                    : UILabel!
    @IBOutlet weak var dobErrorLabel                      : UILabel!
    @IBOutlet weak var residesCityErrorLabel              : UILabel!
    @IBOutlet weak var residesStateErrorLabel             : UILabel!
    @IBOutlet weak var residesCountryErrorLabel           : UILabel!
    
    // height constraints
    @IBOutlet weak var profilePicWidthConstraint          : NSLayoutConstraint!
    @IBOutlet weak var profilePicHeightConstraint         : NSLayoutConstraint!
    
    @IBOutlet weak var actionViewBottomConstraint         : NSLayoutConstraint!
    @IBOutlet weak var personalInfoViewHeightConstraint   : NSLayoutConstraint!
    @IBOutlet weak var sharedInfoViewHeightConstraint     : NSLayoutConstraint!
    @IBOutlet weak var userNameErrorHeightConstraint      : NSLayoutConstraint!
    @IBOutlet weak var firstNameErrorHeightConstraint     : NSLayoutConstraint!
    @IBOutlet weak var lastNameErrorHeightConstraint      : NSLayoutConstraint!
    @IBOutlet weak var emailErrorHeightConstraint         : NSLayoutConstraint!
    @IBOutlet weak var dobErrorHeightConstraint           : NSLayoutConstraint!
    @IBOutlet weak var residesCityErrorHeightConstraint   : NSLayoutConstraint!
    @IBOutlet weak var residesStateErrorHeightConstraint  : NSLayoutConstraint!
    @IBOutlet weak var residesCountryErrorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewHeightConstraint         : NSLayoutConstraint!
    
    @IBOutlet weak var feedButton: UIButton!
    @IBOutlet weak var picVideoButton: UIButton!
    
    @IBAction func feedButtonTouchUpInside(sender: AnyObject) { self.loadMemberDetails(MemberDetailsViewController.DetailType.Feed) }
    @IBAction func picVideoButtonTouchUpInside(sender: AnyObject) { self.loadMemberDetails(MemberDetailsViewController.DetailType.Photo) }
    
    // --------------------------------- //
    //# Mark: Form Event Handlers
    // --------------------------------- //
    
    @IBAction func onCameraTouchUpInside(sender: UIButton) {
        let mediaPicker = MediaAddOptionsViewController.getStoryboardInstance()
        
        mediaPicker.delegate                = self
        mediaPicker.transitioningDelegate   = self.fadeInTransition
        mediaPicker.referringButton         = sender
        mediaPicker.isImageOnly             = true
        
        self.presentViewController(mediaPicker, animated: true, completion: nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    @IBAction func dobOnEditingDidBegin(sender: UITextField)  { self.dobEditBegin(sender) }

    
    // form value change handlers (to mark as dirty)
    @IBAction func onUserNameKeyDown(sender: AnyObject)       { self.checkUsername() }
    @IBAction func onFirstNameKeyDown(sender: AnyObject)      { self.checkFirstName() }
    @IBAction func onLastNameKeyDown(sender: AnyObject)       { self.checkLastName() }
    @IBAction func onEmailKeyDown(sender: AnyObject)          { self.checkEmail() }
    @IBAction func onDobChange(sender: AnyObject)             { /*self.checkDob()*/ }
    
    @IBAction func onNonFriendSwitchChange(sender: AnyObject) { self.isDirty_nonFriend = true; self.checkEnableSaveButton() }
    
    @IBAction func onResidesCityKeyDown(sender: AnyObject)    { self.checkResidesCity() }
    @IBAction func onResidesStateKeyDown(sender: AnyObject)   { self.checkResidesState() }
    @IBAction func onResidesCountryKeyDown(sender: AnyObject) { self.checkResidesCountry() }
    
    @IBAction func saveButtonTap(sender: AnyObject) {
        
        self.dismissKeyboard()
        
        if self.isDirty_profile_pic {
            self.saveImageToDevice()
        }
        else {
            self.saveUserProfile()
        }
    }
 
    @IBAction func changeNumberTouchUpInside(sender: AnyObject) {
        
        let vc = SignupPhoneViewController.getStoryboardInstance()
        vc.transitioningDelegate = self
        vc.modalPresentationStyle   = .Custom

        // let the view know where we're coming from
        vc.changingNumber = true
        vc.callingPhoneLabel = self.phoneLabel
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBAction func closeButtonTouchUpInside(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // --------------------------------- //
    //# Mark: Private Variables
    // --------------------------------- //
    
    private let loadingMaskViewController           = LoadingMaskViewController.getStoryboardInstance()
    private let loadingMaskOverlayViewController    = LoadingMaskViewController.getStoryboardInstance()
    private let errorViewController                 = ErrorViewController.getStoryboardInstance()
    private var timer                               : NSTimer? = nil
    
    private var imagePickerController               : ImagePickerController!
    
    private var newProfilePic                       : ContentItemUploadImage?   = nil
    private var initialProfileWidthConstraint       : CGFloat                   = 0
    private var initialProfileHeightConstraint      : CGFloat                   = 0
    
    private var nameInEditMode                      = false
    private var userNameInEditMode                  = false
    
    private var datePicker                          : UIDatePicker!
    private var datePickerDate                      : NSDate? = nil
    
    private var isDirty_profile_pic                 : Bool = false
    private var isDirty_username                    : Bool = false
    private var isDirty_firstName                   : Bool = false
    private var isDirty_lastName                    : Bool = false
    private var isDirty_email                       : Bool = false
    private var isDirty_dob                         : Bool = false
    private var isDirty_nonFriend                   : Bool = false
    private var isDirty_residesCity                 : Bool = false
    private var isDirty_residesState                : Bool = false
    private var isDirty_residesCountry              : Bool = false
    
    private var hasError_username                   : Bool = false
    private var hasError_firstName                  : Bool = false
    private var hasError_lastName                   : Bool = false
    private var hasError_email                      : Bool = false
    private var hasError_dob                        : Bool = false
    private var hasError_residesCity                : Bool = false
    private var hasError_residesState               : Bool = false
    private var hasError_residesCountry             : Bool = false
    
    private var errorLabelHeightConstraint          : CGFloat = 0        // updated from storyboard
    private var personalInfoDefaultHeight           : CGFloat = 0
    private var sharedInfoDefaultHeight             : CGFloat = 0
    
    private var bSavingPic                          : Bool = false
    private var bSavingProfile                      : Bool = false
    
    var isPresenting                                : Bool = false
    
    private var imageEditor     : ImageEditor?
    private var selectedImage   : UIImage?
    
    // dob must be at least 13
    private var maxDatePickerDate = NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Year, value: -13, toDate: NSDate(), options: [])
    
    private let fadeInTransition = FadeInAnimatedTransition()
    
    static func getStoryboardInstance() -> ProfileViewController {
        return UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() as! ProfileViewController
    }
    
    // --------------------------------- //
    //# Mark: Load Overrides
    // --------------------------------- //
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    // clear open keyboards on tap
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        self.dismissKeyboard()
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppStyles.sharedInstance.setImageEditButton(self.cameraButton)
        
        // dismiss keyboard handler
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ProfileViewController.dismissKeyboard)))
        
        // default save button to disabled
        self.disabledSaveButton()
        
        // default width / height constraints
        self.initialProfileWidthConstraint  = self.profilePicWidthConstraint.constant
        self.initialProfileHeightConstraint = self.profilePicHeightConstraint.constant
        
        // default the height constraints for view containers and error labels
        self.personalInfoDefaultHeight      = self.personalInfoViewHeightConstraint.constant
        self.sharedInfoDefaultHeight        = self.sharedInfoViewHeightConstraint.constant
        self.errorLabelHeightConstraint     = self.userNameErrorHeightConstraint.constant
        self.hideErrorLabels()
        
        // hide top header if not presenting
        if !self.isPresenting {
            self.headerViewHeightConstraint.constant = 0
        }
        else {
            self.closeButton.tintColor = AppStyles.sharedInstance.whiteColor
            
            // apply styles to sub header bar
            AppStyles.sharedInstance.setSubHeaderBarStyles(headerView)
        }
        
        self.feedButton.setTitleColor(AppStyles.sharedInstance.tintColor, forState: .Normal)
//        self.feedButton.setTitle(Localization.sharedInstance.getLocalizedString("options_tab_bar_0", table: "MemberProfile"), forState: .Normal)
        
        self.picVideoButton.setTitleColor(AppStyles.sharedInstance.tintColor, forState: .Normal)
        self.picVideoButton.setTitle(Localization.sharedInstance.getLocalizedString("options_tab_bar_1", table: "MemberProfile"), forState: .Normal)
        
        // load the profile
        self.loadUserProfile()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // add observers to listen for the keyboard to be pulled up or hidden
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProfileViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    //handle moving elements when the keyboard is pulled up
    func keyboardWillChangeFrame(notification: NSNotification) {
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.actionViewBottomConstraint)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return !self.isPresenting
    }
    
    // clear open keyboards on tap
    func dismissKeyboard() {
        self.view.endEditing(true)
        
        if let dp = self.datePicker {
            dp.resignFirstResponder()
            
            // call change event manually
            //self.birthDateTextFieldEditingChanged(self.dobBox)
        }
    }
    
    func profilePicTap(sender: MediaTapGestureRecognizer) {
        let vc = MediaImageViewController.getStoryboardInstance()
        vc.contentUrl = sender.contentURL
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    // --------------------------------- //
    //# Mark: Server Calls
    // --------------------------------- //
    
    private func saveUserProfile(){
        
        // get the form values that have changed
        let proSettings = Profile.init(_userName: (self.isDirty_username) ? userNameTextBox.text : nil
            , _firstName: (self.isDirty_firstName) ? firstNameTextBox.text : nil
            , _lastName: (self.isDirty_lastName) ? lastNameTextBox.text : nil
            , _nonFriendAccess: (self.isDirty_nonFriend) ? nonFriendAccessSwitch.on : nil
            , _dob: (self.isDirty_dob) ? self.datePickerDate : nil
            , _email: (self.isDirty_email) ? emailTextBox.text : nil
            , _residesLocality: (self.isDirty_residesCity) ? residesCityTextBox.text : nil
            , _residesProvince: (self.isDirty_residesState) ? residesStateTextBox.text : nil
            , _residesCountry: (self.isDirty_residesCountry) ? residesCountryTextBox.text : nil)
        
        
        
        if(proSettings.IsEmpty() == false){ self.bSavingProfile = true }
        if(self.isDirty_profile_pic){ self.bSavingPic = true }
        
        // queue loading mask if either are saving
        if(self.bSavingProfile || self.bSavingPic){
            self.disabledSaveButton()
            
            if(self.bSavingPic){
                
                self.loadingMaskViewController.queueLoadingMask(self.actionView, loadingViewAlpha: 1.0, showCompletion: { self.saveUserProfilePic() } )
            }
            else{
                self.loadingMaskViewController.queueLoadingMask(self.actionView, loadingViewAlpha: 1.0, showCompletion: nil )
            }
        }
        
        // save profile
        if(self.bSavingProfile){
        
            TreemProfileService.sharedInstance.setSelfProfile(
                proSettings,
                success:
                {
                    (data:JSON) in
                
                    if(self.bSavingPic == false){
                        self.cancelSaveMask(true, completion: nil)
                    }
                    
                    self.bSavingProfile = false
                
                },
                failure: {
                    (error, wasHandled) -> Void in
                    
                    // cancel loading mask and return to view with alert
                    self.cancelSaveMask(false, completion: {
                        
                        // invalid email passed
                        if (error == TreemServiceResponseCode.GenericResponseCode2) {
                            CustomAlertViews.showCustomAlertView(
                                title   : Localization.sharedInstance.getLocalizedString("email_invalid", table: "Profile"),
                                message : Localization.sharedInstance.getLocalizedString("email_invalid_message", table: "Profile"),
                                fromViewController: self,
                                willDismiss:  {
                                    self.animateErrorHeightConstraint(
                                        Localization.sharedInstance.getLocalizedString("error_invalid_email", table: "Profile"),
                                        errorLabel: self.emailErrorLabel,
                                        heightConstraint: self.emailErrorHeightConstraint,
                                        constant: self.errorLabelHeightConstraint
                                    )
                                }
                            )
                            self.hasError_email = true
                        }
                            
                        // username passed is in use already
                        else if (error == TreemServiceResponseCode.GenericResponseCode3){
                            CustomAlertViews.showCustomAlertView(
                                title   : Localization.sharedInstance.getLocalizedString("username_exists", table: "Profile"),
                                message : Localization.sharedInstance.getLocalizedString("username_exists_message", table: "Profile"),
                                fromViewController: self,
                                willDismiss:  {
                                    self.animateErrorHeightConstraint(
                                        Localization.sharedInstance.getLocalizedString("username_already_taken", table: "Profile"),
                                        errorLabel: self.userNameErrorLabel,
                                        heightConstraint: self.userNameErrorHeightConstraint,
                                        constant: self.errorLabelHeightConstraint
                                    )
                                }
                            )
                            self.hasError_username = true
                        }

                        // email passed is in use already
                        else if (error == TreemServiceResponseCode.GenericResponseCode4){
                            CustomAlertViews.showCustomAlertView(
                                title   : Localization.sharedInstance.getLocalizedString("email_exists", table: "Profile"),
                                message : Localization.sharedInstance.getLocalizedString("email_exists_message", table: "Profile"),
                                fromViewController: self,
                                willDismiss:  {
                                    self.animateErrorHeightConstraint(
                                        Localization.sharedInstance.getLocalizedString("email_already_taken", table: "Profile"),
                                        errorLabel: self.emailErrorLabel,
                                        heightConstraint: self.emailErrorHeightConstraint,
                                        constant: self.errorLabelHeightConstraint
                                    )
                                }
                            )
                            self.hasError_email = true
                        }
                        else if !wasHandled {
                            CustomAlertViews.showGeneralErrorAlertView()
                        }
                    })
                    
                    self.bSavingProfile = false
                    
                }
            )
        }
        
    }
    
    private func loadUserProfile(){
        
        self.loadingMaskViewController.queueLoadingMask(self.scrollView, loadingViewAlpha: 1.0, showCompletion: nil)
        
        TreemProfileService.sharedInstance.getSelfProfile(
            success:
            {
                (data:JSON) in
                
                let profile_data : Profile = Profile(json: data)
                
                // load profile pic
                if let profilePicUrl = profile_data.profilePic, url = NSURL(string: profilePicUrl) {
                    TreemContentService.sharedInstance.getContentRepositoryFile(url, cacheKey: profile_data.profilePicId, success: {
                        (image) -> () in
                        
                        dispatch_async(dispatch_get_main_queue(), {

                            // load the profile image
                            if let image = image {
                                self.loadProfileImage(image)
                            }
                            else {
                                self.profilePic.image = UIImage(named: "Avatar-Profile")
                            }
                        })
                    })
                    
                    self.profilePic.userInteractionEnabled = true
                    self.profilePic.addGestureRecognizer(
                        MediaTapGestureRecognizer(
                            target      : self,
                            action      : #selector(ProfileViewController.profilePicTap(_:)),
                            contentURL  : url,
                            contentURLId: profile_data.profilePicId,
                            contentID   : nil,
                            contentType : TreemContentService.ContentTypes.Image,
                            contentOwner: true
                        )
                    )
                }
                else {
                    self.profilePic.image = UIImage(named: "Avatar-Profile")
                }
                
                self.userNameTextBox.text = profile_data.username
                self.firstNameTextBox.text = profile_data.firstName
                self.lastNameTextBox.text = profile_data.lastName
                self.emailTextBox.text = profile_data.email
                
                // set dob (date object)
                if(profile_data.dob != nil){
                    self.setDobBoxValue(profile_data.dob!)
                }

				if (profile_data.phone != nil) {
					self.phoneLabel.text = profile_data.phone
				}
				else {
					self.phoneLabel.text = Localization.sharedInstance.getLocalizedString("phone_not_set", table: "Profile")
				}


                if(profile_data.nonFriendAccess != nil){
                    self.nonFriendAccessSwitch.on = profile_data.nonFriendAccess!
                }
                
                self.residesCityTextBox.text = profile_data.residesLocality
                self.residesStateTextBox.text = profile_data.residesProvince
                self.residesCountryTextBox .text = profile_data.residesCountry
                
                self.loadingMaskViewController.cancelLoadingMask(nil)
                
            },
            failure: {
                (error) -> Void in
                
                // cancel loading mask and return to view with alert
                self.loadingMaskViewController.cancelLoadingMask({
                    CustomAlertViews.showGeneralErrorAlertView()
                })
            }
        )
    }
    
    func saveUserProfilePic() {
        if let profilePic = newProfilePic, contentItem = ContentItemUploadImage(fileExtension: profilePic.fileExtension!, image: profilePic.image!, profile: true) {
            let contentUploadManager = TreemContentServiceUploadManager(
                treeSession: CurrentTreeSettings.sharedInstance.treeSession,
                contentItemUpload: contentItem,
                success: {
                    (data) -> Void in

                    // last one will cancel loading mask
                    if(!self.bSavingProfile){
                        self.cancelSaveMask(true, completion: nil)
                    }
                    
                    self.bSavingPic = false
                },
                failure: {
                    (error, wasHandled) -> Void in
                    
                    self.cancelSaveMask(false, completion: {
                        
                        // unsupported content type
                        if error == TreemServiceResponseCode.GenericResponseCode2 {
                            var typesList = ""
                            
                            for type in TreemContentService.ContentFileExtensions.cases {
                                typesList += "-" + type
                            }
                            
                            CustomAlertViews.showCustomAlertView(title: "Unsupported type", message: "Image/video uploaded is not a supported type. Supported types include:" + typesList)
                        }
                            // attachment too large
                        else if error == TreemServiceResponseCode.GenericResponseCode3 {
                            CustomAlertViews.showCustomAlertView(title: "File too large", message: "Maximum upload size is " + String(TreemContentServiceUploadManager.maxContentGigaBytes) + " gb.")
                        }
                        else if !wasHandled {
                            CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                        }
                    })
                },
                progress: nil,
                multiStarted: nil
            )
            
            contentUploadManager.startUpload()
        }
    }
    
    // ------------------------------------- //
    //# Mark: Media Picker Delegate Functions
    // ------------------------------------- //
    
    func cancelSelected() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imageSelected(image: UIImage, fileExtension: TreemContentService.ContentFileExtensions, picker: UIImagePickerController) {
        self.selectedImage = image

        self.imageEditor = ImageEditor(image: self.selectedImage!.rotateCameraImageToOrientation(self.selectedImage!, maxResolution: AppSettings.max_post_image_resolution), delegate:  self, isProfile: (image.size.width != image.size.height))
        
        self.dismissViewControllerAnimated(true, completion: {
            self.presentViewController(self.imageEditor!, animated: true, completion: nil)
        })
    }
    
    func videoSelected(fileURL: NSURL, orientation: ContentItemOrientation, fileExtension: TreemContentService.ContentFileExtensions, picker: UIImagePickerController) {
        // shouldn't be reached, but just in case
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // ------------------------------- //
    
    func imageEditor(editor: CLImageEditor!, didFinishEdittingWithImage image: UIImage!) {
        
        let tempImage = image.rotateCameraImageToOrientation(image, maxResolution: AppSettings.max_post_image_resolution)
        
        // store information for later
        self.isDirty_profile_pic = true
        
        self.selectedImage = tempImage
        
        // load the image
        self.loadProfileImage(tempImage)
        self.checkEnableSaveButton()
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }

    
    // --------------------------------- //
    //# Mark: Form Checkers
    // --------------------------------- //
    
    private func checkUsername() {

        let heightConstant  = self.errorLabelHeightConstraint
        
        if self.isUsernameValid() {
            
            // check if username already taken
            TreemAuthenticationService.sharedInstance.checkUsername(
                self.userNameTextBox.text!.trim(),
                failureCodesHandled: [
                    TreemServiceResponseCode.NetworkError, // don't show error if couldn't retrieve result
                    TreemServiceResponseCode.LockedOut
                ],
                success: {
                    (data:JSON) in
                    
                    // make sure current username is still valid when we come back so we don't clear the error dialog
                    if(self.isUsernameValid()){
                        self.hasError_username = false
                    
                        // not dirty if the username belongs to current user
                        self.isDirty_username = (data.int32Value == 0)
                        self.checkEnableSaveButton()
                    
                        // clear error if present
                        self.animateErrorHeightConstraint(nil, errorLabel: self.userNameErrorLabel, heightConstraint: self.userNameErrorHeightConstraint, constant: 0)
                    }
                },
                failure: {
                    error, wasHandled in
                    
                    if error == TreemServiceResponseCode.GenericResponseCode2 {
                        self.animateErrorHeightConstraint(
                            Localization.sharedInstance.getLocalizedString("username_already_taken", table: "Profile"),
                            errorLabel: self.userNameErrorLabel,
                            heightConstraint: self.userNameErrorHeightConstraint,
                            constant: heightConstant
                        )
                        
                        // error
                        self.hasError_username = true
                        self.isDirty_username = false
                        self.checkEnableSaveButton()
                    }
                }
            )
        }
    }
    
    private func checkFirstName() {
        var isValid         = false
        
        // username is alphanumeric
        if var firstName = self.firstNameTextBox.text {
            firstName = firstName.trim()
            
            if firstName.characters.count > 0 {
                isValid = firstName.isValidName()
            }
        }
        
        let text: String?   = isValid ? nil : Localization.sharedInstance.getLocalizedString("error_letters_punc_only", table: "Profile")
        let heightConstant  = isValid ? 0 : self.errorLabelHeightConstraint
        
        self.animateErrorHeightConstraint(
            text,
            errorLabel: self.firstNameErrorLabel,
            heightConstraint: self.firstNameErrorHeightConstraint,
            constant: heightConstant
        )
        
        // set flags and check button
        self.hasError_firstName = (!isValid)
        self.isDirty_firstName = isValid
        self.checkEnableSaveButton()
    }
    
    private func checkLastName() {
        var isValid         = false
        
        // username is alphanumeric
        if var lastName = self.lastNameTextBox.text {
            lastName = lastName.trim()
            
            if lastName.characters.count > 0 {
                isValid = lastName.isValidName()
            }
        }
        
        let text: String?   = isValid ? nil : Localization.sharedInstance.getLocalizedString("error_letters_punc_only", table: "Profile")
        let heightConstant  = isValid ? 0 : self.errorLabelHeightConstraint
        
        self.animateErrorHeightConstraint(
            text,
            errorLabel: self.lastNameErrorLabel,
            heightConstraint: self.lastNameErrorHeightConstraint,
            constant: heightConstant
        )
        
        // set flags and check button
        self.hasError_lastName = (!isValid)
        self.isDirty_lastName = isValid
        self.checkEnableSaveButton()
    }
    
    
    private func checkEmail() {
        var isValid         = false
        
        // username is alphanumeric
        if var email = self.emailTextBox.text {
            email = email.trim()
            
            if email.characters.count > 0 {
                isValid = email.isValidEmail()
            }
            else { isValid = true }             // email isn't required
        }
        
        let text: String?   = isValid ? nil : Localization.sharedInstance.getLocalizedString("error_invalid_email", table: "Profile")
        let heightConstant  = isValid ? 0 : self.errorLabelHeightConstraint
        
        self.animateErrorHeightConstraint(
            text,
            errorLabel: self.emailErrorLabel,
            heightConstraint: self.emailErrorHeightConstraint,
            constant: heightConstant
        )
        
        // set flags and check button
        self.hasError_email = (!isValid)
        self.isDirty_email = isValid
        self.checkEnableSaveButton()
    }
    
    // the date picker object is set to not allow future dates so this check is a bit overkill but just to be safe incase someone messes with it...
    private func checkDob(){
        var isValid         = false
		var errorText: String? = nil
        
        let curDate = NSDate()

        if(self.datePickerDate != nil) {
			if (self.datePickerDate?.compare(curDate) == NSComparisonResult.OrderedDescending) { //If selected date is greater than today
				errorText = Localization.sharedInstance.getLocalizedString("error_future_date", table: "Profile")
			}
			else if (self.datePickerDate?.compare(self.maxDatePickerDate!) == NSComparisonResult.OrderedDescending) { //If selected date would mean the user is <13 years old
				errorText = Localization.sharedInstance.getLocalizedString("error_under_13", table: "Profile")
			}
			else if (self.datePickerDate?.compare(self.datePicker.minimumDate!) == NSComparisonResult.OrderedAscending) { //If they've picked something from too long ago
				errorText = Localization.sharedInstance.getLocalizedString("error_past_date", table: "Profile")
			}
			else {
				isValid = true
			}
        }
        
        let text: String?   = errorText
        let heightConstant  = isValid ? 0 : self.errorLabelHeightConstraint
        
        self.animateErrorHeightConstraint(
            text,
            errorLabel: self.dobErrorLabel,
            heightConstraint: self.dobErrorHeightConstraint,
            constant: heightConstant
        )
        
        // set flags and check button
        self.hasError_dob = (!isValid)
        self.isDirty_dob = isValid
        self.checkEnableSaveButton()
    }
    
    private func checkResidesCity(){
        var isValid         = false
        
        // username is alphanumeric
        if var residesCity = self.residesCityTextBox.text {
            residesCity = residesCity.trim()
            
            if residesCity.characters.count > 0 {
                isValid = residesCity.isAlphaPunctuationWhiteSpace()
            }
            else { isValid = true }             // city isn't required
        }
        
        let text: String?   = isValid ? nil : Localization.sharedInstance.getLocalizedString("error_letters_punc_only", table: "Profile")
        let heightConstant  = isValid ? 0 : self.errorLabelHeightConstraint
        
        self.animateErrorHeightConstraint(
            text,
            errorLabel: self.residesCityErrorLabel,
            heightConstraint: self.residesCityErrorHeightConstraint,
            constant: heightConstant
        )
        
        // set flags and check button
        self.hasError_residesCity = (!isValid)
        self.isDirty_residesCity = isValid
        self.checkEnableSaveButton()
    }
    
    private func checkResidesState(){
        var isValid         = false
        
        // username is alphanumeric
        if var residesState = self.residesStateTextBox.text {
            residesState = residesState.trim()
            
            if residesState.characters.count > 0 {
                isValid = residesState.isAlphaPunctuationWhiteSpace()
            }
            else { isValid = true }             // state isn't required
        }
        
        let text: String?   = isValid ? nil : Localization.sharedInstance.getLocalizedString("error_letters_punc_only", table: "Profile")
        let heightConstant  = isValid ? 0 : self.errorLabelHeightConstraint
        
        self.animateErrorHeightConstraint(
            text,
            errorLabel: self.residesStateErrorLabel,
            heightConstraint: self.residesStateErrorHeightConstraint,
            constant: heightConstant
        )
        
        // set flags and check button
        self.hasError_residesState = (!isValid)
        self.isDirty_residesState = isValid
        self.checkEnableSaveButton()
    }
    
    private func checkResidesCountry(){
        var isValid         = false
        
        // username is alphanumeric
        if var residesCountry = self.residesCountryTextBox.text {
            residesCountry = residesCountry.trim()
            
            if residesCountry.characters.count > 0 {
                isValid = residesCountry.isAlphaPunctuationWhiteSpace()
            }
            else { isValid = true }             // country isn't required
        }
        
        let text: String?   = isValid ? nil : Localization.sharedInstance.getLocalizedString("error_letters_punc_only", table: "Profile")
        let heightConstant  = isValid ? 0 : self.errorLabelHeightConstraint
        
        self.animateErrorHeightConstraint(
            text,
            errorLabel: self.residesCountryErrorLabel,
            heightConstraint: self.residesCountryErrorHeightConstraint,
            constant: heightConstant
        )
        
        // set flags and check button
        self.hasError_residesCountry = (!isValid)
        self.isDirty_residesCountry = isValid
        self.checkEnableSaveButton()
    }
    
    private func isUsernameValid() -> Bool {
        var isValid = false
        
        // username is alphanumeric
        if var username = self.userNameTextBox.text {
            username = username.trim()
            
            if username.characters.count > 0 {
                isValid = username.isAlphaNumeric()
            }
        }
        
        // show the error label
        if(!isValid){
            // error
            self.hasError_username = true
            self.isDirty_username = false
            self.checkEnableSaveButton()
            
            self.animateErrorHeightConstraint(
                Localization.sharedInstance.getLocalizedString("error_letters_numbers_only", table: "Profile"),
                errorLabel: self.userNameErrorLabel,
                heightConstraint: self.userNameErrorHeightConstraint,
                constant: self.errorLabelHeightConstraint
            )
        }
        
        return isValid
    }
    
    
    private func animateErrorHeightConstraint(errorText: String? = nil, errorLabel: UILabel, heightConstraint: NSLayoutConstraint, constant: CGFloat) {
        // alter error text
        if let text = errorText {
            errorLabel.text = " " + text
        }
        else {
            errorLabel.text = nil
        }
        
        if constant != heightConstraint.constant {
            heightConstraint.constant = constant
            
            UIView.animateWithDuration(
                AppStyles.sharedInstance.viewAnimationDuration,
                animations: {
                    // animate constraint
                    self.view.layoutIfNeeded()
                }
            )
            
//            self.setContainerViewHeights()
        }
    }
    
    // --------------------------------- //
    //# Mark: Form Helpers
    // --------------------------------- //
    
    func loadProfileImage(image: UIImage){
        
        // load the profile image
        let size = UIImage.getResizeImageScaleSize(CGSize(width: self.initialProfileWidthConstraint * 2, height: self.initialProfileHeightConstraint), oldSize: image.size)
        
        // update constraints
        self.profilePicWidthConstraint.constant     = size.width
        self.profilePicHeightConstraint.constant    = size.height
        
        // apply new image
        UIView.transitionWithView(
            self.profilePic,
            duration: 0.1,
            options: UIViewAnimationOptions.TransitionCrossDissolve,
            animations: {
                self.profilePic.image = image
            },
            completion: nil
        )
    }
    
    func dobEditBegin(sender: UITextField) {
        // show date picker
        self.datePicker = UIDatePicker()
        
        self.datePicker.datePickerMode   = UIDatePickerMode.Date
        self.datePicker.backgroundColor  = UIColor.whiteColor()
        
        // get minimum date
		let calendar        = NSCalendar.currentCalendar()
		let dateComponents  = NSDateComponents()

		dateComponents.year     = 1900
		dateComponents.month    = 1
		dateComponents.day      = 1

		self.datePicker.minimumDate = calendar.dateFromComponents(dateComponents)


		//Must be >=13 to use Treem, so use 13 years ago as the highest selectable birth date
		//self.datePicker.maximumDate = calendar.dateByAddingUnit(NSCalendarUnit.Year, value: -13, toDate: NSDate(), options: [])
        
        sender.inputView = self.datePicker
        
        self.datePicker.addTarget(self, action: #selector(ProfileViewController.birthDatePickerValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        // if first time loading date picker, set it to the server dob
        if(self.datePickerDate != nil){
            self.datePicker.setDate(self.datePickerDate!, animated: false)
        }
        else{
            self.datePicker.setDate(self.maxDatePickerDate!, animated: false)
            self.birthDatePickerValueChanged(self.datePicker)
        }
    }
    
    func birthDatePickerValueChanged(sender:UIDatePicker) {
        self.setDobBoxValue(sender.date)
        self.checkDob()
    }
    
    func setDobBoxValue(dateObj: NSDate){
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.NoStyle
        
        dobBox.text = dateFormatter.stringFromDate(dateObj)
        
        self.datePickerDate = dateObj
    }
    
    private func disabledSaveButton(){
        
        // disable save button initially
        AppStyles.sharedInstance.setButtonDefaultStyles(self.saveButton)
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.saveButton, enabled: false)
        
        self.isDirty_profile_pic = false
        self.isDirty_username = false
        self.isDirty_firstName = false
        self.isDirty_lastName = false
        self.isDirty_email = false
        self.isDirty_dob = false
        self.isDirty_nonFriend = false
        self.isDirty_residesCity = false
        self.isDirty_residesState = false
        self.isDirty_residesCountry = false
        
    }
    
    private func checkEnableSaveButton(){
        
        if((
            (!self.hasError_username) &&
            (!self.hasError_firstName) &&
            (!self.hasError_lastName) &&
            (!self.hasError_email) &&
            (!self.hasError_dob) &&
            (!self.hasError_residesCity) &&
            (!self.hasError_residesState) &&
            (!self.hasError_residesCountry)
            ) && (
            (self.isDirty_profile_pic) ||
            (self.isDirty_username) ||
            (self.isDirty_firstName) ||
            (self.isDirty_lastName) ||
            (self.isDirty_email) ||
            (self.isDirty_dob) ||
            (self.isDirty_nonFriend) ||
            (self.isDirty_residesCity) ||
            (self.isDirty_residesState) ||
            (self.isDirty_residesCountry)
            )){
                AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.saveButton, enabled: true, withAnimation: true)
        }
        else{
            AppStyles.sharedInstance.setButtonDefaultStyles(self.saveButton)
            AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.saveButton, enabled: false)
        }
        
    }
    
    private func hideErrorLabels(){
        self.userNameErrorHeightConstraint.constant = 0
        self.firstNameErrorHeightConstraint.constant = 0
        self.lastNameErrorHeightConstraint.constant = 0
        self.emailErrorHeightConstraint.constant = 0
        self.dobErrorHeightConstraint.constant = 0
        self.residesCityErrorHeightConstraint.constant = 0
        self.residesStateErrorHeightConstraint.constant = 0
        self.residesCountryErrorHeightConstraint.constant = 0
    }
    
    private func cancelSaveMask(showSaveMessage: Bool, completion: (() -> ())?){
        
        self.loadingMaskViewController.cancelLoadingMask({
            self.loadingMaskOverlayViewController.cancelLoadingMask({
            
                if(showSaveMessage){
                    self.errorViewController.showErrorMessageView(self.actionView, text: "✓ Profile Saved")
                    
                    // dismiss save message after 1 second
                    self.cancelTimer()
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ProfileViewController.dismissSaveMessage), userInfo: nil, repeats: false)
                    
                }
                completion?()
            })
        })
    }
    
    private func cancelTimer() {
        if let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
    func dismissSaveMessage(){ self.errorViewController.removeErrorView() }
    
    private func loadMemberDetails(loadType: MemberDetailsViewController.DetailType){
        let vc = MemberDetailsViewController.getStoryboardInstance()
        vc.loadType = loadType
        vc.userIsSelf = true
        vc.modalPresentationCapturesStatusBarAppearance = true
        
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func saveImageToDevice() {
        let assetsLibrary = ALAssetsLibrary()
        
        assetsLibrary.writeImageToSavedPhotosAlbum(self.selectedImage!.CGImage!, orientation: ALAssetOrientation(rawValue: self.selectedImage!.imageOrientation.rawValue)!,
            completionBlock: { (referenceUrl, error) -> Void in
                
                #if DEBUG
                    print("photo saved to asset")
                    print(referenceUrl)   // assets-library://asset/asset.JPG?id=CCC70B9F-748A-43F2-AC61-8755C974EE15&ext=JPG
                #endif
                
                assetsLibrary.assetForURL(referenceUrl,
                    
                    resultBlock: {
                        asset in
                        
                        let fileName = asset.defaultRepresentation().filename()
                        
                        #if DEBUG
                            print("Selected file:\(fileName)")
                        #endif
                        
                        let fileExtension = TreemContentService.ContentFileExtensions.fromString(fileName.getPathNameExtension())
                        
                        self.newProfilePic = ContentItemUploadImage(fileExtension: fileExtension, image: self.selectedImage!, profile: true)
                        
                        self.saveUserProfile()
                    },
                    failureBlock: {
                        _ in
                        
                        self.dismissViewControllerAnimated(true, completion: nil)
                })
                
                #if DEBUG
                if let error = error {
                    print(error.description)
                }
                #endif
        })
    }
}
