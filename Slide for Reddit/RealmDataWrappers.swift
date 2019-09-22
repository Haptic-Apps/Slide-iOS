//
//  RealmDataWrappers.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/26/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import RealmSwift
import reddift

class RealmDataWrapper {
    
    //Takes a Link from reddift and turns it into a Realm model
    static func linkToRSubmission(submission: Link) -> RSubmission {
        let flair = submission.linkFlairText.isEmpty ? submission.linkFlairCssClass : submission.linkFlairText
        var bodyHtml = submission.selftextHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")
        bodyHtml = bodyHtml.replacingOccurrences(of: "<div class=\"md\">", with: "")
        
        var json: JSONDictionary?
        json = submission.baseJson
        
        var w: Int = 0
        var h: Int = 0
        var thumb = false //is thumbnail present
        var big = false //is big image present
        var lowq = false //is lq image present
        var burl: String = "" //banner url
        var turl: String = "" //thumbnail url
        var lqUrl: String = "" //lq banner url
        
        let previews = ((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["resolutions"] as? [Any])
        let preview = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["url"] as? String)
        
        var videoPreview = (((((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["variants"] as? [String: Any])?["mp4"] as? [String: Any])?["source"] as? [String: Any])?["url"] as? String)
        if videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil {
            videoPreview = (((json?["media"] as? [String: Any])?["reddit_video"] as? [String: Any])?["fallback_url"] as? String)
        }
        if videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil {
            videoPreview = (((json?["preview"] as? [String: Any])?["reddit_video_preview"] as? [String: Any])?["fallback_url"] as? String)
        }
        if (videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil) && json?["crosspost_parent_list"] != nil {
            videoPreview = (((((json?["crosspost_parent_list"] as? [Any])?.first as? [String: Any])?["preview"] as? [String: Any])?["reddit_video_preview"] as? [String: Any])?["fallback_url"] as? String)
        }
        
        if (videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil) && json?["crosspost_parent_list"] != nil {
            videoPreview = (((((json?["crosspost_parent_list"] as? [Any])?.first as? [String: Any])?["media"] as? [String: Any])?["reddit_video"] as? [String: Any])?["fallback_url"] as? String)
        }

        if preview != nil && !(preview?.isEmpty())! {
            burl = (preview!.replacingOccurrences(of: "&amp;", with: "&"))
            w = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["width"] as? Int)!
            if w < 200 {
                big = false
            } else {
                h = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["height"] as? Int)!
                big = true
            }
        }
        
        let thumbnailType = ContentType.getThumbnailType(submission: submission)
        switch thumbnailType {
        case .NSFW:
            thumb = true
            turl = "nsfw"
        case .DEFAULT:
            thumb = true
            turl = "web"
        case .SELF, .NONE:
            thumb = false
        case .URL:
            thumb = true
            turl = submission.thumbnail.removingPercentEncoding ?? submission.thumbnail
        }
        
