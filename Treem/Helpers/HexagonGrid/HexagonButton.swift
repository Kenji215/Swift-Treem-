//
//  HexagonButton.swift
//  Treem
//
//  Created by Matthew Walker on 7/11/15.
//  Copyright (c) 2015 Treem LLC. All rights reserved.
//

import UIKit

@IBDesignable
class HexagonButton: UIButton {
    private var hexagonShape        : CAShapeLayer?     = nil
    private var fillColorLock       : Bool              = false
    private var gradientLayer       : CAGradientLayer?  = nil
    private var faviconImageView    : UIImageView?      = nil
    private var indicatorImageView  : UIImageView?      = nil
    
    var gridPosition            : HexagonGridPosition?  = nil
    var width                   : CGFloat               = 55
    var height                  : CGFloat               = 110
    var id                      : Int                   = 0
    
    // default constants
    private let defaultContentInsets = UIEdgeInsetsMake(0, 5, 0, 5)
    private let indicatorIconLength : CGFloat = 15
    private let favIconLength       : CGFloat = 18
    
    enum HexTypes: Int {
        case OPEN = 0
        case EMPTYBRANCH
        case BRANCH
        case ACTION
    }

    var type = HexTypes.OPEN

    @IBInspectable
    var iconImageName           : String?   = nil {
        didSet {
            self.updateIconImage()
        }
    }
    
    @IBInspectable
    var iconImageColor          : UIColor?  = nil {
        didSet {
            self.imageView?.tintColor = self.iconImageColor
        }
    }
    
    @IBInspectable
    var titleColor : UIColor = UIColor.whiteColor() {
        didSet {
            self.setTitleColor(self.titleColor, forState: .Normal)
            
            let highlightColor = self.iconImageDarkens ? self.titleColor.darkerColorForColor(0.15) : self.titleColor.lighterColorForColor(0.15)
            
            self.setTitleColor(highlightColor, forState: .Highlighted)
        }
    }
    
    @IBInspectable
    var iconImageDarkens        : Bool      = true
    
    @IBInspectable
    var titleFont: UIFont = UIFont.systemFontOfSize(16.0) {
        didSet {
            self.titleLabel?.font   = self.titleFont
        }
    }

    @IBInspectable
    var lineWidth: CGFloat = 2
    
    @IBInspectable
    var strokeColor: UIColor = UIColor.whiteColor() {
        didSet {
            self.hexagonShape?.strokeColor  = self.strokeColor.CGColor
            
            self.drawHexagonIfNeeded(true)
        }
    }
    
    @IBInspectable
    var fillColor: UIColor = UIColor.grayColor() {
        didSet {
            self.fillColorLock = false
            
            self.drawHexagonIfNeeded(true)
        }
    }
    
    var fillColorInitial: UIColor = UIColor.grayColor() {
        didSet {
            self.fillColor = self.fillColorInitial
        }
    }
    
    private var fillColorHighlighted: UIColor {
        return self.iconImageDarkens ? self.fillColor.darkerColorForColor(0.12) : self.fillColor.lighterColorForColor(0.15)
    }
    
    override var frame: CGRect {
        didSet {
            self.drawHexagonIfNeeded(true)
        }
    }
    
    override var highlighted: Bool {
        didSet {
            if(highlighted) {
                let tint = UIColor.whiteColor()
                
                self.tintColor = tint
                self.imageView?.tintColor = tint
                
                if(!self.fillColorLock) {
                    self.fillColor = self.fillColorHighlighted
                }
                
                self.fillColorLock = true
            }
            else {
                self.fillColor              = self.fillColorInitial
                self.fillColorLock          = false
                self.imageView?.tintColor   = self.titleColor
                self.tintColor              = self.titleColor
            }
        }
    }
    
