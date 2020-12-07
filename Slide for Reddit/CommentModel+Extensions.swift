//
//  CommentModel+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/6/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation
import reddift

public extension CommentModel {
    //Takes a Comment from reddift and turns it into a Realm model
    static func commentToCommentModel(comment: Comment, depth: Int) -> CommentModel {
        let flair = comment.authorFlairText.isEmpty ? comment.authorFlairCssClass : comment.authorFlairText
        var bodyHtml = comment.bodyHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")

        bodyHtml = bodyHtml.replacingOccurrences(of: "<div class=\"md\">", with: "")
        let commentModel = CommentModel()
        let json = comment.baseJson
        commentModel.id = comment.getId()
        commentModel.author = comment.author
        commentModel.created = Date(timeIntervalSince1970: TimeInterval(comment.createdUtc))
        commentModel.isEdited = comment.edited > 0
        commentModel.edited = Date(timeIntervalSince1970: TimeInterval(comment.edited))
        commentModel.htmlBody = bodyHtml
        commentModel.subreddit = comment.subreddit
        commentModel.submissionTitle = comment.submissionTitle
        commentModel.isSaved = comment.saved
        commentModel.markdownBody = comment.body
        commentModel.removalReason = comment.baseJson["ban_note"] as? String ?? ""
        commentModel.removalNote = comment.baseJson["mod_note"] as? String ?? ""
        commentModel.removedBy = comment.baseJson["banned_by"] as? String ?? ""
        commentModel.isRemoved = !commentModel.removedBy?.isEmpty()
        commentModel.approvedBy = comment.baseJson["approved_by"] as? String ?? ""
        commentModel.isApproved = !commentModel.approvedBy?.isEmpty()
        commentModel.isStickied = comment.stickied
        //todo flairs and awards
        //todo reports
        commentModel.isCakeday = comment.baseJson["author_cakeday"] as? Bool ?? false


        commentModel.score = Int32(comment.score)
        commentModel.depth = Int32(depth)
        
        commentModel.isMod = comment.canMod
        commentModel.linkId = comment.linkId
        commentModel.isArchived = comment.archived
        commentModel.distinguished = comment.distinguished.type
        commentModel.controversality = Int32(comment.controversiality)
        commentModel.hasVoted = comment.likes != .none
        commentModel.voteDirection = comment.likes == .up
        commentModel.name = comment.name
        commentModel.parentId = comment.parentId
        commentModel.scoreHidden = comment.scoreHidden
        commentModel.permalink = "https://www.reddit.com" + comment.permalink
        return commentModel
    }
    
    var likes: VoteDirection {
        if hasVoted {
            if voteDirection {
                return .up
            } else {
                return .down
            }
        }
        return .none
    }
    
    //Takes a More from reddift and turns it into a Realm model
    static func moreToRMore(more: More) -> MoreModel {
        let moreModel = MoreModel()
        if more.id.endsWith("_") {
            moreModel.id = "more_\(NSUUID().uuidString)"
        } else {
            moreModel.id = more.id
        }
        moreModel.name = more.name
        moreModel.parentId = more.parentId
        moreModel.count = Int32(more.count)
        moreModel.childrenString = more.children.joined()
        return moreModel
    }

}
