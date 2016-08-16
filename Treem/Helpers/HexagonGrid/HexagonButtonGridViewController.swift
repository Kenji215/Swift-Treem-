//
//  HexagonButtonGridViewController.swift
//  Treem
//
//  Created by Matthew Walker on 7/13/15.
//  Copyright (c) 2015 Treem LLC. All rights reserved.
//
//  Custom viewcontroller to draw a grid of hexagons based on an x,y coordinate system using an “even-r” horizontal layout (even rows are offset)
//

import UIKit


@IBDesignable
class HexagonButtonGridViewController: UIViewController {
    var hexagonGridView         : UIView!
    var centerHexagonHistory    : [HexagonButton] = []
    
    // dictionary of hexagon buttons in the grid
    lazy var hexagonButtons: [HexagonGridPosition: HexagonButton]  = Dictionary<HexagonGridPosition, HexagonButton> ()
    
    let defaultGridCenterPosition = HexagonGridPosition(x: 0, y: 0)
    
    var hexButtonInViewCenter       : HexagonButton!
    var initialCenterPoint          : CGPoint?  = nil
    
    // grid style variables
    var lineWidth                       : CGFloat           = 1.8
    var hexagonRadius                   : CGFloat           = 40 {
        willSet (newRadius) {
            self.hexagonHeight  = newRadius * 2
            self.hexagonWidth   = newRadius * sqrt(3)
        }
    }
    
    private(set) var hexagonHeight      : CGFloat           = 80
    private(set) var hexagonWidth       : CGFloat           = 4 * sqrt(3)
    
    var animDuration                    : NSTimeInterval    = 0.2    
    
    lazy var backDropViews: [UIView] = []
    
    // add views used in backdrop behind hexagon buttons
    func addHexGridBackDropView(view: UIView) {
        self.backDropViews.append(view)
        self.hexagonGridView.insertSubview(view, atIndex: 0)
    }
    
    // animate hexagons placed in center of grid view frame to their view frame position
    func animateExpandHexagonsIntoPositionFromCenter(hexagonButtons: Set<HexagonButton>, delay: NSTimeInterval = 0, fromOffset: CGFloat = 0, completion: ((Bool)->())? = nil) {
        let firstBackDropView : UIView? = (backDropViews.count > 0) ? self.backDropViews.first : nil
        
        for hexButton in hexagonButtons {
            if hexButton.gridPosition != nil {
                let buttonOffset = getHexagonButtonOffset(hexButton, fromPreviousOffset: self.getHexagonButtonOffset(self.hexButtonInViewCenter))
                
                if let backView = firstBackDropView {
                    self.hexagonGridView.insertSubview(hexButton, aboveSubview: backView)
                }
                else {
                    self.hexagonGridView.addSubview(hexButton)
                    self.hexagonGridView.sendSubviewToBack(hexButton)
                }
                
                let newOrigin = CGPoint(x: hexButton.frame.origin.x + buttonOffset.0, y: hexButton.frame.origin.y + buttonOffset.1)
                
                UIView.animateWithDuration(
                    self.animDuration,
                    delay: delay,
                    options: .CurveEaseOut,
                    animations: {
                        hexButton.frame.origin = newOrigin
                    },
                    completion: completion
                )
            }
        }
    }
    
    func animateExpandNeighborHexagonsIntoPosition(delay delay: NSTimeInterval) {
        let hexagonImmediateNeighbors   = self.getHexButtonNeighbors(self.hexButtonInViewCenter)
        let hexagonSecondNeighbors      = self.getHexButtonNeighbors(self.hexButtonInViewCenter, distance: 2)
        
        // show immediate neighbors first
        self.animateExpandHexagonsIntoPositionFromCenter(hexagonImmediateNeighbors, delay: delay)
        
        // show second neighbors second
        self.animateExpandHexagonsIntoPositionFromCenter(hexagonSecondNeighbors, delay: delay)
    }
    
