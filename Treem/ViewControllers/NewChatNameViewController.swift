//
//  File.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/11/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit

class NewChatNameViewController: UIViewController {
    
    var nameChatDelegate        : NewChatViewController? = nil
    var charUserIds             : [Int]? = nil
    
    private lazy var loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var chatNameTextView: UITextView!
    @IBOutlet weak var startChatButton: UIButton!
    
    @IBOutlet weak var showView: UIView!
    @IBOutlet weak var showViewBottomConstraint: NSLayoutConstraint!
    
    static func getStoryboardInstance() -> NewChatNameViewController {
        return UIStoryboard(name: "NewChatName", bundle: nil).instantiateInitialViewController() as! NewChatNameViewController
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make sure we have some people to start the chat with...
        if(self.charUserIds == nil) { self.dismissView() }
        else if (self.charUserIds!.count < 1) { self.dismissView() }
        
        AppStyles.sharedInstance.setButtonDefaultStyles(self.startChatButton)
        AppStyles.sharedInstance.setButtonEnabledAndAjustStyles(self.startChatButton, enabled: true)
        
        self.cancelButton.tintColor = AppStyles.sharedInstance.midGrayColor
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(NewChatNameViewController.dismissViewTapHandler)))
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // add observers for showing/hiding keyboard
        let notifCenter = NSNotificationCenter.defaultCenter()
        
        notifCenter.addObserver(self, selector: #selector(NewChatNameViewController.keyboardWillChangeFrame(_:)), name:UIKeyboardWillChangeFrameNotification, object: nil)
        
        // set focus to the chat name text field
        self.chatNameTextView.becomeFirstResponder()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // remove observers
        let notifCenter = NSNotificationCenter.defaultCenter()
        notifCenter.removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
    }
    
    @IBAction func startChatButtonTouchUpInside(sender: AnyObject) {
        
        let chatSessObj = ChatSession()
        chatSessObj.chatUserIds = self.charUserIds
        chatSessObj.chatName    = self.chatNameTextView.text
        
        self.showLoadingMask()
        
        TreemChatService.sharedInstance.initializeChatSession(
            CurrentTreeSettings.sharedInstance.treeSession,
            chatSession: chatSessObj,
            success: {
                data in
                
                self.cancelLoadingMask({
                
                    let newSession = ChatSession.init(json: data)
                    
                    if let newId = newSession.sessionId {
                        self.dismissView({
                            self.nameChatDelegate?.newChatWasCreated(newId, chatName: chatSessObj.chatName)
                        })
                    }
                    else {
                        CustomAlertViews.showGeneralErrorAlertView(self, willDismiss: nil)
                    }
                })
            },
            failure: {
                error, wasHandled in
                
                self.cancelLoadingMask()
            }
        )
    }
    

    @IBAction func cancelButtonTouchUpInside(sender: AnyObject) {
        self.dismissView()
    }
    
    // handle moving elements when keyboard is pulled up
    func keyboardWillChangeFrame(notification: NSNotification){
        KeyboardHelper.adjustViewAboveKeyboard(notification, currentView: self.view, constraint: self.showViewBottomConstraint)
    }
    
    func dismissViewTapHandler() {
        self.dismissView()
    }
    
    private func dismissView(completion: (() -> Void)? = nil){
        self.chatNameTextView.resignFirstResponder()
    
        if(completion == nil){
            self.dismissViewControllerAnimated(true, completion: { self.nameChatDelegate?.cancelMask() })
        }
        else{
            self.dismissViewControllerAnimated(true, completion: completion)
        }
    }
    
    private func showLoadingMask(completion: (() -> Void)? = nil) {
        self.loadingMaskViewController.queueLoadingMask(self.showView, loadingViewAlpha: 1.0, showCompletion: completion)
    }
    
    private func cancelLoadingMask(completion: (() -> Void)? = nil) {
        self.loadingMaskViewController.cancelLoadingMask(completion)
    }
}