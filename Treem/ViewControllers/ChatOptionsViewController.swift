//
//  ChatOptionsViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/16/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//


import UIKit
class ChatOptionsViewController : UIViewController, UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {

    var delegate            : ChatSessionViewController? = nil
    var chatSession         : ChatSession? = nil
    var isCreator           : Bool = false
    var referringButton     : UIButton? = nil
    
    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var displayViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var displayViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var viewAreaTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var participantsButton: UIButton!
    @IBOutlet weak var endChatButton: UIButton!
    @IBOutlet weak var endChatHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var endChatTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var leaveChatButton: UIButton!
    @IBOutlet weak var leaveChatHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leaveChatTopConstraint: NSLayoutConstraint!
    
    static func getStoryboardInstance() -> ChatOptionsViewController {
        return UIStoryboard(name: "ChatOptions", bundle: nil).instantiateInitialViewController() as! ChatOptionsViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = AppStyles.overlayColor
        
        // override appearance styles
        let white = AppStyles.sharedInstance.whiteColor
        
        self.participantsButton.tintColor   = white
        self.endChatButton.tintColor        = white
        self.leaveChatButton.tintColor      = white
        
        // if referring button provided, recreate
        if let referButton = self.referringButton {
            let button  = referButton.copyButtonSelective()
            let color   = UIColor(red: 153/255, green: 153/255, blue: 153/255, alpha: 1.0)
            
            button.tintColor = color
            button.setTitleColor(color, forState: .Normal)
            button.setTitleColor(AppStyles.sharedInstance.darkGrayColor, forState: .Highlighted)
            
            button.frame.origin.y = referButton.convertPoint(referButton.frame.origin, toView: self.view).y
            
            self.viewAreaTopConstraint.constant = button.frame.origin.y + 10
            
            button.translatesAutoresizingMaskIntoConstraints = true
            
            // add dismiss view gesture to replicated button
            button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatOptionsViewController.dismissView)))
            
            self.view.addSubview(button)
        }
        
        if (self.chatSession != nil){
            // hide buttons depending on what was passed
            if(self.isCreator){
                self.leaveChatButton.hidden = true
                
                self.displayViewHeightConstraint.constant = self.displayViewHeightConstraint.constant
                            - self.leaveChatHeightConstraint.constant
                            - self.leaveChatTopConstraint.constant
                
                self.leaveChatHeightConstraint.constant = 0
                self.leaveChatTopConstraint.constant = 0
            }
            else{
                self.endChatButton.hidden = true
                
                self.displayViewHeightConstraint.constant = self.displayViewHeightConstraint.constant
                    - self.endChatHeightConstraint.constant
                    - self.endChatTopConstraint.constant
                
                self.endChatHeightConstraint.constant = 0
                self.endChatTopConstraint.constant = 0
            }
            
            self.preferredContentSize = CGSizeMake(self.displayViewWidthConstraint.constant, self.displayViewHeightConstraint.constant)
        }
        else{
            self.dismissViewControllerAnimated(false, completion: nil)
        }
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatOptionsViewController.dismissView)))
    }
    
    @IBAction func participantsButtonTouchUpInside(sender: AnyObject) {
        // dismiss the options view and tell the delegate to end the session
        self.dismissViewControllerAnimated(false, completion: { self.delegate?.optionsParticipants() })
    }
    
    @IBAction func endChatTouchUpInside(sender: AnyObject) {
        CustomAlertViews.showCustomConfirmView(
            title: "End Chat"
            , message: "Are you sure you want to end this chat for all members?"
            , fromViewController: self
            , yesHandler: {
                alertAction in
                
                // dismiss the options view and tell the delegate to end the session
                self.dismissViewControllerAnimated(false, completion: { self.delegate?.optionsEndChat() })
                                
            }
            , noHandler: {
                alertAction in
                // do nothign
            })
    }
    
    @IBAction func leaveChatTouchUpInside(sender: AnyObject) {
        CustomAlertViews.showCustomConfirmView(
            title: "Leave Chat"
            , message: "Are you sure you want to leave this chat, once you go you won't be able to rejoin."
            , fromViewController: self
            , yesHandler: {
                alertAction in
                
                // dismiss the options view and tell the delegate to leave the chat
                self.dismissViewControllerAnimated(false, completion: { self.delegate?.optionsLeaveChat() })
                
            }
            , noHandler: {
                alertAction in
                // do nothign
        })
    }
    
    func dismissView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
