//
//  RedditLink.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/4/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import reddift
import SafariServices
import UIKit

class RedditLink {
    
    public static func getViewControllerForURL(urlS: URL) -> UIViewController {
        let oldUrl = urlS
        var url = formatRedditUrl(urlS: urlS)
        var np = false
        if url.isEmpty() {
            if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
                let safariVC = SFHideSafariViewController(url: oldUrl, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
                if #available(iOS 10.0, *) {
                    safariVC.preferredBarTintColor = ColorUtil.backgroundColor
                    safariVC.preferredControlTintColor = ColorUtil.fontColor
                } else {
                    // Fallback on earlier versions
                }
                return safariVC
            }
            return WebsiteViewController.init(url: oldUrl, subreddit: "")
        } else if url.hasPrefix("np") {
            np = true
            url = url.substring(2, length: url.length - 2)
        }
        
        let percentUrl = url.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? url
        
        let type = getRedditLinkType(urlBase: URL.init(string: percentUrl)!)
        
        var parts = url.split("/")
        var endParameters = ""
        if parts[parts.count - 1].startsWith("?") {
            endParameters = parts[parts.count - 1]
            parts.remove(at: parts.count - 1)
        }
                
        let safeURL = url.startsWith("/") ? "https://www.reddit.com" + url : url
        
