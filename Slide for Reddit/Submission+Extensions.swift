//
//  submissionModel+Extensions.swift
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
        let managedContext = SlideCoreData.sharedInstance.backgroundContext
        let submissionEntity = NSEntityDescription.entity(forEntityName: "Submission", in: managedContext)!
        let submissionModel = NSManagedObject(entity: submissionEntity, insertInto: managedContext) as! Submission
        
        return submissionModel.update(submission: submission, context: SlideCoreData.sharedInstance.backgroundContext)
    }
    
    func update(submission: Link, context: NSManagedObjectContext) -> Submission {
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
        
        do {
            try self.smallPreview = ((previews?.first as? [String: Any])?["url"] as? String)?.convertHtmlSymbols() ?? ""
        } catch {
            
        }
        
        self.subredditIcon = ((json?["sr_detail"] as? [String: Any])?["icon_img"] as? String ?? ((json?["sr_detail"] as? [String: Any])?["community_icon"] as? String ?? ""))

        self.id = submission.getId()
        self.author = submission.author
        self.created = Date(timeIntervalSince1970: TimeInterval(submission.createdUtc))
        self.isEdited = submission.edited > 0
        self.edited = Date(timeIntervalSince1970: TimeInterval(submission.edited))
        self.htmlBody = bodyHtml
        self.subreddit = submission.subreddit
        self.isArchived = submission.archived
        self.isLocked = submission.locked
        do {
            try self.contentUrl = ((submission.url?.absoluteString) ?? "").convertHtmlSymbols() ?? ""
        } catch {
            self.contentUrl = (submission.url?.absoluteString) ?? ""
        }
        self.contentUrl = self.contentUrl?.removingPercentEncoding ?? self.contentUrl
        
        self.title = submission.title
        self.commentCount = Int32(submission.numComments)
        self.isSaved = submission.saved
        self.isStickied = submission.stickied
        self.isVisited = submission.visited
        self.bannerUrl = burl
        self.thumbnailUrl = turl
        self.hasThumbnail = thumb
        self.isNSFW = submission.over18
        self.hasBanner = big
        self.lqURL = String.init(htmlEncodedString: lqUrl)
        self.domain = submission.domain
        self.isLQ = lowq
        self.score = Int32(submission.score)
        self.hasVoted = submission.likes != .none
        self.upvoteRatio = submission.upvoteRatio
        self.voteDirection = submission.likes == .up
        self.name = submission.name
        do {
            try self.videoPreview = (videoPreview ?? "").convertHtmlSymbols() ?? ""
        } catch {
            self.videoPreview = videoPreview ?? ""
        }
        
        do {
            try self.videoMP4 = ((((((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["variants"] as? [String: Any])?["mp4"] as? [String: Any])?["source"] as? [String: Any])?["url"] as? String) ?? "").convertHtmlSymbols() ?? ""
        } catch {
            self.videoMP4 = ""
        }
        
        if self.videoMP4 == "" {
            do {
                try self.videoMP4 = ((((json?["media"] as? [String: Any])?["reddit_video"] as? [String: Any])?["fallback_url"] as? String) ?? "").convertHtmlSymbols() ?? ""
            } catch {
                self.videoMP4 = ""
            }
        }

        self.imageHeight = Int32(h)
        self.imageWidth = Int32(w)
        self.distinguished = submission.distinguished.type
        self.isMod = submission.canMod
        self.isSelf = submission.isSelf
        self.markdownBody = submission.selftext
        self.permalink = submission.permalink

        self.isSpoiler = submission.baseJson["spoiler"] as? Bool ?? false
        self.isOC = submission.baseJson["is_original_content"] as? Bool ?? false
        self.removedBy = submission.baseJson["banned_by"] as? String ?? ""
        self.removalReason = submission.baseJson["ban_note"] as? String ?? ""
        self.removalNote = submission.baseJson["mod_note"] as? String ?? ""
        self.isRemoved = !(self.removedBy ?? "").isEmpty()
        self.isCakeday = submission.baseJson["author_cakeday"] as? Bool ?? false
        self.hidden = submission.baseJson["hidden"] as? Bool ?? false

        var reportsDict = NSMutableDictionary()
        
        for item in submission.baseJson["mod_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            reportsDict[array[0]] = array[1]
        }
        for item in submission.baseJson["user_reports"] as? [AnyObject] ?? [] {
            let array = item as! [Any]
            reportsDict[array[0]] = array[1]
        }
        self.reportsJSON = reportsDict.jsonString()
        
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
        self.awardsJSON = jsonDict.jsonString()
        
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
        self.flairJSON = flairDict.jsonString()

        var galleryDict = NSMutableDictionary()
        var galleryImages = [String]()
        for item in (submission.baseJson["gallery_data"] as? JSONDictionary)?["items"] as? [JSONDictionary] ?? [] {
            if let image = (submission.baseJson["media_metadata"] as? JSONDictionary)?[item["media_id"] as! String]  as? JSONDictionary {
                if image["s"] != nil && (image["s"] as? JSONDictionary)?["u"] != nil {
                    galleryImages.append((image["s"] as? JSONDictionary)?["u"] as! String)
                }
            }
        }
        galleryDict["images"] = galleryImages
        self.galleryJSON = galleryDict.jsonString()

        var pollsDict = NSMutableDictionary()
        for item in (submission.baseJson["poll_data"] as? JSONDictionary)?["options"] as? [AnyObject] ?? [] {
            if let poll = item as? JSONDictionary {
                if poll["text"] != nil {
                    pollsDict[poll["text"] as? String ?? ""] = poll["vote_count"] as? Int ?? -1
                }
            }
        }
        if let pollTotal = (submission.baseJson["poll_data"] as? JSONDictionary)?["total_vote_count"] as? Int {
            pollsDict["total"] = pollTotal
        }

        self.pollJSON = pollsDict.jsonString()
        
        self.approvedBy = submission.baseJson["approved_by"] as? String ?? ""
        self.isApproved = !(self.approvedBy ?? "").isEmpty()
        
        self.isCrosspost = false

        if let crosspostParent = json?["crosspost_parent_list"] as? [Any] {
            self.isCrosspost = true
            let sub = (crosspostParent.first as? [String: Any])?["subreddit"] as? String ?? ""
            let author = (crosspostParent.first as? [String: Any])?["author"] as? String ?? ""
            let permalink = (crosspostParent.first as? [String: Any])?["permalink"] as? String ?? ""
            self.crosspostSubreddit = sub
            self.crosspostAuthor = author
            self.crosspostPermalink = permalink
            
            var galleryDict = NSMutableDictionary()
            var galleryImages = [String]()
            galleryDict["images"] = galleryImages
            self.galleryJSON = galleryDict.jsonString()
            for item in ((crosspostParent.first as? [String: Any])?["gallery_data"] as? JSONDictionary)?["items"] as? [JSONDictionary] ?? [] {
                if let image = ((crosspostParent.first as? [String: Any])?["media_metadata"] as? JSONDictionary)?[item["media_id"] as! String]  as? JSONDictionary {
                    if image["s"] != nil && (image["s"] as? JSONDictionary)?["u"] != nil {
                        galleryImages.append((image["s"] as? JSONDictionary)?["u"] as! String)
                    }
                }
            }
            galleryDict["images"] = galleryImages
            self.galleryJSON = galleryDict.jsonString()
        }
        
        context.performAndWait {
            do {
                try context.save()
            } catch let error as NSError {
                print(error)
            }

        }
        return self
    }
    
    internal func getLinkView() -> LinkCellView {
        var target = CurrentType.none
        let submission = self

        var thumb = submission.hasThumbnail
        var big = submission.hasBanner
        let height = submission.imageHeight

        var type = ContentType.getContentType(baseUrl: submission.url)
        if submission.isSelf {
            type = .SELF
        }

        //        if (SettingValues.bannerHidden) {
        //            big = false
        //            thumb = true
        //        }

        let fullImage = ContentType.fullImage(t: type)

        if !fullImage && height < 75 {
            big = false
            thumb = true
        }

        if type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big {
            big = false
            thumb = false
        }

        if height < 75 {
            thumb = true
            big = false
        }

        if type == ContentType.CType.SELF && SettingValues.hideImageSelftext
            || SettingValues.noImages && submission.isSelf {
            big = false
            thumb = false
        }

        if big || !submission.hasThumbnail {
            thumb = false
        }

        if !big && !thumb && submission.type != .SELF && submission.type != .NONE { //If a submission has a link but no images, still show the web thumbnail
            thumb = true
        }

        let sub = submission.subreddit
        if submission.isNSFW && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection && Subscriptions.isCollection(sub)) {
            big = false
            thumb = true
        }

        if SettingValues.noImages {
            big = false
            thumb = false
        }
        if thumb && type == .SELF {
            thumb = false
        }

        if thumb && !big {
            target = .thumb
        } else if big {
            target = .banner
        } else {
            target = .text
        }

        if type == .LINK && SettingValues.linkAlwaysThumbnail {
            target = .thumb
        }

        var cell: LinkCellView!
        if target == .thumb {
            cell = ThumbnailLinkCellView()
        } else if target == .banner {
            if SettingValues.shouldAutoPlay() && (ContentType.displayVideo(t: type) && type != .VIDEO) {
                cell = AutoplayBannerLinkCellView()
            } else {
                cell = BannerLinkCellView()
            }
        } else {
            cell = TextLinkCellView()
        }

        return cell

    }
    
    var hasPoll: Bool {
        return pollDictionary.keys.count > 0
    }
    
    var pollTotal: Int {
        return pollDictionary["total"] as? Int ?? 0
    }
    
    var flairDictionary: [String: AnyObject] {
        return flairJSON?.dictionaryValue() ?? [String: AnyObject]()
    }
    
    var galleryDictionary: [String: AnyObject] {
        return galleryJSON?.dictionaryValue() ?? [String: AnyObject]()
    }

    var pollDictionary: [String: AnyObject] {
        return pollJSON?.dictionaryValue() ?? [String: AnyObject]()
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

extension NSManagedObject {
    
    func getId() -> String {
        if let object = self as? Submission {
            return object.id
        } else if let object = self as? CommentModel {
            return object.id
        } else if let object = self as? MoreModel {
            return object.id
        } else if let object = self as? MessageModel {
            return object.id
        } else {
            return ""
        }
    }
}
