//
//  RDTOAuth2Token.swift
//  reddift
//
//  Created by sonson on 2015/04/11.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
OAuth2 token for access reddit.com API.
*/
public struct OAuth2Token: Token {
    public static let baseURL = "https://www.reddit.com/api/v1"
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: Int
    public let scope: String
    public let refreshToken: String
    public let name: String
    public let expiresDate: TimeInterval
    
    /**
    Initialize vacant OAuth2AppOnlyToken with JSON.
    */
    public init() {
        self.name = ""
        self.accessToken = ""
        self.tokenType = ""
        self.expiresIn = 0
        self.scope = ""
        self.refreshToken = ""
        self.expiresDate = Date.timeIntervalSinceReferenceDate + 0
    }
    
    /**
    Initialize OAuth2AppOnlyToken with JSON.
    
    - parameter json: JSON as JSONDictionary should include "name", "access_token", "token_type", "expires_in", "scope" and "refresh_token".
    */
    public init(_ json: JSONDictionary) {
        self.name = json["name"] as? String ?? ""
        self.accessToken = json["access_token"] as? String ?? ""
        self.tokenType = json["token_type"] as? String ?? ""
        let expiresIn = json["expires_in"] as? Int ?? 0
        self.expiresIn = expiresIn
        self.expiresDate = json["expires_date"] as? TimeInterval ?? Date.timeIntervalSinceReferenceDate + Double(expiresIn)
        self.scope = json["scope"] as? String ?? ""
        self.refreshToken = json["refresh_token"] as? String ?? ""
    }
    
    /**
    Create OAuth2Token object from JSON.
    
    - parameter json: JSON object as JSONDictionary must include "name", "access_token", "token_type", "expires_in", "scope" and "refresh_token". If it does not, returns Result<NSError>.
    - returns: OAuth2Token object includes a new access token.
    */
    static func tokenWithJSON(_ json: JSONAny) -> Result<OAuth2Token> {
        if let json = json as? JSONDictionary {
            if let _ = json["access_token"] as? String,
                let _ = json["token_type"] as? String,
                let _ = json["expires_in"] as? Int,
                let _ = json["scope"] as? String,
                let _ = json["refresh_token"] as? String {
                    return Result(value: OAuth2Token(json))
            }
        }
        return Result(error:ReddiftError.tokenJsonObjectIsNotDictionary as NSError)
    }
    
    /**
    Create URLRequest object to request getting an access token.
    
    - parameter code: The code which is obtained from OAuth2 redict URL at reddit.com.
    - returns: URLRequest object to request your access token.
    */
    static func requestForOAuth(_ code: String) -> URLRequest? {
        guard let URL = URL(string: OAuth2Token.baseURL + "/access_token") else { return nil }
        var request = URLRequest(url:URL)
        do {
            try request.setRedditBasicAuthentication()
            let param = "grant_type=authorization_code&code=" + code + "&redirect_uri=" + Config.sharedInstance.redirectURI
            let data = param.data(using: .utf8)
            request.httpBody = data
            request.httpMethod = "POST"
            return request
        } catch {
            print(error)
            return nil
        }
    }
    
    /**
    Create request object for refreshing access token.
    
    - returns: URLRequest object to request refreshing your access token.
    */
    public func requestForRefreshing() -> URLRequest? {
        guard let URL = URL(string: OAuth2Token.baseURL + "/access_token") else { return nil }
        var request = URLRequest(url:URL)
        do {
            try request.setRedditBasicAuthentication()
            let param = "grant_type=refresh_token&refresh_token=" + refreshToken
            let data = param.data(using: .utf8)
            request.httpBody = data
            request.httpMethod = "POST"
            return request
        } catch {
            print(error)
            return nil
        }
    }
    
