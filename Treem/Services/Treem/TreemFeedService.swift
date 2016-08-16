//
//  TreemFeedService.swift
//  Treem
//
//  Created by Matthew Walker on 11/30/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

class TreemFeedService {
    static let sharedInstance = TreemFeedService()

    private let url = "https://feed.\(TreemService.baseDomain)/"

    func getUserContentPosts(treeSession: TreeSession, page: Int? = nil, pageSize: Int? = nil, date: NSDate? = nil, user_id: Int?, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        let url         = self.url + "content" + ((user_id == nil) ? "" : "/" + String(user_id!))
        
        var parameters: Dictionary<String,AnyObject> = [:]
        
        parameters = TreemService.getPagingParameters(parameters, page: page, pageSize: pageSize)
        
        if let date = date {
            parameters["f_date"] = date.getISOFormattedString()
        }
        
        TreemService().get(
            url,
            parameters              : parameters,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func getPosts(treeSession: TreeSession, page: Int? = nil, pageSize: Int? = nil, date: NSDate? = nil, viewSize: CGFloat? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        let branchID    = treeSession.currentBranchID
        let url         = self.url + "posts" + (branchID > 0 ? "/" + String(branchID) : "")

        var parameters: Dictionary<String,AnyObject> = [:]

        parameters = TreemService.getPagingParameters(parameters, page: page, pageSize: pageSize)

        if let date = date {
            parameters["f_date"] = date.getISOFormattedString()
        }
        
        if let size = viewSize {
            parameters["vsize"] = size
        }
        
        TreemService().get(
            url,
            parameters              : parameters,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func getUserPosts(treeSession: TreeSession, userId: Int?, page: Int? = nil, pageSize: Int? = nil, date: NSDate? = nil, viewSize: CGFloat? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url         = self.url + "userposts" + ((userId == nil) ? "" : "/" + String(userId!))
        
        var parameters: Dictionary<String,AnyObject> = [:]
        
        parameters = TreemService.getPagingParameters(parameters, page: page, pageSize: pageSize)
        
        if let date = date {
            parameters["f_date"] = date.getISOFormattedString()
        }
        
        if let size = viewSize {
            parameters["vsize"] = size
        }
        
        TreemService().get(
            url,
            parameters              : parameters,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
        
    }

    func getPostDetails(treeSession: TreeSession, postID: Int, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        let url                 = self.url + "post/" + String(postID)

        TreemService().get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }

    func getPostComments(treeSession: TreeSession, postID: Int, page: Int? = nil, pageSize: Int? = nil, viewSize: CGFloat? = nil, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        let url                 = self.url + "replies/" + String(postID)
        
        var parameters: Dictionary<String,AnyObject> = [:]
        
        if let size = viewSize {
            parameters["vsize"] = size
        }
        
        parameters = TreemService.getPagingParameters(parameters, page: page, pageSize: pageSize)

        TreemService().get(
            url,
            parameters              : parameters,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }

    func removePost(treeSession: TreeSession, postID: Int, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        let url                 = self.url + "post/" + String(postID)
        var json : JSON         = [:]

        // delete content along with post
        json["del_content"].intValue = 1

        TreemService().delete(
            url,
            json                    : json,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func removeReply(treeSession: TreeSession, replyID: Int, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url                 = self.url + "reply/" + String(replyID)
        
        TreemService().delete(
            url,
            json                    : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func removeShare(treeSession: TreeSession, shareId: Int, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url                 = self.url + "share/" + String(shareId)
        
        TreemService().delete(
            url,
            json                    : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }

    func setPost(treeSession: TreeSession, post: Post, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        let url                 = self.url + "post" + (post.postId > 0 ? "/" + String(post.postId) : "")
        var json : JSON         = post.toJSON()

        if post.postId > 0  {
            // delete content along with post if editing existing
            json["del_content"].intValue = 1
        }

        TreemService().post(
            url,
            json: json,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
    }

    func setViewPost(treeSession: TreeSession, postId: Int, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {

        let url                 = self.url + "viewpost/" + String(postId)

        TreemService().post(
            url,
            json: nil,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
    }


    func setReply(treeSession: TreeSession, postID: Int, reply: Reply, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){

        let url                 = self.url + "reply/" + String(postID)
        
        let json:JSON           =  reply.toJSON()

        TreemService().post(
            url,
            json: json,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
    }

    func setPostReaction(treeSession: TreeSession, postID: Int, reaction: Post.ReactionType, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){

        let url                 = self.url + "react/" + String(postID)

        var json:JSON = [:]
        json["react"].intValue = reaction.rawValue


        TreemService().post(
            url,
            json: json,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )

    }
    
    func setReplyReaction(treeSession: TreeSession, replyID: Int, reaction: Post.ReactionType, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url + "reply/react/" + String(replyID)
        
        var json:JSON = [:]
        json["react"].intValue = reaction.rawValue
        
        
        TreemService().post(
            url,
            json: json,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
        
    }

    func removePostReaction(treeSession: TreeSession, postID: Int, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){

        let url                 = self.url + "react/" + String(postID)

        TreemService().delete(
            url,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )

    }
    
    func removeReplyReaction(treeSession: TreeSession, replyID: Int, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){
        
        let url                 = self.url + "reply/react/" + String(replyID)
        
        TreemService().delete(
            url,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
        
    }
    
    func getPostReactions(treeSession: TreeSession, postID: Int, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url                 = self.url + "reacts/" + String(postID)
        
        TreemService().get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func getReplyReactions(treeSession: TreeSession, replyID: Int, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url                 = self.url + "reply/reacts/" + String(replyID)
        
        TreemService().get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }
    
    func getPostUsers(treeSession: TreeSession, postID: Int, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url                 = self.url + "postusers/" + String(postID)
        
        TreemService().get(
            url,
            parameters              : nil,
            headers                 : treeSession.getTreemServiceHeader(),
            failureCodesHandled     : failureCodesHandled,
            success                 : success,
            failure                 : failure
        )
    }

    func setPostShare(treeSession: TreeSession, shareID: Int, postID: Int, message: String?, branchId: Int?, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler){

        let url                 = self.url + "share/" + String(postID) + (shareID > 0 ? "/" + String(shareID) : "")

        var json:JSON = [:]
       
        // add the post properties if they aren't nil
        if let msg = message { json["msg"].stringValue = msg }
        if let bId = branchId { json["b_id"].intValue = bId }
       
        TreemService().post(
            url,
            json: json,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
            )
        
    }
    
    func setPostAbuse(treeSession: TreeSession, postID: Int, abuse: Abuse, failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
        
        let url                 = self.url + "abuse/" + String(postID)
        
        var json:JSON = [:]
        json["abuse"].intValue = (abuse.reason?.rawValue)!

        TreemService().post(
            url,
            json: json,
            headers: treeSession.getTreemServiceHeader(),
            failureCodesHandled: failureCodesHandled,
            success: success,
            failure: failure
        )
    }
    
    func getUrlParse(treeSession: TreeSession, postUrl: String,
        failureCodesHandled: Set<TreemServiceResponseCode>? = nil, success: TreemServiceSuccessHandler, failure: TreemServiceFailureHandler) {
            let url             = self.url + "urlparse?url=" + postUrl.encodingForURLQueryValue()!
            
            TreemService().get(
                url,
                parameters              : nil,
                headers                 : treeSession.getTreemServiceHeader(),
                failureCodesHandled     : failureCodesHandled,
                success                 : success,
                failure                 : failure
            )
    }
    
}