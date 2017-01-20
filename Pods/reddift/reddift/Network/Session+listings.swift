//
//  Session+listings.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
The sort method for listing Link object, "/r/[subreddit]/[sort]" or "/[sort]".
*/
enum PrivateLinkSortBy {
    case controversial
    case top
    
    var path: String {
        switch self {
        case .controversial:
            return "/controversial"
        case .top:
            return "/top"
        }
    }
}

extension Session {

    /**
     Get the comment tree for a given Link article.
     If supplied, comment is the ID36 of a comment in the comment tree for article.
     This comment will be the (highlighted) focal point of the returned view and context will be the number of parents shown.
     A comment tree often includes "More" objects and vacant comment objects.
     "More" objects have children comment objects.
     This API is used for expand of them.
     And vacant comment objects must be re-downloaded again using this API.
    
    - parameter link: Link from which comment will be got.
    - parameter sort: The type of sorting.
    - parameter comments: If supplied, comment is the ID36 of a comment in the comment tree for article. When you want to expand "more" object or vacant comment objects, you have to specify it. Default is nil.
    - parameter depth: The maximum depth of subtrees in the thread. Default is nil.
    - parameter limit: The maximum number of comments to return. Default is nil.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getArticles(_ link: Link, sort: CommentSort, comments: [String]? = nil, depth: Int? = nil, context: Int? = 1,  limit: Int? = nil, completion: @escaping (Result<(Listing, Listing)>) -> Void) throws -> URLSessionDataTask {
        var parameter = ["sort":sort.type, "showmore":"True"]
        if let depth = depth {
            parameter["depth"] = "\(depth)"
        }
        if let limit = limit {
            parameter["limit"] = "\(limit)"
        }
        if let comments = comments {
            let commaSeparatedIDString = comments.joined(separator: ",")
            parameter["comment"] = commaSeparatedIDString
        }
        parameter["context"] = "\(context)"
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/comments/" + link.id + ".json", parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<(Listing, Listing)> in
            
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2ListingTuple)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Get Links from all subreddits or user specified subreddit.
    
    - parameter paginator: Paginator object for paging contents.
    - parameter subreddit: Subreddit from which Links will be gotten.
    - parameter integratedSort: The original type of sorting a list, .Controversial, .Top, .Hot, or .New.
    - parameter TimeFilterWithin: The type of filtering contents. When integratedSort is .Hot or .New, this parameter is ignored.
    - parameter limit: The maximum number of comments to return. Default is 25.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getList(_ paginator: Paginator, subreddit: SubredditURLPath?, sort: LinkSortType, timeFilterWithin: TimeFilterWithin, limit: Int = 25, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        do {
            switch sort {
            case .controversial:
                return try getList(paginator, subreddit: subreddit, privateSortType: .controversial, timeFilterWithin: timeFilterWithin, limit: limit, completion: completion)
            case .top:
                return try getList(paginator, subreddit: subreddit, privateSortType: .top, timeFilterWithin: timeFilterWithin, limit: limit, completion: completion)
            case .new:
                return try getNewOrHotList(paginator, subreddit: subreddit, type: "new", limit:limit, completion: completion)
            case .hot:
                return try getNewOrHotList(paginator, subreddit: subreddit, type: "hot", limit:limit, completion: completion)
            case .rising:
                return try getNewOrHotList(paginator, subreddit: subreddit, type: "rising", limit:limit, completion: completion)
            }
        } catch { throw error }
    }
    
    /**
    Get Links from all subreddits or user specified subreddit.
    
    - parameter paginator: Paginator object for paging contents.
    - parameter subreddit: Subreddit from which Links will be gotten.
    - parameter sort: The type of sorting a list.
    - parameter TimeFilterWithin: The type of filtering contents.
    - parameter limit: The maximum number of comments to return. Default is 25.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    func getList(_ paginator: Paginator, subreddit: SubredditURLPath?, privateSortType: PrivateLinkSortBy, timeFilterWithin: TimeFilterWithin, limit: Int = 25, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        let parameter = paginator.dictionaryByAdding(parameters: [
            "limit"    : "\(limit)",
            "show"     : "all",
//          "sr_detail": "true",
            "t"        : timeFilterWithin.param
        ])
        var path = "\(privateSortType.path).json"
        if let subreddit = subreddit { path = "\(subreddit.path)\(privateSortType.path).json" }
        print(path)
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:path, parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Listing> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Get hot Links from all subreddits or user specified subreddit.
    
    - parameter paginator: Paginator object for paging contents.
    - parameter subreddit: Subreddit from which Links will be gotten.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    func getHotList(_ paginator: Paginator, subreddit: SubredditURLPath?, limit: Int = 25, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        do {
            return try getNewOrHotList(paginator, subreddit: subreddit, type: "hot", limit:limit, completion: completion)
        } catch { throw error }
    }
    
    /**
    Get new Links from all subreddits or user specified subreddit.
    
    - parameter paginator: Paginator object for paging contents.
    - parameter subreddit: Subreddit from which Links will be gotten.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    func getNewList(_ paginator: Paginator, subreddit: SubredditURLPath?, limit: Int = 25, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        do {
            return try getNewOrHotList(paginator, subreddit: subreddit, type: "new", limit:limit, completion: completion)
        } catch { throw error }
    }
    
    /**
    Get hot or new Links from all subreddits or user specified subreddit.
    
    - parameter paginator: Paginator object for paging contents.
    - parameter subreddit: Subreddit from which Links will be gotten.
    - parameter type: "new" or "hot" as type.
    - parameter limit: The maximum number of comments to return. Default is 25.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    func getNewOrHotList(_ paginator: Paginator, subreddit: SubredditURLPath?, type: String, limit: Int = 25, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        let parameter = paginator.dictionaryByAdding(parameters: [
            "limit"    : "\(limit)",
            //            "sr_detail": "true",
            "show"     : "all",
            ])
        var path = "\(type).json"
        if let subreddit = subreddit { path = "\(subreddit.path)/\(type).json" }
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:path, parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Listing> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    The Serendipity content.
    But this endpoints return invalid redirect URL...
    I don't know how this URL should be handled....
    
    - parameter subreddit: Specified subreddit to which you would like to get random link
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getRandom(_ subreddit: Subreddit? = nil, completion: @escaping (Result<(Listing, Listing)>) -> Void) throws -> URLSessionDataTask {
        var path = "/random"
        if let subreddit = subreddit { path = subreddit.url + "/random" }
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:path, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<(Listing, Listing)> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2ListingTuple)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    // MARK: BDT does not cover following methods.
    
    /**
    Related page: performs a search using title of article as the search query.
    
    - parameter paginator: Paginator object for paging contents.
    - parameter thing:  Thing object to which you want to obtain the contents that are related.
    - parameter limit: The maximum number of comments to return. Default is 25.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getRelatedArticles(_ paginator: Paginator, thing: Thing, limit: Int = 25, completion: @escaping (Result<(Listing, Listing)>) -> Void) throws -> URLSessionDataTask {
        let parameter = paginator.dictionaryByAdding(parameters: [
            "limit"    : "\(limit)",
            //            "sr_detail": "true",
            "show"     : "all",
        ])
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/related/" + thing.id, parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<(Listing, Listing)> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2ListingTuple)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Return a list of other submissions of the same URL.
    
    - parameter paginator: Paginator object for paging contents.
    - parameter thing:  Thing object by which you want to obtain the same URL is mentioned.
    - parameter limit: The maximum number of comments to return. Default is 25.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getDuplicatedArticles(_ paginator: Paginator, thing: Thing, limit: Int = 25, completion: @escaping  (Result<(Listing, Listing)>) -> Void) throws -> URLSessionDataTask {
        let parameter = paginator.dictionaryByAdding(parameters: [
            "limit"    : "\(limit)",
//            "sr_detail": "true",
            "show"     : "all"
        ])
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/duplicates/" + thing.id, parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<(Listing, Listing)> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2ListingTuple)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Get a listing of links by fullname.
    
    :params: links A list of Links
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getLinksById(_ links: [Link], completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        let fullnameList = links.map({ (link: Link) -> String in link.name })
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/by_id/" + fullnameList.joined(separator: ","), method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Listing> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
}