        switch type {
        case .SHORTENED:
            return CommentViewController.init(submission: parts[1], subreddit: nil, np: np)
        case .LIVE:
            print(parts[1])
            return LiveThreadViewController.init(id: parts[2])
        case .WIKI:
            return WebsiteViewController.init(url: URL(string: safeURL)!, subreddit: "")
        case .SEARCH:
            let end = parts[parts.count - 1]
            let sub: String
            let restrictSub = end.contains("restrict_sr=on") || end.contains("restrict_sr=1")
            if restrictSub {
                sub = parts[2]
            } else {
                sub = "all"
            }
            let query: String
            
            if let q = urlS.queryDictionary["q"] {
                query = q.removingPercentEncoding?.removingPercentEncoding ?? q
            } else {
                query = ""
            }
            return SearchViewController(subreddit: sub, searchFor: query)
        case .COMMENT_PERMALINK:
            var comment = ""
            var contextNumber = 3
            if parts.count >= 7 {
                var end = parts[6]
                var endCopy = end
                if end.contains("?") { end = end.substring(0, length: end.indexOf("?")!) }
                
                if end.length >= 3 {
                    comment = end
                }
                if endCopy.contains("?context=") {
                    if !endParameters.isEmpty() {
                        endCopy = endParameters
                    }
                    let index = endCopy.indexOf("?context=")! + 9
                    contextNumber = Int(endCopy.substring(index, length: endCopy.length - index))!
                }
            }
            if contextNumber == 0 {
                contextNumber = 3
            }
            return CommentViewController.init(submission: parts[4], comment: comment, context: contextNumber, subreddit: parts[2], np: np)
            
        case .SUBMISSION:
            return CommentViewController.init(submission: parts[4], subreddit: parts[2], np: np)
            
        case .SUBMISSION_WITHOUT_SUB:
            return CommentViewController.init(submission: parts[2], subreddit: nil, np: np)
            
        case .SUBREDDIT:
            return SingleSubredditViewController.init(subName: parts[2], single: true)
        case .MESSAGE:
            return ReplyViewController.init(name: "/r/\(parts[parts.count - 1])", completion: { (_) in
            })
        case .USER:
            return ProfileViewController.init(name: parts[2])
        case .OTHER:
            break
            
        }
        if SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL || SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY {
            let safariVC = SFHideSafariViewController(url: oldUrl, entersReaderIfAvailable: SettingValues.browser == SettingValues.BROWSER_SAFARI_INTERNAL_READABILITY)
            if #available(iOS 10.0, *) {
                safariVC.preferredBarTintColor = ColorUtil.backgroundColor
                safariVC.preferredControlTintColor = ColorUtil.fontColor
            } else {
                // Fallback on earlier versions
            }
            return safariVC
        }
        return WebsiteViewController.init(url: oldUrl, subreddit: "")
    }
    
    /**
     * Takes an reddit.com url and formats it for easier use
     *
     * @param url The url to format
     * @return Formatted url without subdomains, language tags & other unused prefixes
     */
    static func formatRedditUrl(urlS: URL) -> String {
        var url = urlS.absoluteString
        if url.hasPrefix("applewebdata:") {
            url = urlS.path
        }
        
        // Strip unused prefixes that don't require special handling
        url.stringByRemovingRegexMatches(pattern: "(?i)^(https?://)?(www\\.)?((ssl|pay|amp)\\.)?")
        
        if url.matches(regex: "(?i)[a-z0-9-_]+\\.reddit\\.com.*") { // tests for subdomain
            let subdomain = urlS.host
            let domainRegex = "(?i)" + subdomain! + "\\.reddit\\.com"
            if (subdomain?.hasPrefix("np"))! {
                // no participation link: https://www.reddit.com/r/NoParticipation/wiki/index
                url.stringByRemovingRegexMatches(pattern: domainRegex, replaceWith: "reddit.com")
                url = "np" + url
            } else if (subdomain?.matches(regex: "beta|blog|code|mod|out|store"))! {
                return ""
            } else if (subdomain?.matches(regex: "(?i)([_a-z0-9]{2}-)?[_a-z0-9]{1,2}"))! {
                /*
                 Either the subdomain is a language tag (with optional region) or
                 a single letter domain, which for simplicity are ignored.
                 */
                url.stringByRemovingRegexMatches(pattern: domainRegex, replaceWith: "reddit.com")
            } else {
                // subdomain is a subreddit, change subreddit.reddit.com to reddit.com/r/subreddit
                url.stringByRemovingRegexMatches(pattern: domainRegex, replaceWith: "reddit.com/r/" + subdomain!)
            }
        }
        
        if url.hasPrefix("/") { url = "reddit.com" + url }
        if url.hasSuffix("/") { url = url.substring(0, length: url.length - 1) }
        
        // Converts links such as reddit.com/help to reddit.com/r/reddit.com/wiki
        if url.matches(regex: "(?i)[^/]++/(?>wiki|help)(?>$|/.*)") {
            url.stringByRemovingRegexMatches(pattern: "(?i)/(?>wiki|help)", replaceWith: "/r/reddit.com/wiki")
        }
        
        url = url.removingPercentEncoding ?? url
        url = url.removingPercentEncoding ?? url //For some reason, some links are doubly encoded
        
        url = url.replacingOccurrences(of: "&amp;", with: "&")

        return url
    }
    
    /**
     * Determines the reddit link type
     *
     * @param url Reddit.com link
     * @return LinkType
     */
    static func getRedditLinkType(urlBase: URL) -> RedditLinkType {
        let url = urlBase.absoluteString
        if url.matches(regex: "(?i)redd\\.it/\\w+") {
            // Redd.it link. Format: redd.it/post_id
            return RedditLinkType.SHORTENED
        } else if url.matches(regex: "(?i)reddit\\.com/live/[^/]*") {
            return RedditLinkType.LIVE
        } else if url.matches(regex: "(?i)reddit\\.com/message/compose.*") {
            return RedditLinkType.MESSAGE
        } else if url.matches(regex: "(?i)reddit\\.com(?:/r/[a-z0-9-_.]+)?/(?:wiki|help).*") {
            // Wiki link. Format: reddit.com/r/$subreddit/wiki/$page [optional]
            return RedditLinkType.WIKI
        } else if url.matches(regex: "(?i)reddit\\.com/r/[a-z0-9-_.]+/about.*") {
            // Unhandled link. Format: reddit.com/r/$subreddit/about/$page [optional]
            return RedditLinkType.OTHER
        } else if url.matches(regex: "(?i)reddit\\.com/r/[a-z0-9-_.]+/search.*") {
            // Wiki link. Format: reddit.com/r/$subreddit/search?q= [optional]
            return RedditLinkType.SEARCH
        } else if url.matches(regex: "(?i)reddit\\.com/r/[a-z0-9-_.]+/comments/\\w+/\\w*/.*") {
            // Permalink to comments. Format: reddit.com/r/$subreddit/comments/$post_id/$post_title [can be empty]/$comment_id
            return RedditLinkType.COMMENT_PERMALINK
        } else if url.matches(regex: "(?i)reddit\\.com/r/[a-z0-9-_.]+/comments/\\w+.*") {
            // Submission. Format: reddit.com/r/$subreddit/comments/$post_id/$post_title [optional]
            return RedditLinkType.SUBMISSION
        } else if url.matches(regex: "(?i)reddit\\.com/comments/\\w+.*") {
            // Submission without a given subreddit. Format: reddit.com/comments/$post_id/$post_title [optional]
            return RedditLinkType.SUBMISSION_WITHOUT_SUB
        } else if url.matches(regex: "(?i)reddit\\.com/r/[a-z0-9-_.]+.*") {
            // Subreddit. Format: reddit.com/r/$subreddit/$sort [optional]
            return RedditLinkType.SUBREDDIT
        } else if url.matches(regex: "(?i)reddit\\.com/u(?:ser)?/[a-z0-9-_]+.*") {
            // User. Format: reddit.com/u [or user]/$username/$page [optional]
            return RedditLinkType.USER
        } else {
            //Open all links that we can't open in another app
            return RedditLinkType.OTHER
        }
    }
    
    enum RedditLinkType {
        case SHORTENED
        case WIKI
        case COMMENT_PERMALINK
        case SUBMISSION
        case SUBMISSION_WITHOUT_SUB
        case SUBREDDIT
        case USER
        case SEARCH
        case MESSAGE
        case LIVE
        case OTHER
    }
    
}
extension String {
    func matches(regex: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: [])
            let results = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.length))
            return results.count > 0
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }
    mutating func stringByRemovingRegexMatches(pattern: String, replaceWith: String = "") {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSRange(location: 0, length: self.length)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return
        }
    }
    
}
