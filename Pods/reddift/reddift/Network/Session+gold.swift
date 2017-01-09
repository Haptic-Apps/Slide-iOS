//
//  Session+gold.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

extension Session {
    /**
     Reddit gold?
     Gilds the specified content by fullname?
     - parameter fullname: fullname of a thing
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func gild(_ fullname: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["fullname":fullname]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/v1/gold/gild/", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Reddit gold?
     Gives gold to the specified user whose name is specified by username?
     - parameter username: A valid, existing reddit username
     - parameter months: an integer between 1 and 36
     - returns: Data task which requests search to reddit.com.
     */
    public func giveGold(_ username: String, months: Int, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["fullname":username, "months":String(months)]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/v1/gold/give/", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
}
