//
//  Submission+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/5/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreData
import reddift
import UIKit

public extension Submission {
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
    
    internal var type: ContentType.CType {
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
        if let link = contentUrl, let url = URL(string: link) {
            return url
        }
        return nil
    }
    
    //Takes a Link from reddift and turns it into a Realm model
    static func linkToSubmission(submission: Link) -> Submission {
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
        
        var videoPreview = (((json?["media"] as? [String: Any])?["reddit_video"] as? [String: Any])?["hls_url"] as? String)
        
        if videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil {
            videoPreview = (((json?["media"] as? [String: Any])?["reddit_video"] as? [String: Any])?["fallback_url"] as? String)
        }
        if videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil {
            videoPreview = (((json?["preview"] as? [String: Any])?["reddit_video_preview"] as? [String: Any])?["fallback_url"] as? String)
        }
        if videoPreview != nil && videoPreview!.isEmpty || videoPreview == nil {
            videoPreview = (((((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["variants"] as? [String: Any])?["mp4"] as? [String: Any])?["source"] as? [String: Any])?["url"] as? String)
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
        
        let type = ContentType.getContentType(baseUrl: submission.url)
        if big { //check for low quality image
            if previews != nil && !(previews?.isEmpty)! {
                if submission.url != nil && type == .IMGUR {
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
        let Submission = Submission()
        do {
            try Submission.smallPreview = ((previews?.first as? [String: Any])?["url"] as? String)?.convertHtmlSymbols() ?? ""
        } catch {
            
        }
        
        Submission.subreddit_icon = ((json?["sr_detail"] as? [String: Any])?["icon_img"] as? String ?? ((json?["sr_detail"] as? [String: Any])?["community_icon"] as? String ?? ""))

        Submission.id = submission.getId()
        Submission.author = submission.author
        Submission.created = NSDate(timeIntervalSince1970: TimeInterval(submission.createdUtc))
        Submission.isEdited = submission.edited > 0
        Submission.edited = NSDate(timeIntervalSince1970: TimeInterval(submission.edited))
        Submission.silver = ((json?["gildings"] as? [String: Any])?["gid_1"] as? Int) ?? 0
        Submission.gold = ((json?["gildings"] as? [String: Any])?["gid_2"] as? Int) ?? 0
        Submission.platinum = ((json?["gildings"] as? [String: Any])?["gid_3"] as? Int) ?? 0
        Submission.htmlBody = bodyHtml
        Submission.subreddit = submission.subreddit
        Submission.archived = submission.archived
        Submission.locked = submission.locked
        do {
            try Submission.urlString = ((submission.url?.absoluteString) ?? "").convertHtmlSymbols() ?? ""
        } catch {
            Submission.urlString = (submission.url?.absoluteString) ?? ""
        }
        Submission.urlString = Submission.urlString.removingPercentEncoding ?? Submission.urlString
        Submission.title = submission.title
        Submission.commentCount = submission.numComments
        Submission.saved = submission.saved
        Submission.stickied = submission.stickied
        Submission.visited = submission.visited
        Submission.bannerUrl = burl
        Submission.thumbnailUrl = turl
        Submission.thumbnail = thumb
        Submission.nsfw = submission.over18
        Submission.banner = big
        Submission.lqUrl = String.init(htmlEncodedString: lqUrl)
        Submission.domain = submission.domain
        Submission.lQ = lowq
        Submission.score = submission.score
        Submission.flair = flair
        Submission.voted = submission.likes != .none
        Submission.upvoteRatio = submission.upvoteRatio
        Submission.vote = submission.likes == .up
        Submission.name = submission.id
        do {
            try Submission.videoPreview = (videoPreview ?? "").convertHtmlSymbols() ?? ""
        } catch {
            Submission.videoPreview = videoPreview ?? ""
        }
        
        do {
            try Submission.videoMP4 = ((((((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["variants"] as? [String: Any])?["mp4"] as? [String: Any])?["source"] as? [String: Any])?["url"] as? String) ?? "").convertHtmlSymbols() ?? ""
        } catch {
            Submission.videoMP4 = ""
        }
        
        if Submission.videoMP4 == "" {
            do {
                try Submission.videoMP4 = ((((json?["media"] as? [String: Any])?["reddit_video"] as? [String: Any])?["fallback_url"] as? String) ?? "").convertHtmlSymbols() ?? ""
            } catch {
                Submission.videoMP4 = ""
            }
        }

        Submission.height = h
        Submission.width = w
        Submission.distinguished = submission.distinguished.type
        Submission.canMod = submission.canMod
        Submission.isSelf = submission.isSelf
        Submission.body = submission.selftext
        Submission.permalink = submission.permalink
        Submission.canMod = submission.canMod
        Submission.spoiler = submission.baseJson["spoiler"] as? Bool ?? false
        Submission.oc = submission.baseJson["is_original_content"] as? Bool ?? false
        Submission.removedBy = submission.baseJson["banned_by"] as? String ?? ""
        Submission.removalReason = submission.baseJson["ban_note"] as? String ?? ""
        Submission.removalNote = submission.baseJson["mod_note"] as? String ?? ""
        Submission.removed = !Submission.removedBy.isEmpty()
        Submission.cakeday = submission.baseJson["author_cakeday"] as? Bool ?? false
        Submission.hidden = submission.baseJson["hidden"] as? Bool ?? false

        for item in submission.baseJson["mod_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            Submission.reports.append("\(array[0]): \(array[1])")
        }
        for item in submission.baseJson["user_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            Submission.reports.append("\(array[0]): \(array[1])")
        }
        
        let jsonDict = NSMutableDictionary()
        for item in submission.baseJson["all_awardings"] as? [AnyObject] ?? [] {
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
        Submission.awardsJSON = jsonDict.jsonString()
        
        let flairDict = NSMutableDictionary()
        for item in submission.baseJson["link_flair_richtext"] as? [AnyObject] ?? [] {
            if let flair = item as? JSONDictionary {
                if flair["e"] as? String == "text" {
                    if let title = (flair["t"] as? String)?.unescapeHTML {
                        if let color = submission.baseJson["link_flair_background_color"] as? String, !color.isEmpty {
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
        Submission.flairJSON = flairDict.jsonString()

        Submission.gallery.removeAll()
        for item in (submission.baseJson["gallery_data"] as? JSONDictionary)?["items"] as? [JSONDictionary] ?? [] {
            if let image = (submission.baseJson["media_metadata"] as? JSONDictionary)?[item["media_id"] as! String]  as? JSONDictionary {
                if image["s"] != nil && (image["s"] as? JSONDictionary)?["u"] != nil {
                    Submission.gallery.append((image["s"] as? JSONDictionary)?["u"] as! String)
                }
            }
        }


        Submission.pollOptions.removeAll()
        for item in (submission.baseJson["poll_data"] as? JSONDictionary)?["options"] as? [AnyObject] ?? [] {
            if let poll = item as? JSONDictionary {
                if poll["text"] != nil {
                    let name = poll["text"] as? String ?? ""
                    let amount = poll["vote_count"] as? Int ?? -1
                    Submission.pollOptions.append("\(name);\(amount)")
                }
            }
        }
        
        Submission.pollTotal = (submission.baseJson["poll_data"] as? JSONDictionary)?["total_vote_count"] as? Int ?? 0

        Submission.gilded = Submission.silver + Submission.gold + Submission.platinum + jsonDict.allKeys.count > 0

        Submission.approvedBy = submission.baseJson["approved_by"] as? String ?? ""
        Submission.approved = !Submission.approvedBy.isEmpty()
        
        if let crosspostParent = json?["crosspost_parent_list"] as? [Any] {
            Submission.isCrosspost = true
            let sub = (crosspostParent.first as? [String: Any])?["subreddit"] as? String ?? ""
            let author = (crosspostParent.first as? [String: Any])?["author"] as? String ?? ""
            let permalink = (crosspostParent.first as? [String: Any])?["permalink"] as? String ?? ""
            Submission.crosspostSubreddit = sub
            Submission.crosspostAuthor = author
            Submission.crosspostPermalink = permalink
            
            Submission.gallery.removeAll()
            for item in ((crosspostParent.first as? [String: Any])?["gallery_data"] as? JSONDictionary)?["items"] as? [JSONDictionary] ?? [] {
                if let image = ((crosspostParent.first as? [String: Any])?["media_metadata"] as? JSONDictionary)?[item["media_id"] as! String]  as? JSONDictionary {
                    if image["s"] != nil && (image["s"] as? JSONDictionary)?["u"] != nil {
                        Submission.gallery.append((image["s"] as? JSONDictionary)?["u"] as! String)
                    }
                }
            }
        }

        return Submission
    }


}