        if big { //check for low quality image
            if previews != nil && !(previews?.isEmpty)! {
                if submission.url != nil && ContentType.isImgurImage(uri: submission.url!) {
                    lqUrl = (submission.url?.absoluteString)!
                    lqUrl = lqUrl.substring(0, length: lqUrl.lastIndexOf(".")!) + (SettingValues.lqLow ? "m" : "l") + lqUrl.substring(lqUrl.lastIndexOf(".")!, length: lqUrl.length - lqUrl.lastIndexOf(".")!)
                } else {
                    let length = previews?.count
                    if SettingValues.lqLow && length! >= 3 {
                        lqUrl = ((previews?[1] as? [String: Any])?["url"] as? String)!
                    } else if length! >= 4 {
                        lqUrl = ((previews?[2] as? [String: Any])?["url"] as? String)!
                    } else if length! >= 5 {
                        lqUrl = ((previews?[length! - 1] as? [String: Any])?["url"] as? String)!
                    } else {
                        lqUrl = preview!
                    }
                    lowq = true
                }
            }
            
        }
        let rSubmission = RSubmission()
        rSubmission.id = submission.getId()
        rSubmission.author = submission.author
        rSubmission.created = NSDate(timeIntervalSince1970: TimeInterval(submission.createdUtc))
        rSubmission.isEdited = submission.edited > 0
        rSubmission.edited = NSDate(timeIntervalSince1970: TimeInterval(submission.edited))
        rSubmission.silver = ((json?["gildings"] as? [String: Any])?["gid_1"] as? Int) ?? 0
        rSubmission.gold = ((json?["gildings"] as? [String: Any])?["gid_2"] as? Int) ?? 0
        rSubmission.platinum = ((json?["gildings"] as? [String: Any])?["gid_3"] as? Int) ?? 0
        rSubmission.gilded = rSubmission.silver + rSubmission.gold + rSubmission.platinum > 0
        rSubmission.htmlBody = bodyHtml
        rSubmission.subreddit = submission.subreddit
        rSubmission.archived = submission.archived
        rSubmission.locked = submission.locked
        do {
            try rSubmission.urlString = ((submission.url?.absoluteString) ?? "").convertHtmlSymbols() ?? ""
        } catch {
            rSubmission.urlString = (submission.url?.absoluteString) ?? ""
        }
        rSubmission.urlString = rSubmission.urlString.removingPercentEncoding ?? rSubmission.urlString
        rSubmission.title = submission.title
        rSubmission.commentCount = submission.numComments
        rSubmission.saved = submission.saved
        rSubmission.stickied = submission.stickied
        rSubmission.visited = submission.visited
        rSubmission.bannerUrl = burl
        rSubmission.thumbnailUrl = turl
        rSubmission.thumbnail = thumb
        rSubmission.nsfw = submission.over18
        rSubmission.banner = big
        rSubmission.lqUrl = String.init(htmlEncodedString: lqUrl)
        rSubmission.domain = submission.domain
        rSubmission.lQ = lowq
        rSubmission.score = submission.score
        rSubmission.flair = flair
        rSubmission.voted = submission.likes != .none
        rSubmission.upvoteRatio = submission.upvoteRatio
        rSubmission.vote = submission.likes == .up
        rSubmission.name = submission.id
        do {
            try rSubmission.videoPreview = (videoPreview ?? "").convertHtmlSymbols() ?? ""
        } catch {
            rSubmission.videoPreview = videoPreview ?? ""
        }

        rSubmission.height = h
        rSubmission.width = w
        rSubmission.distinguished = submission.distinguished.type
        rSubmission.canMod = submission.canMod
        rSubmission.isSelf = submission.isSelf
        rSubmission.body = submission.selftext
        rSubmission.permalink = submission.permalink
        rSubmission.canMod = submission.canMod
        rSubmission.spoiler = submission.baseJson["spoiler"] as? Bool ?? false
        rSubmission.oc = submission.baseJson["is_original_content"] as? Bool ?? false
        rSubmission.removedBy = submission.baseJson["banned_by"] as? String ?? ""
        rSubmission.removalReason = submission.baseJson["ban_note"] as? String ?? ""
        rSubmission.removalNote = submission.baseJson["mod_note"] as? String ?? ""
        rSubmission.removed = !rSubmission.removedBy.isEmpty()
        rSubmission.cakeday = submission.baseJson["author_cakeday"] as? Bool ?? false

        for item in submission.baseJson["mod_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            rSubmission.reports.append("\(array[0]): \(array[1])")
        }
        for item in submission.baseJson["user_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            rSubmission.reports.append("\(array[0]): \(array[1])")
        }
        
        rSubmission.awards.removeAll()
        for item in submission.baseJson["all_awardings"] as? [AnyObject] ?? [] {
            if let award = item as? JSONDictionary {
                if award["icon_url"] != nil && award["count"] != nil {
                    let name = award["name"] as? String ?? ""
                    if name != "Silver" && name != "Gold" && name != "Platinum" {
                        rSubmission.awards.append("\(award["icon_url"]!)*\(award["count"]!)")
                    }
                }
            }
        }

        rSubmission.approvedBy = submission.baseJson["approved_by"] as? String ?? ""
        rSubmission.approved = !rSubmission.approvedBy.isEmpty()
        
