//
//  Post.swift
//  Treem
//
//  Created by Matthew Walker on 11/25/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit
import SwiftyJSON

class Post: NSObject, TableViewCellModelType {
    
    // types of reactions
    enum ReactionType: Int {
        case Neutral            = -1 // equivalent of no reaction
        case Happy              = 0
        case Angry              = 2
        case Sad                = 3
        case Hilarious          = 6
        case Amazed             = 7
        case Worried            = 8
        
        static let allOrderedValues = [
            Neutral,
            Happy,
            Angry,
            Sad,
            Hilarious,
            Amazed,
            Worried
        ]
    }
    
    // model properties
    var postId              : Int               = 0
    var userId              : Int               = 0
    var message             : String?           = nil
    var users               : [User]?           = nil
    var color               : String?           = nil
    var postDate            : NSDate?           = nil
    var viewOnce            : Bool              = false
    var shareable           : Bool              = false
    var editable            : Bool              = false
    var expires             : NSDate?           = nil
    var currentUserTagged   : Bool              = false
    var containsUrl         : Bool              = false
    var taggedUsers         : [Int]             = []
    var taggedNames    : String?           = nil
    
    // abuse object
    var abuse               : Abuse?            = nil
    
    var contentItems    : [ContentItemDelegate]? = nil

    // adding properties
    var branchID        : Int               = 0
    
    // table view cell type properties
    var allRowsIndex    : Int               = 0
    var wasViewed       : Bool              = false
    
       // share info
    var share_id        : Int               = 0
    var share_user_id   : Int               = 0
    var share_message   : String?           = nil
    var share_date      : NSDate?           = nil
    var share_editable  : Bool              = false
    
    // post count data
    var shareCount      : Int           = 0
    var commentCount    : Int           = 0
    var reactCounts     : [(react: ReactionType, count: Int)]? = nil
    var totalReacts     : Int           = 0
    var selfReact       : ReactionType? = nil
    
    //post url details
    var postUrlData     : WebPageData? = nil

    // layout height
    var cellHeightLayout: CGFloat = 0
    private let minMediaViewContentHeight : CGFloat = 200
    
    override init() {}
    
    // load from JSON
    init(data: JSON, postId: Int = 0) {
        super.init()

        self.postId             = postId > 0 ? postId : data["p_id"].intValue
        self.userId             = data["u_id"].intValue
        self.branchID           = data["b_id"].intValue
        self.message            = data["msg"].string
        self.users              = self.loadUsers(data["users"])
        self.color              = data["p_color"].string
        self.postDate           = NSDate(iso8601String: data["p_date"].string)
        self.viewOnce           = data["v_once"].intValue == 1
        self.shareable          = data["shareable"].intValue == 1
        self.editable           = data["editable"].intValue == 1
        self.expires            = NSDate(iso8601String: data["expires"].string)
        self.currentUserTagged  = data["tgd"].intValue == 1
        
        // share info
        self.share_id       = data["sh_id"].intValue
        self.share_user_id  = data["sh_u_id"].intValue
        self.share_message  = data["sh_msg"].string
        self.share_date     = NSDate(iso8601String: data["sh_date"].string)
        self.share_editable = data["sh_editable"].intValue == 1
    
        // get post counts
        self.shareCount     = data["share_cnt"].intValue
        self.commentCount   = data["cmt_cnt"].intValue
        
        self.loadReactions(data["react_cnt"])
        
        // load the shared URL data
        self.containsUrl    = !data["l_url"].stringValue.parseForUrl().isEmpty || !data["l_img_url"].stringValue.parseForUrl().isEmpty
        
        if self.containsUrl {
            self.postUrlData = WebPageData(data: data)
        }
        
        if let sReact = data["s_react"].int {
            self.selfReact = ReactionType(rawValue: sReact)
        }
        
        // populate object based on content type and add to heterogenous array
        let contentType = TreemContentService.ContentTypes(rawValue: data["c_type"].int ?? -1)
        
        if contentType == .Video {
            self.contentItems = [ContentItemDownloadVideo(data: data)]
        }
        else if contentType == .Image {
            self.contentItems = [ContentItemDownloadImage(data: data)]
        }

        self.taggedUsers = data["tgs"].arrayValue.map {$0.intValue}
        self.taggedNames = data["tg_names"].string      // names are comma delimited

        // precalculate cell layout height
        self.generateCellLayoutHeight()
    }
    