    func animateContractHexagonsIntoCenterFromPosition(hexagonButtons: Set<HexagonButton>, delay: NSTimeInterval = 0) {
        // this assumes the center has been set to the previous button
        let currentCenterOffset = getHexagonButtonOffset(self.hexButtonInViewCenter)
        
        for hexButton in hexagonButtons {
            if hexButton.gridPosition != nil {
                let buttonOffset    = getHexagonButtonOffset(hexButton, fromPreviousOffset: currentCenterOffset)
                let newOrigin       = CGPoint(x: hexButton.frame.origin.x - buttonOffset.0, y: hexButton.frame.origin.y - buttonOffset.1)
                
                self.hexagonGridView.sendSubviewToBack(hexButton)
                
                UIView.animateWithDuration(self.animDuration, delay: delay, options: .CurveEaseOut,
                    animations: {
                        hexButton.frame.origin = newOrigin
                    },
                    completion: {
                        _ in
                        
                        // remove from view
                        hexButton.removeFromSuperview()
                        
                        // remove from grid
                        self.hexagonButtons.removeValueForKey(hexButton.gridPosition!)
                    }
                )
            }
        }
    }
    
    func clearGrid() {
        
        // clear all sub views in grid
        for view in self.hexagonGridView.subviews {
            view.removeFromSuperview()
        }
        
        // remove remaining hexagon references
        self.hexagonButtons         = [:]
        self.centerHexagonHistory   = []
        self.backDropViews          = []
        self.hexButtonInViewCenter  = nil
        
        // reset origin of current grid view
        self.hexagonGridView.bounds.origin = CGPoint(x: 0,y: 0)
    }
    
    func getHexButtonToCenterOffset(newCenterButton: HexagonButton) -> (x: CGFloat, y: CGFloat) {
        // offset view to place new selected button in center
        let previousCenter = self.hexButtonInViewCenter
        
        let previousOffset  : (CGFloat, CGFloat)?   = (previousCenter != nil ? getHexagonButtonOffset(previousCenter) : nil)
        let newOffset       : (CGFloat, CGFloat)    = self.getHexagonButtonOffset(newCenterButton, fromPreviousOffset: previousOffset)
        
        return newOffset
    }
    
    // draw hexagon buttons stored
    func drawHexagonButtonsInViewCenter(buttons: Set<HexagonButton>, fromCenterButton: HexagonButton? = nil) {
        if (buttons.count > 0) {
            let centerPoint = fromCenterButton?.center ?? self.getViewCenter()
            let width       = self.hexagonWidth
            let height      = self.hexagonHeight
            let x           = centerPoint.x - (width / 2)
            let y           = centerPoint.y - (height / 2)
            let hexFrame    = CGRectMake(x, y, width, height)
            
            for button in buttons {
                // set layout properties that apply to all hexagons in grid
                button.width        = self.hexagonWidth
                button.height       = self.hexagonHeight
                button.lineWidth    = self.lineWidth
                button.frame        = hexFrame
                
                // add to grid view
                self.hexagonGridView.insertSubview(button, aboveSubview: self.hexagonGridView)
            }
        }
    }
    
    func setBackDropOverlay(color: UIColor?) {
        UIView.animateWithDuration(0.2, animations: {
            self.hexagonGridView.backgroundColor = (color == nil) ? nil : color!.colorWithAlphaComponent(0.7)
        })
    }
    
    // add hexagon to particular grid position to be drawn (one per grid coordinate allowed)
    func setHexagonButton(hexagonButton: HexagonButton) {
        self.hexagonButtons[hexagonButton.gridPosition!] = hexagonButton
    }
    
    // add hexagon to particular grid positions to be drawn (one per grid coordinate allowed)
    func setHexagonButtons(hexagonButtons: Set<HexagonButton>) {
        for button in hexagonButtons {
            self.setHexagonButton(button)
        }
    }
    