        if json?["crosspost_parent_list"] != nil {
            rSubmission.isCrosspost = true
            let sub = ((json?["crosspost_parent_list"] as? [Any])?.first as? [String: Any])?["subreddit"] as? String ?? ""
            let author = ((json?["crosspost_parent_list"] as? [Any])?.first as? [String: Any])?["author"] as? String ?? ""
            let permalink = ((json?["crosspost_parent_list"] as? [Any])?.first as? [String: Any])?["permalink"] as? String ?? ""
            rSubmission.crosspostSubreddit = sub
            rSubmission.crosspostAuthor = author
            rSubmission.crosspostPermalink = permalink
        }
        return rSubmission
    }
    
    //Takes a Link from reddift and turns it into a Realm model
    static func updateSubmission(_ rSubmission: RSubmission, _ submission: Link) -> RSubmission {
        let flair = submission.linkFlairText.isEmpty ? submission.linkFlairCssClass : submission.linkFlairText
        var bodyHtml = submission.selftextHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")
        bodyHtml = bodyHtml.replacingOccurrences(of: "<div class=\"md\">", with: "")
        
        var json: JSONDictionary?
        json = submission.baseJson
        
        var w: Int = 0
        var h: Int = 0
        var thumb = false //is thumbnail present
        var big = false //is big image present
        var lowq = false //is lq image present
        var burl: String = "" //banner url
        var turl: String = "" //thumbnail url
        var lqUrl: String = "" //lq banner url
        
        let previews = ((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["resolutions"] as? [Any])
        let preview = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["url"] as? String)
        
        var videoPreview = (((((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["variants"] as? [String: Any])?["mp4"] as? [String: Any])?["source"] as? [String: Any])?["url"] as? String)
        if videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil {
            videoPreview = (((json?["media"] as? [String: Any])?["reddit_video"] as? [String: Any])?["fallback_url"] as? String)
        }
        if videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil {
            videoPreview = (((json?["preview"] as? [String: Any])?["reddit_video_preview"] as? [String: Any])?["fallback_url"] as? String)
        }
        if (videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil) && json?["crosspost_parent_list"] != nil {
            videoPreview = (((((json?["crosspost_parent_list"] as? [Any])?.first as? [String: Any])?["preview"] as? [String: Any])?["reddit_video_preview"] as? [String: Any])?["fallback_url"] as? String)
        }
        if (videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil) && json?["crosspost_parent_list"] != nil {
            videoPreview = (((((json?["crosspost_parent_list"] as? [Any])?.first as? [String: Any])?["media"] as? [String: Any])?["reddit_video"] as? [String: Any])?["fallback_url"] as? String)
        }

        if preview != nil && !(preview?.isEmpty())! {
            burl = (preview!.replacingOccurrences(of: "&amp;", with: "&"))
            w = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["width"] as? Int)!
            if w < 200 {
                big = false
            } else {
                h = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["height"] as? Int)!
                big = true
            }
        }
        
        let thumbnailType = ContentType.getThumbnailType(submission: submission)
        switch thumbnailType {
        case .NSFW:
            thumb = true
            turl = "nsfw"
        case .DEFAULT:
            thumb = true
            turl = "web"
        case .SELF, .NONE:
            thumb = false
        case .URL:
            thumb = true
            turl = submission.thumbnail.removingPercentEncoding ?? submission.thumbnail
        }
        
        if big { //check for low quality image
            if previews != nil && !(previews?.isEmpty)! {
                if submission.url != nil && ContentType.isImgurImage(uri: submission.url!) {
                    lqUrl = (submission.url?.absoluteString)!
                    lqUrl = lqUrl.substring(0, length: lqUrl.lastIndexOf(".")!) + (SettingValues.lqLow ? "m" : "l") + lqUrl.substring(lqUrl.lastIndexOf(".")!, length: lqUrl.length - lqUrl.lastIndexOf(".")!)
                } else {
                    let length = previews?.count
                    if SettingValues.lqLow && length! >= 3 {
                        lqUrl = ((previews?[1] as? [String: Any])?["url"] as? String)!
                    } else if length! >= 4 {
                        lqUrl = ((previews?[2] as? [String: Any])?["url"] as? String)!
                    } else if length! >= 5 {
                        lqUrl = ((previews?[length! - 1] as? [String: Any])?["url"] as? String)!
                    } else {
                        lqUrl = preview!
                    }
                    lowq = true
                }
            }
            
        }
        
        rSubmission.awards.removeAll()
        for item in submission.baseJson["all_awardings"] as? [AnyObject] ?? [] {
            if let award = item as? JSONDictionary {
                if award["icon_url"] != nil && award["count"] != nil {
                    let name = award["name"] as? String ?? ""
                    if name != "Silver" && name != "Gold" && name != "Platinum" {
                        rSubmission.awards.append("\(award["icon_url"]!)*\(award["count"]!)")
                    }
                }
            }
        }

        rSubmission.author = submission.author
        rSubmission.created = NSDate(timeIntervalSince1970: TimeInterval(submission.createdUtc))
        rSubmission.isEdited = submission.edited > 0
        rSubmission.edited = NSDate(timeIntervalSince1970: TimeInterval(submission.edited))
        rSubmission.silver = ((submission.baseJson["gildings"] as? [String: Any])?["gid_1"] as? Int) ?? 0
        rSubmission.gold = ((submission.baseJson["gildings"] as? [String: Any])?["gid_2"] as? Int) ?? 0
        rSubmission.platinum = ((submission.baseJson["gildings"] as? [String: Any])?["gid_3"] as? Int) ?? 0
        rSubmission.gilded = rSubmission.silver + rSubmission.gold + rSubmission.platinum > 0
        rSubmission.htmlBody = bodyHtml
        rSubmission.subreddit = submission.subreddit
        rSubmission.archived = submission.archived
        rSubmission.locked = submission.locked
        rSubmission.canMod = submission.canMod
        do {
            try rSubmission.urlString = ((submission.url?.absoluteString) ?? "").convertHtmlSymbols() ?? ""
        } catch {
            rSubmission.urlString = (submission.url?.absoluteString) ?? ""
        }
        rSubmission.urlString = rSubmission.urlString.removingPercentEncoding ?? rSubmission.urlString
        rSubmission.title = submission.title
        rSubmission.commentCount = submission.numComments
        rSubmission.saved = submission.saved
        rSubmission.stickied = submission.stickied
        rSubmission.spoiler = submission.baseJson["spoiler"] as? Bool ?? false
        rSubmission.oc = submission.baseJson["is_original_content"] as? Bool ?? false
        rSubmission.visited = submission.visited
        rSubmission.bannerUrl = burl
        rSubmission.thumbnailUrl = turl
        rSubmission.thumbnail = thumb
        rSubmission.removedBy = submission.baseJson["banned_by"] as? String ?? ""
        rSubmission.removalReason = submission.baseJson["ban_note"] as? String ?? ""
        rSubmission.removalNote = submission.baseJson["mod_note"] as? String ?? ""
        rSubmission.removed = !rSubmission.removedBy.isEmpty()
        rSubmission.nsfw = submission.over18
        rSubmission.banner = big
        rSubmission.lqUrl = String.init(htmlEncodedString: lqUrl)
        rSubmission.domain = submission.domain
        rSubmission.lQ = lowq
        rSubmission.score = submission.score
        rSubmission.flair = flair
        rSubmission.voted = submission.likes != .none
        rSubmission.upvoteRatio = submission.upvoteRatio
        rSubmission.vote = submission.likes == .up
        rSubmission.name = submission.id
        rSubmission.height = h
        rSubmission.width = w
        rSubmission.distinguished = submission.distinguished.type
        rSubmission.isSelf = submission.isSelf
        rSubmission.body = submission.selftext
        rSubmission.permalink = submission.permalink
        do {
            try rSubmission.videoPreview = (videoPreview ?? "").convertHtmlSymbols() ?? ""
        } catch {
            rSubmission.videoPreview = videoPreview ?? ""
        }
        rSubmission.cakeday = submission.baseJson["author_cakeday"] as? Bool ?? false

        if json?["crosspost_parent_list"] != nil {
            rSubmission.isCrosspost = true
            let sub = ((json?["crosspost_parent_list"] as? [Any])?.first as? [String: Any])?["subreddit"] as? String ?? ""
            let author = ((json?["crosspost_parent_list"] as? [Any])?.first as? [String: Any])?["author"] as? String ?? ""
            let permalink = ((json?["crosspost_parent_list"] as? [Any])?.first as? [String: Any])?["permalink"] as? String ?? ""
            rSubmission.crosspostSubreddit = sub
            rSubmission.crosspostAuthor = author
            rSubmission.crosspostPermalink = permalink
        }

        rSubmission.reports.removeAll()
        for item in submission.baseJson["mod_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            rSubmission.reports.append("\(array[0]): \(array[1])")
        }
        for item in submission.baseJson["user_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            rSubmission.reports.append("\(array[0]): \(array[1])")
        }
        rSubmission.approvedBy = submission.baseJson["approved_by"] as? String ?? ""
        rSubmission.approved = !rSubmission.approvedBy.isEmpty()
        return rSubmission
    }
    
    static func friendToRealm(user: User) -> Object {
        let rFriend = RFriend()
        rFriend.name = user.name
        rFriend.friendSince = NSDate(timeIntervalSince1970: TimeInterval(user.date))
        return rFriend
    }
    
    static func commentToRealm(comment: Thing, depth: Int) -> Object {
        if comment is Comment {
            return commentToRComment(comment: comment as! Comment, depth: depth)
        } else {
            return moreToRMore(more: comment as! More)
        }
    }
    
    //Takes a Comment from reddift and turns it into a Realm model
    static func commentToRComment(comment: Comment, depth: Int) -> RComment {
        let flair = comment.authorFlairText.isEmpty ? comment.authorFlairCssClass : comment.authorFlairText
        var bodyHtml = comment.bodyHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")

        bodyHtml = bodyHtml.replacingOccurrences(of: "<div class=\"md\">", with: "")
        let rComment = RComment()
        let json = comment.baseJson
        rComment.id = comment.getId()
        rComment.author = comment.author
        rComment.created = NSDate(timeIntervalSince1970: TimeInterval(comment.createdUtc))
        rComment.isEdited = comment.edited > 0
        rComment.edited = NSDate(timeIntervalSince1970: TimeInterval(comment.edited))
        rComment.silver = ((json["gildings"] as? [String: Any])?["gid_1"] as? Int) ?? 0
        rComment.gold = ((json["gildings"] as? [String: Any])?["gid_2"] as? Int) ?? 0
        rComment.platinum = ((json["gildings"] as? [String: Any])?["gid_3"] as? Int) ?? 0
        rComment.gilded = rComment.silver + rComment.gold + rComment.platinum > 0
        rComment.htmlText = bodyHtml
        rComment.subreddit = comment.subreddit
        rComment.submissionTitle = comment.submissionTitle
        rComment.saved = comment.saved
        rComment.body = comment.body
        rComment.removalReason = comment.baseJson["ban_note"] as? String ?? ""
        rComment.removalNote = comment.baseJson["mod_note"] as? String ?? ""
        rComment.removedBy = comment.baseJson["banned_by"] as? String ?? ""
        rComment.removed = !rComment.removedBy.isEmpty()
        rComment.approvedBy = comment.baseJson["approved_by"] as? String ?? ""
        rComment.approved = !rComment.approvedBy.isEmpty()
        rComment.sticky = comment.stickied
        rComment.flair = flair
        rComment.cakeday = comment.baseJson["author_cakeday"] as? Bool ?? false

        let richtextFlairs = (json["author_flair_richtext"] as? [Any])
        if richtextFlairs != nil && richtextFlairs!.count > 0 {
            for flair in richtextFlairs! {
                if let flairDict = flair as? [String: Any] {
                    if flairDict["e"] != nil && flairDict["e"] as! String == "emoji" {
                        rComment.urlFlair = ((flairDict["u"] as? String) ?? "").decodeHTML().trimmed()
                    } else if flairDict["e"] != nil && flairDict["e"] as! String == "text" {
                        rComment.flair = ((flairDict["t"] as? String) ?? "").decodeHTML().trimmed()
                    }
                }
            }
        }

        for item in comment.modReports {
            let array = item as! [Any]
            rComment.reports.append("\(array[0]): \(array[1])")
        }
        for item in comment.userReports {
            let array = item as! [Any]
            rComment.reports.append("\(array[0]): \(array[1])")
        }
       // TODO: - rComment.pinned = comment.pinned
        rComment.score = comment.score
        rComment.depth = depth
        
        rComment.canMod = comment.canMod
        rComment.linkid = comment.linkId
        rComment.archived = comment.archived
        rComment.distinguished = comment.distinguished.type
        rComment.controversiality = comment.controversiality
        rComment.voted = comment.likes != .none
        rComment.vote = comment.likes == .up
        rComment.name = comment.name
        rComment.parentId = comment.parentId
        rComment.scoreHidden = comment.scoreHidden
        rComment.permalink = "https://www.reddit.com" + comment.permalink
        return rComment
    }
    
    static func messageToRMessage(message: Message) -> RMessage {
        let title = message.baseJson["link_title"] as? String ?? ""
        var bodyHtml = message.bodyHtml.replacingOccurrences(of: "<blockquote>", with: "<cite>").replacingOccurrences(of: "</blockquote>", with: "</cite>")
        bodyHtml = bodyHtml.replacingOccurrences(of: "<div class=\"md\">", with: "")
        let rMessage = RMessage()
        rMessage.htmlBody = bodyHtml
        rMessage.name = message.name
        rMessage.id = message.getId()
        
        rMessage.author = message.author
        rMessage.subreddit = message.subreddit
        rMessage.created = NSDate(timeIntervalSince1970: TimeInterval(message.createdUtc))
        rMessage.isNew = message.new
        rMessage.linkTitle = title
        rMessage.context = message.context
        rMessage.wasComment = message.wasComment
        rMessage.subject = message.subject
        return rMessage
    }
    
    //Takes a More from reddift and turns it into a Realm model
    static func moreToRMore(more: More) -> RMore {
        let rMore = RMore()
        if more.getId().endsWith("_") {
            rMore.id = "more_\(NSUUID().uuidString)"
        } else {
            rMore.id = more.getId()
        }
        rMore.name = more.name
        rMore.parentId = more.parentId
        rMore.count = more.count
        for s in more.children {
            let str = RString()
            str.value = s
            rMore.children.append(str)
        }
        return rMore
    }
    
}