    /**
    Create request object for revoking access token.
    
    - returns: URLRequest object to request revoking your access token.
    */
    func requestForRevoking() -> URLRequest? {
        guard let URL = URL(string: OAuth2Token.baseURL + "/revoke_token") else { return nil }
        var request = URLRequest(url:URL)
        do {
            try request.setRedditBasicAuthentication()
            let param = "token=" + accessToken + "&token_type_hint=access_token"
            let data = param.data(using: .utf8)
            request.httpBody = data
            request.httpMethod = "POST"
            return request
        } catch {
            print(error)
            return nil
        }
    }
    
    /**
    Request to refresh access token.
    
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
    */
    @discardableResult
    public func refresh(_ completion: @escaping (Result<OAuth2Token>) -> Void) throws -> URLSessionDataTask {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        guard let request = requestForRefreshing()
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            let result = Result(from: Response(data: data, urlResponse: response), optional:error as NSError?)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap({(json: JSONAny) -> Result<JSONDictionary> in
                    if let json = json as? JSONDictionary {
                        return Result(value: json)
                    }
                    return Result(error: ReddiftError.tokenJsonObjectIsNotDictionary as NSError)
                })
            switch result {
            case .success(let json):
                var newJSON = json
                newJSON["name"] = self.name as AnyObject
                newJSON["refresh_token"] = self.refreshToken as AnyObject
                completion(OAuth2Token.tokenWithJSON(newJSON))
            case .failure(let error):
                completion(Result(error: error))
            }
        })
        task.resume()
        return task
    }
    
    /**
    Request to revoke access token.
    
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
    */
    @discardableResult
    public func revoke(_ completion: @escaping (Result<JSONAny>) -> Void) throws -> URLSessionDataTask {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        guard let request = requestForRevoking()
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            let result = Result(from: Response(data: data, urlResponse: response), optional:error as NSError?)
                .flatMap(response2Data)
                .flatMap(data2Json)
            completion(result)
        })
        task.resume()
        return task
    }
    
    /**
    Request to get a new access token.
    
    - parameter code: Code to be confirmed your identity by reddit.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
    */
    @discardableResult
    public static func getOAuth2Token(_ code: String, completion: @escaping (Result<OAuth2Token>) -> Void) throws -> URLSessionDataTask {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        guard let request = requestForOAuth(code)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            let result = Result(from: Response(data: data, urlResponse: response), optional:error as NSError?)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap(OAuth2Token.tokenWithJSON)
            switch result {
            case .success(let token):
                do {
                    try token.getProfile({ (result) -> Void in
                        completion(result)
                    })
                } catch { completion(Result(error: error as NSError)) }
            case .failure:
                completion(result)
            }
        })
        task.resume()
        return task
    }
    
    /**
    Request to get user's own profile. Don't use this method after getting access token correctly.
    Use Session.getProfile instead of this.
    
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    func getProfile(_ completion: @escaping (Result<OAuth2Token>) -> Void) throws -> URLSessionDataTask {
        guard let request = URLRequest.requestForOAuth(with: Session.OAuthEndpointURL, path:"/api/v1/me", method:"GET", token:self)
            else { throw ReddiftError.canNotCreateURLRequest as NSError }
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            let result = Result(from: Response(data: data, urlResponse: response), optional:error as NSError?)
                .flatMap(response2Data)
                .flatMap(data2Json)
                .flatMap({ (json: JSONAny) -> Result<Account> in
                    if let object = json as? JSONDictionary {
                        return Result(fromOptional: Account(json: object), error: ReddiftError.accountJsonObjectIsMalformed as NSError)
                    }
                    return Result(error: ReddiftError.accountJsonObjectIsNotDictionary as NSError)
                })
            switch result {
            case .success(let profile):
                let json = ["name":profile.name, "access_token":self.accessToken, "token_type":self.tokenType, "expires_in":self.expiresIn, "expires_date":self.expiresDate, "scope":self.scope, "refresh_token":self.refreshToken] as [String : Any]
                completion(OAuth2Token.tokenWithJSON(json))
            case .failure(let error):
                completion(Result(error: error))
            }
        })
        task.resume()
        return task
    }
}
