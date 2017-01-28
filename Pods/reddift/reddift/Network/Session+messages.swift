//
//  Session+messages.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

extension Session {
    
    // MARK: Update message status
    
    /**
    Mark messages as "unread"
    - parameter id: A comma-separated list of thing fullnames
    - parameter modhash: A modhash, default is blank string not nil.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func markMessagesAsUnread(_ fullnames: [String], modhash: String = "", completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let commaSeparatedFullameString = fullnames.joined(separator: ",")
        let parameter = ["id":commaSeparatedFullameString]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/unread_message", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Mark messages as "read"
    - parameter id: A comma-separated list of thing fullnames
    - parameter modhash: A modhash, default is blank string not nil.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func markMessagesAsRead(_ fullnames: [String], modhash: String = "", completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let commaSeparatedFullameString = fullnames.joined(separator: ",")
        let parameter = ["id":commaSeparatedFullameString]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/read_message", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Mark all messages as "read"
     Queue up marking all messages for a user as read.
     This may take some time, and returns 202 to acknowledge acceptance of the request.
     - parameter modhash: A modhash, default is blank string not nil.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func markAllMessagesAsRead(_ modhash: String = "", completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/read_all_messages", parameter:nil, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Collapse messages
     - parameter id: A comma-separated list of thing fullnames
     - parameter modhash: A modhash, default is blank string not nil.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func collapseMessages(_ fullnames: [String], modhash: String = "", completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let commaSeparatedFullameString = fullnames.joined(separator: ",")
        let parameter = ["id":commaSeparatedFullameString]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/collapse_message", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Uncollapse messages
     - parameter id: A comma-separated list of thing fullnames
     - parameter modhash: A modhash, default is blank string not nil.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func uncollapseMessages(_ fullnames: [String], modhash: String = "", completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let commaSeparatedFullameString = fullnames.joined(separator: ",")
        let parameter = ["id":commaSeparatedFullameString]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/uncollapse_message", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     For blocking via inbox.
     - parameter id: fullname of a thing
     - parameter modhash: A modhash, default is blank string not nil.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func blockViaInbox(_ fullname: String, modhash: String = "", completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["id":fullname]
        guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:"/api/block", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     For unblocking via inbox.
     - parameter id: fullname of a thing
     - parameter modhash: A modhash, default is blank string not nil.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func unblockViaInbox(_ fullname: String, modhash: String = "", completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["id":fullname]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/unblock_subreddit", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    // MARK: Get messages
    
    /**
    Get the message from the specified box.
    - parameter messageWhere: The box from which you want to get your messages.
    - parameter limit: The maximum number of comments to return. Default is 100.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getMessage(_ messageWhere: MessageWhere, limit: Int = 100, completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/message" + messageWhere.path, method:"GET", token:token)
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
    
    // MARK: Compose a message
    
    /**
    Compose new message to specified user.
    - parameter to: Account object of user to who you want to send a message.
    - parameter subject: A string no longer than 100 characters
    - parameter text: Raw markdown text
    - parameter fromSubreddit: Subreddit name?
    - parameter captcha: The user's response to the CAPTCHA challenge
    - parameter captchaIden: The identifier of the CAPTCHA challenge
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func composeMessage(_ to: String, subject: String, text: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameter = [
            "api_type" : "json",
            "text" : text,
            "subject" : subject,
            "to" : to
        ]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/compose", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
}