class RListing: Object {
    override class func primaryKey() -> String? {
        return "subreddit"
    }
    
    @objc dynamic var updated = NSDate(timeIntervalSince1970: 1)
    @objc dynamic var subreddit = ""
    @objc dynamic var comments = false
    let links = List<RSubmission>()
}

class RSubmission: Object {
    override class func primaryKey() -> String? {
        return "id"
    }
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var author = ""
    @objc dynamic var created = NSDate(timeIntervalSince1970: 1)
    @objc dynamic var edited = NSDate(timeIntervalSince1970: 1)
    @objc dynamic var gilded = false
    @objc dynamic var gold = 0
    @objc dynamic var silver = 0
    @objc dynamic var platinum = 0
    @objc dynamic var htmlBody = ""
    @objc dynamic var body = ""
    @objc dynamic var title = ""
    @objc dynamic var subreddit = ""
    @objc dynamic var archived = false
    @objc dynamic var locked = false
    @objc dynamic var urlString = ""
    @objc dynamic var distinguished = ""
    @objc dynamic var videoPreview = ""
    @objc dynamic var isCrosspost = false
    @objc dynamic var spoiler = false
    @objc dynamic var oc = false
    @objc dynamic var canMod = false
    @objc dynamic var crosspostAuthor = ""
    @objc dynamic var crosspostSubreddit = ""
    @objc dynamic var crosspostPermalink = ""
    @objc dynamic var cakeday = false
    
