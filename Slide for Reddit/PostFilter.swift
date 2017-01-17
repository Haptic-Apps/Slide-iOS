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
    static var domains: [String] = []
    static var selftext: [String] = []
    static var titles: [String] = []
    static var profiles: [String] = []
    static var subreddits: [String] = []
    static var flairs: [String] = []

    public func initialize(){
        PostFilter.domains = UserDefaults.standard.array(forKey: "domainfilters") as! [String]? ?? []
        PostFilter.selftext = UserDefaults.standard.array(forKey: "selftextfilters") as! [String]? ?? []
        PostFilter.titles = UserDefaults.standard.array(forKey: "titlefilters") as! [String]? ?? []
        PostFilter.profiles = UserDefaults.standard.array(forKey: "profilefilters") as! [String]? ?? []
        PostFilter.subreddits = UserDefaults.standard.array(forKey: "subredditfilters") as! [String]? ?? []
        PostFilter.flairs = UserDefaults.standard.array(forKey: "flairfilters") as! [String]? ?? []
    }
    
    public static func contains(_ array: [String], value: String) -> Bool{
        for text in array {
            if(text.localizedCaseInsensitiveContains(value)){
                return true
            }
        }
        return false
    }
    
    public static func matches(_ link: Link) -> Bool {
        return (PostFilter.domains.contains(link.domain)) || PostFilter.profiles.contains(link.author) || PostFilter.subreddits.contains(link.subreddit) || contains(PostFilter.flairs, value: link.linkFlairText) || contains(PostFilter.selftext, value: link.selftext) || contains(PostFilter.titles, value: link.title)
    }
    
    public static func filter(_ input: [Link], previous: [Link]?) -> [Link] {
        var ids: [String] = []
        var toReturn: [Link] = []
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
