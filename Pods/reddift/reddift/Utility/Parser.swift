//
//  Parser.swift
//  reddift
//
//  Created by sonson on 2015/04/20.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
 Uitility class.
 Parser class parses JSON and generates objects from it.
 */
class Parser: NSObject {
    /**
     */
    class func parse(dictionary data: JSONDictionary, of kind: String) -> Any? {
        if(data["was_comment"] != nil){ //Override messages that appear to be comments
            return Message(json: data)
        }
        if(kind == "Flair"){
            return FlairTemplate(json: data)
        }
        switch kind {
        case "t1":
            return Comment(json: data)
        case "t2":
            return Account(json: data)
        case "t3":
            return Link(json: data)
        case "t4":
            return Message(json: data)
        case "t5":
            return Subreddit(json:data)
        case "t6":
            return Trophy(json: data)
        case "more":
            return More(json: data)
        case "LabeledMulti":
            return Multireddit(json: data) as Multireddit
        case "LabeledMultiDescription":
            return MultiredditDescription(json: data)
        case "UserList":
            return userList(from: data)
        case "TrophyList":
            return trophyList(from: data)
        default:
            return nil
        }
    }
    
    /**
     */
    class func parse(array: JSONArray, of kind: String) -> Any? {
        switch kind {
        case "KarmaList":
            return subredditKarmaList(from: array)
        default:
            return nil
        }
    }
    
    /**
     Parse thing object in JSON.
     This method dispatches element of JSON to eithr methods to extract classes derived from Thing class.
     */
    class func parse(_ json: JSONDictionary) -> Any? {
        guard let kind = json["kind"] as? String else { return nil }
        if kind == "Listing" {
            return listing(from: json)
        } else if let dictionary  = json["data"] as? JSONDictionary {
            return parse(dictionary: dictionary, of: kind)
        } else if let array = json["data"] as? JSONArray {
            return parse(array: array, of: kind)
        }
        return nil
    }
    
    /**
     Parse more list
     Parse json object to extract a list which is composed of Comment and More.
     */
    class func commentAndMore(from json: JSONAny) -> ([Thing], NSError?) {
        if let json = json as? JSONDictionary {
            if let root = json["json"] as? JSONDictionary {
                if let data = root["data"] as? JSONDictionary {
                    if let things = data["things"] as? [JSONDictionary] {
                        let r = things
                            .flatMap { Parser.parse($0) }
                            .flatMap { $0 as? Thing }
                        return (r, nil)
                    }
                }
                if let _ = json["errors"] {
                    // There is not any specifigations of error messages.
                    // How should I handle it?
                    return ([], ReddiftError.canNotGetMoreCommentForAnyReason as NSError)
                }
            }
        }
        return ([], ReddiftError.moreCommentJsonObjectIsNotDictionary as NSError)
    }
    
    /**
     Parse User list
     */
    class func userList(from json: JSONDictionary) -> [User] {
        var result: [User] = []
        if let children = json["children"] as? [JSONDictionary] {
            children.forEach({
                if let date = $0["date"] as? Double,
                    let name = $0["name"] as? String,
                    let id = $0["id"] as? String {
                    result.append(User(date: date, permissions: $0["mod_permissions"] as? [String], name: name, id: id))
                }
            })
        }
        return result
    }
    
    /**
     Parse SubredditKarma list
     */
    class func subredditKarmaList(from array: JSONArray) -> [SubredditKarma] {
        var result: [SubredditKarma] = []
        if let children = array as? [JSONDictionary] {
            children.forEach({
                if let sr = $0["sr"] as? String,
                    let comment_karma = $0["comment_karma"] as? Int,
                    let link_karma = $0["link_karma"] as? Int {
                    result.append(SubredditKarma(subreddit: sr, commentKarma: comment_karma, linkKarma: link_karma))
                }
            })
        }
        return result
    }
    
    /**
     Parse Trophy list
     */
    class func trophyList(from json: JSONDictionary) -> [Trophy] {
        var result: [Trophy] = []
        if let children = json["trophies"] as? [JSONDictionary] {
            result.append(contentsOf: children.flatMap({ parse($0) as? Trophy }))
        }
        return result
    }
    
    /**
     Parse list object in JSON
     */
    class func listing(from json: JSONDictionary) -> Listing {
        var list: [Thing] = []
        var paginator: Paginator? = Paginator()
        
        if let data = json["data"] as? JSONDictionary {
            if let children = data["children"] as? JSONArray {
                for child in children {
                    if let child = child as? JSONDictionary {
                        let obj: Any? = redditAny(from: child)
                        if let obj = obj as? Thing {
                            list.append(obj)
                        }
                    }
                }
            }
            
            if data["after"] != nil || data["before"] != nil {
                let a = data["after"] as? String ?? ""
                let b = data["before"] as? String ?? ""
                
                if !a.isEmpty || !b.isEmpty {
                    paginator = Paginator(after: a, before: b, modhash: data["modhash"] as? String ?? "")
                }
            }
        }
        return Listing(children:list, paginator: paginator ?? Paginator())
    }
    
    /**
     Parse JSON of the style which is Thing.
     */
    class func flairAny(from json: JSONAny) -> RedditAny? {
        // array
        // json->[AnyObject]
        if let array = json as? JSONArray {
            var output: [Any] = []
            for element in array {
                if let element = element as? JSONDictionary, let obj = flairAny(from: element) {
                    output.append(obj)
                }
            }
            return output
        }
            // dictionary
            // json->JSONDictionary
        else if let json = json as? JSONDictionary {
            return parse(dictionary: json, of: "Flair")
        }
        return nil
    }
    
    /**
     Parse JSON of the style which is Thing.
     */
    class func redditAny(from json: JSONAny) -> RedditAny? {
        // array
        // json->[AnyObject]
        if let array = json as? JSONArray {
            var output: [Any] = []
            for element in array {
                if let element = element as? JSONDictionary, let obj = redditAny(from: element) {
                    output.append(obj)
                }
            }
            return output
        }
            // dictionary
            // json->JSONDictionary
        else if let json = json as? JSONDictionary {
            return parse(json)
        }
        return nil
    }
}
