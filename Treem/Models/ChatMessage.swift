//
//  ChatMessage.swift
//  Treem
//
//  Created by Daniel Sorrell on 2/8/16.
//  Copyright © 2016 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class ChatMessage {
    
    enum MessageType: Int {
        case Text           = 0         // default, the text of the chat
        case Connect        = 1         // user sends out when they connect to a chat
        case Disconnect     = 2         // user sends out when they disconnect from the chat (will still have messages sent and waiting if they re-connect)
        case Add            = 3         // sent out by admin that a new person is added
        case Remove         = 4         // send out by admin or user that they are exiting the chat
        case End            = 5         // sent out when the admin ends the chat
        case TypingStart    = 6         // when a user starts to type
        case TypingEnd      = 7         // when a user stops typing (after 3 seconds)
    }
    
    var messageStringId : String?               = nil       // this is set by the chat client
    var messageType     : MessageType?          = nil
    var sessionId       : String?               = nil       // this will be a guid
    var userId          : Int                   = 0         // user id of the user
    var messageDate     : NSDate?               = nil       // date of when message was sent
    var contentItem     : ContentItemDelegate?  = nil       // for images / videos
    
    // only comes back with messageType = Text
    var messageText     : String?               = nil       // text of the chat message
    
    // these are passed when adding a member to the chat (with user id)
    var username        : String?       = nil       // user name of the user (what is displayed)
    var avatar          : NSURL?        = nil       // user's avatar (if you are friends and they don't share with non friends this will be null)
    var avatarId        : String?       = nil
    
    // --------------------------------- //
    // UI Layout values
    // --------------------------------- //
    private(set) var cellHeightLayout    : CGFloat   = 0
    private(set) var cellMsgLabelFont    : UIFont    = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)

    // static layout values
    private(set) var topNameMargin       : CGFloat   = 8
    private(set) var nameHeight          : CGFloat   = 15
    private(set) var topAvatarMargin     : CGFloat   = 4
    private(set) var bottomMessageMargin : CGFloat   = 8
    private(set) var avatarLeftMargin    : CGFloat   = 10
    private(set) var avatarWidth         : CGFloat   = 32
    private(set) var cellMargin          : CGFloat   = 10    // margin around the cell
    
    private(set) var cellMsgLabelPadding : CGFloat   = 8     // padding inside of message bubble
    
    // sizes generated from message data
    private(set) var cellMessageViewSize    : CGSize    = CGSizeZero
    private(set) var cellMessageTextSize    : CGSize    = CGSizeZero
    private(set) var cellMessageImageSize   : CGSize    = CGSizeZero

    init() {}
    
    init(request_string: String?) {
        if let data_str = request_string {
            self.fromJSON(JSON.parse(data_str))
        }
    }
    
    init(data: JSON){
        self.fromJSON(data)
    }
    
    func toString() -> String {
        if let str = self.toJSON().rawString(){
            return str
        }
        else {
            return ""
        }
    }
    
    private func fromJSON(data: JSON){
        self.messageStringId    = data["m_id"].string
        self.messageType        = MessageType(rawValue: data["m_type"].int ?? MessageType.Text.rawValue)
        self.sessionId          = data["s_id"].string
        self.userId             = data["u_id"].intValue
        self.messageDate        = NSDate(iso8601String: data["m_dttm"].string)
        self.messageText        = data["msg"].string
        self.username           = data["username"].string
        
        if let avatar = data["avatar_stream_url"].string, url = NSURL(string: avatar) {
            self.avatar = url
            
            // store unique identifier for caching purposes
            self.avatarId = data["avatar"].string
        }
        
        // populate object based on content type and add to heterogenous array
        let contentType = TreemContentService.ContentTypes(rawValue: data["c_type"].int ?? -1)
        
        if contentType == .Video {
            self.contentItem = ContentItemDownloadVideo(data: data)
        }
        else if contentType == .Image {
            self.contentItem = ContentItemDownloadImage(data: data)
        }
        
        self.calculateCellLayoutInfo()
    }
    
    func toJSON() -> JSON {
        var json:JSON = [:]

        // add user id (it's non nullable)
        json["u_id"].intValue = self.userId
        
        // add only the properties that aren't null
        if let msgId    = self.messageStringId { json["m_id"].string = msgId }
        if let mType    = self.messageType {  json["m_type"].intValue = mType.rawValue }
        if let sId      = self.sessionId { json["s_id"].string = sId }
        if let mDate    = self.messageDate { json["m_dttm"].string = mDate.getISOFormattedString() }
        if let msg      = self.messageText { json["msg"].string = msg }
        if let uName    = self.username { json["username"].string = uName }
        if let avt = self.avatar {
            json["avatar_stream_url"].string = String(avt)
        }
        
        if let cItem = self.contentItem as? ContentItemDownload {
            json["c_id"].intValue       = cItem.contentID

            if let type = cItem.contentType?.rawValue { json["c_type"].intValue = type }
            if let url  = cItem.contentURL { json["c_url"].string = String(url) }
            
            json["c_width"].int     = Int(cItem.contentWidth)
            json["c_height"].int    = Int(cItem.contentHeight)
        }
        
        return json
    }
    
    func calculateCellLayoutInfo() {
        if let msgType = self.messageType {
            switch(msgType){
                case MessageType.Remove:
                    self.messageText = "left chat"
                default: break
            }
        }
        
        // reset height
        self.cellHeightLayout = 0
        
        // get allocated width for message view content
        let labelPadding2x  = self.cellMsgLabelPadding * 2
        let allocatedWidth  = Device.sharedInstance.mainScreen.bounds.width
            - (self.cellMargin * 2) // margin to the left and right of cell
            - self.avatarWidth      // width of avatar in row
            - self.avatarLeftMargin // margin between avatar and message bubble
            - labelPadding2x        // padding between message content and message view
        
        // if it's a regular chat message update message size based on text
        if let msg = self.messageText {
            
            // add common height properties
            self.addCommonHeightValuesToLayoutHeight()
            
            var labelSize = msg.labelCopyableSizeFromText(self.cellMsgLabelFont)
            
            // check if label can fit in allocated width
            if labelSize.width > allocatedWidth {
                labelSize.width = allocatedWidth
                
                // get new height from constrained width
                labelSize.height = msg.labelCopyableHeightWithConstrainedWidth(labelSize.width, font: self.cellMsgLabelFont)
            }
            
            // store text label size
            self.cellMessageTextSize = CGSize(width: labelSize.width, height: labelSize.height)
            
            // store overall message view size
            self.cellMessageViewSize = CGSize(width: self.cellMessageTextSize.width + labelPadding2x, height: self.cellMessageTextSize.height + labelPadding2x)
            
            // update the row height
            self.cellHeightLayout += self.cellMessageViewSize.height
        }
        // if it's a content item, update message size based on item downloading
        else if let cItem = self.contentItem as? ContentItemDownload {
            
            // add common height properties
            self.addCommonHeightValuesToLayoutHeight()
            
            /* get content default and allocated sizes */
            let contentSize     = CGSize(width: cItem.contentWidth, height: cItem.contentHeight)
            let allocatedSize   = CGSize(width: allocatedWidth * 0.75, height: AppSettings.max_post_image_resolution) // content only fills percentage of view
            
            // scale image down and store size
            self.cellMessageImageSize = UIImage.getResizeImageScaleSize(allocatedSize, oldSize: contentSize)
            
            // store overall message view size
            self.cellMessageViewSize = CGSize(width: self.cellMessageImageSize.width + labelPadding2x, height: self.cellMessageImageSize.height + labelPadding2x)
            
            // update the row height
            self.cellHeightLayout += self.cellMessageViewSize.height
        }
    }
    
    // add all common height values (everything but message height) to cell height property
    private func addCommonHeightValuesToLayoutHeight() {
        self.cellHeightLayout += self.topNameMargin
        self.cellHeightLayout += self.nameHeight
        self.cellHeightLayout += self.topAvatarMargin
        self.cellHeightLayout += self.bottomMessageMargin
    }
}