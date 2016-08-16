//
//  ContentItemDelegate.swift
//  Treem
//
//  Created by Matthew Walker on 1/3/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation

protocol ContentItemDelegate: class {
    var contentID       : Int { get set }
    var contentType     : TreemContentService.ContentTypes? { get set }
    var fileExtension   : TreemContentService.ContentFileExtensions? { get set }
}