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
    
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String : Any]) -> Void) {
        //replyHandler(["subreddit": "r/all", "loading":true])
        if message["sublist"] != nil {
            replyHandler(["subs": Subscriptions.subreddits])
        } else if message["links"] != nil {
            let redditSession = (UIApplication.shared.delegate as! AppDelegate).session ?? Session()
            do {
                try redditSession.getList(Paginator(), subreddit: Subreddit.init(subreddit: "all"), sort: .hot, timeFilterWithin: .day) { (result) in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let listing):
                        var results = [NSDictionary]()
                        for link in listing.children {
                            var dict = NSMutableDictionary()
                            for item in ((link as! Link).baseJson) {
                                if item.value is String {
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
