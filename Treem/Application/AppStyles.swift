//
//  AppStyles.swift
//  Treem
//
//  Created by Matthew Walker on 10/14/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class AppStyles {
    static let sharedInstance = AppStyles()
    
    // constant color definitions
    let whiteColor              = UIColor.whiteColor()
    let lightGrayColor          = UIColor(red: 245/255.0, green: 245/255.0, blue: 245/255.0, alpha: 1)
    let midGrayColor            = UIColor(red: 188/255.0, green: 190/255.0, blue: 188/255.0, alpha: 1)
    let darkGrayColor           = UIColor(red: 78/255.0, green: 85/255.0, blue: 77/255.0, alpha: 1)
    
    static let overlayColor     = UIColor.blackColor().colorWithAlphaComponent(0.85)
    static let dividerFormColor = UIColor(red: 219/255, green: 219/255, blue: 225/255, alpha: 1.0)
    
    // app color configurations
    var navBarTintColor             : UIColor!
    var fieldGrayColor              : UIColor!
    var stockTickerPositive         : UIColor!
    var stockTickerNegative         : UIColor!
    var disabledButtonGray          : UIColor!
    var disabledButtonTitleGray     : UIColor!
    var tintColor                   : UIColor!
    var dividerColor                : UIColor! // used for table divider
    var dividerFormColor            : UIColor! // user for whole form view divider
    var subBarBackgroundColor       : UIColor!
    var subBarActionTintColor       : UIColor!
    var headerColor                 : UIColor!
    var rewardsTintColor            : UIColor!
    var tabBarIconColor             : UIColor!
    var subBarForeColor             : UIColor!
    var indicator                   : UIColor!
    var indicatorActive             : UIColor!
    var textPlaceholderColor        : UIColor!
    
    let viewAnimationDuration       : NSTimeInterval = 0.2

    static var directionDownViewAnimatedTransition: DirectionalAnimatedTransition {
        return DirectionalAnimatedTransition(animationDirection: DirectionalAnimatedTransition.AnimationDirection.Down, showFromAnimation: true, showToAnimation: false)
    }
    static var directionUpViewAnimatedTransition: DirectionalAnimatedTransition {
        return DirectionalAnimatedTransition(animationDirection: DirectionalAnimatedTransition.AnimationDirection.Up, showFromAnimation: false, showToAnimation: true)
    }
    static var directionLeftViewAnimatedTransition: DirectionalAnimatedTransition {
        return DirectionalAnimatedTransition(animationDirection: DirectionalAnimatedTransition.AnimationDirection.Left, showFromAnimation: true, showToAnimation: true)
    }
    static var directionRightViewAnimatedTransition: DirectionalAnimatedTransition {
        return DirectionalAnimatedTransition(animationDirection: DirectionalAnimatedTransition.AnimationDirection.Right, showFromAnimation: true, showToAnimation: true)
    }
    
    func loadDefaultAppStyles() {
        // app color configurations
		self.dividerColor               = UIColor(red: 225/255.0, green: 225/255.0, blue: 225/255.0, alpha: 1)	// white

        self.tintColor                  = UIColor(red: 140/255.0, green: 190/255.0, blue: 49/255.0, alpha: 1.0) // green
        
		self.stockTickerPositive        = UIColor(red: 61/255, green: 150/255, blue: 0, alpha: 1)				// dark green
		self.stockTickerNegative        = UIColor(red: 150/255, green: 14/255, blue: 0, alpha: 1)				// dark red

        self.subBarBackgroundColor      = UIColor(red: 53/255, green: 70/255, blue: 55/255, alpha: 1.0)
        self.subBarActionTintColor      = self.subBarBackgroundColor.lighterColorForColor(0.25)
        
        self.navBarTintColor            = self.subBarBackgroundColor
        self.fieldGrayColor             = UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
        self.disabledButtonGray         = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1.0)
        self.disabledButtonTitleGray    = UIColor(red: 170/255, green: 172/255, blue: 170/255, alpha: 1.0)

        self.headerColor                = darkGrayColor
        
		self.rewardsTintColor           = UIColor(red: 255/255.0, green: 204/255.0, blue: 51/255.0, alpha: 1)	// orange

		self.tabBarIconColor            = UIColor(red: 159/255.0, green: 159/255.0, blue: 159/255.0, alpha: 1)	// medium gray

		self.subBarForeColor            = UIColor(red: 91/255.0, green: 97/255.0, blue: 90/255.0, alpha: 1)		// dark gray

		self.indicator                  = UIColor(red: 78/255.0, green: 85/255.0, blue: 77/255.0, alpha: 1)		// dark gray
		self.indicatorActive            = UIColor(red: 250/255.0, green: 66/255.0, blue: 37/255.0, alpha: 1)	// light red

		self.textPlaceholderColor       = UIColor(red: 199/255.0, green: 199/255.0, blue: 205/255.0, alpha: 1)	// light grey

        // Navigation bar appearance
        let navigationBarAppearance = UINavigationBar.appearance()
        
        navigationBarAppearance.translucent         = false
        navigationBarAppearance.barTintColor        = navBarTintColor
        navigationBarAppearance.titleTextAttributes = [NSForegroundColorAttributeName: whiteColor]
        navigationBarAppearance.tintColor           = tintColor
        
        // Button appearance
        let buttonAppearance = UIButton.appearance()
        
        buttonAppearance.tintColor = tintColor
        
        // Switch appearance
        let switchAppearance = UISwitch.appearance()
        
        switchAppearance.onTintColor = tintColor
        
        // Segmented control appearance
        let segmentedControlAppearance = UISegmentedControl.appearance()
        
        segmentedControlAppearance.setBackgroundImage(UIImage().getImageWithColor(lightGrayColor), forState: .Normal, barMetrics: .Default)
        
        segmentedControlAppearance.setDividerImage(UIImage().getImageWithColor(UIColor.clearColor()), forLeftSegmentState: .Normal, rightSegmentState: .Normal, barMetrics: .Default)
        
        segmentedControlAppearance.tintColor = darkGrayColor
        
        var segmentSelectedAttr = NSDictionary(object: UIFont.boldSystemFontOfSize(14.0), forKey: NSFontAttributeName) as [NSObject : AnyObject]
        segmentSelectedAttr[NSForegroundColorAttributeName] = darkGrayColor
        
        segmentedControlAppearance.setTitleTextAttributes(segmentSelectedAttr, forState: .Selected)
        
        var segmentNormalAttr = NSDictionary(object: UIFont.systemFontOfSize(14.0), forKey: NSFontAttributeName) as [NSObject : AnyObject]
        segmentNormalAttr[NSForegroundColorAttributeName] = darkGrayColor
        
        segmentedControlAppearance.setTitleTextAttributes(segmentNormalAttr, forState: .Normal)
    }
    
    // get edit button to be placed over an image
    func getEditImageButton(title: String?, image: String?) -> UIButton {
        let button = UIButton(type: .System)
        
        button.setTitle(title, forState: .Normal)
        
        if let image = image {
            button.setImage(UIImage(named: image), forState: .Normal)
        }
        
        self.setImageEditButton(button)
        
        return button
    }
    
    func setButtonDefaultStyles(button: UIButton) {
        // set style for title button
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(self.disabledButtonTitleGray, forState: .Disabled)
    }
    
    // default styles for button on dark background
    func setButtonDarkDefaultStyles(button: UIButton) {
        // set style for title button
        button.setTitleColor(AppStyles.sharedInstance.tintColor, forState: .Normal)
        button.setTitleColor(AppStyles.sharedInstance.darkGrayColor, forState: .Disabled)
    }
    
    // transition background color on enabled property change
    func setButtonEnabledAndAjustStyles(button: UIButton, enabled: Bool, withAnimation: Bool = false, showDisabledOutline: Bool = true) {
        button.enabled = enabled
        
        // need to set as background color set is not supported with state
        let backgroundColor = enabled ? self.tintColor : showDisabledOutline ? self.disabledButtonGray : nil
        
        if withAnimation {
            UIView.animateWithDuration(self.viewAnimationDuration, animations: {() -> Void in
                button.backgroundColor = backgroundColor
            })
        }
        else {
            button.backgroundColor = backgroundColor
        }
    }
    
    // used when a top nav is not present and you want a close button hovering over your content
    func setFloatingCloseButtonStyles(button: UIButton){
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(self.disabledButtonTitleGray, forState: .Disabled)
        button.backgroundColor = UIColor.clearColor()
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.whiteColor().CGColor
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 5)
    }
    
    // set image edit button styles
    func setImageEditButton(button: UIButton) {
        button.contentHorizontalAlignment = .Left
        button.imageView?.contentMode = .ScaleAspectFit
        button.tintColor = AppStyles.sharedInstance.darkGrayColor
        button.contentEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, button.titleLabel?.text != nil ? 5 : 0)
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 0)

        button.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.75)
        button.titleLabel?.font = UIFont.systemFontOfSize(14.0, weight: UIFontWeightBold)
        button.setTitleColor(AppStyles.sharedInstance.darkGrayColor, forState: .Normal)
        button.setTitleColor(AppStyles.sharedInstance.midGrayColor, forState: .Highlighted)
        button.titleLabel?.adjustsFontSizeToFitWidth = false
        
        button.sizeToFit()
    }
    
    func setSubHeaderBarStyles(barView: UIView) {
        // apply background
        barView.backgroundColor = self.subBarBackgroundColor
    }
    
    func setMainTabBarAppearance(tabBar: UITabBar) {
        // Tab bar appearance
        tabBar.barTintColor       = UIColor(red: 53/255, green: 70/255, blue: 55/255, alpha: 1.0)
        tabBar.tintColor          = AppStyles.sharedInstance.tintColor
        tabBar.translucent        = false
        tabBar.shadowImage        = UIImage()
        tabBar.backgroundImage    = UIImage() // (background set in storyboard)
        
        // update tab bar item colors
        if let tabBarItems = tabBar.items {
            let defaultColor = tabBar.backgroundColor?.lighterColorForColor(0.3) ?? AppStyles.sharedInstance.midGrayColor
            
            for item in tabBarItems as [UITabBarItem] {
                if let image = item.image {
                    item.image = image.fillTemplateImageWithColor(defaultColor).imageWithRenderingMode(.AlwaysOriginal)
                    item.setTitleTextAttributes([NSForegroundColorAttributeName:defaultColor], forState: .Normal)
                    item.setTitleTextAttributes([NSForegroundColorAttributeName:tabBar.tintColor], forState: .Selected)
                }
            }
        }
    }
    
    func setBranchTabBarAppearance(tabBar: UITabBar) {
        // Tab bar appearance
        tabBar.barTintColor       = self.lightGrayColor
        tabBar.translucent        = false
        tabBar.tintColor          = self.subBarForeColor
        tabBar.shadowImage        = UIImage().getImageWithColor(dividerColor)
        tabBar.backgroundImage    = UIImage().getImageWithColor(UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1))
    }
    
    func setPublicTreeHeaderLabel(label: UILabel){
        label.font = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        label.textColor = self.darkGrayColor
    }
    
    func setURLAttributedLabelStyling(label: TTTAttributedLabel, lightBackground: Bool = true) {
        
        label.linkAttributes            = [
            kCTForegroundColorAttributeName : (lightBackground ? AppStyles.sharedInstance.tintColor.CGColor : AppStyles.sharedInstance.lightGrayColor.CGColor),
            kCTUnderlineStyleAttributeName : NSNumber(int: CTUnderlineStyle.Single.rawValue)
        ]
        
        label.activeLinkAttributes      = [
            kCTForegroundColorAttributeName : (lightBackground ? AppStyles.sharedInstance.tintColor.lighterColorForColor(0.5).CGColor : AppStyles.sharedInstance.lightGrayColor.darkerColorForColor(0.2).CGColor),
            kCTUnderlineStyleAttributeName : NSNumber(int: CTUnderlineStyle.Single.rawValue)
        ]
        
        label.enabledTextCheckingTypes  = NSTextCheckingType.Link.rawValue
    }
}