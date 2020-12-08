//
//  CommentObject.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/7/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

class CommentObject: RedditObject {
    public var approvedBy: String?
    public var author: String = ""
    public var awardsJSON: String?
    public var controversality: Int32
    public var created: Date = Date()
    public var edited: Date?
    public var depth: Int = -1
    public var distinguished: String?
    public var flairJSON: String?
    public var hasVoted: Bool = false
    public var hidden: Bool = false
    public var htmlBody: String = ""
    public var id: String = ""
    public var isApproved: Bool = false
    public var isArchived: Bool = false
    public var isCakeday: Bool = false
    public var isEdited: Bool = false
    public var isMod: Bool = false
    public var isRemoved: Bool = false
    public var isSaved: Bool = false
    public var isStickied: Bool = false
    public var locked: Bool = false
    public var markdownBody: String = ""
    public var linkID: String = ""
    public var name: String = ""
    public var parentID: String = ""
    public var permalink: String = ""
    public var removalNote: String?
    public var removalReason: String?
    public var removedBy: String?
    public var reportsJSON: String?
    public var score: Int
    public var scoreHidden: Bool = false
    public var submissionTitle: String = ""
    public var subreddit: String = ""
    public var voteDirection: Bool = false
    
    static func thingToCommentOrMore(thing: Thing, depth: Int) -> RedditObject? {
        if thing is More {
            return MoreObject.moreToMoreObject(more: thing as! More)
        } else if thing is Comment {
            return CommentObject.commentToCommentObject(comment: thing as! Comment, depth: depth)
        }
        
        return nil
    }

    static func commentToCommentObject(comment: Comment, depth: Int) -> CommentObject {
        return CommentObject(comment: comment, depth: depth)
    }

    public init(comment: Comment, depth: Int) {
        let flair = comment.authorFlairText.isEmpty ? comment.authorFlairCssClass : comment.authorFlairText
        var bodyHtml = comment.bodyHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")

        bodyHtml = bodyHtml.replacingOccurrences(of: "<div class=\"md\">", with: "")
        let json = comment.baseJson
        self.id = comment.getId()
        self.author = comment.author
        self.created = Date(timeIntervalSince1970: TimeInterval(comment.createdUtc))
        self.isEdited = comment.edited > 0
        self.edited = Date(timeIntervalSince1970: TimeInterval(comment.edited))
        self.htmlBody = bodyHtml
        self.subreddit = comment.subreddit
        self.submissionTitle = comment.submissionTitle
        self.isSaved = comment.saved
        self.markdownBody = comment.body
        self.removalReason = comment.baseJson["ban_note"] as? String ?? ""
        self.removalNote = comment.baseJson["mod_note"] as? String ?? ""
        self.removedBy = comment.baseJson["banned_by"] as? String ?? ""
        self.isRemoved = !(self.removedBy ?? "").isEmpty()
        self.approvedBy = comment.baseJson["approved_by"] as? String ?? ""
        self.isRemoved = !(self.approvedBy ?? "").isEmpty()
        self.isStickied = comment.stickied
        let jsonDict = NSMutableDictionary()
        for item in comment.baseJson["all_awardings"] as? [AnyObject] ?? [] {
            if let award = item as? JSONDictionary {
                if award["icon_url"] != nil && award["count"] != nil {
                    let name = award["name"] as? String ?? ""
                    var awardArray = [name]
                    if let awards = award["resized_icons"] as? [AnyObject], awards.count > 1, let url = awards[1]["url"] as? String {
                        awardArray.append(url.unescapeHTML)
                    } else {
                        awardArray.append(award["icon_url"] as? String ?? "")
                    }
                    awardArray.append("\(award["count"] as? Int ?? 0)")
                    awardArray.append(award["description"] as? String ?? "")
                    awardArray.append("\(award["coin_price"] as? Int ?? 0)")
                    
                    //HD icon
                    if let awards = award["resized_icons"] as? [AnyObject], awards.count > 1, let url = awards[awards.count - 1]["url"] as? String {
                        awardArray.append(url.unescapeHTML)
                    } else {
                        awardArray.append(award["icon_url"] as? String ?? "")
                    }
                    jsonDict[name] = awardArray
                }
            }
        }
        self.awardsJSON = jsonDict.jsonString()
        
        let flairDict = NSMutableDictionary()
        for item in comment.baseJson["author_flair_richtext"] as? [AnyObject] ?? [] {
            if let flair = item as? JSONDictionary {
                if flair["e"] as? String == "text" {
                    if let title = (flair["t"] as? String)?.unescapeHTML {
                        if let color = comment.baseJson["link_flair_background_color"] as? String, !color.isEmpty {
                            flairDict[title.trimmed()] = ["color": color]
                        } else {
                            flairDict[title.trimmed()] = [:]
                        }
                    }
                } else if flair["e"] as? String == "emoji" {
                    if let title = (flair["a"] as? String)?.unescapeHTML, let url = flair["u"] as? String, let fallback = flair["a"] as? String {
                        flairDict[title.trimmed()] = ["url": url, "fallback": fallback]
                    }
                }
            }
        }
        self.flairJSON = flairDict.jsonString()

        let reportsDict = NSMutableDictionary()
        for item in comment.baseJson["mod_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            reportsDict[array[0]] = array[1]
        }
        for item in comment.baseJson["user_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            reportsDict[array[0]] = array[1]
        }
        self.reportsJSON = reportsDict.jsonString()

        self.isCakeday = comment.baseJson["author_cakeday"] as? Bool ?? false

        self.score = comment.score
        self.depth = depth
        
        self.isMod = comment.canMod
        self.linkID = comment.linkId
        self.isArchived = comment.archived
        self.distinguished = comment.distinguished.type
        self.controversality = Int32(comment.controversiality)
        self.hasVoted = comment.likes != .none
        self.voteDirection = comment.likes == .up
        self.name = comment.name
        self.parentID = comment.parentId
        self.scoreHidden = comment.scoreHidden
        self.permalink = "https://www.reddit.com" + comment.permalink
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
    var flairDictionary: [String: AnyObject] {
        return flairJSON?.dictionaryValue() ?? [String: AnyObject]()
    }
    
    var awardsDictionary: [String: AnyObject] {
        return awardsJSON?.dictionaryValue() ?? [String: AnyObject]()
    }
    
    var reportsDictionary: [String: AnyObject] {
        return reportsJSON?.dictionaryValue() ?? [String: AnyObject]()
    }
    
    var flair: String {
        return flairDictionary.keys.joined(separator: ",")
    }

}
