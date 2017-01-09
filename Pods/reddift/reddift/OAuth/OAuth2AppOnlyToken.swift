//
//  OAuth2AppOnlyToken.swift
//  reddift
//
//  Created by sonson on 2015/05/05.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
OAuth2Token extension to authorize without a user context.
This class is private and for only unit testing because "Installed app" is prohibited from using "Application Only OAuth" scheme, that is without user context.
*/
public struct OAuth2AppOnlyToken: Token {
    public static let baseURL = "https://www.reddit.com/api/v1"
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: Int
    public let scope: String
    public let refreshToken: String
    public let name: String
    public let expiresDate: TimeInterval
    
    /**
    Time inteval the access token expires from being authorized.
    */
//    public var expiresIn:Int {
//        set (newValue) { _expiresIn = newValue; expiresDate = NSDate.timeIntervalSinceReferenceDate() + Double(_expiresIn) }
//        get { return _expiresIn }
//    }
    
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
    Create URLRequest object to request getting an access token.
    
    - parameter code: The code which is obtained from OAuth2 redict URL at reddit.com.
    - returns: URLRequest object to request your access token.
    */
    public static func requestForOAuth2AppOnly(username: String, password: String, clientID: String, secret: String) -> URLRequest? {
        guard let URL = URL(string: "https://ssl.reddit.com/api/v1/access_token") else { return nil }
        var request = URLRequest(url:URL)
        do {
            try request.setRedditBasicAuthentication(username:clientID, password:secret)
            let param = "grant_type=password&username=" + username + "&password=" + password
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
    Request to get a new access token.
    
    - parameter code: Code to be confirmed your identity by reddit.
    - parameter completion: The completion handler to call when the load request is complete.
    - returns: Data task which requests search to reddit.com.
     */
    @discardableResult
    public static func getOAuth2AppOnlyToken(username: String, password: String, clientID: String, secret: String, completion: @escaping (Result<Token>) -> Void) throws -> URLSessionDataTask {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        guard let request = requestForOAuth2AppOnly(username:username, password:password, clientID:clientID, secret:secret)
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
            var token: OAuth2AppOnlyToken? = nil
            switch result {
            case .success(let json):
                var newJSON = json
                newJSON["name"] = username as AnyObject
                token = OAuth2AppOnlyToken(newJSON)
            default:
                break
            }
            completion(Result(fromOptional: token, error: ReddiftError.unknown as NSError))
        })
        task.resume()
        return task
    }
}
