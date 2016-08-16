//
//  BranchDelegate.swift
//  Treem
//
//  Created by Matthew Walker on 12/9/15.
//  Copyright © 2015 Treem LLC. All rights reserved.
//

import UIKit

protocol PostDelegate {
    func postWasAdded()
    func postWasUpdated(post: Post)
    func postWasDeleted(postID: Int)
    func replyWasDeleted(replyID: Int)
}

extension PostDelegate {
    // default empty implementations
    func postWasAdded() {}
    func postWasUpdated(post: Post) {}
    func postWasDeleted(postID: Int) {}
    func replyWasDeleted(replyID: Int) {}
}