    @IBInspectable
    var useGradientBackground: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setDefaults()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setDefaults()
    }
    
    init() {
        super.init(frame: CGRectZero)
        
        self.setDefaults()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // draw hexagon shape first if needed
        self.drawHexagonIfNeeded()
        
        // update the icon in the hexagon
        self.updateIconImage()
        
        // update title insets based on icon
        self.updateTitleInsets()
    }
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if let shape = self.hexagonShape {
            return CGPathContainsPoint(shape.path, nil, point, false)
        }
        
        return false
    }
    
    func drawHexagonIfNeeded(forceRedraw: Bool = false) {
        let boundsWidth     = self.bounds.width
        let boundsHeight    = self.bounds.height
        let center          = CGPoint(x: boundsWidth / 2, y: boundsHeight / 2)
        
        var radius: CGFloat
        
        // determine radius based on bound dimensions
        if boundsHeight <= boundsWidth {
            radius = boundsWidth / sqrt(3)
        }
        else {
            radius = 0.5 * boundsHeight
        }
        
        if self.hexagonShape == nil || forceRedraw {
            self.hexagonShape?.removeFromSuperlayer()
            
            // get bounds information
            let bezier = self.getHexagonPath(center, radius: radius)
            
            // create sub layer
            let hexShape            = CAShapeLayer()
            
            hexShape.path           = bezier.CGPath
            hexShape.bounds         = self.bounds
            hexShape.lineWidth      = self.lineWidth
            hexShape.position       = center

            self.hexagonShape = hexShape
            
            // insert at lowest layer (make sure button text remains on top)
            self.layer.insertSublayer(hexShape, atIndex: 0)
        }
        
        let hexShape = self.hexagonShape!
        
        hexShape.fillColor      = self.fillColor.CGColor
        hexShape.strokeColor    = self.strokeColor.colorIsClear() ? nil : self.strokeColor.CGColor

        if self.useGradientBackground {
            if self.gradientLayer == nil || forceRedraw {
                self.gradientLayer?.removeFromSuperlayer()
                
                // create new sub path for the hexagon shape
                let gradientBezier = self.getHexagonPath(center, radius: radius)
                
                let gradientLayer           = CAGradientLayer()
                let shift: CGFloat          = self.frame.height / 550.0 // trial and error ratio
                
                gradientLayer.startPoint    = CGPoint(x: 0.5, y: 0)
                gradientLayer.endPoint      = CGPoint(x: 0.5, y: 1.5)
                gradientLayer.frame         = hexShape.frame
                gradientLayer.colors        = [
                    self.fillColor.lighterColorForColor(shift).CGColor,
                    self.fillColor.CGColor
                ]
                
                let gradientMaskLayer       = CAShapeLayer()
                
                gradientMaskLayer.frame     = hexShape.frame
                gradientMaskLayer.path      = gradientBezier.CGPath
                gradientLayer.mask          = gradientMaskLayer
                
                self.gradientLayer = gradientLayer
                
                hexShape.insertSublayer(gradientLayer, atIndex: 1)
            }
        }
        else {
            self.gradientLayer?.removeFromSuperlayer()
        }
    }
    
    private func getHexagonPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        // create new sub path for the hexagon shape
        let bezier = UIBezierPath()
        
        bezier.moveToPoint(CGPoint(x: center.x, y: center.y + CGFloat(radius)))
        
        // Loop through remaining points in hexagon
        let c = CGFloat(M_PI) / 3
        
        // loop through each side (+1 to fully form stroke)
        for i in 1...5 {
            let angleRadians = CGFloat(i) * c
            let x = center.x + (radius * sin(angleRadians))
            let y = center.y + (radius * cos(angleRadians))
            
            bezier.addLineToPoint(CGPoint(x: x, y: y))
        }
        
        bezier.closePath()
        
        return bezier
    }
    
    // set icon image in button
    private func updateIconImage() {
        if let imageName = iconImageName where imageName.characters.count > 0, let image = UIImage(named: imageName) {
            // set image
            self.setImage(image, forState: .Normal)
            
            // get layout values
            let length      = min(round(self.height * 0.22), 26)
            let halfLength  = length * 0.5
            let imageSize   = UIImage.getResizeImageScaleSize(CGSize(width: self.bounds.width, height: length), oldSize: image.size)
            
            // assign layout properties to image view
            let iconView            = self.imageView!
            iconView.contentMode    = .ScaleAspectFit
            iconView.frame          = CGRect(x: self.width * 0.5 - (imageSize.width * 0.5), y: self.height * 0.5 - halfLength, width: imageSize.width, height: imageSize.height)
            iconView.tintColor      = self.titleColor            // icon color always matches tint color (currently)
            
            // adjust image position if title also present
            if let imageName = iconImageName where imageName.characters.count > 0,
                let text = self.titleLabel?.text where text.characters.count > 0
            {
                // position icon image lower if title text present
                iconView.frame.origin.y -= 0.5 * halfLength + 1
            }
        }
    }
    
    private func updateTitleInsets() {
        // if title and icon exist
        if let titleLabel = self.titleLabel, _ = iconImageName, iconFrame = self.imageView?.frame {
            
            // position both in center if both present (with spacer in between)
            let totalHeight = titleLabel.frame.height + iconFrame.height + 10
            let topY        = self.bounds.size.height * 0.5 - (totalHeight * 0.5)
            
            // adjust title frame
            titleLabel.frame = CGRectMake(0, topY + iconFrame.height + 11, self.bounds.width, titleLabel.frame.height)
        }
        
        // adjust image
        self.updateIconImage()
    }
    
    // remove icon image from button
    func removeIconImages() {
        // clear primary image
        self.setImage(nil, forState: .Normal)
        self.iconImageName              = nil
        self.iconImageColor             = nil
        
        // clear indicator image
        self.removeIndicatorIcon()
        
        // clear favorites icon image
        self.removeFaviconImage()
    }
    
    private func setFavIconImageView(image: UIImage) {
        let favIconFrame = CGRect(
            x: self.width * 0.5 - (self.favIconLength * 0.5),
            y: 10,
            width: self.favIconLength,
            height: self.favIconLength + 10
        )
        
        self.faviconImageView = UIImageView(image: image)
        self.faviconImageView!.contentMode = .ScaleAspectFit
        self.faviconImageView!.frame = favIconFrame
        
        self.addSubview(self.faviconImageView!)
    }
    
    func setIndicatorIcon(showIndicator: Bool, active: Bool = false) {
        // clear prior image
        self.removeIndicatorIcon()
        
        if(showIndicator){
            // clear fav icon as it occupies same space
            self.removeFaviconImage()
            
            self.indicatorImageView = UIImageView()
            
            let iconView       = self.indicatorImageView!
            
            iconView.image          = UIImage(named: "Indicator")
            iconView.contentMode    = .ScaleAspectFit
            iconView.tintColor      = (active) ? AppStyles.sharedInstance.indicatorActive : AppStyles.sharedInstance.indicator
            
            //place icon above text
            iconView.frame = CGRect(
                x: (self.width * 0.54) - (self.indicatorIconLength * 0.05),
                y: self.height * 0.23,
                width: self.indicatorIconLength,
                height: self.indicatorIconLength)
            
            self.addSubview(iconView)
        }
    }
    
    // add icon into hexagon within public tree
    func updateFavIconImage(branch: Branch) {
        self.removeFaviconImage()

        if let currIcon = branch.icon where !currIcon.parseForUrl().isEmpty {
            // clear indicator icon as it occupies same space
            self.removeIndicatorIcon()

            // load the icon
            ImageLoader.sharedInstance.loadPublicImage(
                currIcon,
                success: {
                    image in

                    // make sure assigning to correct hexagon
                    if branch.id == self.id {
                        self.setFavIconImageView(image)
                    }
                },
                failure: {
                    #if DEBUG
                        print("Failed to load Favicon for URL: \(currIcon)")
                    #endif
                    
                    if let image = UIImage(named: "Explore") where branch.id == self.id {
                        self.setFavIconImageView(image)
                    }
                }
            )
        }
        else if let url = branch.url, image = UIImage(named: "Explore") where branch.id == self.id && !url.parseForUrl().isEmpty {
            self.setFavIconImageView(image)
        }
    }
    
    // remove indicator icon if present
    private func removeIndicatorIcon() {
        self.indicatorImageView?.removeFromSuperview()
        self.indicatorImageView = nil
    }
    
    // remove URL favicon from button
    func removeFaviconImage() {
        self.faviconImageView?.removeFromSuperview()
        self.faviconImageView = nil
    }
    
    private func setDefaults() {
        // set content edge insets
        self.contentEdgeInsets = self.defaultContentInsets
    }
}
