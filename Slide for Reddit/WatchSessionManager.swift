//
//  WatchSessionManager.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/24/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import WatchConnectivity
import WatchKit

public class WatchSessionManager: NSObject, WCSessionDelegate {
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    public var paginator = Paginator()
    
    public func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        if message["pro"] != nil {
            DispatchQueue.main.async {
                VCPresenter.showVC(viewController: SettingsPro(), popupIfPossible: false, parentNavigationController: nil, parentViewController: (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController)
            }
        } else if message["comments"] != nil {
            DispatchQueue.main.async {
               VCPresenter.openRedditLink("https://redd.it/\((message["comments"] as! String))", nil, (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController)
            }
        } else if message["upvote"] != nil {
            let redditSession = (UIApplication.shared.delegate as! AppDelegate).session ?? Session()
            do {
                try redditSession.setVote(.up, name: "t3_" + (message["upvote"] as! String), completion: { (_) in
                    replyHandler([:])
                })
            } catch {
                replyHandler(["failed": true])
            }
        } else if message["readlater"] != nil {
            ReadLater.addReadLater(id: message["readlater"] as! String, subreddit: message["sub"] as! String)
            replyHandler([:])
        } else if message["sublist"] != nil {
            var colorDict = [String: String]()
            let sublist = Subscriptions.subreddits
            for sub in Subscriptions.subreddits {
                colorDict[sub] = ColorUtil.getColorForSub(sub: sub).hexString
            }
            replyHandler(["subs": colorDict, "orderedsubs": sublist, "pro": SettingValues.isPro])
        } else if message["links"] != nil {
            if message["reset"] as? Bool ?? true {
                paginator = Paginator()
            }
            let sort: LinkSortType
            if message["new"] as? Bool ?? false {
                sort = .new
            } else {
                sort = .hot
            }
            
            DispatchQueue.main.async {
                let redditSession = (UIApplication.shared.delegate as! AppDelegate).session ?? Session()
                do {
                    try redditSession.getList(self.paginator, subreddit: Subreddit.init(subreddit: message["links"] as! String), sort: sort, timeFilterWithin: .day, limit: 10) { (result) in
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let listing):
                            self.paginator = listing.paginator
                            var results = [NSDictionary]()
                            for link in listing.children {
                                let dict = NSMutableDictionary()
                                for item in ((link as! Link).baseJson) {
                                    if (item.key == "subreddit" || item.key == "author" || item.key == "title" || item.key == "thumbnail" || item.key == "is_self" || item.key == "over_18" || item.key == "score" || item.key == "num_comments" || item.key == "spoiler" || item.key == "locked" || item.key == "author" || item.key == "id" || item.key == "domain" || item.key == "permalink" || item.key == "url" || item.key == "created"  || item.key == "stickied" || item.key == "link_flair_text") && (item.value is String || item.value is Int || item.value is Double) {
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
