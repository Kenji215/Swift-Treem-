//
//  ImageEditor.swift
//  Treem
//
//  Created by Matthew Walker on 3/15/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import CLImageEditor

class ImageEditor: CLImageEditor {
    private var isProfile: Bool = false
    
    //# MARK: Initializers
    override init(image: UIImage) {
        super.init(image: image)
        
        self.setDefaults()
    }
    
    override init(image: UIImage, delegate: CLImageEditorDelegate!) {
        super.init(image: image, delegate: delegate)
        
        self.setDefaults()
    }
    
    override init(image: UIImage, delegate: CLImageEditorDelegate!, isProfile: Bool) {
        super.init(image: image, delegate: delegate, isProfile: isProfile)
        
        self.isProfile = isProfile
        
        self.setDefaults()
    }
    
    override init(delegate: CLImageEditorDelegate!) {
        super.init(delegate: delegate)
        
        self.setDefaults()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setDefaults()
    }

    //# MARK: Helper Methods
    private func setDefaults() {
        
        // update theme
        let theme       = self.theme
        let background  = AppStyles.sharedInstance.subBarBackgroundColor

        theme.bundleName        = "ImageEditor"
        theme.backgroundColor   = background
        theme.toolbarColor      = background
        theme.toolbarTextColor  = UIColor.whiteColor()
        theme.toolIconColor     = "black"
        theme.statusBarStyle    = .LightContent
        
        theme.toolbarSelectedButtonColor = background.colorWithAlphaComponent(0.85)
        
        let navBarAppearance = UINavigationBar.appearance()
        
        navBarAppearance.shadowImage    = nil
        navBarAppearance.barTintColor   = AppStyles.sharedInstance.subBarBackgroundColor
        navBarAppearance.clipsToBounds  = true
        
        // set menu item order
        let toolInfo = self.toolInfo
        
        let clipTool = toolInfo.subToolInfoWithToolName("CLClippingTool", recursive: false)
        clipTool.dockedNumber = -4
        
        let rotateTool = toolInfo.subToolInfoWithToolName("CLRotateTool", recursive: false)
        rotateTool.dockedNumber = -3
        
        let resizeTool = toolInfo.subToolInfoWithToolName("CLResizeTool", recursive: false)
        resizeTool.dockedNumber = -2
    }
}