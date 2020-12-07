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
        let managedContext = SlideCoreData.sharedInstance.backgroundContext
        let commentEntity = NSEntityDescription.entity(forEntityName: "CommentModel", in: managedContext)!
        let commentModel = NSManagedObject(entity: commentEntity, insertInto: managedContext) as! CommentModel

        let flair = comment.authorFlairText.isEmpty ? comment.authorFlairCssClass : comment.authorFlairText
        var bodyHtml = comment.bodyHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")

        bodyHtml = bodyHtml.replacingOccurrences(of: "<div class=\"md\">", with: "")
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
        commentModel.isRemoved = !(commentModel.removedBy ?? "").isEmpty()
        commentModel.approvedBy = comment.baseJson["approved_by"] as? String ?? ""
        commentModel.isRemoved = !(commentModel.approvedBy ?? "").isEmpty()
        commentModel.isStickied = comment.stickied
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
        commentModel.awardsJSON = jsonDict.jsonString()
        
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
        commentModel.flairJSON = flairDict.jsonString()

        let reportsDict = NSMutableDictionary()
        for item in comment.baseJson["mod_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            reportsDict[array[0]] = array[1]
        }
        for item in comment.baseJson["user_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            reportsDict[array[0]] = array[1]
        }
        commentModel.reportsJSON = reportsDict.jsonString()

        commentModel.isCakeday = comment.baseJson["author_cakeday"] as? Bool ?? false

        commentModel.score = Int32(comment.score)
        commentModel.depth = Int32(depth)
        
        commentModel.isMod = comment.canMod
        commentModel.linkID = comment.linkId
        commentModel.isArchived = comment.archived
        commentModel.distinguished = comment.distinguished.type
        commentModel.controversality = Int32(comment.controversiality)
        commentModel.hasVoted = comment.likes != .none
        commentModel.voteDirection = comment.likes == .up
        commentModel.name = comment.name
        commentModel.parentID = comment.parentId
        commentModel.scoreHidden = comment.scoreHidden
        commentModel.permalink = "https://www.reddit.com" + comment.permalink
        
        managedContext.performAndWait {
            do {
                try managedContext.save()
            } catch let error as NSError {
                print(error)
            }

        }
        return commentModel
    }
    
    static func thingToCommentOrMore(thing: Thing, depth: Int) -> NSManagedObject? {
        if thing is More {
            return MoreModel.moreToMoreModel(more: thing as! More)
        } else if thing is Comment {
            return CommentModel.commentToCommentModel(comment: thing as! Comment, depth: depth)
        }
        
        return nil
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

public extension MoreModel {
    //Takes a More from reddift and turns it into a Realm model
    static func moreToMoreModel(more: More) -> MoreModel {
        let managedContext = SlideCoreData.sharedInstance.backgroundContext
        let moreEntity = NSEntityDescription.entity(forEntityName: "MoreModel", in: managedContext)!
        let moreModel = NSManagedObject(entity: moreEntity, insertInto: managedContext) as! MoreModel

        if more.id.endsWith("_") {
            moreModel.id = "more_\(NSUUID().uuidString)"
        } else {
            moreModel.id = more.name
        }
        moreModel.name = more.name
        moreModel.parentID = more.parentId
        moreModel.count = Int32(more.count)
        moreModel.childrenString = more.children.joined()
        
        managedContext.performAndWait {
            do {
                try managedContext.save()
            } catch let error as NSError {
                print(error)
            }
        }

        return moreModel
    }
    
}
