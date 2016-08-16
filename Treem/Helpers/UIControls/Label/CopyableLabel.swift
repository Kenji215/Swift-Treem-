//
//  CopyableLabel.swift
//  Treem
//
//  Created by Matthew Walker on 4/14/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import TTTAttributedLabel

class CopyableLabel : TTTAttributedLabel {
    private var initialBackground: UIColor? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIMenuControllerWillHideMenuNotification, object: nil)
    }
    
    private func commonInit() {
        self.initialBackground  = self.backgroundColor
        self.userInteractionEnabled = true
        self.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(CopyableLabel.showMenu(_:))))
    }
    
    func didHideMenu() {
        self.backgroundColor = self.initialBackground
    }
    
    func showMenu(sender: UILabel) {
        self.becomeFirstResponder()
        
        let menu = UIMenuController.sharedMenuController()
        
        if !menu.menuVisible {
            self.initialBackground  = self.backgroundColor // in case background changes
            self.backgroundColor    = AppStyles.sharedInstance.midGrayColor

            menu.setTargetRect(self.bounds, inView: self)
            menu.setMenuVisible(true, animated: true)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CopyableLabel.didHideMenu), name: UIMenuControllerWillHideMenuNotification, object: nil)
        }
    }
    
    override func copy(sender: AnyObject?) {
        UIPasteboard.generalPasteboard().string = text
        
        UIMenuController.sharedMenuController().setMenuVisible(false, animated: true)
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        return action == #selector(NSObject.copy(_:))
    }
}