//
//  PostFilter.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

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

    public static func matches(_ link: RSubmission, baseSubreddit: String) -> Bool {
        let mainMatch = (PostFilter.domains.contains(where: { $0.containedIn(base: link.domain) })) || PostFilter.profiles.contains(where: { $0.caseInsensitiveCompare(link.author) == .orderedSame }) || PostFilter.subreddits.contains(where: { $0.caseInsensitiveCompare(link.subreddit) == .orderedSame }) || contains(PostFilter.flairs, value: link.flair) || contains(PostFilter.selftext, value: link.htmlBody) || contains(PostFilter.titles, value: link.title) || (link.nsfw && !SettingValues.nsfwEnabled)

        let gifs = isGif(baseSubreddit)
        let images = isImage(baseSubreddit)
        let nsfw = isNsfw(baseSubreddit)
        let albums = isAlbum(baseSubreddit)
        let urls = isUrl(baseSubreddit)
        let selftext = isSelftext(baseSubreddit)
        let videos = isVideo(baseSubreddit)

        var contentMatch = !AccountController.isLoggedIn || !SettingValues.nsfwEnabled || nsfw

        switch ContentType.getContentType(submission: link) {
        case .REDDIT, .EMBEDDED, .LINK:
            if urls {
                contentMatch = true
            }
        case .SELF, .NONE:
            if selftext {
                contentMatch = true
            }
        case .ALBUM:
            if albums {
                contentMatch = true
            }
        case .IMAGE, .DEVIANTART, .IMGUR, .XKCD:
            if images {
                contentMatch = true
            }
        case .GIF:
            if gifs {
                contentMatch = true
            }
        case .VID_ME, .VIDEO, .STREAMABLE:
            if videos {
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

    public static func filter(_ input: [RSubmission], previous: [RSubmission]?, baseSubreddit: String) -> [RSubmission] {
        var ids: [String] = []
        var toReturn: [RSubmission] = []
        if previous != nil {
            for p in previous! {
                ids.append(p.getId())
            }
        }

        for link in input {
            if !matches(link, baseSubreddit: baseSubreddit) && !ids.contains(link.getId()) {
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
