//
//  Subscriptions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/6/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

class Subscriptions{
    private static var defaultSubs = ["frontpage", "all", "announcements", "Art", "AskReddit", "askscience",
                                      "aww", "blog", "books", "creepy", "dataisbeautiful", "DIY", "Documentaries",
                                      "EarthPorn", "explainlikeimfive", "Fitness", "food", "funny", "Futurology",
                                      "gadgets", "gaming", "GetMotivated", "gifs", "history", "IAmA",
                                      "InternetIsBeautiful", "Jokes", "LifeProTips", "listentothis",
                                      "mildlyinteresting", "movies", "Music", "news", "nosleep", "nottheonion",
                                      "OldSchoolCool", "personalfinance", "philosophy", "photoshopbattles", "pics",
                                      "science", "Showerthoughts", "space", "sports", "television", "tifu",
                                      "todayilearned", "TwoXChromosomes", "UpliftingNews", "videos", "worldnews",
                                      "WritingPrompts"]
    
    public static var subreddits: [String] {
        if(accountSubs.isEmpty){
            return defaultSubs
        }
        return accountSubs
    }
    
    public static var historySubs: [String] = []
    private static var accountSubs: [String] = []
    
    public static func sync(name: String, completion: (() -> Void)?){
        print("Getting \(name)'s subs")
        if let accounts = UserDefaults.standard.array(forKey: "subs" + name){
            print("Count is \(accounts.count)")
            accountSubs = accounts as! [String]
        } else {
            accountSubs = defaultSubs
        }
        
        if let accounts = UserDefaults.standard.array(forKey: "historysubs" + name){
            print("Count is \(accounts.count)")
            historySubs = accounts as! [String]
        } else {
            historySubs = []
        }

        if((completion) != nil){
            completion!()
        }
    }
    
    public static func addHistorySub(name: String, sub: String){
        historySubs.append(sub)
        UserDefaults.standard.set(historySubs, forKey: "historysubs" + name)
        UserDefaults.standard.synchronize()
    }

    public static func set(name: String, subs: [String], completion: @escaping () -> Void){
        print("Setting subs")
        UserDefaults.standard.set(subs, forKey: "subs" + name)
        UserDefaults.standard.synchronize()
        Subscriptions.sync(name: name, completion: completion)
    }
    
    public static func getSubscriptionsUntilCompletion(session: Session, p: Paginator, tR: [Subreddit], mR: [Multireddit], multis: Bool, completion: @escaping (_ result: [Subreddit], _ multis: [Multireddit]) -> Void){
        var toReturn = tR
        var toReturnMultis = mR
        var paginator = p
        do{
            if(!multis){
            try session.getUserRelatedSubreddit(.subscriber, paginator:paginator, completion: { (result) -> Void in
                switch result {
                case .failure:
                    print(result.error!)
                    completion(toReturn, toReturnMultis)
                    break
                case .success(let listing):
                    toReturn += listing.children.flatMap({$0 as? Subreddit})
                    paginator = listing.paginator
                    print("Size is \(toReturn.count) and hasmore is \(paginator.hasMore())")
                    if(paginator.hasMore()){
                        getSubscriptionsUntilCompletion(session: session, p: paginator, tR: toReturn, mR: toReturnMultis, multis: false, completion: completion)
                    } else {
                        getSubscriptionsUntilCompletion(session: session, p: paginator, tR: toReturn, mR: toReturnMultis, multis: true, completion: completion)
                    }
                }
            })
            } else {
                try session.getMineMultireddit({ (result) in
                    switch result {
                    case .failure:
                        print(result.error!)
                        completion(toReturn, toReturnMultis)
                        break
                    case .success(let multireddits):
                        toReturnMultis.append(contentsOf: multireddits)
                        completion(toReturn, toReturnMultis)
                    }
                })
            }
        } catch {
            completion(toReturn, toReturnMultis)
        }

    }
    
    public static func getSubscriptionsFully(session: Session, completion: @escaping (_ result: [Subreddit], _ multis: [Multireddit]) -> Void) {
        let toReturn: [Subreddit] = []
        let toReturnMultis: [Multireddit] = []
        let paginator = Paginator()
        getSubscriptionsUntilCompletion(session: session, p: paginator, tR: toReturn, mR: toReturnMultis, multis: false, completion: completion)
    }
    
}
