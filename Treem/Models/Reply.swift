//
//  Reply.swift
//  Treem
//
//  Created by Kevin Novak on 12/30/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

class Reply: NSObject, TableViewCellModelType {
    // model properties
    var replyId         : Int           = 0
    var userId          : Int           = 0
    var comment         : String?       = nil
    var user            : User?         = nil
    var replyDate       : NSDate?       = nil
    var editable        : Bool          = false
    
    var containsUrl     : Bool          = false
    var replyUrlData    : WebPageData?  = nil
    
    // reacts stuff
    var reactCounts     : [(react: Post.ReactionType, count: Int)]? = nil
    var totalReacts     : Int           = 0
    var selfReact       : Post.ReactionType? = nil

    // table view cell type properties
    var allRowsIndex    : Int           = 0

    // regular post height layout values
    private(set) var posterTopMargin            : CGFloat = 0
    private(set) var posterHeight               : CGFloat = 0
    private(set) var messageTopMargin           : CGFloat = 0
    private(set) var messageHeight              : CGFloat = 0
    private(set) var messageBottomMargin        : CGFloat = 0
    private(set) var contentHeight              : CGFloat = 0
    private(set) var contentBottomMargin        : CGFloat = 0
    private(set) var urlPreviewHeight           : CGFloat = 0
    private(set) var urlPreviewBottomMargin     : CGFloat = 0
    private(set) var bottomShadeBarHeight       : CGFloat = 0
    private(set) var reactButtonHeight          : CGFloat = 0

    // layout height
    var cellHeightLayout: CGFloat = 0
    
    // modified after cell loaded
    var actionViewHeight           : CGFloat = 0 {
        didSet {
            self.generateCellLayoutHeight()
        }
    }
    
    var contentItems    : [ContentItemDownload]? = nil
    
    var hasReactions: Bool {
        return self.reactCounts != nil && self.reactCounts!.count > 0
    }
    
    private let minMediaViewContentHeight : CGFloat = 200
    
    override init() {}

    // load from JSON
    init(data: JSON, postId: Int = 0) {
        super.init()

        self.replyId            = data["r_id"].intValue
        self.userId             = data["u_id"].intValue
        self.comment            = data["cmt"].string
        self.user               = User(data: data["user"])
        self.replyDate          = NSDate(iso8601String: data["r_date"].string)
        self.editable           = data["editable"].intValue == 1
        
        
        // populate object based on content type and add to heterogenous array
        let contentType = TreemContentService.ContentTypes(rawValue: data["c_type"].int ?? -1)
        
        if contentType == .Video {
            self.contentItems = [ContentItemDownloadVideo(data: data)]
        }
        else if contentType == .Image {
            self.contentItems = [ContentItemDownloadImage(data: data)]
        }
        
        // load the shared URL data
        
        self.containsUrl    = (data["l_url"].stringValue != "" || data["l_img_url"].stringValue != "")
        
        if self.containsUrl {
            self.replyUrlData = WebPageData(data: data)
        }
        
        // load reactions
        self.loadReactions(data["react_cnt"])
        if let sReact = data["s_react"].int {
            self.selfReact = Post.ReactionType(rawValue: sReact)
        }
        
        // precalculate cell layout height
        self.generateCellLayoutHeight()
    }

    // serialize to JSON
    func toJSON() -> JSON {
        var json:JSON = [:]

        // check message
        if let cmt = self.comment {
            if cmt.characters.count > 0 {
                json["cmt"].stringValue = cmt
            }
        }
        
        // if adding content
        if let contentItems = self.contentItems {
            if contentItems.count > 0 {
                let contentItem = contentItems[0]
                
                json["c_id"].intValue       = contentItem.contentID
                
                if let type = contentItem.contentType?.rawValue {
                    json["c_type"].intValue = type
                }
            }
        }
        
        if let pageData = self.replyUrlData {
            if pageData.linkDescription != nil {
                json["l_desc"].stringValue = pageData.linkDescription!
            }
            if pageData.linkUrl != nil {
                json["l_url"].stringValue = pageData.linkUrl!
            }
            if pageData.linkTitle != nil {
                json["l_title"].stringValue = pageData.linkTitle!
            }
            if pageData.linkImage != nil {
                json["l_img_url"].stringValue = pageData.linkImage!
            }
        }
        
        return json
    }

    override var hashValue: Int {
        return "\(self.replyId)".hashValue
    }

