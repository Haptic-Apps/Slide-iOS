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
        Current_Account()
        Favorite_Subreddits()
        Hot_Posts_Tile()
        Hot_Posts()
    }
}

struct AccountTimeline: TimelineProvider {
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }

    typealias Entry = AccountEntry

    func placeholder(in context: Context) -> AccountEntry {
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        let currentAccount = shared?.string(forKey: "current_account") ?? "Guest"
        let karma = shared?.integer(forKey: "karma") ?? 0
        let inbox = shared?.integer(forKey: "inbox") ?? 0
        let image = shared?.data(forKey: "profile_icon") ?? Data()
        let readLater = shared?.integer(forKey: "readlater") ?? 0

        return AccountEntry(date: Date(), name: currentAccount, inbox: inbox, karma: karma, imageData: image, readLater: readLater)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AccountEntry) -> Void) {
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        let currentAccount = shared?.string(forKey: "current_account") ?? "Guest"
        let karma = shared?.integer(forKey: "karma") ?? 0
        let inbox = shared?.integer(forKey: "inbox") ?? 0
        let image = shared?.data(forKey: "profile_icon") ?? Data()
        let readLater = shared?.integer(forKey: "readlater") ?? 0

        completion(AccountEntry(date: Date(), name: currentAccount, inbox: inbox, karma: karma, imageData: image, readLater: readLater))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AccountEntry>) -> Void) {
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")

        let currentAccount = shared?.string(forKey: "current_account") ?? "Guest"
        let karma = shared?.integer(forKey: "karma") ?? 0
        let inbox = shared?.integer(forKey: "inbox") ?? 0
        let image = shared?.data(forKey: "profile_icon") ?? Data()
        let readLater = shared?.integer(forKey: "readlater") ?? 0

        let entry = AccountEntry(date: Date(), name: currentAccount, inbox: inbox, karma: karma, imageData: image, readLater: readLater)
        let timeline = Timeline(entries: [entry], policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: Date())!))
        completion(timeline)
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
        let placeholder = TimelineSubredditProvider.all().first
        return SubredditEntry(date: Date(), subreddits: placeholder?.subs ?? ["all", "frontpage", "popular", "slide_ios"], imageData: getPlaceholderData(placeholder?.subs ?? ["all", "frontpage", "popular", "slide_ios"]), colorData: getColorData(placeholder?.subs ?? ["all", "frontpage", "popular", "slide_ios"]))
    }

    func getSnapshot(for configuration: TimelineSubredditIntent, in context: Context, completion: @escaping (SubredditEntry) -> Void) {
        let placeholder = TimelineSubredditProvider.all().first
        let entry = SubredditEntry(date: Date(), subreddits: placeholder?.subs ?? ["all", "frontpage", "popular", "slide_ios"], imageData: getPlaceholderData(placeholder?.subs ?? ["all", "frontpage", "popular", "slide_ios"]), colorData: getColorData(placeholder?.subs ?? ["all", "frontpage", "popular", "slide_ios"]))
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

    func getColorData(_ subs: [String]) -> [String: UIColor] {
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        var toReturn = [String: UIColor]()
        for item in subs {
            var color: UIColor?
            if let hex = shared?.string(forKey: "color\(item.lowercased().replacingOccurrences(of: "/", with: ""))"), !hex.isEmpty {
                color = UIColor(hexString: hex)
            }
            toReturn[item] = color
        }
        return toReturn
    }

    func getTimeline(for configuration: TimelineSubredditIntent, in context: Context, completion: @escaping (Timeline<SubredditEntry>) -> Void) {

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let entryDate = Calendar.current.date(byAdding: .hour, value: 0, to: currentDate)!

        let subreddits = lookupWidgetDetails(for: configuration).subs
        let entry = SubredditEntry(date: entryDate, subreddits: subreddits, imageData: getPlaceholderData(subreddits), colorData: getColorData(subreddits))
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func lookupWidgetDetails(for configuration: TimelineSubredditIntent) -> TimelineSubredditDetails {
        guard let widgetID = configuration.widgetconfig?.identifier, let widgetForConfig = TimelineSubredditProvider.all().first(where: { widget in
            widget.id == widgetID
        })
        else {
            return TimelineSubredditProvider.all()[0]
        }
        return widgetForConfig
    }

}

struct SubredditEntry: TimelineEntry {
    let date: Date
    let subreddits: [String]
    let imageData: [String: Data]
    let colorData: [String: UIColor?]
}

struct AccountEntry: TimelineEntry {
    public let date: Date
    public let name: String
    public let inbox: Int
    public let karma: Int
    public let imageData: Data
    public let readLater: Int
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
        
        SubredditWithPosts(date: Date(), subreddit: "redacted", colorful: true, posts: SubredditPosts(date: Date(), subreddit: "redacted", posts: getBlankPosts()), imageData: getPreviewData(), color: nil)
    }

    func getSnapshot(for configuration: SingleSubredditIntent, in context: Context, completion: @escaping (SubredditWithPosts) -> Void) {
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        var imageData: Data?
        let subreddit = lookupWidgetDetails(for: configuration).name
        if let data = shared?.data(forKey: "raw" + subreddit) {
            imageData = data
        } else if let url = URL(string: shared?.string(forKey: subreddit) ?? "") {
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
        
        var color: UIColor?
        if let hex = shared?.string(forKey: "color\(subreddit.lowercased().replacingOccurrences(of: "/", with: ""))"), !hex.isEmpty {
            color = UIColor(hexString: hex)
        }

        SubredditLoader.fetch(subreddit: subreddit) { result in
            let subredditPosts: SubredditPosts
            if case .success(let subreddit) = result {
                subredditPosts = subreddit
            } else {
                subredditPosts = SubredditPosts(date: Date(), subreddit: subreddit, posts: [])
            }
            let entry = SubredditWithPosts(date: Date(), subreddit: subreddit, colorful: true, posts: subredditPosts, imageData: imageData ?? Data(), color: color)
            completion(entry)
        }
    }
    
    func getBlankPosts() -> [Post] {
        return [Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome!", image: "", date: 0, imageData: Data())]
    }

    func getTimeline(for configuration: SingleSubredditIntent, in context: Context, completion: @escaping (Timeline<SubredditWithPosts>) -> Void) {
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        var imageData: Data?
        let subreddit = lookupWidgetDetails(for: configuration).name
        
        if let data = shared?.data(forKey: "raw" + subreddit) {
            imageData = data
        } else if let url = URL(string: shared?.string(forKey: subreddit.lowercased()) ?? "") {
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
        
        var color: UIColor?
        if let hex = shared?.string(forKey: "color\(subreddit.lowercased().replacingOccurrences(of: "/", with: ""))"), !hex.isEmpty {
            color = UIColor(hexString: hex)
        }

        SubredditLoader.fetch(subreddit: subreddit) { result in
            let subredditPosts: SubredditPosts
            if case .success(let subreddit) = result {
                subredditPosts = subreddit
            } else {
                subredditPosts = SubredditPosts(date: Date(), subreddit: subreddit, posts: [])
            }
            let entry = SubredditWithPosts(date: Date(), subreddit: subreddit, colorful: configuration.colorful?.boolValue ?? true, posts: subredditPosts, imageData: imageData ?? Data(), color: color)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
    
    private func lookupWidgetDetails(for configuration: SingleSubredditIntent) -> SingleSubredditDetails {
        guard let widgetID = configuration.subreddit?.identifier, let widgetForConfig = SingleSubredditProvider.all().first(where: { widget in
            widget.id == widgetID
        })
      else {
        return SingleSubredditProvider.all()[0]
      }
      return widgetForConfig
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
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    static func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }

    static func fetch(subreddit: String, completion: @escaping (Result<SubredditPosts, Error>) -> Void) {
        var apiUrl = "https://reddit.com/r/\(subreddit).json?limit=7&raw_json=1"

        if subreddit == "frontpage" {
            let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
            if let subs = shared?.array(forKey: "subscriptions") as? [String] {
                let filteredSubs = subs.filter { (sub) -> Bool in
                    return !sub.contains("m/") && sub != "frontpage" && sub != "all" && sub != "popular" && sub != "friends" && sub != "moderated"
                }
                apiUrl = "https://reddit.com/.json?limit=7&raw_json=1"
                let subredditUrl = URL(string: apiUrl)!
                var request = URLRequest(url: subredditUrl)
                request.httpMethod = "POST"
                request.httpBody = "sr=\(filteredSubs.joined(separator: "+"))".data(using: .utf8)
                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    guard error == nil else {
                        completion(.failure(error!))
                        return
                    }
                    let subreddit = getSubredditInfo(subreddit: subreddit, fromData: data!)
                    completion(.success(subreddit))
                }
                task.resume()
            } else {
                apiUrl = "https://reddit.com/.json?limit=7&raw_json=1"
                let subredditUrl = URL(string: apiUrl)!
                let task = URLSession.shared.dataTask(with: subredditUrl) { (data, response, error) in
                    guard error == nil else {
                        completion(.failure(error!))
                        return
                    }
                    let subreddit = getSubredditInfo(subreddit: subreddit, fromData: data!)
                    completion(.success(subreddit))
                }
                task.resume()
            }
        }
    }

    static func getSubredditInfo(subreddit: String, fromData data: Foundation.Data) -> SubredditPosts {
        var posts = [Post]()
        do {
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            if let json = json, json["data"] != nil && (json["data"] as? [String : Any])?["children"] != nil {
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
                    if data["stickied"] as? Bool ?? false == false {
                        posts.append(Post(id: data["id"] as! String, author: data["author"] as! String, subreddit: data["subreddit_name_prefixed"] as! String, title: data["title"] as! String, image: data["thumbnail"] as? String ?? "", date: data["created_utc"] as! Double, imageData: imageData))
                    }
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
    let colorful: Bool
    let posts: SubredditPosts
    let imageData: Data
    let color: UIColor?
}

struct Post: Identifiable, Hashable {
    let id: String
    let author: String
    let subreddit: String
    let title: String
    let image: String
    let date: Double
    let imageData: Data
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
