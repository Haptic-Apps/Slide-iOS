//
//  HotPostsWidget.swift
//  Slide Widgets
//
//  Created by Jonathan Cole on 9/15/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif
import SwiftUI

struct Hot_Posts: Widget {
    let kind: String = "Hot_Posts"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SingleSubredditIntent.self, provider: HotPostsProvider()) { entry in
            Hot_PostsEntryView(entry: entry)
        }
        .configurationDisplayName("Hot Posts List")
        .description("Shows hot posts from a Subreddit.")
        .supportedFamilies([WidgetFamily.systemMedium, WidgetFamily.systemLarge])
    }
}

struct Hot_PostsEntryView: View {
    var entry: HotPostsProvider.Entry
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if entry.subreddit == "redacted" {
            VStack(alignment: .leading) {
                SubredditViewHorizontal(imageData: entry.imageData, title: entry.subreddit, redacted: true, fontColor: Color(getSchemeFontColor())).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                if !entry.posts.posts.isEmpty {
                    ForEach((0..<min(entry.posts.posts.count, (widgetFamily == .systemMedium ? 2 : 5)))) { post in
                        PostView(post: entry.posts.posts[post], redacted: true)
                    }
                }
                Spacer()
            }.frame(maxHeight: .infinity).background(Color(entry.colorful ? (entry.color ?? (UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor())) : getSchemeColor()).opacity(0.8)).redacted(reason: .placeholder)
        } else {
            VStack(alignment: .center) {
                SubredditViewHorizontal(imageData: entry.imageData, title: entry.subreddit, redacted: false, fontColor: Color(getSchemeFontColor())).widgetURL(URL(string: "slide://www.reddit.com/r/\(entry.subreddit)"))
                ForEach((0..<min(entry.posts.posts.count, (widgetFamily == .systemMedium ? 2 : 5)))) { post in
                    PostView(post: entry.posts.posts[post], redacted: false)
                }
            }
            .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
            .background(getBackgroundColor())
        }
    }

    func getBackgroundColor() -> Color {
        return Color(entry.colorful ? (entry.color ?? (UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor())) : getSchemeColor()).opacity(0.8)
    }
    
    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
    
    func getSchemeFontColor() -> UIColor {
        return colorScheme == .light ? .black : .white
    }
}

// MARK: SwiftUI Previews

struct Hot_Posts_Previews: PreviewProvider {
    static var previews: some View {
        Hot_PostsEntryView(entry: SubredditWithPosts(date: Date(), subreddit: "redacted", colorful: true, posts: SubredditPosts(date: Date(), subreddit: "redacted", posts: getBlankPosts()), imageData: getPreviewData(), color: nil))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }

    static func getBlankPosts() -> [Post] {
        return [Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome!", image: "", date: 0, imageData: Data())]
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

// MARK: - Views

struct PostView: View {
    var post: Post
    var redacted: Bool
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        GeometryReader { geom in
            Link(destination: URL(string: "slide://redd.it/\(post.id)")!) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        if redacted {
                            Text(post.subreddit).font(.caption2).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.6).redacted(reason: .placeholder).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1) // Fit to width
                            Text(post.title).font(.footnote).bold().multilineTextAlignment(.leading).redacted(reason: .placeholder).frame(maxWidth: .infinity, alignment: .leading) // Fit to width
                        } else {
                            Text(post.subreddit).font(.caption2).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.6).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1) // Fit to width
                            Text(post.title).font(.footnote).bold().lineSpacing(-5).lineLimit(nil).frame(maxWidth: .infinity, alignment: .leading).multilineTextAlignment(.leading) // Fit to width
                        }
                    }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 4)).frame(maxHeight: geom.size.height, alignment: .topLeading) // Fit to height
                    if redacted {
                        Image(uiImage: UIImage(data: post.imageData) ?? UIImage())
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(CGFloat(10))
                            .clipped().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10)).redacted(reason: .placeholder).alignmentGuide(.trailing) { d in d[.trailing] }
                    } else {
                        if let image = UIImage(data: post.imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .cornerRadius(CGFloat(10))
                                .clipped().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)).alignmentGuide(.trailing) { d in d[.trailing] }
                        } else {
                            ZStack(alignment: .center, content: {
                                Color(colorScheme != .light ? .black : .white).opacity(0.3)
                                Image(systemName: "link")
                                    .foregroundColor(colorScheme == .light ? .primary : .white)
                                    .aspectRatio(contentMode: .fit)
                                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                            }).cornerRadius(CGFloat(10))
                                .aspectRatio(1, contentMode: .fit)
                                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
                        }
                    }
                }
            }
        }
    }
}

struct SubredditViewHorizontal: View {
    var imageData: Data
    var title: String
    var redacted: Bool
    var fontColor: Color

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack {
            if redacted {
                Image(uiImage: UIImage(data: imageData) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20, alignment: .center)
                    .clipShape(Circle())
                    .clipped().redacted(reason: .placeholder)
                Text(self.title).font(.headline).bold().foregroundColor(fontColor).opacity(0.8).redacted(reason: .placeholder).alignmentGuide(.leading) { d in d[.leading] }
                Spacer()
            } else {
                Image(uiImage: UIImage(data: imageData) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 25, height: 25, alignment: .center)
                    .clipShape(Circle())
                    .clipped()
                Text(self.title).font(.headline).bold().foregroundColor(fontColor).opacity(0.8).alignmentGuide(.leading) { d in d[.leading] }
                Spacer()
            }
        }.padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0)).frame(maxWidth: .infinity)
    }
}
