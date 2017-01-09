//
//  Token.swift
//  reddift
//
//  Created by sonson on 2015/05/28.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
Protocol for OAuthToken.
*/
public protocol Token {
    /// token
    var accessToken: String {get}
    /// the type of token
    var tokenType: String {get}
    var expiresIn: Int {get}
    var expiresDate: TimeInterval {get}
    var scope: String {get}
    var refreshToken: String {get}
    
    /// user name to identifiy token.
    var name: String {get}
    
    /// base URL of API
    static var baseURL: String {get}
    
    /// vacant token
    init()
    
    /// deserials Token from JSON data
    init(_ json: JSONDictionary)
}

extension Token {
    /**
    Returns json object
    
    - returns: Dictinary object containing JSON data.
    */
    var JSONObject: JSONDictionary {
        let dict: JSONDictionary = [
            "name":self.name as AnyObject,
            "access_token":self.accessToken as AnyObject,
            "token_type":self.tokenType as AnyObject,
            "expires_in":self.expiresIn as AnyObject,
            "expires_date":self.expiresDate as AnyObject,
            "scope":self.scope as AnyObject,
            "refresh_token":self.refreshToken as AnyObject
        ]
        return dict
    }
}
