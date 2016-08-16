//
//  ImageFilterOptionsPopoverController.swift
//  Treem
//
//  Created by Tracy Merrill on 2/3/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class ImageFilterOptionsPopoverController : UIViewController, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {
    
    var imageForEdit : CIImage?
    var originalImage : CIImage?
    var mainImageView : CroppableImageView?
    var imageSize : CGSize?
    var delegate : ImageEditViewController?
    
    @IBAction func monoTouchUpInside(sender: AnyObject) {
        
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter!.setDefaults()
        filter!.setValue(imageForEdit, forKey: kCIInputImageKey)
        let ctx = CIContext(options:nil)
        
        let cgImage = ctx.createCGImage(filter!.outputImage!, fromRect:filter!.outputImage!.extent)
        
        let newImage = ImageConversionHelpers.convertCGImageToUIImage(cgImage)
        
        delegate?.editedImage = newImage
        delegate?.isImageEdited = true
        
        mainImageView?.imageToCrop = newImage
        
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func tonalTouchUpInside(sender: AnyObject) {
        let filter = CIFilter(name: "CIPhotoEffectTonal")
        filter!.setDefaults()
        filter!.setValue(imageForEdit, forKey: kCIInputImageKey)
        
        let ctx = CIContext(options:nil)
        
        let cgImage = ctx.createCGImage(filter!.outputImage!, fromRect:filter!.outputImage!.extent)
        
        let newImage = ImageConversionHelpers.convertCGImageToUIImage(cgImage)
        
        delegate?.editedImage = newImage
        delegate?.isImageEdited = true
        
        mainImageView?.imageToCrop = newImage
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func noirTouchUpInside(sender: AnyObject) {
        let filter = CIFilter(name: "CIPhotoEffectNoir")
        filter!.setDefaults()
        filter!.setValue(imageForEdit, forKey: kCIInputImageKey)
        
        let ctx = CIContext(options:nil)
        
        let cgImage = ctx.createCGImage(filter!.outputImage!, fromRect:filter!.outputImage!.extent)
        
        let newImage = ImageConversionHelpers.convertCGImageToUIImage(cgImage)
        
        delegate?.editedImage = newImage
        delegate?.isImageEdited = true
        
        mainImageView?.imageToCrop = newImage
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func fadeTouchUpInside(sender: AnyObject) {
        let filter = CIFilter(name: "CIPhotoEffectFade")
        filter!.setDefaults()
        filter!.setValue(imageForEdit, forKey: kCIInputImageKey)
        
        let ctx = CIContext(options:nil)
        
        let cgImage = ctx.createCGImage(filter!.outputImage!, fromRect:filter!.outputImage!.extent)
        
        let newImage = ImageConversionHelpers.convertCGImageToUIImage(cgImage)
        
        delegate?.editedImage = newImage
        delegate?.isImageEdited = true
        
        mainImageView?.imageToCrop = newImage
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func chromeTouchUpInside(sender: AnyObject){
        let filter = CIFilter(name: "CIPhotoEffectChrome")
        filter!.setDefaults()
        filter!.setValue(imageForEdit, forKey: kCIInputImageKey)
        
        let ctx = CIContext(options:nil)
        
        let cgImage = ctx.createCGImage(filter!.outputImage!, fromRect:filter!.outputImage!.extent)
        
        let newImage = ImageConversionHelpers.convertCGImageToUIImage(cgImage)
        
        delegate?.editedImage = newImage
        delegate?.isImageEdited = true
        
        mainImageView?.imageToCrop = newImage
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func processTouchUpInside(sender: AnyObject) {
        let filter = CIFilter(name: "CIPhotoEffectProcess")
        filter!.setDefaults()
        filter!.setValue(imageForEdit, forKey: kCIInputImageKey)
        
        let ctx = CIContext(options:nil)
        
        let cgImage = ctx.createCGImage(filter!.outputImage!, fromRect:filter!.outputImage!.extent)
        
        let newImage = ImageConversionHelpers.convertCGImageToUIImage(cgImage)
        
        delegate?.editedImage = newImage
        delegate?.isImageEdited = true
        
        mainImageView?.imageToCrop = newImage
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func transferTouchUpInside(sender: AnyObject) {
        let filter = CIFilter(name: "CIPhotoEffectTransfer")
        filter!.setDefaults()
        filter!.setValue(imageForEdit, forKey: kCIInputImageKey)
        
        let ctx = CIContext(options:nil)
        
        let cgImage = ctx.createCGImage(filter!.outputImage!, fromRect:filter!.outputImage!.extent)
        
        let newImage = ImageConversionHelpers.convertCGImageToUIImage(cgImage)
        
        delegate?.editedImage = newImage
        delegate?.isImageEdited = true
        
        mainImageView?.imageToCrop = newImage
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func instantTouchUpInside(sender: AnyObject) {
        let filter = CIFilter(name: "CIPhotoEffectInstant")
        filter!.setDefaults()
        filter!.setValue(imageForEdit, forKey: kCIInputImageKey)
        
        let ctx = CIContext(options:nil)
        
        let cgImage = ctx.createCGImage(filter!.outputImage!, fromRect:filter!.outputImage!.extent)
        
        let newImage = ImageConversionHelpers.convertCGImageToUIImage(cgImage)
        
        delegate?.editedImage = newImage
        delegate?.isImageEdited = true
        
        mainImageView?.imageToCrop = newImage
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    @IBAction func originalTouchUpInside(sender: AnyObject) {
        
        let newImage = UIImage(CIImage: originalImage!)
        
        delegate?.editedImage = newImage
        delegate?.isImageEdited = false
        mainImageView?.imageToCrop = newImage
        
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // calculate preferred content size
        let totalHeight: CGFloat = 330
        
        self.preferredContentSize = CGSizeMake(200, totalHeight)
    }
    
    static func getStoryboardInstance() -> ImageFilterOptionsPopoverController {
        let vc = UIStoryboard(name: "ImageFilterOptionsPopover", bundle: nil).instantiateInitialViewController() as! ImageFilterOptionsPopoverController
        
        vc.modalPresentationStyle = .Popover
        
        return vc
    }

}
