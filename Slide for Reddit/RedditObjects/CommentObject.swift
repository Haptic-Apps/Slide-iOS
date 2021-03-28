//
//  CommentObject.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/7/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import Foundation
import reddift

class CommentObject: RedditObject {
    public var approvedBy: String?
    public var author: String = ""
    public var awardsJSON: String?
    public var controversality: Int
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
    public var authorProfileImage: String?
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
    
    convenience init() {
        self.init(comment: Comment(id: ""), depth: -1)
    }
    
    convenience init(model: CommentModel) {
        self.init()
        
        self.approvedBy = model.approvedBy
        self.author = model.author
        self.awardsJSON = model.awardsJSON
        self.controversality = Int(model.controversality)
        self.created = model.created
        self.depth = Int(model.depth)
        self.distinguished = model.distinguished
        self.edited = model.edited
        self.flairJSON = model.flairJSON
        self.hasVoted = model.hasVoted
        self.hidden = model.hidden
        self.htmlBody = model.htmlBody
        self.id = model.id
        self.isApproved = model.isApproved
        self.isArchived = model.isArchived
        self.isCakeday = model.isCakeday
        self.isEdited = model.isEdited
        self.isMod = model.isMod
        self.isRemoved = model.isRemoved
        self.isSaved = model.isSaved
        self.isStickied = model.isStickied
        self.linkID = model.linkID
        self.locked = model.locked
        self.markdownBody = model.markdownBody
        self.name = model.name
        self.parentID = model.parentID
        self.permalink = model.permalink
        self.removalNote = model.removalNote
        self.authorProfileImage = model.authorProfileImage
        
        self.removalReason = model.removalReason
        self.removedBy = model.removedBy
        self.reportsJSON = model.reportsJSON
        self.score = Int(model.score)
        self.submissionTitle = model.submissionTitle
        self.subreddit = model.subreddit
    }

    public init(comment: Comment, depth: Int) {
        let bodyHtml = comment.bodyHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")

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
        self.authorProfileImage = comment.baseJson["profile_img"] as? String
        self.removalNote = comment.baseJson["mod_note"] as? String ?? ""
        self.removedBy = comment.baseJson["banned_by"] as? String ?? ""
        self.isRemoved = !(self.removedBy ?? "").isEmpty()
        self.approvedBy = comment.baseJson["approved_by"] as? String ?? ""
        self.isApproved = !(self.approvedBy ?? "").isEmpty()
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
                    
                    // HD icon
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
        
        if flairDict.allKeys.isEmpty {
            if !comment.authorFlairText.isEmpty {
                flairDict[comment.authorFlairText] = [:]
            } else if !comment.authorFlairCssClass.isEmpty {
                flairDict[comment.authorFlairCssClass] = [:]
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
        self.controversality = comment.controversiality
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

extension CommentObject: Cacheable {    
    func insertSelf(into context: NSManagedObjectContext, andSave: Bool) -> NSManagedObject? {
        context.performAndWaitReturnable {
            var commentModel: CommentModel! = nil
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CommentModel")
            let predicate = NSPredicate(format: "id = %@", self.getId())
            fetchRequest.predicate = predicate
            do {
                let results = try context.fetch(fetchRequest) as! [CommentModel]
                commentModel = results.first
            } catch {
                
            }
            if commentModel == nil {
                commentModel = NSEntityDescription.insertNewObject(forEntityName: "CommentModel", into: context) as? CommentModel
            }

            commentModel.approvedBy = self.approvedBy
            commentModel.author = self.author
            commentModel.authorProfileImage = self.authorProfileImage
            commentModel.awardsJSON = self.awardsJSON
            commentModel.controversality = Int64(self.controversality)
            commentModel.created = self.created
            commentModel.depth = Int64(self.depth)
            commentModel.distinguished = self.distinguished
            commentModel.edited = self.edited ?? Date()
            commentModel.flairJSON = self.flairJSON
            commentModel.hasVoted = self.hasVoted
            commentModel.hidden = self.hidden
            commentModel.htmlBody = self.htmlBody
            commentModel.id = self.id
            commentModel.isApproved = self.isApproved
            commentModel.isArchived = self.isArchived
            commentModel.isCakeday = self.isCakeday
            commentModel.isEdited = self.isEdited
            commentModel.isMod = self.isMod
            commentModel.isRemoved = self.isRemoved
            commentModel.isSaved = self.isSaved
            commentModel.isStickied = self.isStickied
            commentModel.linkID = self.linkID
            commentModel.locked = self.locked
            commentModel.score = Int64(self.score)
            commentModel.markdownBody = self.markdownBody
            commentModel.name = self.name
            commentModel.parentID = self.parentID
            commentModel.permalink = self.permalink
            commentModel.removalNote = self.removalNote
            commentModel.removalReason = self.removalReason
            commentModel.saveDate = Date()
            
            commentModel.removalReason = self.removalReason
            commentModel.removedBy = self.removedBy
            commentModel.reportsJSON = self.reportsJSON
            commentModel.score = Int64(self.score)
            commentModel.submissionTitle = self.submissionTitle
            commentModel.subreddit = self.subreddit

            if andSave {
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Failed to save managed context \(error): \(error.userInfo)")
                    return nil
                }
            }
            
            return commentModel
        }
    }
}
