//
//  WatchSessionManager.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/24/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import reddift
import Foundation
import WatchKit
import WatchConnectivity

public class WatchSessionManager: NSObject, WCSessionDelegate {
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        //replyHandler(["subreddit": "r/all", "loading":true])
        if message["sublist"] != nil {
            var colorDict = [String: String]()
            for sub in Subscriptions.subreddits {
                colorDict[sub] = ColorUtil.getColorForSub(sub: sub).hexString
            }
            replyHandler(["subs": colorDict])
        } else if message["links"] != nil {
            let redditSession = (UIApplication.shared.delegate as! AppDelegate).session ?? Session()
            do {
                try redditSession.getList(Paginator(), subreddit: Subreddit.init(subreddit: message["links"] as! String), sort: .hot, timeFilterWithin: .day, limit: 10) { (result) in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let listing):
                        var results = [NSDictionary]()
                        for link in listing.children {
                            let dict = NSMutableDictionary()
                            for item in ((link as! Link).baseJson) {
                                if (item.key == "subreddit" || item.key == "author" || item.key == "title" || item.key == "thumbnail" || item.key == "is_self" || item.key == "over_18" || item.key == "spoiler" || item.key == "locked" || item.key == "author" || item.key == "id" || item.key == "permalink" || item.key == "url" || item.key == "created"  || item.key == "stickied" || item.key == "link_flair_text") && (item.value is String || item.value is Int || item.value is Double){
                                    dict[item.key] = item.value
                                }
                            }
                            results.append(dict)
                        }
                        replyHandler(["links": results])
                    }
                }
            } catch {
                
            }
        }
    }

    static let sharedManager = WatchSessionManager()
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    private var validSession: WCSession? {
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }

    func doInit() {
        session?.delegate = self
        session?.activate()
    }
}