    static func getRepliesFromData(data: JSON) -> (replies: OrderedSet<Reply>, users: Dictionary<Int, User>) {
        var replies = OrderedSet<Reply>()
        var users = Dictionary<Int, User>()

        for (_, replyData) in data {
            let reply = Reply(data: replyData)

            replies.insert(reply)

            if let replyUser = reply.user {
                users[replyUser.id] = replyUser
            }
        }

        return (replies: replies, users: users)
    }

    private func generateCellLayoutHeight() {
        let messageBoundWidth       = Device.sharedInstance.mainScreen.bounds.width - 20
        let messageFont             = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)
        
        self.posterTopMargin    = 10
        self.posterHeight       = 32
        self.messageTopMargin   = 15
        
        if let comment = comment {
            self.messageHeight          = comment.labelCopyableHeightWithConstrainedWidth(messageBoundWidth, font: messageFont)
            self.messageBottomMargin    = 10
        }
        
        // media container height
        if let contentItems = self.contentItems, contentItem = contentItems[0] as? ContentItemDownload {
            let contentSize = self.getContentSize(contentItem)

            self.contentHeight = ceil(contentSize.height)

            self.contentBottomMargin = 10
        }
        
        // url preview height
        if let pageData = self.replyUrlData where self.containsUrl {
            
            self.urlPreviewHeight = UrlPreviewViewController.getLayoutHeightFromWebData(pageData)
            
            // only add margin if there is url preview content
            if self.urlPreviewHeight > 0 {
                self.urlPreviewBottomMargin = 10
            }
        }

        self.bottomShadeBarHeight  = 1
        
        self.reactButtonHeight = 28
        
        self.cellHeightLayout = self.posterTopMargin +
                self.posterHeight +
                self.messageTopMargin +
                self.messageHeight +
                self.messageBottomMargin +
                self.contentHeight +
                self.contentBottomMargin +
                self.urlPreviewHeight +
                self.urlPreviewBottomMargin +
                self.bottomShadeBarHeight +
                self.reactButtonHeight +
                self.actionViewHeight
    }
    
    // recursively load sub branch network
    private func loadUsers(data: JSON) -> [User]? {
        var users: [User] = []

        for (_, object) in data {
            let user = User(data: object)
            
            users.append(user)
        }
        
        return users.count < 1 ? nil : users
    }
    
    func changeSelfReaction(reaction: Post.ReactionType?) {
        let update = Post.updateSelfReaction(reaction, selfReaction: self.selfReact, reactionCounts: self.reactCounts)
        
        // update the object's values
        self.selfReact = update.selfReact
        self.reactCounts = update.reactCounts
    }
    
    private func loadReactions(data: JSON){
        
        self.reactCounts = []   // initialize array
        self.totalReacts = 0
        
        for(_, object) in data {
            
            let rType = Post.ReactionType(rawValue: object["react"].int ?? Post.ReactionType.Happy.rawValue)
            let rCnt = object["cnt"].int
            
            if((rType != nil) && (rCnt != nil)){
                var reactObj: (react: Post.ReactionType, count: Int)
                reactObj.react = rType!
                reactObj.count = rCnt!
                
                if(reactObj.count > 0){
                    self.totalReacts += reactObj.count
                    self.reactCounts?.append(reactObj)
                }
            }
        }
        if (self.reactCounts?.count < 1) { self.reactCounts = nil }
    }
    
    func getContentSize(contentItem: ContentItemDownload) -> CGSize {
        var contentSize: CGSize
        
        let mediaContainerWidth = UIScreen.mainScreen().bounds.width
        
        // check if sizes were passed back
        if contentItem.contentWidth > 0 && contentItem.contentHeight > 0 {
            
            // check if sizes exceed current viewing frame
            if contentItem.contentWidth > mediaContainerWidth {
                let ratio = mediaContainerWidth / contentItem.contentWidth
                
                // need to resize to fit
                contentSize = CGSize(width: contentItem.contentWidth * ratio, height: contentItem.contentHeight * ratio)
            }
                // else use content size passed back
            else {
                contentSize = CGSize(width: contentItem.contentWidth, height: contentItem.contentHeight)
            }
        }
            // use default size if none passed back
        else {
            contentSize = CGSize(width: mediaContainerWidth, height: self.minMediaViewContentHeight)
        }
        
        contentSize.width   = ceil(contentSize.width)
        contentSize.height  = ceil(contentSize.height)
        
        return contentSize
    }
}