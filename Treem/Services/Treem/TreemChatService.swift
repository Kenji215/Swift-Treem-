//
//  TreemChatService.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/11/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class TreemChatService {
    static let sharedInstance = TreemChatService()
    
    private let url = "https://chat.\(TreemService.baseDomain)/"

    func getBranchChats(treeSession: TreeSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url + "branches"
        
        TreemService().get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
        
    }
    
    func getAvailableChatSessions(treeSession: TreeSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        
        let url                 = self.url + "chats"
        
        TreemService().get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func getChatSession(treeSession: TreeSession, sessionId: String, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {        
        
        let url                 = self.url + "session/" + sessionId
        
        TreemService().get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func initializeChatSession(treeSession: TreeSession, chatSession: ChatSession, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url + "init"
        
        TreemService().post(
            url,
            json                    : chatSession.toInitializeJson(),
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )

    }
    
    func setChatHistory(treeSession: TreeSession, sessionId: String, chatMessage: ChatMessage, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url + "history/" + sessionId
        
        TreemService().post(
            url,
            json                    : chatMessage.toJSON(),
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    
    func setChatHistoryAudit(treeSession: TreeSession, chatMessage: ChatMessage, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url + "audit"
        
        TreemService().post(
            url,
            json                    : chatMessage.toJSON(),
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func leaveChat(treeSession: TreeSession, sessionId: String, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url + "leave/" + sessionId
        
        TreemService().post(
            url,
            json                    : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func endChatSession(treeSession: TreeSession, sessionId: String, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url + "end/" + sessionId
        
        TreemService().post(
            url,
            json                    : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
        
    }
    
}
