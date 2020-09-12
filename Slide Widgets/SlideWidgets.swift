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

struct SubredditView: View {
    var imageData: Data
    var title: String
    var small = false

    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        if !small {
            //Full size small widget
            VStack {
                Image(uiImage: UIImage(data: imageData) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50, alignment: .center)
                    .clipShape(Circle())
                    .clipped()
                Text(self.title).font(.subheadline).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.8).padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
            }.widgetURL(URL(string: "slide://www.reddit.com/r/\(title)")).frame(maxWidth: .infinity)
        } else {
            //Grid widget
            HStack {
                VStack(alignment: .leading) {
                    Link(destination: URL(string: "slide://www.reddit.com/r/\(title)")!) {
                        Image(uiImage: UIImage(data: imageData) ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 30, alignment: .center)
                            .clipShape(Circle())
                            .clipped()
                        Text(self.title).font(.caption).foregroundColor(colorScheme == .light ? .primary : .white).padding(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 0))
                    }.alignmentGuide(.leading) { d in d[.leading] }
                }.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                Spacer()
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(UIImage(data: imageData)?.averageColor ?? getSchemeColor()).opacity(0.8).cornerRadius(15))
        }
    }
    
    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
}

struct Favorite_SubredditsEntryView: View {
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }

    var entry: SubredditsProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    init(entry: SubredditsProvider.Entry) {
        self.entry = entry
    }

    var body: some View {
        VStack {
            if widgetFamily != .systemSmall {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading) {
                    ForEach(entry.subreddits, id: \.self) { key in
                        SubredditView(imageData: entry.imageData[key] ?? Data(), title: key, small: true)
                    }
                }.padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)).frame(maxHeight: .infinity)
            } else {
                SubredditView(imageData: entry.imageData[entry.subreddits[0]] ?? Data(), title: entry.subreddits[0])
            }
        }.frame(maxHeight: .infinity)
        .background(Color(widgetFamily == .systemSmall ? UIImage(data: entry.imageData[entry.subreddits[0]] ?? Data())?.averageColor ?? getSchemeColor() : getSchemeColor())
                .opacity(0.8))
    }
    
    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
    
    func getImage(item: String) -> String {
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        return shared?.string(forKey: item.lowercased()) ?? ""
    }
    
    func getTitle(item: Int) -> String {
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        let subs = shared?.stringArray(forKey: "favorites") ?? [""]
        return subs[item]
    }
}

struct Favorite_Subreddits: Widget {
    /*
     Corresponds to USR_DOMAIN in info.plist, which derives its value
     from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
     */
     func USR_DOMAIN() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
     }

    let kind: String = "Favorite_Subreddits"

    var body: some WidgetConfiguration {
        
        IntentConfiguration(kind: kind, intent: TimelineSubredditIntent.self, provider: SubredditsProvider()) { entry in
            Favorite_SubredditsEntryView(entry: entry)
        }
        .configurationDisplayName("Subreddit")
        .description("Quick links to your favorite Subreddit.")
    }
}

@main
struct SwiftWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        Favorite_Subreddits()
        Hot_Posts()
    }
}


