//
//  OAuth2Authorizer.swift
//  reddift
//
//  Created by sonson on 2015/04/12.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

/**
 Class for opening OAuth2 authorizing page and handling redirect URL.
 This class is used by singleton model.
 You must access this class's instance by only OAuth2Authorizer.sharedInstance.
 */
public class OAuth2Authorizer {
    private var state = ""
    /**
     Singleton model.
     */
    public static let sharedInstance = OAuth2Authorizer()
    
    /**
     Open OAuth2 page to try to authorize with all scopes in Safari.app.
     */
    public func challengeWithAllScopes() throws {
        do {
            try self.challengeWithScopes(["identity", "edit", "flair", "history", "modconfig", "modflair", "modlog", "modposts", "modwiki", "mysubreddits", "privatemessages", "read", "report", "save", "submit", "subscribe", "vote", "wikiedit", "wikiread"])
        } catch {
            throw error
        }
    }
    
    /**
     Open OAuth2 page to try to authorize with user specified scopes in Safari.app.
     
     - parameter scopes: Scope you want to get authorizing. You can check all scopes at https://www.reddit.com/dev/api/oauth.
     */
    public func challengeWithScopes(_ scopes: [String]) throws {
        let commaSeparatedScopeString = scopes.joined(separator: ",")
        
        let length = 64
        let mutableData = NSMutableData(length: Int(length))
        if let data = mutableData {
            let a = OpaquePointer(data.mutableBytes)
            let ptr = UnsafeMutablePointer<UInt8>(a)
            let _ = SecRandomCopyBytes(kSecRandomDefault, length, ptr)
            self.state = data.base64EncodedString(options: .endLineWithLineFeed)
            guard let authorizationURL = URL(string:"https://www.reddit.com/api/v1/authorize.compact?client_id=" + Config.sharedInstance.clientID + "&response_type=code&state=" + self.state + "&redirect_uri=" + Config.sharedInstance.redirectURI + "&duration=permanent&scope=" + commaSeparatedScopeString)
                else { throw ReddiftError.canNotCreateURLRequestForOAuth2Page as NSError }
            #if os(iOS)
                if #available (iOS 10.0, *) {
                    UIApplication.shared.open(authorizationURL, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(authorizationURL)
                }
            #elseif os(macOS)
                NSWorkspace.shared().open(authorizationURL)
            #endif
        } else {
            throw ReddiftError.canNotAllocateDataToCreateURLForOAuth2 as NSError
        }
    }
    
    /**
     Handle URL object which is returned by OAuth2 page at reddit.com
     
     - parameter url: The URL from passed by reddit.com
     - parameter completion: Callback block is execeuted when the access token has been acquired using URL.
     - returns: Returns if the URL object is parsed correctly.
     */
    public func receiveRedirect(_ url: URL, completion: @escaping (Result<OAuth2Token>) -> Void) -> Bool {
        var parameters: [String:String] = url.getKeyVals()!
        let currentState = self.state
        print("Current state is \(currentState)")
        self.state = ""
        if let code = parameters["code"], let state = parameters["state"]?.decodeUrl() {
            if code.characters.count > 0 && state == currentState {
                do {
                    try OAuth2Token.getOAuth2Token(code, completion: completion)
                    return true
                } catch {
                    print(error)
                    return false
                }
            }
        }
        return false
    }
}
extension URL {
    func getKeyVals() -> Dictionary<String, String>? {
        var results = [String:String]()
        var keyValues = self.query?.components(separatedBy: "&")
        if (keyValues?.count)! > 0 {
            for pair in keyValues! {
                let kv = pair.components(separatedBy: "=")
                if kv.count > 1 {
                    results.updateValue(kv[1], forKey: kv[0])
                }
            }
            
        }
        return results
    }
}
extension String
{
    func encodeUrl() -> String
    {
        return self.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    func decodeUrl() -> String
    {
        return self.removingPercentEncoding!
    }
}
