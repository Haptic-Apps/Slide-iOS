//
//  Session+users.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
 The sort method for listing user's subreddit object, "/subreddits/[where]".
 */
public enum NotificationSort: String {
    case new
    case old
    case none
}

/**
 The friend type
 */
public enum FriendType: String {
    case friend
    case enemy
    case moderator
    case moderatorInvite
    case contributor
    case banned
    case muted
    case wikibanned
    case wikicontributor
}

extension Session {
    /**
     Create or update a "friend" relationship.
     This operation is idempotent. It can be used to add a new friend, or update an existing friend (e.g., add/change the note on that friend)
     - parameter username: A valid, existing reddit username.
     - parameter note: A string no longer than 300 characters. This propery does NOT work. Ignored.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func friend(_ username: String, note: String = "", completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var json: [String:String] = [:]
        if !note.isEmpty { json["note"] = note }
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:"/api/v1/me/friends/" + username, data:data, method:"PUT", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
            let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
                return Result(from: Response(data: data, urlResponse: response), optional:error)
                    .flatMap(response2Data)
                    .flatMap(data2Json)
            }
            return executeTask(request, handleResponse: closure, completion: completion)
        } catch {
            throw error
        }
    }
    
    /**
     Stop being friends with a user.
     - parameter username: A valid, existing reddit username.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func unfriend(_ username: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameters = [
            "id":username
        ]
        guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:"/api/v1/me/friends/" + username, parameter:parameters, method:"DELETE", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Get information about a specific 'friend', such as notes.
     - parameter username: A valid, existing reddit username.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getFriends(_ username: String? = nil, completion: @escaping (Result<[User]>) -> Void) throws -> URLSessionDataTask {
        var path = "/api/v1/me/friends"
        if let username = username { path = "/api/v1/me/friends/" + username }
        guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:path, parameter:[:], method:"GET", token:token)
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
    
    /**
     Get information about a specific 'blocked', such as notes.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getBlocked(_ completion: @escaping (Result<[User]>) -> Void) throws -> URLSessionDataTask {
        let path = "/api/v1/me/blocked"
        guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:path, parameter:[:], method:"GET", token:token)
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
    
    /**
     Create a relationship between a user and another user or subreddit.
     OAuth2 use requires appropriate scope based on the 'type' of the relationship:
     * moderator: Use "moderator_invite"
     * moderator_invite: modothers
     * contributor: modcontributors
     * banned: modcontributors
     * muted: modcontributors
     * wikibanned: modcontributors and modwiki
     * wikicontributor: modcontributors and modwiki
     * friend: Use /api/v1/me/friends/{username}
     * enemy: Use /api/block
     - parameter name: the name of an existing user
     - parameter note: a string no longer than 300 characters
     - parameter banMessageMd: raw markdown text
     - parameter duration: an integer between 1 and 999
     - parameter type: FriendType
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func friend(_ name: String, note: String, banMessageMd: String, container: String, duration: Int, type: FriendType, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameters = [
            "container":container,
            "name":name,
            "type":"friend"
//            "uh":modhash
        ]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/friend", parameter:parameters, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Remove a relationship between a user and another user or subreddit
     The user can either be passed in by name (nuser) or by fullname (iuser).
     If type is friend or enemy, 'container' MUST be the current user's fullname; for other types, the subreddit must be set via URL (e.g., /r/funny/api/unfriend)
     OAuth2 use requires appropriate scope based on the 'type' of the relationship:
     * moderator: modothers
     * moderator_invite: modothers
     * contributor: modcontributors
     * banned: modcontributors
     * muted: modcontributors
     * wikibanned: modcontributors and modwiki
     * wikicontributor: modcontributors and modwiki
     * friend: Use /api/v1/me/friends/{username}
     * enemy: privatemessages
     - parameter name: the name of an existing user
     - parameter id: fullname of a thing
     - parameter type: FriendType
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func unfriend(_ name: String = "", id: String = "", type: FriendType, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameters = [
            "type":type.rawValue
//            "uh":modhash
        ]
        
        if !name.isEmpty { parameters["name"] = name }
        if !id.isEmpty { parameters["id"] = id }
        
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/unfriend", parameter:parameters, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Get my notifications.
     - parameter sort: Sort type of notifications, as NotificationSort.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getNotifications(_ sort: NotificationSort, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameters = [
            "count":"30",
//            "start_date":"",
//            "end_date":"",
            "sort":sort.rawValue
        ]
        guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:"/api/v1/me/notifications", parameter:parameters, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Mark a notification as read or unread.
     - parameter id: Notification's ID.
     - parameter read: true or false as boolean.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func setNotifications(_ id: Int, read: Bool, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let json = [
            "read": read ? "true" : "false"
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:"/api/v1/me/notifications/\(id)", data:data, method:"PATCH", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
            let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
                return Result(from: Response(data: data, urlResponse: response), optional:error)
                    .flatMap(response2Data)
                    .flatMap(data2Json)
            }
            return executeTask(request, handleResponse: closure, completion: completion)
        } catch { throw error }
    }
    
    /**
     Return a list of trophies for the specified user.
     - parameter username: Name of user.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getTrophies(_ username: String, completion: @escaping (Result<[Trophy]>) -> Void) throws -> URLSessionDataTask {
        let path = "/api/v1/user/\(username)/trophies"
        guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:path, method:"GET", token:token)
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
    
    /**
    Get Links or Comments that a user liked, saved, commented, hide, diskiked and etc.
    - parameter username: Name of user.
    - parameter content: The type of user's contents as UserContent.
    - parameter paginator: Paginator object for paging contents.
    - parameter limit: The maximum number of comments to return. Default is 25.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getUserContent(_ username: String, content: UserContent, sort: UserContentSortBy, timeFilterWithin: TimeFilterWithin, paginator: Paginator, limit: Int = 25, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        let parameter = paginator.dictionaryByAdding(parameters: [
            "limit"    : "\(limit)",
//          "sr_detail": "true",
            "sort"     : sort.param,
            "show"     : "given"
            ])
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/user/" + username + content.path + ".json", parameter:parameter, method:"GET", token:token)
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
    Return information about the user, including karma and gold status.
    - parameter username: The name of an existing user
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getUserProfile(_ username: String, completion: @escaping (Result<Account>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/user/\(username)/about.json", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Account> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
}
