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
        let flair = submission.linkFlairText.isEmpty ? submission.linkFlairCssClass : submission.linkFlairText;
        let bodyHtml = submission.selftextHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
        
        var json: JSONDictionary? = nil
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
        let preview  = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["url"] as? String)
        
        if (preview != nil && !(preview?.isEmpty())!) {
            burl = (preview!.replacingOccurrences(of: "&amp;", with: "&"))
            w = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["width"] as? Int)!
            h = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["height"] as? Int)!
            big = true
        }
        
        let thumbnailType = ContentType.getThumbnailType(submission: submission)
        switch(thumbnailType){
        case .NSFW:
            thumb = true
            turl = "nsfw"
            break
        case .DEFAULT:
            thumb = true
            turl = "web"
            break
        case .SELF,  .NONE:
            thumb = false
            break
        case .URL:
            thumb = true
            turl = submission.thumbnail
            break
        }
        
        if(big){ //check for low quality image
            if(previews != nil && !(previews?.isEmpty)!){
                if (submission.url != nil && ContentType.isImgurImage(uri: submission.url!)) {
                    lqUrl = (submission.url?.absoluteString)!
                    lqUrl = lqUrl.substring(0, length: lqUrl.lastIndexOf(".")!) + (SettingValues.lqLow ? "m" : "l") + lqUrl.substring(lqUrl.lastIndexOf(".")!, length: lqUrl.length - lqUrl.lastIndexOf(".")!)
                } else {
                    let length = previews?.count
                    if (SettingValues.lqLow && length! >= 3)
                    {
                        lqUrl = ((previews?[1] as? [String: Any])?["url"] as? String)!
                    }
                    else if (length! >= 4)
                    {
                        lqUrl = ((previews?[2] as? [String: Any])?["url"] as? String)!
                    }
                    else if (length! >= 5)
                    {
                        lqUrl = ((previews?[length! - 1] as? [String: Any])?["url"] as? String)!
                    }
                    else
                    {
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
        rSubmission.gilded = submission.gilded
        rSubmission.htmlBody = bodyHtml
        rSubmission.subreddit = submission.subreddit
        rSubmission.archived = submission.archived
        rSubmission.locked = submission.locked
        rSubmission.urlString =  try! ((submission.url?.absoluteString) ?? "").convertHtmlSymbols() ?? ""
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
        rSubmission.height = h
        rSubmission.width = w
        rSubmission.distinguished = submission.distinguished
        rSubmission.isSelf = submission.isSelf
        rSubmission.body = submission.selftext
        rSubmission.permalink = submission.permalink
        return rSubmission
    }
    
    static func commentToRealm(comment: Thing, depth: Int) -> Object {
        if(comment is Comment) {
            return commentToRComment(comment: comment as! Comment, depth: depth)
        } else {
            return moreToRMore(more: comment as! More)
        }
    }
    
       //Takes a Comment from reddift and turns it into a Realm model
    static func commentToRComment(comment: Comment, depth: Int) -> RComment {
        let flair = comment.authorFlairCssClass.isEmpty ? comment.authorFlairCssClass : comment.authorFlairText;
        let bodyHtml = comment.bodyHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
        let rComment = RComment()
        rComment.id = comment.getId()
        rComment.author = comment.author
        rComment.created = NSDate(timeIntervalSince1970: TimeInterval(comment.createdUtc))
        rComment.isEdited = comment.edited > 0
        rComment.edited = NSDate(timeIntervalSince1970: TimeInterval(comment.edited))
        rComment.gilded = comment.gilded
        rComment.htmlText = bodyHtml
        rComment.subreddit = comment.subreddit
        rComment.submissionTitle = comment.submissionTitle
        rComment.saved = comment.saved
        rComment.body = comment.body
        //todo rComment.pinned = comment.pinned
        rComment.score = comment.score
        rComment.depth = depth
        rComment.flair = flair
        rComment.linkid = comment.linkId
        rComment.distinguished = comment.distinguished
        rComment.controversiality = comment.controversiality
        rComment.voted = comment.likes != .none
        rComment.vote = comment.likes == .up
        rComment.name = comment.name
        rComment.parentId = comment.parentId
        rComment.scoreHidden = comment.scoreHidden
        //todo rComment.permalink = comment.permalink
        return rComment
    }
    
    static func messageToRMessage(message: Message) -> RMessage {
       let title = message.baseJson["link_title"] as? String ?? ""
        let bodyHtml = message.bodyHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
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
        rMore.id = more.getId()
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
    override static func primaryKey() -> String? {
        return "id"
    }
    dynamic var created = NSDate(timeIntervalSince1970: 1)
    dynamic var subreddit = ""
    dynamic var id = ""
    let links = List<RSubmission>()
}

class RSubmission: Object {
    override static func primaryKey() -> String? {
        return "id"
    }
    dynamic var id = ""
    dynamic var name = ""
    dynamic var author = ""
    dynamic var created = NSDate(timeIntervalSince1970: 1)
    dynamic var edited = NSDate(timeIntervalSince1970: 1)
    dynamic var gilded = 0
    dynamic var htmlBody = ""
    dynamic var body = ""
    dynamic var title = ""
    dynamic var subreddit = ""
    dynamic var archived = false
    dynamic var locked = false
    dynamic var urlString = ""
    dynamic var distinguished = ""
    
    var type: ContentType.CType {
        if(isSelf){
            return .SELF
        }
        if url != nil {
        return ContentType.getContentType(baseUrl: url!)
        } else {
            return .NONE
        }
    }
    
    var url: URL? {
        return URL.init(string: self.urlString)
    }

    dynamic var isEdited = false
    dynamic var commentCount = 0
    dynamic var saved = false
    dynamic var stickied = false
    dynamic var visited = false
    dynamic var isSelf = false
    dynamic var permalink = ""
    dynamic var bannerUrl = ""
    dynamic var thumbnailUrl = ""
    dynamic var lqUrl = ""
    dynamic var lQ = false
    dynamic var thumbnail = false
    dynamic var banner = false
    dynamic var nsfw = false
    dynamic var score = 0
    dynamic var upvoteRatio: Double = 0
    dynamic var flair = ""
    dynamic var domain = ""
    dynamic var voted = false
    dynamic var height = 0
    dynamic var width = 0
    dynamic var vote = false
    let comments = List<RComment>()
    
    func getId() -> String {
        return id
    }
    
    var likes : VoteDirection {
        if(voted){
            if(vote){
                return .up
            } else {
                return .down
            }
        }
        return .none
    }
}

class RMessage: Object {
    override static func primaryKey() -> String? {
        return "id"
    }
    dynamic var id = ""
    dynamic var name = ""
    dynamic var author = ""
    dynamic var created = NSDate(timeIntervalSince1970: 1)
    dynamic var htmlBody = ""
    dynamic var isNew = false
    dynamic var linkTitle = ""
    dynamic var context = ""
    dynamic var wasComment  = false
    dynamic var subreddit = ""
    dynamic var subject = ""
    
    func getId() -> String {
        return id
    }
}


class RComment: Object {
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func getId() -> String {
        return id
    }

    dynamic var id = ""
    dynamic var name = ""
    dynamic var body = ""
    dynamic var author = ""
    dynamic var permalink = ""
    dynamic var created = NSDate(timeIntervalSince1970: 1)
    dynamic var edited = NSDate(timeIntervalSince1970: 1)
    dynamic var depth = 0
    dynamic var gilded = 0
    dynamic var htmlText = ""
    dynamic var distinguished = ""
    dynamic var linkid = ""
    dynamic var submissionTitle = ""
    dynamic var pinned = false
    dynamic var controversiality = 0
    dynamic var isEdited = false
    dynamic var subreddit = ""
    dynamic var scoreHidden = false
    dynamic var parentId = ""
    dynamic var score = 0
    dynamic var flair = ""
    dynamic var voted = false
    dynamic var vote = false
    dynamic var saved = false
    
    var likes : VoteDirection {
        if(voted){
            if(vote){
                return .up
            } else {
                return .down
            }
        }
        return .none
    }
}

class RString: Object {
    dynamic var value = ""
}

class RMore: Object {
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func getId() -> String {
        return id
    }
    dynamic var count = 0
    dynamic var id = ""
    dynamic var name = ""
    dynamic var parentId = ""
    let children = List<RString>()
}

class RSubmissionListing: Object {
    dynamic var name = ""
    dynamic var accessed = NSDate(timeIntervalSince1970: 1)
    dynamic var comments = false
    let submissions = List<RSubmission>()
}
extension String {
    func convertHtmlSymbols() throws -> String? {
        guard let data = data(using: .utf8) else { return nil }
        
        return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil).string
    }
}
extension String {
    init(htmlEncodedString: String) {
        self.init()
        guard let encodedData = htmlEncodedString.data(using: .utf8) else {
            self = htmlEncodedString
            return
        }
        
        let attributedOptions: [String : Any] = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue
        ]
        
        do {
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            self = attributedString.string
        } catch {
            print("Error: \(error)")
            self = htmlEncodedString
        }
    }
}