    var type: ContentType.CType {
        if isSelf {
            return .SELF
        }
        if url != nil {
            return ContentType.getContentType(baseUrl: url)
        } else {
            return .NONE
        }
    }
    
    var url: URL? {
        return URL.init(string: self.urlString)
    }
    
    var reports = List<String>()
    var awards = List<String>()
    @objc dynamic var removedBy = ""
    @objc dynamic var removed = false
    @objc dynamic var approvedBy = ""
    @objc dynamic var approved = false
    @objc dynamic var removalReason = ""
    @objc dynamic var removalNote = ""
    
    @objc dynamic var isEdited = false
    @objc dynamic var commentCount = 0
    @objc dynamic var saved = false
    @objc dynamic var stickied = false
    @objc dynamic var visited = false
    @objc dynamic var isSelf = false
    @objc dynamic var permalink = ""
    @objc dynamic var bannerUrl = ""
    @objc dynamic var thumbnailUrl = ""
    @objc dynamic var lqUrl = ""
    @objc dynamic var lQ = false
    @objc dynamic var thumbnail = false
    @objc dynamic var banner = false
    @objc dynamic var nsfw = false
    @objc dynamic var score = 0
    @objc dynamic var upvoteRatio: Double = 0
    @objc dynamic var flair = ""
    @objc dynamic var domain = ""
    @objc dynamic var voted = false
    @objc dynamic var height = 0
    @objc dynamic var width = 0
    @objc dynamic var vote = false
    let comments = List<RComment>()
    
