//
//  Session+CAPTCHA.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
    import UIKit
    public typealias CAPTCHAImage = UIImage
#elseif os(macOS)
    import Cocoa
    public typealias CAPTCHAImage = NSImage
#endif

/**
Parse simple string response for "/api/needs_captcha"

- parameter data: Binary data is returned from reddit.

- returns: Result object. If data is "true" or "false", Result object has boolean, otherwise error object.
*/
func data2Bool(_ data: Data) -> Result<Bool> {
    if let decoded = String(data:data, encoding:.utf8) {
        if decoded == "true" {
            return Result(value:true)
        } else if decoded == "false" {
            return Result(value:false)
        }
    }
    return Result(error:ReddiftError.needsCAPTCHAResponseIsInvalid as NSError)
}

/**
Parse simple string response for "/api/needs_captcha"

- parameter data: Binary data is returned from reddit.

- returns: Result object. If data is "true" or "false", Result object has boolean, otherwise error object.
*/
func data2Image(_ data: Data) -> Result<CAPTCHAImage> {
#if os(iOS) || os(tvOS)
    let captcha = UIImage(data: data)
#elseif os(macOS)
    let captcha = NSImage(data: data)
#endif
    return Result(fromOptional: captcha, error: ReddiftError.imageOfCAPTCHAIsInvalid as NSError)
}

/**
Parse JSON contains "iden" for CAPTHA.
{"json": {"data": {"iden": "<code>"},"errors": []}}

- parameter json: JSON object, like above sample.
- returns: Result object. When parsing is succeeded, object contains iden as String.
*/
func idenJSON2String(_ json: JSONAny) -> Result<String> {
    if let json = json as? JSONDictionary {
        if let j = json["json"] as? JSONDictionary {
            if let data = j["data"] as? JSONDictionary {
                if let iden = data["iden"] as? String {
                    return Result(value:iden)
                }
            }
        }
    }
    return Result(error:ReddiftError.identifierOfCAPTCHAIsMalformed as NSError)
}

extension Session {
    /**
    Check whether CAPTCHAs are needed for API methods that define the "captcha" and "iden" parameters.
    
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func checkNeedsCAPTCHA(_ completion: @escaping (Result<Bool>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/needs_captcha", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Bool> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Bool)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Responds with an iden of a new CAPTCHA.
    Use this endpoint if a user cannot read a given CAPTCHA, and wishes to receive a new CAPTCHA.
    To request the CAPTCHA image for an iden, use /captcha/iden.
    
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getIdenForNewCAPTCHA(_ completion: @escaping (Result<String>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["api_type":"json"]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/new_captcha", parameter:parameter, method:"POST", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<String> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(idenJSON2String)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Request a CAPTCHA image for given an iden.
    An iden is given as the captcha field with a BAD_CAPTCHA error, you should use this endpoint if you get a BAD_CAPTCHA error response.
    Responds with a 120x50 image/png which should be displayed to the user.
    The user's response to the CAPTCHA should be sent as captcha along with your request.
    To request a new CAPTCHA, Session.getIdenForNewCAPTCHA.
    
    - parameter iden: Code to get a new CAPTCHA. Use Session.getIdenForNewCAPTCHA.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getCAPTCHA(_ iden: String, completion: @escaping (Result<CAPTCHAImage>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/captcha/" + iden, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<CAPTCHAImage> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Image)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Request a CAPTCHA image
    Responds with a 120x50 image/png which should be displayed to the user.
    The user's response to the CAPTCHA should be sent as captcha along with your request.
    
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
    */
    public func getCAPTCHA(_ completion: @escaping (Result<CAPTCHAImage>) -> Void) throws -> Void {
        do {
            try getIdenForNewCAPTCHA { (result) -> Void in
                switch result {
                case .failure(let error):
                    completion(Result(error: error))
                case .success(let iden):
                    do {
                        try self.getCAPTCHA(iden, completion:completion)
                    } catch { completion(Result(error: error as NSError)) }
                }
            }
        } catch { completion(Result(error: error as NSError)) }
    }
}
