//
//  TreeGridTheme.swift
//  Treem
//
//  Created by Matthew Walker on 9/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

struct TreeGridTheme {
    var barTextBoldColor        : UIColor
    var backgroundColor         : UIColor
    var backgroundImage         : String?
    var buttonStrokeColor       : UIColor
    var initialBranchColor      : UIColor
    var defaultBranchFillColor  : UIColor
    var backFillColor           : UIColor
    var addFillColor            : UIColor
    var addTitleColor           : UIColor
    var actionFillColor         : UIColor
    var actionTitleColor        : UIColor
    var editBranchAlpha         : CGFloat
    var branchBarTitleColor     : UIColor
    var hexagonLineWidth        : CGFloat
    var centerBranchFillColor   : UIColor
    
    // all settings should be set
    init(
        barTextBoldColor        : UIColor,
        backgroundColor         : UIColor,
        backgroundImage         : String?,
        buttonStrokeColor       : UIColor,
        initialBranchColor      : UIColor,
        defaultBranchFillColor  : UIColor,
        backFillColor           : UIColor,
        addFillColor            : UIColor,
        addTitleColor           : UIColor,
        actionFillColor         : UIColor,
        actionTitleColor        : UIColor,
        editBranchAlpha         : CGFloat,
        branchBarTitleColor     : UIColor,
        hexagonLineWidth        : CGFloat,
        centerBranchFillColor   : UIColor
    ) {
        self.barTextBoldColor       = barTextBoldColor
        self.backgroundColor        = backgroundColor
        self.backgroundImage        = backgroundImage
        self.buttonStrokeColor      = buttonStrokeColor
        self.initialBranchColor     = initialBranchColor
        self.defaultBranchFillColor = defaultBranchFillColor
        self.backFillColor          = backFillColor
        self.addFillColor           = addFillColor
        self.addTitleColor          = addTitleColor
        self.actionFillColor        = actionFillColor
        self.actionTitleColor       = actionTitleColor
        self.editBranchAlpha        = editBranchAlpha
        self.branchBarTitleColor    = branchBarTitleColor
        self.hexagonLineWidth       = hexagonLineWidth
        self.centerBranchFillColor  = centerBranchFillColor
    }
    
    static var membersTheme: TreeGridTheme {
        let clear = UIColor.clearColor()
        let white = UIColor.whiteColor()
        
        let theme = TreeGridTheme (
            barTextBoldColor        : white,
            backgroundColor         : clear,
            backgroundImage         : "HomeBackground",
            buttonStrokeColor       : clear,
            initialBranchColor      : UIColor(red: 102 / 255, green: 141 / 255, blue: 60 / 255, alpha: 1),
            defaultBranchFillColor  : clear,
            backFillColor           : white,
            addFillColor            : UIColor(red: 201/255.0, green: 201/255.0, blue: 201/255.0, alpha: 0.5),
            addTitleColor           : UIColor(red: 201/255.0, green: 201/255.0, blue: 201/255.0, alpha: 0.95),
            actionFillColor         : clear,
            actionTitleColor        : white,
            editBranchAlpha         : 0.3,
            branchBarTitleColor     : white,
            hexagonLineWidth        : 1.4,
            centerBranchFillColor   : white
        )
        
        return theme
    }
    
    static var secretTheme: TreeGridTheme {
        let clear       = UIColor.clearColor()
        let offWhite    = UIColor(red: 225 / 255, green: 225 / 255, blue: 225 / 255, alpha: 1)
        
        let theme = TreeGridTheme (
            barTextBoldColor        : UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1),
            backgroundColor         : clear,
            backgroundImage         : "HomeBackgroundDark",
            buttonStrokeColor       : clear,
            initialBranchColor      : UIColor(red: 170 / 255, green: 176 / 255, blue: 170 / 255, alpha: 1),
            defaultBranchFillColor  : clear,
            backFillColor           : offWhite,
            addFillColor            : UIColor(red: 0, green: 0, blue: 0, alpha: 0.85),
            addTitleColor           : UIColor(red: 104 / 255, green: 110 / 255, blue: 104/255, alpha: 1.0),
            actionFillColor         : clear,
            actionTitleColor        : offWhite,
            editBranchAlpha         : 0.6,
            branchBarTitleColor     : UIColor.whiteColor(),
            hexagonLineWidth        : 1.8,
            centerBranchFillColor   : UIColor.blackColor()
        )
        
        return theme
    }
    
    static var exploreTheme: TreeGridTheme {
        let clear = UIColor.clearColor()
        let white = UIColor.whiteColor()
        
        let theme = TreeGridTheme (
            barTextBoldColor        : white,
            backgroundColor         : clear,
            backgroundImage         : "HomeBackgroundPublic",
            buttonStrokeColor       : clear,
            initialBranchColor      : UIColor(red: 86 / 255, green: 127 / 255, blue: 171/255, alpha: 1),
            defaultBranchFillColor  : clear,
            backFillColor           : white,
            addFillColor            : UIColor(red: 201/255.0, green: 201/255.0, blue: 201/255.0, alpha: 0.55),
            addTitleColor           : UIColor(red: 201/255.0, green: 201/255.0, blue: 211/255.0, alpha: 0.95),
            actionFillColor         : clear,
            actionTitleColor        : white,
            editBranchAlpha         : 0.3,
            branchBarTitleColor     : white,
            hexagonLineWidth        : 1.4,
            centerBranchFillColor   : white
        )
        
        return theme
    }
}