    func getId() -> String {
        return id
    }
    
    var likes: VoteDirection {
        if voted {
            if vote {
                return .up
            } else {
                return .down
            }
        }
        return .none
    }
}

class RMessage: Object {
    override class func primaryKey() -> String? {
        return "id"
    }
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var author = ""
    @objc dynamic var created = NSDate(timeIntervalSince1970: 1)
    @objc dynamic var htmlBody = ""
    @objc dynamic var isNew = false
    @objc dynamic var linkTitle = ""
    @objc dynamic var context = ""
    @objc dynamic var wasComment = false
    @objc dynamic var subreddit = ""
    @objc dynamic var subject = ""
    
    func getId() -> String {
        return id
    }
}

class RComment: Object {
    override class func primaryKey() -> String? {
        return "id"
    }
    
    func getId() -> String {
        return id
    }
    
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var body = ""
    @objc dynamic var author = ""
    @objc dynamic var permalink = ""
    var reports = List<String>()
    @objc dynamic var removedBy = ""
    @objc dynamic var removalReason = ""
    @objc dynamic var removalNote = ""
    @objc dynamic var approvedBy = ""
    @objc dynamic var approved = false
    @objc dynamic var removed = false
    @objc dynamic var created = NSDate(timeIntervalSince1970: 1)
    @objc dynamic var edited = NSDate(timeIntervalSince1970: 1)
    @objc dynamic var depth = 0
    @objc dynamic var gilded = false
    @objc dynamic var gold = 0
    @objc dynamic var silver = 0
    @objc dynamic var platinum = 0
    @objc dynamic var htmlText = ""
    @objc dynamic var distinguished = ""
    @objc dynamic var linkid = ""
    @objc dynamic var canMod = false
    @objc dynamic var sticky = false
    @objc dynamic var submissionTitle = ""
    @objc dynamic var pinned = false
    @objc dynamic var controversiality = 0
    @objc dynamic var isEdited = false
    @objc dynamic var subreddit = ""
    @objc dynamic var scoreHidden = false
    @objc dynamic var parentId = ""
    @objc dynamic var archived = false
    @objc dynamic var score = 0
    @objc dynamic var flair = ""
    @objc dynamic var voted = false
    @objc dynamic var vote = false
    @objc dynamic var saved = false
    @objc dynamic var cakeday = false
    
