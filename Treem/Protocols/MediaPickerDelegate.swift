//
//  MediaPickerDelegate.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/25/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

protocol MediaPickerDelegate {
    // called if media selection cancelled
    func cancelSelected()
    
    // if an image is selected, either a new one taken from the camera or an existing from their device
    func imageSelected(image: UIImage, fileExtension: TreemContentService.ContentFileExtensions, picker: UIImagePickerController)
    
    // if an image is selected, either a new one taken from the camera or an existing from their device
    func videoSelected(fileURL: NSURL, orientation: ContentItemOrientation, fileExtension: TreemContentService.ContentFileExtensions, picker: UIImagePickerController)
}
