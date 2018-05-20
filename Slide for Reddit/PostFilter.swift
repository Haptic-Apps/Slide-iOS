//
//  PostFilter.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/17/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit
import reddift

class PostFilter {
    static var domains: [NSString] = []
    static var selftext: [NSString] = []
    static var titles: [NSString] = []
    static var profiles: [NSString] = []
    static var subreddits: [NSString] = []
    static var flairs: [NSString] = []
    static var openExternally: [NSString] = []

    public static func initialize(){
        PostFilter.domains = UserDefaults.standard.array(forKey: "domainfilters") as! [NSString]? ?? []
        PostFilter.selftext = UserDefaults.standard.array(forKey: "selftextfilters") as! [NSString]? ?? []
        PostFilter.titles = UserDefaults.standard.array(forKey: "titlefilters") as! [NSString]? ?? []
        PostFilter.profiles = UserDefaults.standard.array(forKey: "profilefilters") as! [NSString]? ?? []
        PostFilter.subreddits = UserDefaults.standard.array(forKey: "subredditfilters") as! [NSString]? ?? []
        PostFilter.flairs = UserDefaults.standard.array(forKey: "flairfilters") as! [NSString]? ?? []
        PostFilter.openExternally = UserDefaults.standard.array(forKey: "openexternally") as! [NSString]? ?? []
    }
    
    public static func saveAndUpdate(){
        UserDefaults.standard.set(PostFilter.domains, forKey: "domainFilters")
        UserDefaults.standard.set(PostFilter.selftext, forKey: "selftextfilters")
        UserDefaults.standard.set(PostFilter.titles, forKey: "titlefilters")
        UserDefaults.standard.set(PostFilter.profiles, forKey: "profilefilters")
        UserDefaults.standard.set(PostFilter.subreddits, forKey: "subredditfilters")
        UserDefaults.standard.set(PostFilter.flairs, forKey: "flairfilters")
        UserDefaults.standard.set(PostFilter.openExternally, forKey: "openexternally")
        UserDefaults.standard.synchronize()
        initialize()
    }

    
    public static func contains(_ array: [NSString], value: String) -> Bool{
        for text in array {
            if(text.localizedCaseInsensitiveContains(value)){
                return true
            }
        }
        return false
    }
    
    public static func matches(_ link: RSubmission) -> Bool {
        return (PostFilter.domains.contains(where: { $0.containedIn(base: link.domain)})) || PostFilter.profiles.contains(where: {$0.caseInsensitiveCompare(link.author) == .orderedSame}) || PostFilter.subreddits.contains(where: {$0.caseInsensitiveCompare(link.subreddit) == .orderedSame}) || contains(PostFilter.flairs, value: link.flair) || contains(PostFilter.selftext, value: link.htmlBody) || contains(PostFilter.titles, value: link.title ) || (link.nsfw && !SettingValues.nsfwEnabled)
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


    public static func filter(_ input: [RSubmission], previous: [RSubmission]?) -> [RSubmission] {
        var ids: [String] = []
        var toReturn: [RSubmission] = []
        if(previous != nil){
            for p in previous! {
                ids.append(p.getId())
            }
        }
        
        for link in input {
            if !matches(link) && !ids.contains(link.getId()){
                toReturn.append(link)
            }
        }
        return toReturn
    }
}

public extension NSString {
    func containedIn(base: String?) -> Bool {
        if(base == nil){
            return false
        }
        return base!.range(of: String(self), options: .caseInsensitive) != nil
    }
}