    // set particular button to be center of view
    func setHexButtonInViewCenter(button: HexagonButton, offsetAnimation: ((xOffset: CGFloat, yOffset: CGFloat) -> ())? = nil, completion: ((Bool) -> ())? = nil) {
        let newOffset = getHexButtonToCenterOffset(button)

        if (offsetAnimation != nil || completion != nil || newOffset.0 != 0 || newOffset.1 != 0) {
            let newOrigin = CGPoint(x: self.hexagonGridView.bounds.origin.x + newOffset.0, y: self.hexagonGridView.bounds.origin.y + newOffset.1)
            
            UIView.animateWithDuration(
                self.animDuration,
                animations: {
                    // adjust view bounds
                    self.hexagonGridView.bounds.origin = newOrigin
                    
                    if let extraAnimations = offsetAnimation {
                        extraAnimations(xOffset: newOrigin.x, yOffset: newOrigin.y)
                    }
                },
                completion: completion
            )
        }
        
        self.hexButtonInViewCenter = button
        self.centerHexagonHistory.append(button)
    }
    
    func setPreviousHexButtonCenter(animate: Bool = false, offsetAnimation: ((xOffset: CGFloat, yOffset: CGFloat) -> ())? = nil, completion: ((Bool) -> ())? = nil) {
        if(animate) {
            let currentCenter       = self.hexButtonInViewCenter
            let currentCenterOffset = self.getHexagonButtonOffset(currentCenter)
            let newCenter           = self.getPreviousHexagonCenter()
            
            let offset = getHexagonButtonOffset(newCenter, fromPreviousOffset: currentCenterOffset)
            
            if (offsetAnimation != nil || completion != nil || offset.0 != 0 || offset.1 != 0) {
                let newOrigin = CGPoint(x: self.hexagonGridView.bounds.origin.x + offset.0, y: self.hexagonGridView.bounds.origin.y + offset.1)
                
                UIView.animateWithDuration(
                    self.animDuration,
                    animations: {
                        // adjust view bounds
                        self.hexagonGridView.bounds.origin = newOrigin
                        
                        if let extraAnimations = offsetAnimation {
                            extraAnimations(xOffset: newOrigin.x, yOffset: newOrigin.y)
                        }
                    },
                    completion: completion
                )
            }
        }
        
        self.centerHexagonHistory.removeLast()
        self.hexButtonInViewCenter = self.centerHexagonHistory.last
    }
    
    func getPreviousHexagonCenter() -> HexagonButton {
        if(self.centerHexagonHistory.count > 1) {
            return self.centerHexagonHistory[self.centerHexagonHistory.count - 2]
        }
        else {
            return self.centerHexagonHistory[self.centerHexagonHistory.count - 1]
        }
    }
    
