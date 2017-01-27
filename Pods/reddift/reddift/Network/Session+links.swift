//
//  Session+links.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

extension Session {
    /**
    Submit a new comment or reply to a message, whose parent is the fullname of the thing being replied to.
    Its value changes the kind of object created by this request:
    
    - the fullname of a Link: a top-level comment in that Link's thread.
    - the fullname of a Comment: a comment reply to that comment.
    - the fullname of a Message: a message reply to that message.
    
    Response is JSON whose type is t1 Thing.
    
    - parameter text: The body of comment, should be the raw markdown body of the comment or message.
    - parameter parentName: Name of Thing is commented or replied to.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func postComment(_ text: String, parentName: String, completion: @escaping (Result<Comment>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["thing_id":parentName, "api_type":"json", "text":text]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/comment", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Comment> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2Comment)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
     /**
     Submit a reply to a message, whose parent is the fullname of the thing being replied to.
     Its value changes the kind of object created by this request:
     
     - the fullname of a Link: a top-level comment in that Link's thread.
     - the fullname of a Message: a message reply to that message.
     
     Response is JSON whose type is t1 Thing.
     
     - parameter text: The body of comment, should be the raw markdown body of the comment or message.
     - parameter parentName: Name of Thing is commented or replied to.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func replyMessage(_ text: String, parentName: String, completion: @escaping (Result<RedditAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["thing_id":parentName, "api_type":"json", "text":text]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/comment", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<RedditAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }

    /**
    Delete a Link or Comment.
    
    - parameter thing: Thing object to be deleted.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func deleteCommentOrLink(_ name: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["id":name]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/del", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    /**
     Edit a Link or Comment.
     
     - parameter thing: Thing object to be edited.
     - parameter newBody: String value of new body
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func editCommentOrLink(_ name: String, newBody: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["thing_id":name, "text": newBody]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/editusertext", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    /**
    Vote specified thing.
    
    - parameter direction: The type of voting direction as VoteDirection.
    - parameter thing: Thing will be voted.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func setVote(_ direction: VoteDirection, name: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["dir":String(direction.rawValue), "id":name]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/vote", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    /**
    Save a specified content.
    
    - parameter save: If you want to save the content, set to "true". On the other, if you want to remove the content from saved content, set to "false".
    - parameter name: Name of Thing will be saved/unsaved.
    - parameter category: Name of category into which you want to saved the content
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func setSave(_ save: Bool, name: String, category: String = "", completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameter = ["id":name]
        if !category.isEmpty {
            parameter["category"] = category
        }
        let path = save ? "/api/save" : "/api/unsave"
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:path, parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    /**
    Set hide/show a specified content.
    
    - parameter save: If you want to hide the content, set to "true". On the other, if you want to show the content, set to "false".
    - parameter name: Name of Thing will be hide/show.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func setHide(_ hide: Bool, name: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["id":name]
        let path = hide ? "/api/hide" : "/api/unhide"
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:path, parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    /**
    Return a listing of things specified by their fullnames.
    Only Links, Comments, and Subreddits are allowed.
    
    - parameter names: Array of contents' fullnames.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getInfo(_ names: [String], completion: @escaping (Result<Listing>) -> Void) throws -> URLSessionDataTask {
        let commaSeparatedNameString = names.joined(separator: ",")
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/info", parameter:["id":commaSeparatedNameString], method:"GET", token:token)
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
    Mark or unmark a link NSFW.

    - parameter thing: Thing object, to set fullname of a thing.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func setNSFW(_ mark: Bool, thing: Thing, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let path = mark ? "/api/marknsfw" : "/api/unmarknsfw"
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:path, parameter:["id":thing.name], method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    // MARK: BDT does not cover following methods.
    
    /**
    Get a list of categories in which things are currently saved.
    
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getSavedCategories(_ completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/saved_categories", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    /**
    Report a link, comment or message.
    Reporting a thing brings it to the attention of the subreddit's moderators. Reporting a message sends it to a system for admin review.
    For links and comments, the thing is implicitly hidden as well.
    
    - parameter thing: Thing object, to set fullname of a thing.
    - parameter reason: Reason of a string no longer than 100 characters.
    - parameter otherReason: The other reason of a string no longer than 100 characters.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func report(_ thing: Thing, reason: String, otherReason: String, completion: @escaping (Result<RedditAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = [
            "api_type"    :"json",
            "reason"      :reason,
            "other_reason":otherReason,
            "thing_id"    :thing.name
        ]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/report", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2RedditAny, completion: completion)
    }
    
    /**
    Submit a link to a subreddit.
    
    - parameter subreddit: The subreddit to which is submitted a link.
    - parameter title: The title of the submission. up to 300 characters long.
    - parameter URL: A valid URL
    - parameter captcha: The user's response to the CAPTCHA challenge
    - parameter captchaIden: The identifier of the CAPTCHA challenge
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func submitLink(_ subreddit: Subreddit, title: String, URL: String, captcha: String, captchaIden: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = [
            "api_type" : "json",
            "captcha" : captcha,
            "iden" : captchaIden,
            "kind" : "link",
            "resubmit" : "true",
            "sendreplies" : "true",
            "sr" : subreddit.displayName,
            "title" : title,
            "url" : URL
        ]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/submit", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    /**
    Submit a text to a subreddit.
    Response JSON is,  {"json":{"data":{"id":"35ljt6","name":"t3_35ljt6","url":"https://www.reddit.com/r/sandboxtest/comments/35ljt6/this_is_test/"},"errors":[]}}
    
    - parameter subreddit: The subreddit to which is submitted a link.
    - parameter title: The title of the submission. up to 300 characters long.
    - parameter text: Raw markdown text
    - parameter captcha: The user's response to the CAPTCHA challenge
    - parameter captchaIden: The identifier of the CAPTCHA challenge
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func submitText(_ subreddit: Subreddit, title: String, text: String, captcha: String, captchaIden: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = [
            "api_type" : "json",
            "captcha" : captcha,
            "iden" : captchaIden,
            "kind" : "self",
            "resubmit" : "true",
            "sendreplies" : "true",
            "sr" : subreddit.displayName,
            "text" : text,
            "title" : title
        ]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/submit", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    /**
     Retrieve additional comments omitted from a base comment tree. When a comment tree is rendered, the most relevant comments are selected for display first.
     Remaining comments are stubbed out with "MoreComments" links. This API call is used to retrieve the additional comments represented by those stubs, up to 20 at a time.
     The two core parameters required are link and children. link is the fullname of the link whose comments are being fetched.
     children is a comma-delimited list of comment ID36s that need to be fetched. If id is passed, it should be the ID of the MoreComments object this call is replacing.
     This is needed only for the HTML UI's purposes and is optional otherwise. 
     NOTE: you may only make one request at a time to this API endpoint. Higher concurrency will result in an error being returned.
     - parameter children: A comma-delimited list of comment ID36s.
     - parameter link: Thing object from which you get more children.
     - parameter sort: The type of sorting children.
     - parameter id: (optional) id of the associated MoreChildren object.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getMoreChildren(_ children: [String], link: Link, sort: CommentSort, id: String? = nil, completion: @escaping (Result<[Thing]>) -> Void) throws -> URLSessionDataTask {
        let commaSeparatedChildren = children.joined(separator: ",")
        var parameter = [
            "children":commaSeparatedChildren,
            "link_id":link.name,
            "sort":sort.type,
            "api_type":"json"
        ]
        if let id = id {
            parameter["id"] = id
        }
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/morechildren", parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[Thing]> in
            print(response?.url?.absoluteString)
            print(String(data: data!, encoding: String.Encoding.utf8))
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2CommentAndMore)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
}
