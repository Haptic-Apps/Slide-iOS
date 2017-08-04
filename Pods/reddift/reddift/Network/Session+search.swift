//
//  Session+search.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

extension Session {
    
    /**
     Search link with query. If subreddit is nil, this method searched links from all of reddit.com.
     
     - parameter subreddit: Specified subreddit to which you would like to limit your search.
     - parameter query: The search keywords, must be less than 512 characters.
     - parameter paginator: Paginator object for paging.
     - parameter sort: Sort type, specified by SearchSortBy.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getSearch(_ subreddit: Subreddit?, query: String, paginator: Paginator, sort: SearchSortBy, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        var path = "/search"
        var restrict = false
        if let subreddit = subreddit {
            path = subreddit.path + "/search.json"
            restrict = true
        }
        if(subreddit != nil && subreddit!.displayName == "all"){
            restrict = false
        }
        
        let parameter = paginator.dictionaryByAdding(parameters: ["q":query, "sort":sort.path, "restrict_sr": restrict ? "yes" : "no"])
        
        guard let request = URLRequest.requestForOAuth(with: "https://reddit.com", path:path, parameter:parameter, method:"GET", token:token)
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
