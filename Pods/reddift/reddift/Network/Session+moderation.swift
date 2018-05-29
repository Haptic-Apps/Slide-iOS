//
//  Session+moderation.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

extension Session {
    @discardableResult
    public func approve(_ name: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["id":name]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/approve", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }
    
    @discardableResult
    public func distinguish(_ name: String, how : String? = nil, sticky : Bool? = nil, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameter = ["id":name, "api_type": "json"]
        if(how != nil){
            parameter["how"] = how!
        }
        if(sticky != nil){
            parameter["sticky"] = String(sticky!)
        }
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/distinguish", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }

    @discardableResult
    public func sticky(_ name: String, sticky : Bool, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameter = ["id":name, "api_type": "json", "state" : String(sticky)]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/set_subreddit_sticky", parameter:parameter, method:"POST", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }

    @discardableResult
    public func setNSFW(_ name: String, nsfw : Bool, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameter = ["id":name]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path: nsfw ? "/api/marknsfw" : "/api/unmarknsfw", parameter:parameter, method:"POST", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }

    @discardableResult
    public func setSpoiler(_ name: String, spoiler : Bool, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameter = ["id":name]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path: spoiler ? "/api/spoiler" : "/api/unspoiler", parameter:parameter, method:"POST", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }

    @discardableResult
    public func setLocked(_ name: String, locked : Bool, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameter = ["id":name]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path: locked ? "/api/lock" : "/api/unlock", parameter:parameter, method:"POST", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }

    @discardableResult
    public func remove(_ name: String, spam: Bool? = nil, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameter = ["id":name]
        if(spam != nil){
            parameter["spam"] = String(spam!)
        }
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/remove", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }

    @discardableResult
    public func ban(_ name: String, banContext: String? = nil, banReason: String, duration: Int = 999, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        var parameter = ["api_type":"json",
                         "name" : name,
                         "ban_reason": banReason,
                         "type": "banned",
                         "duration": String(duration)]
        if(banContext != nil){
            parameter["ban_context"] = banContext!
        }
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/friend", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        return executeTask(request, handleResponse: handleResponse2JSON, completion: completion)
    }

}
