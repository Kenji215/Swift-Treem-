//
//  ChatSession.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/11/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON


class ChatSession {

    var sessionId       : String?           = nil       // this will be a guid
    var chatName        : String?           = nil
    var chatUserIds     : [Int]?            = nil
    var chatStart       : NSDate?           = nil
    var lastSentDate    : NSDate?           = nil
    var creatorId       : Int?              = nil
    var creator         : User?             = nil
    var users           : [Int: User]?      = nil
    var activeUsers     : [Int]?            = nil
    var history         : [ChatMessage]?    = nil
    var branchId        : Int?              = nil
    var unreadChats     : Bool              = false
    
    init(){}
    
    init(json: JSON) {
        self.sessionId          = json["s_id"].string
        self.chatName           = json["c_name"].string
        self.chatStart          = NSDate(iso8601String: json["c_start"].string)
        self.lastSentDate       = NSDate(iso8601String: json["c_last_sent"].string)
        self.creatorId          = json["creator_id"].int

        self.creator            = User.init(data: json["creator"])
        if let cr = self.creator {
            if(cr.id < 1) { self.creator = nil}
        }
        
        self.activeUsers        = json["active_ids"].arrayValue.map { $0.int! }
        
        self.branchId           = json["b_id"].int
        self.unreadChats        = (json["unread"].int == 1)
        
        self.users              = self.loadUsers(json["users"])
        self.history            = self.loadHistory(json["history"])
    }
    
    func loadUsers(data: JSON) -> [Int: User]? {
        var users: [Int: User]? = [:]
        
        for (_, object) in data {
            let user = User(data:object)
            
            if(user.id > 0){
                users![user.id] = user
            }
        }
        
        if users!.count < 1 {
            users = nil
        }
        
        return users
    }
    
    func loadHistory(data: JSON) -> [ChatMessage]? {
        var history: [ChatMessage]? = []
        
        for (_, object) in data {
            let msg = ChatMessage(data:object)
            
            if(msg.userId > 0){
                history!.append(msg)
            }
        }
        
        if history!.count < 1 {
            history = nil
        }
        
        return history
    }
    
    func toInitializeJson() -> JSON {
        var json:JSON = [:]

        if let userIds = self.chatUserIds {
            json["c_ids"].arrayObject  = userIds
            if let cName = self.chatName { json["c_name"].string = cName }
        }
        
        return json
    }

    static func loadChatSessions(data: JSON) -> [ChatSession]? {
        var sessions: [ChatSession]? = []
        
        for (_, object) in data {
            let session = ChatSession(json:object)
            
            if(session.sessionId != nil) {
                sessions!.append(session)
            }
        }
        
        if sessions!.count < 1 {
            sessions = nil
        }
        
        return sessions
    }
    
    static func loadBranchChats(data: JSON) -> [Int:Bool]? {
        var branchChats: [Int:Bool]? = [:]
        
        for (_, object) in data {
            let chat = ChatSession(json:object)
            
            if(chat.branchId != nil) {
                branchChats![chat.branchId!] = chat.unreadChats
            }
        }
        
        if branchChats!.count < 1 {
            branchChats = nil
        }
        
        return branchChats
    }
}