    // get neighbor button of given hex button. Use 1 for immediate neighbor, or 2 for 2nd distant neighbor
    func getHexButtonNeighbors(hexButton: HexagonButton, distance: Int = 1, newNeighborsOnly: Bool = false, defaultStyleHandler: ((HexagonButton)->(Void))? = nil) -> Set<HexagonButton> {
        var neighbors           : Set<HexagonButton> = []
        var neighborPositions   : [HexagonGridPosition]
        
        let gridPosition    = hexButton.gridPosition!
        let centerX         = gridPosition.x
        let centerY         = gridPosition.y
        
        let even            = (centerY % 2 == 0)
        let evenOffset      = (even ? 1 : 0)
        let oddOffset       = (even ? 0 : 1)
        
        // neighbor of neighbors (2nd level neighbor)
        if(distance == 2) {
            neighborPositions = [
                HexagonGridPosition(x: centerX, y: centerY + 2),
                HexagonGridPosition(x: centerX + 1, y: centerY - 2),
                HexagonGridPosition(x: centerX + 1 + evenOffset, y: centerY - 1),
                HexagonGridPosition(x: centerX + 2, y: centerY),
                HexagonGridPosition(x: centerX + 1 + evenOffset, y: centerY + 1),
                HexagonGridPosition(x: centerX + 1, y: centerY + 2),
                HexagonGridPosition(x: centerX - 2, y: centerY),
                HexagonGridPosition(x: centerX - 1, y: centerY + 2),
                HexagonGridPosition(x: centerX - 1 - oddOffset, y: centerY + 1),
                HexagonGridPosition(x: centerX - 1 - oddOffset, y: centerY - 1),
                HexagonGridPosition(x: centerX, y: centerY - 2),
                HexagonGridPosition(x: centerX - 1, y: centerY - 2)
            ]
        }
            // immediate neighbors
        else {
            neighborPositions = [
                HexagonGridPosition(x: centerX + evenOffset, y: centerY - 1),
                HexagonGridPosition(x: centerX + 1, y: centerY),
                HexagonGridPosition(x: centerX + evenOffset, y: centerY + 1),
                HexagonGridPosition(x: centerX - oddOffset, y: centerY + 1),
                HexagonGridPosition(x: centerX - 1, y: centerY),
                HexagonGridPosition(x: centerX - oddOffset, y: centerY - 1)
            ]
        }
        
        for position in neighborPositions {
            var hexButton = self.getHexagonButtonFromGridPosition(position)
            
            if(newNeighborsOnly) {
                if(hexButton == nil) {
                    hexButton = HexagonButton()
                    hexButton?.gridPosition = position
                    
                    if(defaultStyleHandler != nil) {
                        let handler = defaultStyleHandler!
                        
                        handler(hexButton!)
                    }
                    
                    neighbors.insert(hexButton!)
                }
            }
            else {
                if (hexButton == nil) {
                    hexButton = HexagonButton()
                    hexButton!.gridPosition = position
                }
                
                neighbors.insert(hexButton!)
            }
        }
        
        return neighbors
    }
    
    func getHexagonButtonFromGridPosition(gridPosition: HexagonGridPosition) -> HexagonButton? {
        return self.hexagonButtons[gridPosition]
    }
    
    // hex grid based off of “even-r” horizontal layout where 0,0 is center of hexagon grid
    private func getHexagonButtonOffset(hexButton: HexagonButton, fromPreviousOffset: (CGFloat, CGFloat)? = nil) -> (x: CGFloat, y: CGFloat) {
        let width       = CGFloat(hexButton.width)
        let ylocation   = CGFloat(hexButton.gridPosition!.y)
        var xlocation   = CGFloat(hexButton.gridPosition!.x)
        
        // calculate x offset based on grid location
        var xoffset     = xlocation * width
        
        // if y position odd, shift by half (odd y values are shifted half length in "even-r")
        if(ylocation % 2 != 0) {
            xlocation   -= 0.5
            xoffset     -= 0.5 * width
        }
        
        xoffset += (xlocation * self.lineWidth)
        
        // calculate y offset based on grid location
        var yoffset = (ylocation * self.hexagonHeight * 0.75) + (ylocation * self.lineWidth)
        
        // adjust from previous offset if provided
        if(fromPreviousOffset != nil) {
            xoffset -= fromPreviousOffset!.0
            yoffset -= fromPreviousOffset!.1
        }
        
        return (xoffset, yoffset)
    }
    
    func getViewCenter() -> CGPoint {
        if let initialCenter = self.initialCenterPoint {
            return initialCenter
        }
        else {
            // store center for later reuse in case frame changes
            self.initialCenterPoint = CGPointMake(floor(self.hexagonGridView.bounds.width * 0.5), floor(self.hexagonGridView.bounds.height * 0.5))
            
            return self.initialCenterPoint!
        }
    }
    
    func removeHexagonAtGridPosition(gridPosition: HexagonGridPosition) {
        if let hexagon = self.hexagonButtons[gridPosition] {
            hexagon.removeFromSuperview()
        }
        
        self.hexagonButtons.removeValueForKey(gridPosition)
    }
}