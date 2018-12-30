//
//  PostFilter.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import RealmSwift
import reddift
import UIKit

class PostFilter {
    static var domains: [NSString] = []
    static var selftext: [NSString] = []
    static var titles: [NSString] = []
    static var profiles: [NSString] = []
    static var subreddits: [NSString] = []
    static var flairs: [NSString] = []
    static var openExternally: [NSString] = []
    static var filters: UserDefaults?

    public static func initialize() {
        PostFilter.domains = UserDefaults.standard.array(forKey: "domainfilters") as! [NSString]? ?? []
        PostFilter.selftext = UserDefaults.standard.array(forKey: "selftextfilters") as! [NSString]? ?? []
        PostFilter.titles = UserDefaults.standard.array(forKey: "titlefilters") as! [NSString]? ?? []
        PostFilter.profiles = UserDefaults.standard.array(forKey: "profilefilters") as! [NSString]? ?? []
        PostFilter.subreddits = UserDefaults.standard.array(forKey: "subredditfilters") as! [NSString]? ?? []
        PostFilter.flairs = UserDefaults.standard.array(forKey: "flairfilters") as! [NSString]? ?? []
        PostFilter.openExternally = UserDefaults.standard.array(forKey: "openexternally") as! [NSString]? ?? ["itunes.apple.com"]
        filters = UserDefaults.init(suiteName: "filters")
        print(PostFilter.domains)

    }

    public static func saveAndUpdate() {
        UserDefaults.standard.set(PostFilter.domains, forKey: "domainfilters")
        UserDefaults.standard.set(PostFilter.selftext, forKey: "selftextfilters")
        UserDefaults.standard.set(PostFilter.titles, forKey: "titlefilters")
        UserDefaults.standard.set(PostFilter.profiles, forKey: "profilefilters")
        UserDefaults.standard.set(PostFilter.subreddits, forKey: "subredditfilters")
        UserDefaults.standard.set(PostFilter.flairs, forKey: "flairfilters")
        UserDefaults.standard.set(PostFilter.openExternally, forKey: "openexternally")
        UserDefaults.standard.synchronize()
        initialize()
    }

    public static func contains(_ array: [NSString], value: String) -> Bool {
        for text in array {
            if text.localizedCaseInsensitiveContains(value) {
                return true
            }
        }
        return false
    }
    
    public static func containedIn(_ array: [NSString], value: String) -> Bool {
        for text in array {
            if value.localizedCaseInsensitiveContains(String(text)) {
                return true
            }
        }
        return false
    }

    public static func matches(_ link: RSubmission, baseSubreddit: String) -> Bool {
        let mainMatch = (PostFilter.domains.contains(where: { $0.containedIn(base: link.domain) })) ||
            PostFilter.profiles.contains(where: { $0.caseInsensitiveCompare(link.author) == .orderedSame }) ||
            PostFilter.subreddits.contains(where: { $0.caseInsensitiveCompare(link.subreddit) == .orderedSame }) ||
            contains(PostFilter.flairs, value: link.flair) ||
            containedIn(PostFilter.selftext, value: link.htmlBody) ||
            containedIn(PostFilter.titles, value: link.title) ||
            (link.nsfw && !SettingValues.nsfwEnabled)
        
        if mainMatch {
            //No need to check further
            return mainMatch
        }

        var contentMatch = false
        if link.nsfw {
            // Hide NSFW if the user is not logged in, nsfw is not enabled (can only be done while authenticated),
            // or the subreddit-specific nsfw filter is turned on
            contentMatch = !AccountController.isLoggedIn || !SettingValues.nsfwEnabled || isNsfw(baseSubreddit)
        }

        switch ContentType.getContentType(submission: link) {
        case .REDDIT, .EMBEDDED, .LINK:
            if isUrl(baseSubreddit) {
                contentMatch = true
            }
        case .SELF, .NONE:
            if isSelftext(baseSubreddit) {
                contentMatch = true
            }
        case .ALBUM:
            if isAlbum(baseSubreddit) {
                contentMatch = true
            }
        case .IMAGE, .DEVIANTART, .IMGUR, .XKCD:
            if isImage(baseSubreddit) {
                contentMatch = true
            }
        case .GIF:
            if isGif(baseSubreddit) {
                contentMatch = true
            }
        case .VID_ME, .VIDEO, .STREAMABLE:
            if isVideo(baseSubreddit) {
                contentMatch = true
            }
        default:
            break
        }

        return mainMatch || contentMatch
    }

