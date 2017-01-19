//
//  Multireddit.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
Type of Multireddit icon.
*/
public enum MultiredditIconName: String {
    case artAndDesign = "art and design"
    case ask = "ask"
    case books = "books"
    case business = "business"
    case cars = "cars"
    case comics = "comics"
    case cuteAnimals = "cute animals"
    case diy = "diy"
    case entertainment = "entertainment"
    case foodAndDrink = "food and drink"
    case funny = "funny"
    case games = "games"
    case grooming = "grooming"
    case health = "health"
    case lifeAdvice = "life advice"
    case military = "military"
    case modelsPinup = "models pinup"
    case music = "music"
    case news = "news"
    case philosophy = "philosophy"
    case picturesAndGifs = "pictures and gifs"
    case science = "science"
    case shopping = "shopping"
    case sports = "sports"
    case style = "style"
    case tech = "tech"
    case travel = "travel"
    case unusualStories = "unusual stories"
    case video = "video"
    case none = "None"
    
    init(_ name: String) {
        self = MultiredditIconName(rawValue:name) ?? .none
    }
}

/**
Type of Multireddit visibility.
*/
public enum MultiredditVisibility: String {
    case `private` = "private"
    case `public` = "public"
    case hidden = "hidden"
    
    init(_ type: String) {
        self = MultiredditVisibility(rawValue:type) ?? .private
    }
}

/**
Type of Multireddit weighting scheme.
*/
public enum MultiredditWeightingScheme: String {
    case classic = "classic"
    case fresh = "fresh"
    
    init(_ type: String) {
        self = MultiredditWeightingScheme(rawValue:type) ?? .classic
    }
}

/**
Multireddit class.
*/
public struct Multireddit: SubredditURLPath {
    public var descriptionMd: String
    public var displayName: String
    public var iconName: MultiredditIconName
    public var keyColor: String
    public var subreddits: [String]
    public var visibility: MultiredditVisibility
    public var weightingScheme: MultiredditWeightingScheme
    
    // can not update following attritubes
    public let descriptionHtml: String
    public let path: String
    public let name: String
    public let iconUrl: String
    public let canEdit: Bool
    public let copiedFrom: String
    public let created: TimeInterval
    public let createdUtc: TimeInterval
    
    public init(name: String, user: String) {
        self.descriptionMd = ""
        self.displayName = name
        self.iconName = MultiredditIconName("")
        self.visibility = MultiredditVisibility("")
        self.keyColor = ""
        self.subreddits = []
        self.weightingScheme = MultiredditWeightingScheme("")
        self.descriptionHtml = ""
        self.path = "/user/" + user + "/m/" + name
        self.name = name
        self.iconUrl = ""
        self.canEdit = false
        self.copiedFrom = ""
        self.created = 0
        self.createdUtc = 0
    }
    
    public init(json: JSONDictionary) {
        descriptionMd = json["description_md"] as? String ?? ""
        displayName = json["display_name"] as? String ?? ""
        
        iconName = MultiredditIconName(json["icon_name"] as? String ?? "")
        visibility = MultiredditVisibility(json["visibility"] as? String ?? "")
        
        keyColor = json["key_color"] as? String ?? ""
        
        var buf: [String] = []
        if let temp = json["subreddits"] as? [JSONDictionary] {
            for element in temp {
                if let element = element as? [String:String], let name = element["name"] {
                    buf.append(name)
                }
            }
        }
        subreddits = buf
        
        weightingScheme = MultiredditWeightingScheme(json["weighting_scheme"] as? String ?? "")
        
        descriptionHtml = json["description_html"] as? String ?? ""
        path = json["path"] as? String ?? ""
        name = json["name"] as? String ?? ""
        iconUrl = json["icon_url"] as? String ?? ""
        canEdit = json["can_edit"] as? Bool ?? false
        copiedFrom = json["copied_from"] as? String ?? ""
        created = json["created"] as? TimeInterval ?? 0
        createdUtc = json["created_utc"] as? TimeInterval ?? 0
    }
    
    /**
     Create new multireddit path as String from "/user/sonson_twit/m/testmultireddit12" replacing its name with "newMultiredditName". For example, returns ""/user/sonson_twit/m/newmulti" when path is "/user/sonson_twit/m/testmultireddit12" and newMultiredditName is "newmulti".
     
     - parameter newMultiredditName: New display name for path.
     - returns: new path as String.
     */
    public func multiredditPathReplacingNameWith(_ newMultiredditName: String) throws -> String {
        do {
            let regex = try NSRegularExpression(pattern:"^/user/(.+?)/m/", options: .caseInsensitive)
            if let match = regex.firstMatch(in: self.path, options: [], range: NSRange(location:0, length:self.path.characters.count)) {
                if match.numberOfRanges > 1 {
                    let range = match.rangeAt(1)
                    let userName = (self.path as NSString).substring(with: range)
                    return "/user/\(userName)/m/\(newMultiredditName)"
                }
            }
            throw NSError(domain: "", code: 0, userInfo: nil)
        } catch { throw error }
    }
}
