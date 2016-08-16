//
//  MediaAddOptionsViewController.swift
//  Treem
//
//  Created by Tracy Merrill on 1/27/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import AssetsLibrary
import MobileCoreServices

class MediaAddOptionsViewController : UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   
    @IBOutlet weak var albumButton              : UIButton!
    @IBOutlet weak var takePhotoButton          : UIButton!
    @IBOutlet weak var menuViewTopConstraint    : NSLayoutConstraint!
    
    var delegate                    : MediaPickerDelegate?      = nil
    var referringButton             : UIButton?                 = nil
    var isImageOnly                 : Bool                      = false
    
    private var currentPicker       : ImagePickerController?    = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = AppStyles.overlayColor
        
        // override appearance styles
        let white       = AppStyles.sharedInstance.whiteColor
        
        albumButton.tintColor       = white
        takePhotoButton.tintColor   = white
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MediaAddOptionsViewController.dismissView)))
        
        // default mid-way in view
        var topConstant: CGFloat = self.view.frame.height * 0.5
        
        // if referring button provided, recreate
        if let referButton = self.referringButton {
            let button  = referButton.copyButtonSelective()
            let color   = AppStyles.sharedInstance.lightGrayColor
            
            button.tintColor = color
            button.setTitleColor(color, forState: .Normal)
            button.setTitleColor(AppStyles.sharedInstance.darkGrayColor, forState: .Highlighted)

            button.frame.origin = referButton.superview!.convertPoint(referButton.frame.origin, toView: nil)
            
            button.translatesAutoresizingMaskIntoConstraints = true
            
            // add dismiss view gesture to replicated button
            button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MediaAddOptionsViewController.dismissView)))
            
            self.view.addSubview(button)

            // if button is below half way, position menu down
            if (button.frame.origin.y < self.view.bounds.height * 0.5) {
                topConstant = button.frame.maxY + 40
            }
            // otherwise position menu above
            else {
                topConstant = button.frame.minY - button.frame.height - 80
            }
        }
        
        menuViewTopConstraint.constant = topConstant
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    static func getStoryboardInstance() -> MediaAddOptionsViewController {
        return UIStoryboard(name: "MediaAddOptions", bundle: nil).instantiateInitialViewController() as! MediaAddOptionsViewController
    }
    
    @IBAction func albumSelector(sender: AnyObject) {
        let imagePickerController = ImagePickerController()
        
        imagePickerController.delegate      = self
        imagePickerController.sourceType    = .PhotoLibrary
        imagePickerController.mediaTypes    = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary)!
        imagePickerController.videoQuality  = UIImagePickerControllerQualityType.TypeMedium

        if self.isImageOnly {
            imagePickerController.mediaTypes = [kUTTypeImage as String]
        }
        else {
            imagePickerController.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.PhotoLibrary)!
        }
        
        self.currentPicker = imagePickerController
        
        self.presentViewController(self.currentPicker!, animated: true, completion: nil)
    }
    
    @IBAction func captureNewMedia(sender: AnyObject) {
        if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera))
        {
            let imagePickerController = ImagePickerController()
            
            imagePickerController.delegate          = self
            imagePickerController.sourceType        = .Camera
            imagePickerController.videoQuality      = UIImagePickerControllerQualityType.Type640x480
            
            if self.isImageOnly {
                imagePickerController.mediaTypes = [kUTTypeImage as String]
            }
            else {
                imagePickerController.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.Camera)!
            }
            
            imagePickerController.modalPresentationStyle = .CurrentContext
            imagePickerController.modalPresentationCapturesStatusBarAppearance = true

            self.currentPicker = imagePickerController
            
            self.presentViewController(self.currentPicker!, animated: true, completion: nil)
        }
        else {
            self.noCamera()
        }
    }
    
    private func noCamera() {
        CustomAlertViews.showCustomAlertView(
            title   : Localization.sharedInstance.getLocalizedString("no_camera", table: "MediaAddOptions"),
            message : Localization.sharedInstance.getLocalizedString("no_camera_message", table: "MediaAddOptions"),
            fromViewController:  self
        )
    }
    
    func dismissView() {
        self.delegate?.cancelSelected()
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

        // get url of image first
        if let referenceUrl = info[UIImagePickerControllerReferenceURL] as? NSURL {

            ALAssetsLibrary().assetForURL(
                referenceUrl,
                resultBlock: {
                    asset in
                    
                    let fileName = asset.defaultRepresentation().filename()
                    
                    #if DEBUG
                        print("Selected file:\(fileName)")
                    #endif
                    
                    // get extension to check if it's a supported media types
                    let fileExtension = TreemContentService.ContentFileExtensions.fromString(fileName.getPathNameExtension())
                    
                    if fileExtension.isValidExtension() {
                        if let mediaType = info[UIImagePickerControllerMediaType] as? NSString {
                            if UTTypeConformsTo(mediaType, kUTTypeImage) {
                                if var image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                                    
                                    // adjust to correct orientation
                                    image = image.rotateCameraImageToOrientation(image, maxResolution: AppSettings.max_post_image_resolution)
                                    
                                    self.delegate?.imageSelected(image, fileExtension: fileExtension, picker: picker)
                                }
                            }
                            else if UTTypeConformsTo(mediaType, kUTTypeMovie) || UTTypeConformsTo(mediaType, kUTTypeVideo) {
                                if let fileURL = info[UIImagePickerControllerMediaURL] as? NSURL {

                                    self.delegate?.videoSelected(fileURL, orientation: self.getVideoOrientation(fileURL), fileExtension: fileExtension, picker: picker)
                                }
                            }
                        }
                    }
                },
                failureBlock: {
                    _ in

                }
            )
        }
        else if let image = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            ALAssetsLibrary().writeImageToSavedPhotosAlbum(image.CGImage!, metadata: info[UIImagePickerControllerMediaMetadata]! as! [NSObject : AnyObject], completionBlock: {
                
                (referenceUrl, error) -> Void in
                
                #if DEBUG
                    print("photo saved to asset")
                    print(referenceUrl)   // assets-library://asset/asset.JPG?id=CCC70B9F-748A-43F2-AC61-8755C974EE15&ext=JPG
                #endif
                
                // you can load your UIImage that was just saved to your asset as follow
                ALAssetsLibrary().assetForURL(
                    referenceUrl,
                    resultBlock: {
                        asset in
                        
                        let fileName = asset.defaultRepresentation().filename()
                        // get extension to check if it's a supported media types
                        let fileExtension = TreemContentService.ContentFileExtensions.fromString(fileName.getPathNameExtension())
                        
                        if fileExtension.isValidExtension() {
                            if let mediaType = info[UIImagePickerControllerMediaType] as? NSString {
                                if UTTypeConformsTo(mediaType, kUTTypeImage) {
                                    if var image = info[UIImagePickerControllerOriginalImage] as? UIImage {

                                        // adjust to correct orientation
                                        image = image.rotateCameraImageToOrientation(image, maxResolution: AppSettings.max_post_image_resolution)
                                        
                                        self.delegate?.imageSelected(image, fileExtension: fileExtension, picker: picker)
                                    }
                                }
                            }
                        }
                    }
                    , failureBlock: {
                        (error) -> Void in
                        
                        #if DEBUG
                        if let error = error {
                            print(error.description)
                        }
                        #endif
                    }
                )
                
                #if DEBUG
                if let error = error {
                    print(error.description)
                }
                #endif
            })
        }
        else if let pickedVideo:NSURL = (info[UIImagePickerControllerMediaURL] as? NSURL) {
            ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(pickedVideo, completionBlock: { (referenceUrl, error) -> Void in
                
                #if DEBUG
                    print("video saved to asset")
                    print(referenceUrl)   // assets-library://asset/asset.JPG?id=CCC70B9F-748A-43F2-AC61-8755C974EE15&ext=JPG
                #endif
                
                // you can load your UIImage that was just saved to your asset as follow
                ALAssetsLibrary().assetForURL(
                    referenceUrl,
                    resultBlock: {
                        asset in
                        
                        let fileName = asset.defaultRepresentation().filename()
                        
                        // get extension to check if it's a supported media types
                        let fileExtension = TreemContentService.ContentFileExtensions.fromString(fileName.getPathNameExtension())
                        
                        if fileExtension.isValidExtension() {
                            if let mediaType = info[UIImagePickerControllerMediaType] as? NSString {
                                if UTTypeConformsTo(mediaType, kUTTypeMovie) || UTTypeConformsTo(mediaType, kUTTypeVideo) {
                                    if let fileURL = info[UIImagePickerControllerMediaURL] as? NSURL {

                                        self.delegate?.videoSelected(fileURL, orientation: self.getVideoOrientation(fileURL), fileExtension: fileExtension, picker: picker)
                                    }
                                }
                            }
                        }
                    },
                    failureBlock: {
                        (error) -> Void in
                            #if DEBUG
                            if let error = error {
                                print(error.description)
                            }
                            #endif
                    }
                )
                
                #if DEBUG
                if let error = error {
                    print(error.description)
                }
                #endif
            })

        }
    }
    
    private func getVideoOrientation(vidUrl: NSURL) -> ContentItemOrientation {
        
        var orientation     = ContentItemOrientation.LandscapeLeft
        let asset           = AVURLAsset(URL: vidUrl, options: nil)
        let tracks          = asset.tracksWithMediaType(AVMediaTypeVideo)
        
        if(tracks.count > 0) {
            let transform =  tracks[0].preferredTransform
            let vidAngle  = self.radiansToDegrees(atan2(transform.b, transform.a))
            
            switch(Int(vidAngle)){
                case 0: orientation = ContentItemOrientation.LandscapeLeft; break;
                case 90: orientation = ContentItemOrientation.LandscapePortrait; break;
                case 180: orientation = ContentItemOrientation.LandscapeRight; break;
                case -90: orientation = ContentItemOrientation.LandscapePortraitInverted; break;
                default: orientation = ContentItemOrientation.LandscapeLeft; break;
            }
        }
        
        return orientation
    }
    
    private func radiansToDegrees(radians: CGFloat) -> CGFloat{
        return CGFloat(Double(radians * 180) / M_PI)
    }
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool)
    {
        viewController.navigationItem.title = "Albums"
    }
}