    // serialize to JSON
    func toJSON() -> JSON {
        var json:JSON = [:]

        // if posting to specific branch
        if (self.branchID > 0) {
            json["b_id"].intValue = self.branchID
        }
        
        // check message
        if let msg = self.message {
            if msg.characters.count > 0 {
                json["msg"].stringValue = msg
            }
        }
        
        // check if expiration given
        if let expires = self.expires {
            json["expires"].stringValue = expires.getISOFormattedString()
        }
        
        // if post can be shared
        if self.shareable {
            json["shareable"].intValue = 1
        }
        
        // if allowing view once only
        if self.viewOnce {
            json["v_once"].intValue = 1
        }

        json["tgs"].arrayObject = self.taggedUsers

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
        
        if let pageData = self.postUrlData {
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
        return "\(self.postId),\(self.share_id)".hashValue
    }
    
    static func getUserReactions(data: JSON) -> [User]? {
        var users: [User] = []
        
        for (_, object) in data {
            let user = User(data: object["user"])
            
            if let sReact = object["react"].int {
                if let reactType = ReactionType(rawValue: sReact){
                    user.listIcon = self.getReactionImage(reactType)
                }
            }
            
            users.append(user)
        }
        
        return users.count < 1 ? nil : users
    }
    
    static func getPostUsers(data: JSON) -> (count: Int?, users: [User]?)? {        
        var usrs: [User] = []
        var usr_cnt: Int? = 0
        
        usr_cnt = data["user_cnt"].int
        
        if let cnt = usr_cnt {
            return (cnt,nil)
        }
        else{
            for (_, object) in data {
                usrs.append(User(data: object))
            }
            if usrs.count >= 1 {
                return (nil,usrs)
            }
        }
        
        return nil
    }
    
    static func getReactionImage(react: ReactionType) -> UIImage {
        var name: String!
        
        switch(react){
        case Post.ReactionType.Neutral          : name = "Neutral"
        case Post.ReactionType.Happy            : name = "Happy"
        case Post.ReactionType.Angry            : name = "Angry"
        case Post.ReactionType.Sad              : name = "Sad"
        case Post.ReactionType.Hilarious        : name = "Hilarious"
        case Post.ReactionType.Amazed           : name = "Amazed"
        case Post.ReactionType.Worried          : name = "Worried"
        }
        
        return UIImage(named: name)!
    }

    
    static func getPostsFromData(data: JSON) -> (posts: OrderedSet<Post>, users: Dictionary<Int, User>) {
        var posts = OrderedSet<Post>()
        var users = Dictionary<Int, User>()
        
        for (_, postData) in data {
            let post = Post(data: postData)
            
            posts.insert(post)
            
            if let postUsers = post.users {
                for user in postUsers {
                    users[user.id] = user
                }
            }
        }
        
        return (posts: posts, users: users)
    }

    // Retrieve information for a single post
    // Still conforms to the setup of getPostsFromData, because we're still filling out the same main tableview with this information
    static func getPostDetailsFromData(data: JSON) -> (post: Post, users: Dictionary<Int, User>) {
        var users = Dictionary<Int, User>()

        let post = Post(data: data)

        if let postUsers = post.users {
            for user in postUsers {
                users[user.id] = user
            }
        }

        return (post: post, users: users)

    }

    // layout affecting variables
    var isSharedPost: Bool {
        return (self.share_id > 0) && (self.share_user_id > 0)
    }
    
    var hasReactions: Bool {
        return self.reactCounts != nil && self.reactCounts!.count > 0
    }
    
    var hasMessage: Bool {
        return self.message != nil
    }
    
    var hasSharedMessage: Bool {
        return self.share_message != nil
    }
    
    // share height layout values
    private(set) var sharePosterTopMargin       : CGFloat = 0
    private(set) var sharePosterHeight          : CGFloat = 0
    private(set) var shareMessageTopMargin      : CGFloat = 0
    private(set) var shareMessageHeight         : CGFloat = 0
    private(set) var shareMessageBottomMargin   : CGFloat = 0
    
    // regular post height layout values
    private(set) var posterTopMargin            : CGFloat = 10
    private(set) var posterHeight               : CGFloat = 32
    private(set) var taggedTopMargin            : CGFloat = 0
    private(set) var taggedHeight               : CGFloat = 0
    private(set) var messageTopMargin           : CGFloat = 15
    private(set) var messageHeight              : CGFloat = 0
    private(set) var messageBottomMargin        : CGFloat = 0
    private(set) var contentHeight              : CGFloat = 0
    private(set) var contentBottomMargin        : CGFloat = 0
    private(set) var reactTopMargin             : CGFloat = 0
    private(set) var reactHeight                : CGFloat = 0
    private(set) var reactBottomMargin          : CGFloat = 0
    private(set) var postOptionsHeight          : CGFloat = 28
    private(set) var bottomShadeBarHeight       : CGFloat = 8
    
    // modified after cell loaded 
    var actionViewHeight           : CGFloat = 0 {
        didSet {
            self.generateCellLayoutHeight()
        }
    }
    
    // modified after cell loaded (image load can fail in url preview)
    var urlPreviewHeight        : CGFloat = 0
    var urlPreviewImageHeight   : CGFloat = 0
    var urlPreviewBottomMargin  : CGFloat = 0
    
    func generateCellLayoutHeight() {
        let messageBoundWidth       = UIScreen.mainScreen().bounds.width - 20
        let messageFont             = UIFont.systemFontOfSize(15, weight: UIFontWeightRegular)
        var totalHeight: CGFloat    = 0

        /*
            Shared post
        */

        if self.isSharedPost {
            self.sharePosterTopMargin   = 10
            self.sharePosterHeight      = 32
            
            // shared message text provided
            if let msg = self.share_message {
                self.shareMessageTopMargin      = 15
                self.shareMessageHeight         = msg.labelCopyableHeightWithConstrainedWidth(messageBoundWidth, font: messageFont)
                self.shareMessageBottomMargin   = 10
            }
            // message text not provided
            else {
                self.shareMessageTopMargin      = 10
            }
            
            totalHeight += (self.sharePosterTopMargin + self.sharePosterHeight + self.shareMessageTopMargin + self.shareMessageHeight + self.shareMessageBottomMargin)
        }
        
        /*
            Regular post
        */
        
        // poster information (always shown)
        totalHeight += (self.posterTopMargin + self.posterHeight)
        
        // if member(s) are tagged
        if self.currentUserTagged {
            self.taggedTopMargin    = 15 // tagged top margin
            self.taggedHeight       = 14 // tagged button height
            
            totalHeight += (self.taggedTopMargin + self.taggedHeight)
        }

        // tagged bottom margin / message top margin
        totalHeight += self.messageTopMargin
        
        // message label height
        if let msg = self.message {
            self.messageHeight = msg.labelCopyableHeightWithConstrainedWidth(messageBoundWidth, font: messageFont)

            self.messageBottomMargin = 15
            
            totalHeight += (self.messageHeight + self.messageBottomMargin)
        }
        
        // url preview height
        if let pageData = self.postUrlData where self.containsUrl {
            self.urlPreviewHeight = UrlPreviewViewController.getLayoutHeightFromWebData(pageData)

            // only add margin if there is url preview content
            if self.urlPreviewHeight > 0 {
                self.urlPreviewBottomMargin = 15
            }

            totalHeight += (self.urlPreviewHeight + self.urlPreviewBottomMargin)
        }
        
        // media container height
        if let contentItems = self.contentItems, contentItem = contentItems[0] as? ContentItemDownload {
            let contentSize = self.getContentSize(contentItem)
            
            self.contentHeight = ceil(contentSize.height)

            self.contentBottomMargin = self.isSharedPost ? 10 : 15
            
            totalHeight += (self.contentHeight + self.contentBottomMargin)
        }
        
        // react container height
        if self.hasReactions {
            if self.isSharedPost {
                self.reactTopMargin = 10
            }
            
            self.reactHeight = 16

            self.reactBottomMargin = 10
            
            totalHeight += (self.reactTopMargin + self.reactHeight + self.reactBottomMargin)
        }
        else if self.isSharedPost {
            self.reactBottomMargin = 10
            
            totalHeight += self.reactBottomMargin
        }

        totalHeight += (self.postOptionsHeight + self.bottomShadeBarHeight + self.actionViewHeight)
        
        self.cellHeightLayout = totalHeight
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
        
        if self.reactCounts == nil {
            self.reactBottomMargin  = 0
            self.reactHeight        = 0
            self.reactTopMargin     = 0
        }
        
        self.generateCellLayoutHeight()
    }
    
            
    static func updateSelfReaction(reaction: Post.ReactionType?
                , selfReaction: ReactionType?
                , reactionCounts: [(react: ReactionType, count: Int)]?)
        -> (selfReact: ReactionType?, reactCounts: [(react: ReactionType, count: Int)]?) {
            
        var selfReact = selfReaction
        var reactCounts = reactionCounts
            
        let decrementReaction = selfReact
        let incrementReaction = reaction
        
        // if decrementing a reaction
        if let decrementReaction = decrementReaction, _ = reactCounts {
            
            // cycle through each reaction and look for reaction
            for i in 0 ..< reactCounts!.count {
                if reactCounts![i].react == decrementReaction {
                    reactCounts![i].count -= 1
                    
                    // if the react count is now 0 remove from array (loop breaks below)
                    if reactCounts![i].count < 1 {
                        reactCounts!.removeAtIndex(i)
                    }
                    
                    break
                }
            }
            
            // if cleared last reaction type, nil array
            if reactCounts?.count < 1 {
                reactCounts = nil
            }
        }
        
        // if incrementing a reaction
        if let incrementReaction = incrementReaction {
            
            // if no current reactions, initialize array
            if reactCounts == nil {
                reactCounts = []
            }
            
            var reactionFound = false
            
            // look for reaction in array first
            for i in 0 ..< reactCounts!.count {
                if reactCounts![i].react == incrementReaction {
                    reactCounts![i].count += 1
                    
                    reactionFound = true
                    
                    break
                }
            }
            
            // if reaction not found, append to array
            if !reactionFound {
                reactCounts?.append((react: incrementReaction, count: 1))
            }
        }
        
        // update self value
        selfReact = reaction
        
        return (selfReact, reactCounts)
    }
    
    private func loadReactions(data: JSON){
        
        self.reactCounts = []   // initialize array
        self.totalReacts = 0
        
        for(_, object) in data {
            
            let rType = ReactionType(rawValue: object["react"].int ?? ReactionType.Happy.rawValue)
            let rCnt = object["cnt"].int
            
            if((rType != nil) && (rCnt != nil)){
                var reactObj: (react: ReactionType, count: Int)
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
    
}