    @objc dynamic var urlFlair = ""
    
    var likes: VoteDirection {
        if voted {
            if vote {
                return .up
            } else {
                return .down
            }
        }
        return .none
    }
}

class RString: Object {
    @objc dynamic var value = ""
}

class RMore: Object {
    override class func primaryKey() -> String? {
        return "id"
    }
    
    func getId() -> String {
        return id
    }
    
    @objc dynamic var count = 0
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var parentId = ""
    let children = List<RString>()
}

class RSubmissionListing: Object {
    @objc dynamic var name = ""
    @objc dynamic var accessed = NSDate(timeIntervalSince1970: 1)
    @objc dynamic var comments = false
    let submissions = List<RSubmission>()
}

class RFriend: Object {
    @objc dynamic var name = ""
    @objc dynamic var friendSince = NSDate(timeIntervalSince1970: 1)
}

extension String {
    func convertHtmlSymbols() throws -> String? {
        guard let data = data(using: .utf8) else {
            return nil
        }
        
        return try NSAttributedString(data: data, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary([convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType): convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.html), convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.characterEncoding): String.Encoding.utf8.rawValue]), documentAttributes: nil).string
    }
}

extension String {
    init(htmlEncodedString: String) {
        self.init()
        guard let encodedData = htmlEncodedString.data(using: .utf8) else {
            self = htmlEncodedString
            return
        }
        
        let attributedOptions: [String: Any] = [
            convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType): convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.html),
            convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.characterEncoding): String.Encoding.utf8.rawValue,
            ]
        
        do {
            let attributedString = try NSAttributedString(data: encodedData, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary(attributedOptions), documentAttributes: nil)
            self = attributedString.string
        } catch {
            print("Error: \(error)")
            self = htmlEncodedString
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringDocumentReadingOptionKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.DocumentReadingOptionKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.DocumentReadingOptionKey(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringDocumentAttributeKey(_ input: NSAttributedString.DocumentAttributeKey) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringDocumentType(_ input: NSAttributedString.DocumentType) -> String {
	return input.rawValue
}
