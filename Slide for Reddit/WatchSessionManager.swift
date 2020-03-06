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
#if !os(iOS)
import WatchKit
#endif

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
                let redditSession = (UIApplication.shared.delegate as! AppDelegate).session ?? Session()
                do {
                    print(message)
                    try redditSession.getArticles((message["comments"] as! String).replacingOccurrences(of: "t3_", with: ""), sort: CommentSort.top, comments: message["context"]  == nil ? nil : [(message["context"] as! String).replacingOccurrences(of: "t1_", with: "")], depth: 2, context: 0, limit: 50, completion: { (result) in
                            switch result {
                            case .failure(let error):
                                print(error)
                            case .success(let tuple):
                                let listing = tuple.1
                                var objects = [NSDictionary]()
                                let children = message["context"]  == nil ? listing.children : (listing.children[0] as! Comment).replies.children
                                for child in children {
                                    if let comment = child as? Comment {
                                        objects.append(["context": comment.id, "id": comment.getId(), "body": comment.bodyHtml, "submission": comment.linkId, "author": comment.author, "created": DateFormatter().timeSince(from: NSDate(timeIntervalSince1970: TimeInterval(comment.createdUtc)), numericDates: true), "score": comment.score, "upvoted": (comment.likes) == VoteDirection.up, "downvoted": (comment.likes) == VoteDirection.down])
                                        if comment.likes == VoteDirection.down {
                                            ActionStates.downVotedFullnames.append(comment.getId())
                                        } else if comment.likes == VoteDirection.up {
                                            ActionStates.upVotedFullnames.append(comment.getId())
                                        }

                                    }
                                }
                                DispatchQueue.main.async {
                                    replyHandler(["comments": objects])
                                }
                            }
                        })
                } catch {
                }
            }
        } else if message["vote"] != nil {
            let fullname = message["vote"] as? String ?? ""
            do {
                var vote = VoteDirection.none
                if message["upvote"] as? Bool ?? false == true {
                    var isUp = false
                    if ActionStates.upVotedFullnames.contains(fullname) {
                        isUp = true
                    }
                    if !isUp {
                        vote = .up
                    }
                } else if message["downvote"] as? Bool ?? false == true {
                    var isDown = false
                    if ActionStates.downVotedFullnames.contains(fullname) {
                        isDown = true
                    }
                    if !isDown {
                        vote = .down
                    }
                }
                print(vote)
                try (UIApplication.shared.delegate as? AppDelegate)?.session?.setVote(vote, name: fullname, completion: { (result) in
                    switch result {
                    case .success(_):
                        var message = ["upvoted": (vote == .up), "downvoted": (vote == .down)]
                        print(message)
                        replyHandler(message)
                        if let index = ActionStates.upVotedFullnames.firstIndex(of: fullname) {
                            ActionStates.upVotedFullnames.remove(at: index)
                        }
                        
                        if let index = ActionStates.downVotedFullnames.firstIndex(of: fullname) {
                            ActionStates.downVotedFullnames.remove(at: index)
                        }
                        
                        if let index = ActionStates.unvotedFullnames.firstIndex(of: fullname) {
                            ActionStates.unvotedFullnames.remove(at: index)
                        }
                        
                        switch vote {
                        case .up:
                            ActionStates.upVotedFullnames.append(fullname)
                        case .down:
                            ActionStates.downVotedFullnames.append(fullname)
                        default:
                            ActionStates.unvotedFullnames.append(fullname)
                        }
                    case .failure(let error):
                        print(error)
                        replyHandler(["failed": true])
                    }
                })
            } catch {
                replyHandler(["failed": true])
            }
        } else if message["readlater"] != nil {
            ReadLater.addReadLater(id: message["readlater"] as! String, subreddit: message["sub"] as! String)
            replyHandler([:])
        } else if message["sublist"] != nil {
            var colorDict = [String: String]()
            var sublist = Subscriptions.pinned
            sublist.append(contentsOf: Subscriptions.subreddits)
            for sub in Subscriptions.subreddits {
                colorDict[sub] = ColorUtil.getColorForSub(sub: sub).hexString()
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
                    var sub = message["links"] as! String
                    if sub == "" {
                        sub = "all"
                    }
                    try redditSession.getList(self.paginator, subreddit: Subreddit.init(subreddit: sub), sort: sort, timeFilterWithin: .day, limit: 10) { (result) in
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
                                        if item.key == "created" {
                                            dict["created"] = DateFormatter().timeSince(from: NSDate(timeIntervalSince1970: TimeInterval((link as! Link).createdUtc)), numericDates: true)
                                        } else {
                                            dict[item.key] = item.value
                                        }
                                    }
                                }
                                
                                dict["id"] = ((link as! Link)).getId()
                                
                                dict["upvoted"] = ((link as! Link).likes) == VoteDirection.up
                                dict["downvoted"] = ((link as! Link).likes) == VoteDirection.down
                                if ((link as! Link).likes) == VoteDirection.down {
                                    ActionStates.downVotedFullnames.append((link as! Link).getId())
                                } else if ((link as! Link).likes) == VoteDirection.up {
                                    ActionStates.upVotedFullnames.append((link as! Link).getId())
                                }
                                dict["readLater"] = ReadLater.isReadLater(id: ((link as! Link).id))
                                dict["bigimage"] = nil
                                
                                var json: JSONDictionary?
                                json = (link as! Link).baseJson

                                let preview = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["url"] as? String)
                                
                                if preview != nil && !(preview?.isEmpty())! {
                                    let burl = (preview!.replacingOccurrences(of: "&amp;", with: "&"))
                                    let w = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["width"] as? Int)!
                                    if w >= 200 {
                                        dict["bigimage"] = burl
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
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
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
