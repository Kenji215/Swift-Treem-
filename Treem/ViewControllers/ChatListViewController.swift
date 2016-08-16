//
//  ChatListViewController.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/11/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import UIKit
import MediaPlayer

class ChatListViewController : UITableViewController, UIViewControllerTransitioningDelegate {

    private var chatSessions            :[ChatSession]? = nil
    private var forwardColor            : UIColor?      = nil
    
    private lazy var loadingMaskViewController   = LoadingMaskViewController.getStoryboardInstance()
    
    // used for loading a chat session directly
    var existingSessionId               : String?   = nil
    var existingSessionName             : String?   = nil
    var initializeUserIds               : [Int]?    = nil
    var parentView                      : UIView?   = nil
    var branchViewDelegate              : BranchViewDelegate? = nil
    
    let downloadOperations = DownloadContentOperations()
    
    static func getStoryboardInstance() -> ChatListViewController {
        return UIStoryboard(name: "ChatList", bundle: nil).instantiateInitialViewController() as! ChatListViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.checkForExistingChat()
        
        // clear empty footer cells
        self.tableView.tableFooterView = UIView()
        
        // apply common styles
        self.tableView.separatorColor = AppStyles.sharedInstance.dividerColor
    }
    
    override func viewWillAppear(animated: Bool) {
        self.loadChatSession()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if indexPath.row == 0 {
            return 36
        }
        
        return tableView.rowHeight
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sessions = self.chatSessions {
            return sessions.count
        }

        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let sessions = self.chatSessions where sessions.indices.contains(indexPath.row) {
            let session = sessions[indexPath.row]
            
            // empty session id (new chat)
            if session.sessionId == nil {
                let cell = tableView.dequeueReusableCellWithIdentifier("ChatListNewCell", forIndexPath: indexPath) as! ChatListNewTableViewCell
                cell.tag = indexPath.row
                
                // apply color to row image
                cell.newChatImageView.image     = cell.newChatImageView.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                cell.newChatImageView.tintColor = AppStyles.sharedInstance.darkGrayColor
                
                return cell
            }
            // existing session id (existing chat)
            else {
                let cell = tableView.dequeueReusableCellWithIdentifier("ChatListCell", forIndexPath: indexPath) as! ChatListTableViewCell
                cell.tag = indexPath.row
                
                if(session.unreadChats) {
                    cell.indicatorImageView.tintColor = AppStyles.sharedInstance.indicatorActive
                }
                else{
                    cell.indicatorImageView.hidden = true
                }
                
                cell.chatNameLabel.text = session.chatName
                
                cell.startDateLabel.text = session.lastSentDate?.getRelativeShorthandDateFormattedString()

                if let creator = session.creator {
                    cell.creatorNameLabel.text = creator.getFullName()
                    
                    // get avatar image
                    if let avatarURL = creator.avatar, downloader = DownloadContentOperation(url: avatarURL, cacheKey: creator.avatarId) {
                        downloader.completionBlock = {
                            if let image = downloader.image where !downloader.cancelled {
                                // perform UI changes back on the main thread
                                dispatch_async(dispatch_get_main_queue(), {
                                    
                                    // check that the cell hasn't been reused
                                    if (cell.tag == indexPath.row) {
                                        
                                        // if cell in view then animate, otherwise add if in table but not visible
                                        if tableView.visibleCells.contains(cell) {
                                            UIView.transitionWithView(
                                                cell.avatarImageView,
                                                duration: 0.1,
                                                options: UIViewAnimationOptions.TransitionCrossDissolve,
                                                animations: {
                                                    cell.avatarImageView.image = image
                                                },
                                                completion: nil
                                            )
                                        }
                                        else {
                                            cell.avatarImageView.image = image
                                        }
                                    }
                                })
                            }
                        }                    
                        self.downloadOperations.startDownload(indexPath, downloadContentOperation: downloader)
                    }
                }
                
                return cell
            }
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatListCell", forIndexPath: indexPath) as! ChatListTableViewCell
        cell.tag = indexPath.row
        
        return cell
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {

        if let sessions = self.chatSessions where (sessions.indices.contains(indexPath.row)) {
            let session = sessions[indexPath.row]
            
            if session.sessionId == nil {
                self.navigateToNewChat()
            }
            else {
                let chatSessionVC = ChatSessionViewController.getStoryboardInstance()
                
                chatSessionVC.chatSessionId         = session.sessionId
                chatSessionVC.chatName              = session.chatName
                chatSessionVC.parentView            = self.parentView
                chatSessionVC.branchViewDelegate    = self.branchViewDelegate
                
                self.navigateToExistingChat(chatSessionVC)
            }
        }
        
        return indexPath
    }
    
    private func loadChatSession() {
        self.showLoadingMask()
        
        // get view size
        TreemChatService.sharedInstance.getAvailableChatSessions(
            CurrentTreeSettings.sharedInstance.treeSession,
            success: {
                data in
                
                    self.chatSessions = ChatSession.loadChatSessions(data) ?? []
                
                    // prepend an option for new chat
                    self.chatSessions?.insert(ChatSession(), atIndex: 0)
                
                    self.tableView.reloadData()
                    
                    if(self.chatSessions != nil){
                        self.cancelLoadingMask()
                    }
                    else{
                        self.cancelLoadingMask()
                        
                        self.navigateToNewChat()
                    }
            },
            failure: {
                error, wasHandled in
                
                self.cancelLoadingMask()
            }
        )
    }
    
    private func showLoadingMask(completion: (() -> Void)? = nil) {
        self.loadingMaskViewController.queueLoadingMask(self.view, loadingViewAlpha: 1.0, showCompletion: completion)
    }
    
    private func cancelLoadingMask(completion: (() -> Void)? = nil) {
        self.loadingMaskViewController.cancelLoadingMask(completion)
    }
    
    private func navigateBackToList() {
        self.navigationController?.popViewControllerAnimated(true)
        
        self.branchViewDelegate?.setDefaultTitle?()
    }
    
    private func navigateToExistingChat(chatSessionVC: ChatSessionViewController) {
        chatSessionVC.branchViewDelegate = self.branchViewDelegate
        
        self.navigationController?.pushViewController(chatSessionVC, animated: true)
        
        self.branchViewDelegate?.toggleBackButton(true, onTouchUpInside: {
            self.navigateBackToList()
        })
    }
    
    private func navigateToNewChat() {
        let vc = NewChatViewController.getStoryboardInstance()

        vc.chatListDelegate     = self
        vc.activeChats          = (self.chatSessions != nil)
        vc.parentView           = self.parentView
        vc.branchViewDelegate   = self.branchViewDelegate
        
        self.navigationController?.pushViewController(vc, animated: true)
        
        self.branchViewDelegate?.toggleBackButton(true, onTouchUpInside: {
            self.navigateBackToList()
        })
        
        self.branchViewDelegate?.setTemporaryTitle?("New Chat")
    }
    
    private func checkForExistingChat() {
        if let existingId = self.existingSessionId {            
            let chatSessionVC = ChatSessionViewController.getStoryboardInstance()
            
            chatSessionVC.chatSessionId         = existingId
            chatSessionVC.chatName              = self.existingSessionName
            chatSessionVC.initializeUserIds     = self.initializeUserIds
            chatSessionVC.parentView            = self.parentView
            chatSessionVC.branchViewDelegate    = self.branchViewDelegate
            
            self.navigateToExistingChat(chatSessionVC)
        }
    }
}
