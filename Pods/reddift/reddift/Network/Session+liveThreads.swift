//
//  Session+liveThreads.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//
import Foundation

extension Session {
    @discardableResult
    public func getLiveThreadDetails(_ id: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/live/\(id)/about.json", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    func json2Things(from json: JSONAny) -> Result<[JSONAny]> {
        if let json = json as? JSONDictionary, let data = json["data"] as? JSONDictionary, let things = data["children"] as? JSONArray {
            // No error?
            return Result(value: things)
        } else if let json = json as? JSONDictionary, let j = json["json"] as? JSONDictionary, let errors = j["errors"] as? JSONArray {
            // Error happened.
            for obj in errors {
                if let errorStrings = obj as? [String] {
                    print(errorStrings)
                    return Result(error: ReddiftError.commentJsonObjectIsMalformed as NSError)
                }
            }
        }
        return Result(error: ReddiftError.commentJsonObjectIsMalformed as NSError)
    }
    
    @discardableResult
    public func getCurrentThreads(_ id: String, completion: @escaping (Result<[JSONAny]>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/live/\(id).json", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[JSONAny]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(self.json2Things)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
}
