//
//  Session+subreddits.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

extension Bool {
    var string: String {
        return self ? "true" : "false"
    }
}

/**
 The type of subreddit user
 */
public enum SubredditAbout: String {
    case banned
    case muted
    case wikibanned
    case contributors
    case wikicontributors
    case moderators
}

extension Session {
    /**
     Return subreddits recommended for the given subreddit(s).
     Gets a list of subreddits recommended for srnames, filtering out any that appear in the optional omit param.
     */
    @discardableResult
    public func recommendedSubreddits(_ omit: [String], srnames: [String], completion: @escaping (Result<[String]>) -> Void) throws -> URLSessionDataTask {
        var parameter: [String:String] = [:]
        
        if omit.count > 0 {
            parameter["omit"] = omit.joined(separator: ",")
        }
        if srnames.count > 0 {
            parameter["srnames"] = srnames.joined(separator: ",")
        }
        
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/recommend/sr/srnames", parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[String]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap({
                    if let array = $0 as? [[String:String]] {
                        return Result(value: array.flatMap({$0["sr_name"]}))
                    }
                    return Result(error:ReddiftError.sr_nameOfRecommendedSubredditKeyNotFound as NSError)
                })
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     List subreddit names that begin with a query string.
     Subreddits whose names begin with query will be returned. If include_over_18 is false, subreddits with over-18 content restrictions will be filtered from the results.
     If exact is true, only an exact match will be returned.
     - parameter exact: boolean value, if this is true, only an exact match will be returned.
     - parameter include_over_18: boolean value, if this is true NSFW contents will be included returned list.
     - parameter query: a string up to 50 characters long, consisting of printable characters.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func searchRedditNames(_ query: String, exact: Bool = false, includeOver18: Bool = false, completion: @escaping (Result<[String]>) -> Void) throws -> URLSessionDataTask {
        let parameter = [
            "query":query,
            "exact":exact.string,
            "include_over_18":includeOver18.string
        ]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/search_reddit_names", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[String]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap({
                    if let dict = $0 as? JSONDictionary, let array = dict["names"] as? [String] {
                        return Result(value: array.flatMap({$0}))
                    }
                    return Result(error:ReddiftError.nameAsResultOfSearchSubredditKeyNotFound as NSError)
                })
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Return information about the subreddit.
     - parameter subredditName: Subreddit's name.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func about(_ subredditName: String, completion: @escaping (Result<Subreddit>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/r/\(subredditName)/about.json", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Subreddit> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Return a list of subreddits that are relevant to a search query.
     Data includes the subscriber count, description, and header image.
     - parameter query: Query is used for seqrch.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func searchSubredditsByTopic(_ query: String, completion: @escaping (Result<[String]>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["query":query]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/subreddits_by_topic", parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[String]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap({
                    if let array = $0 as? [[String:String]] {
                        return Result(value: array.flatMap({$0["name"]}))
                    }
                    return Result(error:ReddiftError.nameAsResultOfSearchSubredditKeyNotFound as NSError)
                })
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Get the submission text for the subreddit.
     This text is set by the subreddit moderators and intended to be displayed on the submission form.
     See also: /api/site_admin.
     - parameter subredditName: Subreddit's name.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getSubmitText(_ subredditName: String, completion: @escaping (Result<String>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/r/\(subredditName)/api/submit_text", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<String> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap({
                    if let dict = $0 as? [String:String], let submitText = dict["submit_text"] {
                        return Result(value: submitText)
                    }
                    return Result(error:ReddiftError.submit_textxSubredditKeyNotFound as NSError)
                })
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Fetch user list of subreddit.
     - parameter subreddit: Subreddit.
     - parameter aboutWhere: Type of user list, SubredditAbout.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func about(_ subreddit: Subreddit, aboutWhere: SubredditAbout, user: String = "", count: Int = 0, limit: Int = 25, completion: @escaping (Result<[User]>) -> Void) throws -> URLSessionDataTask {
        let parameter = [
            "count"    : "\(count)",
            "limit"    : "\(limit)",
            "show"     : "all",
            //          "sr_detail": "true",
            //          "user"     :"username"
        ]
        let path = "/r/\(subreddit.displayName)/about/\(aboutWhere.rawValue)"
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:path, parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[User]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    @discardableResult
    public func flairList(_ subreddit: String, link: String = "", name: String = "", completion: @escaping (Result<[FlairTemplate]>) -> Void) throws -> URLSessionDataTask {
        
        var parameter = [
            "link"    : "\(link)",
            "name"    : "\(name)",
        ]
        
        if(link.isEmpty && name.isEmpty){
            parameter = [:]
        } else if(link.isEmpty && !name.isEmpty){
            parameter = [
                "name"    : "\(name)",
            ]
        } else if(!link.isEmpty && name.isEmpty){
            parameter = [
                "link"    : "\(link)",
            ]
        }
        
        let path = "/r/\(subreddit)/api/flairselector"
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:path, parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[FlairTemplate]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }

    @discardableResult
    public func flairSubmission(_ subreddit: String, flairId: String, submissionFullname: String, text: String = "", completion: @escaping (Result<String>) -> Void) throws -> URLSessionDataTask {

        var parameter = [
            "api_type": "json",
            "flair_template_id"    : flairId,
            "link"    : submissionFullname,
        ]

        if(!text.isEmpty){
            parameter["text"] = text
        }

        let path = "/r/\(subreddit)/api/selectflair"
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:path, parameter:parameter, method:"POST", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<String> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                    .flatMap(response2Data)
                    .flatMap(data2String)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }

    /**
     Subscribe to or unsubscribe from a subreddit. The user must have access to the subreddit to be able to subscribe to it.
     - parameter subreddit: Subreddit obect to be subscribed/unsubscribed
     - parameter subscribe: If you want to subscribe it, set true.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func setSubscribeSubreddit(_ subreddit: Subreddit, subscribe: Bool, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameter = ["sr_name":subreddit.displayName]
        parameter["action"] = (subscribe) ? "sub" : "unsub"
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/subscribe", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    /**
     Get all subreddits.
     The where parameter chooses the order in which the subreddits are displayed.
     popular sorts on the activity of the subreddit and the position of the subreddits can shift around.
     new sorts the subreddits based on their creation date, newest first.
     - parameter subredditsWhere: Chooses the order in which the subreddits are displayed among SubredditsWhere.
     - parameter paginator: Paginator object for paging.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getSubreddit(_ subredditWhere: SubredditsWhere, paginator: Paginator?, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        let parameter = paginator?.dictionaryByAdding(parameters: [:])
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:subredditWhere.path, parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Listing> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap({
                    (redditAny: RedditAny) -> Result<Listing> in
                    if let listing = redditAny as? Listing {
                        return Result(value: listing)
                    }
                    return Result(error: ReddiftError.jsonObjectIsNotListingThing as NSError)
                })
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Get subreddits the user has a relationship with. The where parameter chooses which subreddits are returned as follows:
     
     - subscriber - subreddits the user is subscribed to
     - contributor - subreddits the user is an approved submitter in
     - moderator - subreddits the user is a moderator of
     
     - parameter mine: The type of relationship with the user as SubredditsMineWhere.
     - parameter paginator: Paginator object for paging contents.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getUserRelatedSubreddit(_ mine: SubredditsMineWhere, paginator: Paginator, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:mine.path, parameter:paginator.parameterDictionary, method:"GET", token:token)
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
     Search subreddits by title and description.
     
     - parameter query: The search keywords, must be less than 512 characters.
     - parameter paginator: Paginator object for paging.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getSubredditSearch(_ query: String, paginator: Paginator, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        let parameter = paginator.dictionaryByAdding(parameters: ["q":query])
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/subreddits/search", parameter:parameter, method:"GET", token:token)
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
     Search subreddits by title and description.
     
     - parameter query: The search keywords, must be less than 512 characters.
     - parameter paginator: Paginator object for paging.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getSubredditSearchWithErrorHandling(_ query: String, paginator: Paginator, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        let parameter = paginator.dictionaryByAdding(parameters: ["q":query])
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/subreddits/search", parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Listing> in
            let result: Result<Listing> = Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
            return result
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     DOES NOT WORK... WHY?
     */
    @discardableResult
    public func getSticky(_ subreddit: Subreddit, completion: @escaping (Result<RedditAny>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/r/" + subreddit.displayName + "/sticky", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2RedditAny, completion: completion)
    }
}
