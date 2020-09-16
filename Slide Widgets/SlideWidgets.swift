//
//  Favorite_Subreddits.swift
//  Favorite Subreddits
//
//  Created by Carlos Crane on 9/11/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif
import SwiftUI

@main
struct SwiftWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        Favorite_Subreddits()
        Hot_Posts()
    }
}

struct SubredditsProvider: IntentTimelineProvider {

    public typealias Intent = TimelineSubredditIntent
    public typealias Entry = SubredditEntry
    
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }
    
    func placeholder(in context: Context) -> SubredditEntry {
        return SubredditEntry(date: Date(), subreddits: ["all", "frontpage", "popular", "slide_ios"], imageData: getPlaceholderData(["all", "frontpage", "popular", "slide_ios"]))
    }

    func getSnapshot(for configuration: TimelineSubredditIntent, in context: Context, completion: @escaping (SubredditEntry) -> Void) {
        let entry = SubredditEntry(date: Date(), subreddits: ["all", "frontpage", "popular", "slide_ios"], imageData: getPlaceholderData(["all", "frontpage", "popular", "slide_ios"]))
        completion(entry)
    }
    
    func getPlaceholderData(_ subs: [String]) -> [String: Data] {
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        var toReturn = [String: Data]()
        for item in subs {
            if let data = shared?.data(forKey: "raw\(item)") {
                toReturn[item] = data
            } else if let url = URL(string: shared?.string(forKey: item.lowercased()) ?? "") {
                do {
                    toReturn[item] = try Data(contentsOf: url)
                } catch {
                    if let data = shared?.data(forKey: "raw") {
                        toReturn[item] = data
                    } else {
                        toReturn[item] = Data()
                    }
                }
            } else {
                if let data = shared?.data(forKey: "raw") {
                    toReturn[item] = data
                } else {
                    toReturn[item] = Data()
                }
            }
        }
        return toReturn
    }

    func getTimeline(for configuration: TimelineSubredditIntent, in context: Context, completion: @escaping (Timeline<SubredditEntry>) -> Void) {

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .hour, value: 0, to: currentDate)!
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        let subreddits = [configuration.sub1 ?? "all", configuration.sub2 ?? "frontpage", configuration.sub3 ?? "popular", configuration.sub4 ?? "slide_ios"]
        let entry = SubredditEntry(date: entryDate, subreddits: subreddits, imageData: getPlaceholderData(subreddits))
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SubredditEntry: TimelineEntry {
    let date: Date
    let subreddits: [String]
    let imageData: [String: Data]
}

class ImageLoader: ObservableObject {
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }

    var didChange = PassthroughSubject<Data, Never>()
    
    public private(set) var data = Data() {
        willSet {
            didChange.send(newValue)
        }
    }

    init(urlString: String, subreddit: String) {
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        if let data = shared?.data(forKey: "raw" + subreddit.lowercased()) {
            DispatchQueue.main.async {
                self.data = data
            }
            return
        }

        guard let url = URL(string: urlString) else {
            if let data = shared?.data(forKey: "raw") {
                DispatchQueue.main.async {
                    self.data = data
                }
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.data = data
            }
        }
        task.resume()
    }
}

struct HotPostsProvider: IntentTimelineProvider {
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }
    
    public typealias Intent = SingleSubredditIntent
    public typealias Entry = SubredditWithPosts

    func placeholder(in context: Context) -> SubredditWithPosts {
        SubredditWithPosts(date: Date(), subreddit: "redacted", posts: SubredditPosts(date: Date(), subreddit: "redacted", posts: getBlankPosts()), imageData: getPreviewData())
    }

    func getSnapshot(for configuration: SingleSubredditIntent, in context: Context, completion: @escaping (SubredditWithPosts) -> Void) {
        let entry = SubredditWithPosts(date: Date(), subreddit: "redacted", posts: SubredditPosts(date: Date(), subreddit: "redacted", posts: getBlankPosts()), imageData: getPreviewData())
        completion(entry)
    }
    
    func getBlankPosts() -> [Post] {
        return [Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome!", image: "", date: 0, imageData: Data())]
    }

    func getTimeline(for configuration: SingleSubredditIntent, in context: Context, completion: @escaping (Timeline<SubredditWithPosts>) -> Void) {
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        var imageData: Data?
        if let data = shared?.data(forKey: "raw" + (configuration.subreddit?.lowercased() ?? "")) {
            imageData = data
        } else if let url = URL(string: shared?.string(forKey: configuration.subreddit?.lowercased() ?? "") ?? "") {
            do {
                imageData = try Data(contentsOf: url)
            } catch {
                if let data = shared?.data(forKey: "raw") {
                    imageData = data
                }
            }
        } else {
            if let data = shared?.data(forKey: "raw") {
                imageData = data
            }
        }

        SubredditLoader.fetch(subreddit: configuration.subreddit ?? "all") { result in
            let subredditPosts: SubredditPosts
            if case .success(let subreddit) = result {
                subredditPosts = subreddit
            } else {
                subredditPosts = SubredditPosts(date: Date(), subreddit: configuration.subreddit ?? "all", posts: [])
            }
            let entry = SubredditWithPosts(date: Date(), subreddit: configuration.subreddit ?? "all", posts: subredditPosts, imageData: imageData ?? Data())
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
    
    func getPreviewData() -> Data {
        var imageData: Data?
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        if let data = shared?.data(forKey: "rawall") {
            imageData = data
        }
        return imageData ?? Data()
    }
}

struct SubredditLoader {
    static func fetch(subreddit: String, completion: @escaping (Result<SubredditPosts, Error>) -> Void) {
        var apiUrl = "https://reddit.com/r/\(subreddit).json?limit=5&raw_json=1"
        if subreddit == "frontpage" {
            apiUrl = "https://reddit.com.json?limit=5&raw_json=1"
        }
        let branchContentsURL = URL(string: apiUrl)!
        let task = URLSession.shared.dataTask(with: branchContentsURL) { (data, response, error) in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            let subreddit = getSubredditInfo(subreddit: subreddit, fromData: data!)
            completion(.success(subreddit))
        }
        task.resume()
    }

    static func getSubredditInfo(subreddit: String, fromData data: Foundation.Data) -> SubredditPosts {
        var posts = [Post]()
        do {
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            if let json = json, json["data"] != nil && (json["data"] as? [String:Any])?["children"] != nil {
                let children = (json["data"] as! [String: Any])["children"] as! [[String: Any]]
                for child in children {
                    let data = child["data"] as! [String: Any]
                    let thumbnail = data["thumbnail"] as? String ?? ""
                    var imageData = Data()
                    if let url = URL(string: thumbnail) {
                        do {
                            imageData = try Data(contentsOf: url)
                        } catch {
                        }
                    }
                    posts.append(Post(id: data["id"] as! String, author: data["author"] as! String, subreddit: data["subreddit_name_prefixed"] as! String, title: data["title"] as! String, image: data["thumbnail"] as? String ?? "", date: data["created_utc"] as! Double, imageData: imageData))
                }
            }
        } catch {
        }
        
        return SubredditPosts(date: Date(), subreddit: subreddit, posts: posts)
    }
}

struct SubredditPosts {
    let date: Date
    let subreddit: String
    let posts: [Post]
}

struct SubredditWithPosts: TimelineEntry {
    let date: Date
    let subreddit: String
    let posts: SubredditPosts
    let imageData: Data
}

struct Post: Identifiable {
    let id: String
    let author: String
    let subreddit: String
    let title: String
    let image: String
    let date: Double
    let imageData: Data
}