    public static func openExternally(_ link: RSubmission) -> Bool {
        return (PostFilter.openExternally.contains(where: {
            $0.containedIn(base: link.domain)
        }))
    }

    public static func openExternally(_ link: URL) -> Bool {
        return (PostFilter.openExternally.contains(where: {
            $0.containedIn(base: link.host)
        }))
    }

    public static func enabledArray(_ sub: String) -> [Bool] {
        return [isImage(sub), isAlbum(sub), isGif(sub), isVideo(sub), isUrl(sub), isSelftext(sub), isNsfw(sub)]
    }

    public static func filter(_ input: [Object], previous: [RSubmission]?, baseSubreddit: String) -> [Object] {
        var ids: [String] = []
        var toReturn: [Object] = []
        if previous != nil {
            for p in previous! {
                ids.append(p.getId())
            }
        }

        for link in input {
            if link is RSubmission {
                if !matches(link as! RSubmission, baseSubreddit: baseSubreddit) && !ids.contains((link as! RSubmission).getId()) {
                    toReturn.append(link)
                }
            } else if link is RComment {
                let comment = link as! RComment
                let mainMatch = PostFilter.profiles.contains(where: { $0.caseInsensitiveCompare(comment.author) == .orderedSame }) ||
                    PostFilter.subreddits.contains(where: { $0.caseInsensitiveCompare(comment.subreddit) == .orderedSame }) ||
                    contains(PostFilter.flairs, value: comment.flair)
                if !mainMatch {
                    toReturn.append(link)
                }
            } else if link is RMessage {
                let message = link as! RMessage
                let mainMatch = PostFilter.profiles.contains(where: { $0.caseInsensitiveCompare(message.author) == .orderedSame })
                if !mainMatch {
                    toReturn.append(link)
                }
            } else {
                toReturn.append(link)
            }
        }
        return toReturn
    }

    public static func setEnabledArray(_ sub: String, _ enabled: [Bool]) {
        filters!.set(enabled[0], forKey: "\(sub)_imageFilter")
        filters!.set(enabled[1], forKey: "\(sub)_albumFilter")
        filters!.set(enabled[2], forKey: "\(sub)_gifFilter")
        filters!.set(enabled[3], forKey: "\(sub)_videoFilter")
        filters!.set(enabled[4], forKey: "\(sub)_urlFilter")
        filters!.set(enabled[5], forKey: "\(sub)_selfFilter")
        filters!.set(enabled[6], forKey: "\(sub)_nsfwFilter")
        filters!.synchronize()
    }

    public static func isGif(_ baseSubreddit: String) -> Bool {
        return filters!.object(forKey: "\(baseSubreddit)_gifFilter") == nil ? false : filters!.bool(forKey: "\(baseSubreddit)_gifFilter")
    }

    public static func isImage(_ baseSubreddit: String) -> Bool {
        return filters!.object(forKey: "\(baseSubreddit)_imageFilter") == nil ? false : filters!.bool(forKey: "\(baseSubreddit)_imageFilter")
    }

    public static func isAlbum(_ baseSubreddit: String) -> Bool {
        return filters!.object(forKey: "\(baseSubreddit)_albumFilter") == nil ? false : filters!.bool(forKey: "\(baseSubreddit)_albumFilter")
    }

    public static func isNsfw(_ baseSubreddit: String) -> Bool {
        return filters!.object(forKey: "\(baseSubreddit)_nsfwFilter") == nil ? false : filters!.bool(forKey: "\(baseSubreddit)_nsfwFilter")
    }

    public static func isSelftext(_ baseSubreddit: String) -> Bool {
        return filters!.object(forKey: "\(baseSubreddit)_selfFilter") == nil ? false : filters!.bool(forKey: "\(baseSubreddit)_selfFilter")
    }

    public static func isUrl(_ baseSubreddit: String) -> Bool {
        return filters!.object(forKey: "\(baseSubreddit)_urlFilter") == nil ? false : filters!.bool(forKey: "\(baseSubreddit)_urlFilter")
    }

    public static func isVideo(_ baseSubreddit: String) -> Bool {
        return filters!.object(forKey: "\(baseSubreddit)_videoFilter") == nil ? false : filters!.bool(forKey: "\(baseSubreddit)_videoFilter")
    }

}

public extension NSString {
    func containedIn(base: String?) -> Bool {
        if base == nil {
            return false
        }
        return base!.range(of: String(self), options: .caseInsensitive) != nil
    }
}