struct Favorite_Subreddits_Previews: PreviewProvider {
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    static func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }

    static var previews: some View {
        Favorite_SubredditsEntryView(entry: SubredditEntry(date: Date(), subreddits: ["all", "frontpage", "popular", "slide_ios"], imageData: getPlaceholderData(["all", "frontpage", "popular", "slide_ios"])))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
    
    static func getPlaceholderData(_ subs: [String]) -> [String: Data] {
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

extension UIImage {
    /// Average color of the image, nil if it cannot be found
    var averageColor: UIColor? {
        // convert our image to a Core Image Image
        guard let inputImage = CIImage(image: self) else { return nil }

        // Create an extent vector (a frame with width and height of our current input image)
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                    y: inputImage.extent.origin.y,
                                    z: inputImage.extent.size.width,
                                    w: inputImage.extent.size.height)

        // create a CIAreaAverage filter, this will allow us to pull the average color from the image later on
        guard let filter = CIFilter(name: "CIAreaAverage",
                                  parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        // A bitmap consisting of (r, g, b, a) value
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])

        // Render our output image into a 1 by 1 image supplying it our bitmap to update the values of (i.e the rgba of the 1 by 1 image will fill out bitmap array
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)

        // Convert our bitmap images of r, g, b, a to a UIColor
        return UIColor(red: CGFloat(bitmap[0]) / 255,
                       green: CGFloat(bitmap[1]) / 255,
                       blue: CGFloat(bitmap[2]) / 255,
                       alpha: CGFloat(bitmap[3]) / 255)
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
        SubredditWithPosts(date: Date(), subreddit: "all", posts: SubredditPosts(date: Date(), subreddit: "all", posts: getBlankPosts()), imageData: getPreviewData())
    }

    func getSnapshot(for configuration: SingleSubredditIntent, in context: Context, completion: @escaping (SubredditWithPosts) -> Void) {
        let entry = SubredditWithPosts(date: Date(), subreddit: "all", posts: SubredditPosts(date: Date(), subreddit: "all", posts: getBlankPosts()), imageData: getPreviewData())
        completion(entry)
    }
    
    func getBlankPosts() -> [Post] {
        return [Post(id: UUID().uuidString, author: "", subreddit: "", title: "", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "", subreddit: "", title: "", image: "", date: 0, imageData: Data())]
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
        let json = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let children = (json["data"] as! [String: Any])["children"] as! [[String: Any]]
        var posts = [Post]()
        for child in children {
            let data = child["data"] as! [String: Any]
            let thumbnail = data["thumbnail"] as! String
            var imageData = Data()
            if let url = URL(string: thumbnail) {
                do {
                    imageData = try Data(contentsOf: url)
                } catch {
                }
            }
            posts.append(Post(id: data["id"] as! String, author: data["author"] as! String, subreddit: data["subreddit_name_prefixed"] as! String, title: data["title"] as! String, image: data["thumbnail"] as! String, date: data["created_utc"] as! Double, imageData: imageData))
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

struct SubredditViewHorizontal: View {
    var imageData: Data
    var title: String

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack {
            Image(uiImage: UIImage(data: imageData) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 30, height: 30, alignment: .center)
                .clipShape(Circle())
                .clipped()
            Text(self.title).font(.headline).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.8).alignmentGuide(.leading) { d in d[.leading] }
        }.widgetURL(URL(string: "slide://www.reddit.com/r/\(title)")).padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0))
    }
}

struct PostView: View {
    var post: Post
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .top) {
            Link(destination: URL(string: "slide://redd.it/\(post.id)")!) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(post.subreddit).font(.caption).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.6).alignmentGuide(.leading) { d in d[.leading] }
                        Text(post.author).font(.caption).foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.6).alignmentGuide(.leading) { d in d[.leading] }
                    }
                    Text(post.title).font(.footnote).bold().multilineTextAlignment(.leading)
                }.padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 4))
            }
            Spacer()
            Image(uiImage: UIImage(data: post.imageData) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40, alignment: .center)
                .cornerRadius(CGFloat(5))
                .clipped().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)).alignmentGuide(.trailing) { d in d[.trailing] }
        }
    }
}

struct Hot_PostsEntryView: View {
    var entry: HotPostsProvider.Entry
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        VStack(alignment: .leading) {
            SubredditViewHorizontal(imageData: entry.imageData, title: entry.subreddit).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
            ForEach((0..<(widgetFamily == .systemMedium ? 2 : 5))) { post in
                PostView(post: entry.posts.posts[post])
            }
            Spacer()
        }.frame(maxHeight: .infinity).background(Color(UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor() )
                                                    .opacity(0.8))
    }
    
    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
}

struct Hot_Posts: Widget {
    let kind: String = "Hot_Posts"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SingleSubredditIntent.self, provider: HotPostsProvider()) { entry in
            Hot_PostsEntryView(entry: entry)
        }
        .configurationDisplayName("Hot Posts")
        .description("Shows hot posts from a Subreddit.")
    }
}

struct Hot_Posts_Previews: PreviewProvider {
    static var previews: some View {
        Hot_PostsEntryView(entry: SubredditWithPosts(date: Date(), subreddit: "all", posts: SubredditPosts(date: Date(), subreddit: "all", posts: getBlankPosts()), imageData: getPreviewData()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
    
    static func getBlankPosts() -> [Post] {
        return [Post(id: UUID().uuidString, author: "", subreddit: "", title: "", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "", subreddit: "", title: "", image: "", date: 0, imageData: Data())]
    }

    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    static func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }
    
    static func getPreviewData() -> Data {
        var imageData: Data?
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        if let data = shared?.data(forKey: "rawall") {
            imageData = data
        }
        return imageData ?? Data()
    }

}
