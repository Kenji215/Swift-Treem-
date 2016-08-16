//
//  ImageEditViewController.swift
//  Treem
//
//  Created by Tracy Merrill on 1/29/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

//import UIKit
//import AssetsLibrary
//
//@objc protocol ImageEdited {
//    func imageUpdated(updatedImage: UIImage, isEdited: Bool)
//}
//
//class ImageEditViewController : UIViewController, CroppableImageViewDelegateProtocol, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIPopoverPresentationControllerDelegate {
//    
//    @IBOutlet var parentView: UIView!
//    @IBOutlet weak var imageView: CroppableImageView!
//    @IBOutlet weak var cropButton: UIButton!
//    @IBOutlet var imageEditedDelegate: ImageEdited?
//    
//    @IBAction func selectFilterType(sender: AnyObject) {
//        
//        filterPopover = ImageFilterOptionsPopoverController.getStoryboardInstance()
//        
//        filterPopover!.mainImageView = imageView
//        filterPopover!.imageSize = imageSize
//        filterPopover!.delegate = self
//        
//        if editedImage != nil {
//            
//            filterPopover!.originalImage = ImageConversionHelpers.convertUIImageToCIImage(originalImage!)
//            filterPopover!.imageForEdit = ImageConversionHelpers.convertUIImageToCIImage(editedImage!)
//        }
//        else {
//            filterPopover!.originalImage = ImageConversionHelpers.convertUIImageToCIImage(originalImage!)
//            filterPopover!.imageForEdit = ImageConversionHelpers.convertUIImageToCIImage(originalImage!)
//        }
//        
//        if let filterPickerMenuView = filterPopover!.popoverPresentationController {
//            filterPickerMenuView.permittedArrowDirections    = .Any
//            filterPickerMenuView.delegate                    = self
//            filterPickerMenuView.sourceView                  = sender as? UIView
//            filterPickerMenuView.sourceRect = CGRect(x: sender.bounds.width *  0.5, y: sender.bounds.height * 0.5, width: 0, height: 0)
//            
//            self.presentViewController(filterPopover!, animated: true, completion: nil)
//        }
//    }
//    
//    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
//        return .None
//    }
//    
//    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
//        return UIInterfaceOrientationMask.Portrait;
//    }
//    
//    @IBAction func cropPhoto(sender: AnyObject) {
//        editedImage = imageView.croppedImage()
//        
//        let size = UIImage.getResizeImageScaleSize(CGSize(width: self.view.frame.width, height: 400), oldSize: editedImage!.size)
//        
//        imageView!.frame         = CGRectMake(0, 0, size.width, size.height)
//
//        
//        editedImage = editedImage!.rotateCameraImageToOrientation(editedImage!, maxResolution: AppSettings.sharedInstance.max_post_image_resolution)
//        
//        imageView.imageToCrop = editedImage
//        isImageEdited = true
//    }
//    
//    @IBAction func saveTouchUpInside(sender: AnyObject) {
//        if editedImage == nil {
//            editedImage = originalImage
//        }
//        
//        imageEditedDelegate?.imageUpdated(editedImage!, isEdited: isImageEdited!)
//    }
//    
//    
//    @IBAction func cancelTouchUpInside(sender: AnyObject) {
//        self.dismissViewControllerAnimated(true, completion: nil)
//    }
//    
//    var originalImage                   : UIImage?
//    var editedImage                     : UIImage?
//    var editedUrl                       : NSURL?
//    var imageSize                       : CGSize?
//    var isImageEdited                   : Bool?
//    var filterPopover                   : ImageFilterOptionsPopoverController?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        let formatImage = self.originalImage!
//        
//        imageView.cropDelegate = self
//        
//        imageView.imageToCrop = formatImage
//        
//        isImageEdited = false
//    }
//    
//    override func prefersStatusBarHidden() -> Bool {
//        return true
//    }
//    
//    static func getStoryboardInstance() -> ImageEditViewController {
//        let vc = UIStoryboard(name: "MediaImageEdit", bundle: nil).instantiateInitialViewController() as! ImageEditViewController
//
//        return vc
//    }
//    
//    func haveValidCropRect(haveValidCropRect:Bool)
//    {   
//        cropButton.enabled = haveValidCropRect
//    }
//}
