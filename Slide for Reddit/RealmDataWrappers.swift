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
        let type = ContentType.getContentType(submission: submission)
        
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
        
        let previews = ((json?["preview"] as? [String: Any])?["images"] as? [Any])
        let preview  = ((previews?.first as? [String: Any])?["source"] as? [String: Any])?["url"] as? String
        
        
        
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
            if(previews != nil && !previews!.isEmpty){
                if (ContentType.isImgurImage(uri: submission.url!)) {
                    lqUrl = (submission.url?.absoluteString)!
                    lqUrl = lqUrl.substring(0, length: lqUrl.lastIndexOf(".")!) + (SettingValues.lqLow ? "m" : (SettingValues.lqMid ? "l" : "h")) + lqUrl.substring(lqUrl.lastIndexOf(".")!, length: lqUrl.length - lqUrl.lastIndexOf(".")!)
                } else {
                    let length = previews!.count
                    if (SettingValues.lqLow && length >= 3)
                    {
                        lqUrl = ((((previews!.first as! [String: Any])["resolutions"] as? [Any])?[2] as? [String: Any])?["url"] as? String)!
                    }
                    else if (SettingValues.lqMid && length >= 4)
                    {
                        lqUrl = ((((previews!.first as! [String: Any])["resolutions"] as? [Any])?[2] as? [String: Any])?["url"] as? String)!
                    }
                    else if (length >= 5)
                    {
                        lqUrl = ((((previews!.first as! [String: Any])["resolutions"] as? [Any])?[length - 1] as? [String: Any])?["url"] as? String)!
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
        rSubmission.created = NSDate(timeIntervalSince1970: TimeInterval(submission.created))
        rSubmission.isEdited = submission.edited > 0
        rSubmission.edited = NSDate(timeIntervalSince1970: TimeInterval(submission.edited))
        rSubmission.gilded = submission.gilded
        rSubmission.htmlBody = bodyHtml
        rSubmission.subreddit = submission.subreddit
        rSubmission.archived = submission.archived
        rSubmission.locked = submission.locked
        rSubmission.urlString = (submission.url?.absoluteString) ?? ""
        rSubmission.title = submission.title
        rSubmission.commentCount = submission.numComments
        rSubmission.saved = submission.saved
        rSubmission.stickied = submission.stickied
        rSubmission.visited = submission.visited
        rSubmission.bannerUrl = burl
        rSubmission.thumbnailUrl = turl
        rSubmission.thumbnail = thumb
        rSubmission.banner = big
        rSubmission.lqUrl = lqUrl
        rSubmission.lQ = lowq
        rSubmission.score = submission.score
        rSubmission.flair = flair
        rSubmission.voted = submission.likes != .none
        rSubmission.upvoteRatio = submission.upvoteRatio
        rSubmission.vote = submission.likes == .up
        rSubmission.name = submission.name
        rSubmission.height = h
        rSubmission.width = w
        rSubmission.isSelf = submission.isSelf
        rSubmission.permalink = submission.permalink
        return rSubmission
    }
    
    //Takes a Comment from reddift and turns it into a Realm model
    static func commentToRComment(comment: Comment) -> RComment {
        let flair = comment.authorFlairCssClass.isEmpty ? comment.authorFlairCssClass : comment.authorFlairText;
        let bodyHtml = comment.bodyHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
        let rComment = RComment()
        rComment.id = comment.getId()
        rComment.author = comment.author
        rComment.created = NSDate(timeIntervalSince1970: TimeInterval(comment.created))
        rComment.isEdited = comment.edited > 0
        rComment.edited = NSDate(timeIntervalSince1970: TimeInterval(comment.edited))
        rComment.gilded = comment.gilded
        rComment.htmlText = bodyHtml
        rComment.subreddit = comment.subreddit
        rComment.saved = comment.saved
        //todo rComment.pinned = comment.pinned
        rComment.score = comment.score
        rComment.flair = flair
        rComment.voted = comment.likes != .none
        rComment.vote = comment.likes == .up
        rComment.name = comment.name
        //todo rComment.permalink = comment.permalink
        return rComment
    }

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
    dynamic var subreddit = ""
    dynamic var archived = false
    dynamic var locked = false
    dynamic var urlString = ""
    var url: URL? {
        return URL.init(string: urlString)
    }
    dynamic var isEdited = false
    dynamic var title = ""
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
    dynamic var score = 0
    dynamic var upvoteRatio: Double = 0
    dynamic var flair = ""
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
    dynamic var subreddit = ""
    
    var url: URL? {
        return URL.init(string: urlString)
    }
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
    dynamic var author = ""
    dynamic var permalink = ""
    dynamic var created = NSDate(timeIntervalSince1970: 1)
    dynamic var edited = NSDate(timeIntervalSince1970: 1)
    dynamic var depth = 0
    dynamic var gilded = 0
    dynamic var htmlText = ""
    dynamic var pinned = false
    dynamic var controlvertial = false
    dynamic var isEdited = false
    dynamic var subreddit = ""
    dynamic var scoreHidden = false
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

class RSubmissionListing: Object {
    dynamic var name = ""
    dynamic var accessed = NSDate(timeIntervalSince1970: 1)
    dynamic var comments = false
    let submissions = List<RSubmission>()
}
