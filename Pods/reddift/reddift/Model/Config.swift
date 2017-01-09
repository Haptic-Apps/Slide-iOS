//
//  Config.swift
//  reddift
//
//  Created by sonson on 2015/04/13.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import Foundation

/**
Class to manage parameters of reddift.
This class is used as singleton model
*/
struct Config {
	/// Application verison, be updated by Info.plist later.
    let version: String
	/// Bundle identifier, be updated by Info.plist later.
    let bundleIdentifier: String
	/// Developer's reddit user name
    let developerName: String
	/// OAuth redirect URL you register
    let redirectURI: String
	/// Application ID
    let clientID: String
    
    /**
    Singleton model.
    */
    static let sharedInstance = Config()
    
    /**
    Returns User-Agent for API
    */
    var userAgent: String {
        return "ios:" + bundleIdentifier + ":v" + version + "(by /u/" + developerName + ")"
    }
    
    /**
    Returns scheme of redirect URI.
    */
    var redirectURIScheme: String {
        if let scheme = URL(string:redirectURI)?.scheme {
            return scheme
        } else {
            return ""
        }
    }
	
    init() {
        version =  Bundle.infoValueInMainBundle(for: "CFBundleShortVersionString") as? String ?? "1.0"
        bundleIdentifier = Bundle.infoValueInMainBundle(for: "CFBundleIdentifier") as? String ?? ""
        
        var _developerName: String? = nil
        var _redirectURI: String? = nil
        var _clientID: String? = nil
		if let path = Bundle.main.path(forResource: "reddift_config", ofType: "json") {
			if let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary {
                        _developerName = json["DeveloperName"] as? String
                        _redirectURI = json["redirect_uri"] as? String
                        _clientID = json["client_id"] as? String
                    }
                } catch {
                    
                }
			}
		}
        
        developerName = _developerName ?? ""
        redirectURI = _redirectURI ?? ""
        clientID = _clientID ?? ""
    }
}
