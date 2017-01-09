//
//  NSMutableURLRequest+reddift.swift
//  reddift
//
//  Created by sonson on 2015/04/13.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

extension URLRequest {
    
    var curlCommand: String {
        get {
            var command = "curl"
            if let allHTTPHeaderFields = allHTTPHeaderFields {
                for (key, value) in allHTTPHeaderFields {
                    let value = value.replacingOccurrences(of: "\"", with: "\\\"")
                    command += " --header \"\(key): \(value)\""
                }
            }
            if let url = self.url {
                command += " '\(url.absoluteString)'"
            }
            command += " -X \(self.httpMethod)"
            if let data = self.httpBody {
                if var str = String(data: data, encoding: .utf8) {
                    str = str.replacingOccurrences(of: "\"", with: "\\\"")
                    command += " -d \"\(str)\""
                } else {
                    command += " -d <CANNOT PARSE AS STRING DATA>"
                }
            }
            return command
        }
    }
    
    mutating func setRedditBasicAuthentication() throws {
        let basicAuthenticationChallenge = Config.sharedInstance.clientID + ":"
        if let data = basicAuthenticationChallenge.data(using: .utf8) {
            let base64Str = data.base64EncodedString(options: .lineLength64Characters)
            setValue("Basic " + base64Str, forHTTPHeaderField:"Authorization")
        } else {
            throw ReddiftError.canNotCreateDataObjectForClientIDForBasicAuthentication as NSError
        }
    }
    
    mutating func setRedditBasicAuthentication(username: String, password: String) throws {
        let basicAuthenticationChallenge = username + ":" + password
        if let data = basicAuthenticationChallenge.data(using: .utf8) {
            let base64Str = data.base64EncodedString(options: .lineLength64Characters)
            setValue("Basic " + base64Str, forHTTPHeaderField:"Authorization")
        } else {
            throw ReddiftError.canNotCreateDataObjectForUserInfoForBasicAuthentication as NSError
        }
    }
    
    mutating func setOAuth2Token(_ token: Token?) {
        if let token = token {
            setValue("bearer " + token.accessToken, forHTTPHeaderField:"Authorization")
        }
    }
    
    mutating func setUserAgentForReddit() {
        self.setValue(Config.sharedInstance.userAgent, forHTTPHeaderField: "User-Agent")
    }
    
    static func requestForOAuth(with baseURL: String, path: String, method: String, token: Token?) -> URLRequest? {
        guard let URL = URL(string:baseURL + path) else { return nil }
        var request = URLRequest(url: URL)
        request.setOAuth2Token(token)
        request.httpMethod = method
        request.setUserAgentForReddit()
#if _TEST
        print("curl command:\n\(request.curlCommand)")
#endif
        return request
    }
    
    static func requestForOAuth(with baseURL: String, path: String, data: Data, method: String, token: Token?) -> URLRequest? {
        if method == "POST" || method == "PATCH" || method == "PUT" {
            guard let URL = URL(string:baseURL + path) else { return nil }
            var request = URLRequest(url: URL)
            request.setOAuth2Token(token)
            request.httpMethod = method
            request.httpBody = data
            request.setUserAgentForReddit()
#if _TEST
            print("curl command:\n\(request.curlCommand)")
#endif
            return request
        } else { return nil }
    }
    
    static func requestForOAuth(with baseURL: String, path: String, parameter: [String:String]?, method: String, token: Token?) -> URLRequest? {
        if method == "POST" {
            return requestForOAuthPostMethod(with: baseURL, path:path, parameter:parameter ?? [:], method:method, token:token)
        } else {
            return requestForOAuthGetMethod(with: baseURL, path:path, parameter:parameter ?? [:], method:method, token:token)
        }
    }
    
    static func requestForOAuthGetMethod(with baseURL: String, path: String, parameter: [String:String], method: String, token: Token?) -> URLRequest? {
        let param = parameter.URLQuery
        guard let URL = param.characters.isEmpty ? URL(string:baseURL + path) : URL(string:baseURL + path + "?" + param) else { return nil }
        var request = URLRequest(url: URL)
        request.setOAuth2Token(token)
        request.httpMethod = method
        request.setUserAgentForReddit()
#if _TEST
        print("curl command:\n\(request.curlCommand)")
#endif
        return request
    }
    
    static func requestForOAuthPostMethod(with baseURL: String, path: String, parameter: [String:String], method: String, token: Token?) -> URLRequest? {
        guard let URL = URL(string:baseURL + path) else { return nil }
        var request = URLRequest(url: URL)
        request.setOAuth2Token(token)
        request.httpMethod = method
        let data = parameter.URLQuery.data(using: .utf8)
        request.httpBody = data
        request.setUserAgentForReddit()
#if _TEST
        print(request.curlCommand)
#endif
        return request
    }
}
