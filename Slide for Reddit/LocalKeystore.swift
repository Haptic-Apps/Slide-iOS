//
//  LocalKeystore.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/2/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import Security

public class LocalKeystore {
    /**
     Restores token for OAuth2 from Keychain.
     - parameter name: Specifies user name of token you want to restore from Keychain.
     - returns: OAuth2Token object.
     */
    public class func token(of name: String) throws -> OAuth2Token {
        do {
            let data = UserDefaults.standard.data(forKey: "AUTH+\(name)")
            if data == nil {
                throw ReddiftError.specifiedNameTokenNotFoundInKeychain as NSError
            }
            if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? JSONDictionary {
                return OAuth2Token(json)
            }
            throw ReddiftError.specifiedNameTokenNotFoundInKeychain as NSError
        } catch {
            throw error
        }
    }
    
    /**
     Restores user name list from Keychain.
     
     - returns: List contains user names that was used to save tokens.
     */
    public class var savedNames: [String] {
        return UserDefaults.standard.array(forKey: "SAVED_TOKENS") as? [String] ?? [String]()
    }
    
    /**
     Saves OAuth2 token object into Keychain.
     
     - parameter token: OAuth2Token object, that must have valid user name which is used to save it into Keychain.
     */
    public class func save(token: OAuth2Token) throws {
        if token.name.isEmpty {
            throw ReddiftError.tokenNameIsInvalid as NSError
        }
        do {
            let JSONObject: JSONDictionary = [
                    "name": token.name as AnyObject,
                    "access_token": token.accessToken as AnyObject,
                    "token_type": token.tokenType as AnyObject,
                    "expires_in": token.expiresIn as AnyObject,
                    "expires_date": token.expiresDate as AnyObject,
                    "scope": token.scope as AnyObject,
                    "refresh_token": token.refreshToken as AnyObject,
                    ]

            let data = try JSONSerialization.data(withJSONObject: JSONObject, options: [])
            UserDefaults.standard.set(data, forKey: "AUTH+\(token.name)")
            var tokenArray = UserDefaults.standard.array(forKey: "SAVED_TOKENS") as? [String] ?? [String]()
            for item in tokenArray {
                if item == token.name {
                    //Username is already saved
                    UserDefaults.standard.synchronize()
                    return
                }
            }
            tokenArray.append(token.name)
            UserDefaults.standard.set(tokenArray, forKey: "SAVED_TOKENS")
            UserDefaults.standard.synchronize()
        } catch {
            throw error
        }
    }
    
    /**
     Saves OAuth2 token object into Keychain.
     
     - parameter token: OAuth2Token object.
     - parameter name: Valid user name which is used to save it into Keychain.
     */
    public class func save(token: OAuth2Token, of name: String) throws {
        do {
            let JSONObject: JSONDictionary = [
                "name": token.name as AnyObject,
                "access_token": token.accessToken as AnyObject,
                "token_type": token.tokenType as AnyObject,
                "expires_in": token.expiresIn as AnyObject,
                "expires_date": token.expiresDate as AnyObject,
                "scope": token.scope as AnyObject,
                "refresh_token": token.refreshToken as AnyObject,
                ]
            let data = try JSONSerialization.data(withJSONObject: JSONObject, options: [])
            UserDefaults.standard.set(data, forKey: "AUTH+\(name)")
            var tokenArray = UserDefaults.standard.array(forKey: "SAVED_TOKENS") as? [String] ?? [String]()
            for item in tokenArray {
                if item == token.name {
                    //Username is already saved
                    UserDefaults.standard.synchronize()
                    return
                }
            }
            tokenArray.append(token.name)
            UserDefaults.standard.set(tokenArray, forKey: "SAVED_TOKENS")
            UserDefaults.standard.synchronize()
        } catch {
            throw error
        }
    }
    
    /**
     Removes OAuth2 token whose user name is specified by the name parmeter from Keychain.
     
     - parameter name: Valid user name which is used to save it into Keychain.
     */
    public class func removeToken(of name: String) throws {
        if name.isEmpty {
            throw ReddiftError.tokenNameIsInvalid as NSError
        }
        UserDefaults.standard.removeObject(forKey: "AUTH+\(name)")
        var tokenArray = UserDefaults.standard.array(forKey: "SAVED_TOKENS") as? [String] ?? [String]()
        
        tokenArray = tokenArray.filter{$0 != name}
        
        UserDefaults.standard.set(tokenArray, forKey: "SAVED_TOKENS")
        UserDefaults.standard.synchronize()
    }
}
