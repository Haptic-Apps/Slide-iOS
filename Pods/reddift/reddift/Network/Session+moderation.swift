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
