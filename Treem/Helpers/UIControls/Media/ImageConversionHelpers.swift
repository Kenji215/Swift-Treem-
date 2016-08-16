//
//  ImageConversionHelpers.swift
//  Treem
//
//  Created by Tracy Merrill on 2/3/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

public class ImageConversionHelpers {
    
    static func convertUIImageToCGImage(uiImage: UIImage) -> CGImage! {
        
        let firstConvert = convertUIImageToCIImage(uiImage)
        
        let cgImage = convertCIImageToCGImage(firstConvert)
        
        return cgImage
    }
    
    static func convertCGImageToUIImage(cgImage: CGImage) -> UIImage {
        
        let uiImage = UIImage(CGImage: cgImage)
        
        return uiImage
    }
    
    static func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        return context.createCGImage(inputImage, fromRect:inputImage.extent)
    }
    
    static func convertCGImageToCIImage(inputImage: CGImage) -> CIImage! {
        let cgImage = CIImage(CGImage: inputImage)
        return cgImage
    }
    
    static func convertUIImageToCIImage(uiImage: UIImage) -> CIImage! {
        let ciImage = CIImage(image: uiImage)
        
        return ciImage
    }
    static func convertCIImageToUIImage(ciImage: CIImage) -> UIImage! {
        let uiImage = UIImage(CIImage: ciImage)
        
        return uiImage
    }
}