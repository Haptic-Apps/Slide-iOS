//
//  Session+multireddit.swift
//  reddift
//
//  Created by sonson on 2015/05/19.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
    import UIKit
    public typealias RedditColor = UIColor
#elseif os(macOS)
    import Cocoa
    public typealias RedditColor = NSColor
#endif

/**
Parse JSON dictionary object to the list of Multireddit.

- parameter json: JSON dictionary object is generated NSJSONSeirialize class.

- returns: Result object. Result object has any Thing or Listing object, otherwise error object.
*/
func json2Multireddit(_ json: JSONAny) -> Result<Multireddit> {
    if let json = json as? JSONDictionary {
        if let kind = json["kind"] as? String {
            if kind == "LabeledMulti" {
                if let data = json["data"] as? JSONDictionary {
                    let obj = Multireddit(json: data)
                    return Result(value: obj)
                }
            }
        }
    }
    return Result(error: ReddiftError.multiredditJsonObjectIsNotDictionary as NSError)
}

extension Session {
    /**
    Create a new multireddit. Responds with 409 Conflict if it already exists.
    
    - parameter displayName: A string no longer than 50 characters.
    - parameter descriptionMd: Raw markdown text.
    - parameter iconName: Icon name as MultiIconName.
    - parameter keyColor: Color. as RedditColor object.(does not implement. always uses white.)
    - parameter subreddits: List of subreddits as String array.
    - parameter visibility: Visibility as MultiVisibilityType.
    - parameter weightingScheme: One of `classic` or `fresh`.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func createMultireddit(_ displayName: String, descriptionMd: String, iconName: MultiredditIconName = .none, keyColor: RedditColor = RedditColor.white, visibility: MultiredditVisibility = .private, weightingScheme: String = "classic", completion: @escaping (Result<Multireddit>) -> Void) throws -> URLSessionDataTask {
        guard let token = self.token else { throw ReddiftError.tokenIsNotAvailable as NSError }
        
        let multipath = "/user/\(token.name)/m/\(displayName)"
        let names: [[String:String]] = []
        let json = [
            "description_md" : descriptionMd,
            "display_name" : displayName,
            "icon_name" : "",
            "key_color" : "#FFFFFF",
            "subreddits" : names,
            "visibility" : "private",
            "weighting_scheme" : "classic"
        ] as [String : Any]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            guard let jsonString = String(data:data, encoding:.utf8)
                else { throw ReddiftError.failedToCreateJSONForMultireadditPosting as NSError }
        
            let parameter = ["model":jsonString]
            guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/" + multipath, parameter:parameter, method:"POST", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
            let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Multireddit> in
                return Result(from: Response(data: data, urlResponse: response), optional:error)
                    .flatMap(response2Data)
                    .flatMap(data2Json)
                    .flatMap(json2Multireddit)
            }
            return executeTask(request, handleResponse: closure, completion: completion)
        } catch { throw error }
    }
    
    /**
     Fetch a multi's data and subreddit list by name.
     This API does not work.
     
     - parameter multi: Multireddit object to be deleted.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getMultireddit(_ multi: Multireddit, completion: @escaping (Result<[Multireddit]>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["multipath":multi.path, "expand_srs":"true"]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/" + multi.path, parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[Multireddit]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2MultiredditArray)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Delete the multi.
     
     - parameter multi: Multireddit object to be deleted.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func deleteMultireddit(_ multi: Multireddit, completion: @escaping (Result<String>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/" + multi.path, method:"DELETE", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<String> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2String)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Update the multireddit. Responds with 409 Conflict if it already exists.
     
    - parameter multi: Multireddit object to be updated.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func updateMultireddit(_ multi: Multireddit, completion: @escaping (Result<Multireddit>) -> Void) throws -> URLSessionDataTask {
        let multipath = multi.path
        let names: [[String:String]] = []
        let json = [
            "description_md" : multi.descriptionMd,
            "display_name" : multi.name,
            "icon_name" : multi.iconName.rawValue,
            "key_color" : "#FFFFFF",
            "subreddits" : names,
            "visibility" : multi.visibility.rawValue,
            "weighting_scheme" : "classic"
        ] as [String : Any]
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            if let jsonString = String(data:data, encoding:.utf8) {
                let parameter = ["model":jsonString as String]
                guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/" + multipath, parameter:parameter, method:"PUT", token:token)
                    else { throw ReddiftError.canNotCreateURLRequest as NSError }
                let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Multireddit> in
                    return Result(from: Response(data: data, urlResponse: response), optional:error)
                        .flatMap(response2Data)
                        .flatMap(data2Json)
                        .flatMap(json2Multireddit)
                }
                return executeTask(request, handleResponse: closure, completion: completion)
            } else { throw ReddiftError.failedToCreateJSONForMultireadditPosting as NSError }
        } catch { throw error }
    }
    
    /**
    Fetch a list of public multis belonging to username.
    - parameter username: A valid, existing reddit username
    - parameter expandSrs: Boolean value, default is false.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getPublicMultiredditOfUsername(_ username: String, expandSrs: Bool = false, completion: @escaping (Result<[Multireddit]>) -> Void) throws -> URLSessionDataTask {
        let parameter = ["expand_srs":expandSrs ? "true" : "false", "username":username]
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/user/" + username, parameter:parameter, method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[Multireddit]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2MultiredditArray)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Copy the mulitireddit.
    path	String	"/user/sonson_twit/m/testmultireddit12"
    
    - parameter multi: Multireddit object to be copied.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func copyMultireddit(_ multi: Multireddit, newDisplayName: String, completion: @escaping (Result<Multireddit>) -> Void) throws -> URLSessionDataTask {
        do {
            let parameter = [
                "display_name" : newDisplayName,
                "from" : multi.path,
                "to" : try multi.multiredditPathReplacingNameWith(newDisplayName)
            ]
            guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/copy", parameter:parameter, method:"POST", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
            let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Multireddit> in
                return Result(from: Response(data: data, urlResponse: response), optional:error)
                    .flatMap(response2Data)
                    .flatMap(data2Json)
                    .flatMap(json2Multireddit)
            }
            return executeTask(request, handleResponse: closure, completion: completion)
        } catch { throw error }
    }
    
    /**
    Rename the mulitireddit.
    
    - parameter multi: Multireddit object to be copied.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func renameMultireddit(_ multi: Multireddit, newDisplayName: String, completion: @escaping (Result<Multireddit>) -> Void) throws -> URLSessionDataTask {
        do {
            let parameter = [
                "display_name" : newDisplayName,
                "from" : multi.path,
                "to" : try multi.multiredditPathReplacingNameWith(newDisplayName)
            ]
            guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/rename", parameter:parameter, method:"POST", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
            let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<Multireddit> in
                return Result(from: Response(data: data, urlResponse: response), optional:error)
                    .flatMap(response2Data)
                    .flatMap(data2Json)
                    .flatMap(json2Multireddit)
            }
            return executeTask(request, handleResponse: closure, completion: completion)
        } catch { throw error }
    }

    
    /**
    Add a subreddit to multireddit.
    
    - parameter multireddit: multireddit object
    - parameter subreddit:
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func addSubredditToMultireddit(_ multireddit: Multireddit, subredditDisplayName: String, completion: @escaping (Result<String>) -> Void) throws -> URLSessionDataTask {
        let jsonString = "{\"name\":\"\(subredditDisplayName)\"}"
        let srname = subredditDisplayName
        let parameter = ["model":jsonString, "srname":srname]
    
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/" + multireddit.path + "/r/" + srname, parameter:parameter, method:"PUT", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<String> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap({(json: JSONAny) -> Result<String> in
                    if let json = json as? JSONDictionary {
                        if let subreddit = json["name"] as? String {
                            return Result(value: subreddit)
                        }
                        return Result(error: ReddiftError.multiredditJsonObjectIsMalformed as NSError)
                    }
                    return Result(error: ReddiftError.multiredditJsonObjectIsNotDictionary as NSError)
                })
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }

    /**
     Remove a subreddit from multireddit.
     
     - parameter multireddit: multireddit object
     - parameter subreddit: displayname of subreddit to be removed.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func removeSubredditFromMultireddit(_ multireddit: Multireddit, subredditDisplayName: String, completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let jsonString = "{\"name\":\"\(subredditDisplayName)\"}"
        let srname = subredditDisplayName
        let parameter = ["model":jsonString, "srname":srname]
        
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/" + multireddit.path + "/r/" + srname, parameter:parameter, method:"DELETE", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<JSONAny> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Get users own multireddit.
    
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getMineMultireddit(_ completion: @escaping (Result<[Multireddit]>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/mine", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<[Multireddit]> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2MultiredditArray)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
    Get the description of the specified Multireddit.
    
    - parameter multireddit: multireddit object
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func getMultiredditDescription(_ multireddit: Multireddit, completion: @escaping (Result<MultiredditDescription>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/" + multireddit.path + "/description", method:"GET", token:token)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<MultiredditDescription> in
            return Result(from: Response(data: data, urlResponse: response), optional:error)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(json2RedditAny)
                .flatMap(redditAny2Object)
        }
        return executeTask(request, handleResponse: closure, completion: completion)
    }
    
    /**
     Put the description of the specified Multireddit.
     
     - parameter multireddit: multireddit object
     - parameter description: description as Markdown format.
     - parameter modhash: a modhash, default is blank string.
     - parameter completion: The completion handler to call when the load request is complete.
     - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public func putMultiredditDescription(_ multireddit: Multireddit, description: String, modhash: String = "", completion: @escaping (Result<MultiredditDescription>) -> ()) throws -> URLSessionDataTask {
        let json = ["body_md":description]
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            guard let jsonString = String(data:data, encoding:.utf8)
                else { throw ReddiftError.failedToCreateJSONForMultireadditPosting as NSError }
            
            let parameter = ["model":jsonString]
            guard let request = URLRequest.requestForOAuth(with: baseURL, path:"/api/multi/" + multireddit.path + "/description/", parameter:parameter, method:"PUT", token:token)
                else { throw ReddiftError.canNotCreateURLRequest as NSError }
            let closure = {(data: Data?, response: URLResponse?, error: NSError?) -> Result<MultiredditDescription> in
                return Result(from: Response(data: data, urlResponse: response), optional:error)
                    .flatMap(response2Data)
                    .flatMap(data2Json)
                    .flatMap(json2RedditAny)
                    .flatMap(redditAny2Object)
            }
            return executeTask(request, handleResponse: closure, completion: completion)
        } catch { throw error }
    }
}
