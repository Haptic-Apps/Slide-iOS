//
//  Session+account.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

extension Session {
    /**
     Get preference
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getPreference(_ completion: @escaping (Result<Preference>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:"/api/v1/me/prefs", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Preference> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2Preference)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     DOES NOT WORK, I CAN NOT UNDERSTAND WHY IT DOES NOT.
     Patch preference with Preference object.
     - parameter preference: Preference object.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func patchPreference(_ preference: Preference, completion: @escaping (Result<Preference>) -> Void) throws -> URLSessionDataTask {
        let json = preference.json()
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:"/api/v1/me/prefs", data:data, method:"PATCH", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
            let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Preference> in
                return Result(from: Response(data: data, urlResponse: response), optional:error)
                    .flatMap(response2Data)
                    .flatMap(data2Json)
                    .flatMap(json2Preference)
            }
            return executeTask(request, handleResponse: closure, completion: completion)
        } catch { throw error }
    }
    
    /**
     Get friends
     - parameter paginator: Paginator object for paging contents.
     - parameter limit: The maximum number of comments to return. Default is 25.
     - parameter count: A positive integer (default: 0)
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getFriends(_ paginator: Paginator, count: Int = 0, limit: Int = 1, completion: @escaping (Result<RedditAny>) -> Void) throws -> URLSessionDataTask {
        do {
            let parameter = paginator.dictionaryByAdding(parameters: [
                "limit"    : "\(limit)",
                "show"     : "all",
                "count"    : "\(count)"
                //          "sr_detail": "true",
                ])
            guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/prefs/friends", parameter:parameter, method:"GET", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
            let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<RedditAny> in
                return Result(from: Response(data: data, urlResponse: response), optional:error)
                    .flatMap(response2Data)
                    .flatMap(data2Json)
                    .flatMap(json2RedditAny)
            }
            return executeTask(request, handleResponse: closure, completion: completion)
        } catch { throw error }
    }
    
    /**
     Get blocked
     - parameter paginator: Paginator object for paging contents.
     - parameter limit: The maximum number of comments to return. Default is 25.
     - parameter count: A positive integer (default: 0)
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getBlocked(_ paginator: Paginator, count: Int = 0, limit: Int = 25, completion: @escaping (Result<[User]>) -> Void) throws -> URLSessionDataTask {
        do {
            let parameter = paginator.dictionaryByAdding(parameters: [
                "limit"    : "\(limit)",
                "show"     : "all",
                "count"    : "\(count)"
                //          "sr_detail": "true",
                ])
            guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/prefs/blocked", parameter:parameter, method:"GET", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
            let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[User]> in
                return Result(from: Response(data: data, urlResponse: response), optional:error)
                    .flatMap(response2Data)
                    .flatMap(data2Json)
                    .flatMap(json2RedditAny)
                    .flatMap(redditAny2Object)
            }
            return executeTask(request, handleResponse: closure, completion: completion)
        } catch { throw error }
    }
    
    /**
     Return a breakdown of subreddit karma.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getKarma(_ completion: @escaping (Result<[SubredditKarma]>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/v1/me/karma", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[SubredditKarma]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Return a list of trophies for the current user.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getTrophies(_ completion: @escaping (Result<[Trophy]>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/v1/me/trophies", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[Trophy]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    public func requestForGettingProfile() throws -> URLRequest {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/v1/me", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return request
    }
    
    /**
    Gets the identity of the user currently authenticated via OAuth.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getProfile(_ completion: @escaping (Result<Account>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/v1/me", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure: (_ data: Data?, _ response: URLResponse?, _ error: NSError?) -> Result<Account> = accountInResult
        return executeTask(request, handleResponse: closure, completion: completion)
    }
}
