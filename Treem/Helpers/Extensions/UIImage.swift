//
//  UIImage.swift
//  Treem
//
//  Created by Matthew Walker on 8/11/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import CoreGraphics
import UIKit

extension UIImage {
    // get an image object filled with color 
    func getImageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0, 0, 1, 1)
    
        UIGraphicsBeginImageContext(rect.size)
        
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func fillTemplateImageWithColor(tintColor: UIColor) -> UIImage {
        let size = self.size
        
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        
        let context = UIGraphicsGetCurrentContext()!
        
        CGContextTranslateCTM(context, 0, size.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        CGContextSetBlendMode(context, .Normal)
        
        let rect = CGRectMake(0, 0, size.width, size.height) as CGRect
        CGContextClipToMask(context, rect, self.CGImage)
        tintColor.setFill()
        CGContextFillRect(context, rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext() as UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    static func getResizeImageScaleSize(newSize: CGSize, oldSize: CGSize) -> CGSize {
        let ratio   = min(newSize.width / oldSize.width, newSize.height / oldSize.height)
        let newSize = CGSizeMake(oldSize.width * ratio, oldSize.height * ratio)
        
        return newSize
    }
    
    func resizeImageScaleAspectFit(size: CGSize) -> UIImage {
        let newSize = UIImage.getResizeImageScaleSize(size, oldSize: self.size)

        UIGraphicsBeginImageContext(newSize)
        
        self.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func resizeImageScaleWithRatio(size: CGSize) -> UIImage {
        
        var scaledImageRect = CGRect.zero;
        
        let aspectWidth:CGFloat = size.width / self.size.width;
        let aspectHeight:CGFloat = size.height / self.size.height;
        let aspectRatio:CGFloat = min(aspectWidth, aspectHeight);
        
        scaledImageRect.size.width = self.size.width * aspectRatio;
        scaledImageRect.size.height = self.size.height * aspectRatio;
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0;
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0;
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        
        self.drawInRect(scaledImageRect);
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return scaledImage;
    }
    
    // Transformations from https://discussions.apple.com/thread/1537011
    //
    func rotateCameraImageToOrientation(image : UIImage, maxResolution : CGFloat) -> UIImage {
        let imgRef  = image.CGImage
        let width   = CGFloat(CGImageGetWidth(imgRef))
        let height  = CGFloat(CGImageGetHeight(imgRef))
        
        var bounds  = CGRectMake(0, 0, width, height)
        var scaleRatio : CGFloat = 1
        
        if (width > maxResolution || height > maxResolution) {
            
            scaleRatio = min(maxResolution / bounds.size.width, maxResolution / bounds.size.height)
            bounds.size.height = bounds.size.height * scaleRatio
            bounds.size.width = bounds.size.width * scaleRatio
        }
        
        var transform   = CGAffineTransformIdentity
        let orientation = image.imageOrientation
        let imageSize   = CGSizeMake(width, height)
        
        switch(image.imageOrientation) {
        case .Up :
            transform = CGAffineTransformIdentity
            
        case .UpMirrored :
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0)
            transform = CGAffineTransformScale(transform, -1.0, 1.0)
            
        case .Down :
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
            
        case .DownMirrored :
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height)
            transform = CGAffineTransformScale(transform, 1.0, -1.0)
            
        case .Left :
            let storedHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = storedHeight
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width)
            transform = CGAffineTransformRotate(transform, 3.0 * CGFloat(M_PI) / 2.0)
            
        case .LeftMirrored :
            let storedHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = storedHeight
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width)
            transform = CGAffineTransformScale(transform, -1.0, 1.0)
            transform = CGAffineTransformRotate(transform, 3.0 * CGFloat(M_PI) / 2.0)
            
        case .Right :
            let storedHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = storedHeight
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI) / 2.0)
            
        case .RightMirrored :
            let storedHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = storedHeight
            transform = CGAffineTransformMakeScale(-1.0, 1.0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI) / 2.0)
        }
        
        UIGraphicsBeginImageContext(bounds.size)
        let context = UIGraphicsGetCurrentContext()
        
        if orientation == .Right || orientation == .Left {
            CGContextScaleCTM(context, -scaleRatio, scaleRatio)
            CGContextTranslateCTM(context, -height, 0)
        }
        else {
            CGContextScaleCTM(context, scaleRatio, -scaleRatio)
            CGContextTranslateCTM(context, 0, -height)
        }
        
        CGContextConcatCTM(context, transform)
        CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef)
        
        let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return imageCopy
    }
}