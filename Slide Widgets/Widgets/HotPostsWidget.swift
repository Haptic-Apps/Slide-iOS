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
        .configurationDisplayName("Hot Posts")
        .description("Shows hot posts from a Subreddit.")
    }
}

struct Hot_PostsEntryView: View {
    var entry: HotPostsProvider.Entry
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if entry.subreddit == "redacted" {
            VStack(alignment: .leading) {
                SubredditViewHorizontal(imageData: entry.imageData, title: entry.subreddit, redacted: true).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                if !entry.posts.posts.isEmpty {
                    ForEach((0..<min(entry.posts.posts.count, (widgetFamily == .systemMedium ? 2 : 5)))) { post in
                        PostView(post: entry.posts.posts[post], redacted: true)
                    }
                }
                Spacer()
            }.frame(maxHeight: .infinity).background(Color(UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor() )
                                                        .opacity(0.8)).redacted(reason: .placeholder)
        } else {
            if widgetFamily == .systemSmall {
                VStack(alignment: .leading) {
                    SubredditViewHorizontal(imageData: entry.imageData, title: entry.subreddit, redacted: false).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(
                    ZStack(alignment: .bottomLeading) {
                        Color.clear
                        VStack(alignment: .leading) {
                            HStack {
                                Text(entry.posts.posts.first!.subreddit).font(.caption).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.6).alignmentGuide(.leading) { d in d[.leading] }
                                Text(entry.posts.posts.first!.author).font(.caption).foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.6).alignmentGuide(.leading) { d in d[.leading] }
                            }
                            Text(entry.posts.posts.first!.title).font(.title3).bold().multilineTextAlignment(.leading)
                        }.padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 4)).widgetURL(URL(string: "slide://redd.it/\(entry.posts.posts.first!.id)")!)
                    }
                    .background(
                        Image(uiImage: UIImage(data: entry.posts.posts.first!.imageData) ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(CGFloat(5))
                        .clipped().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)).blur(radius: 3).opacity(0.5)
                        .background(
                            Color(UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor()))
                                .opacity(0.8))
                )
            } else {
                VStack(alignment: .leading) {
                    SubredditViewHorizontal(imageData: entry.imageData, title: entry.subreddit, redacted: false).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)).widgetURL(URL(string: "slide://www.reddit.com/r/\(entry.subreddit)"))
                    if !entry.posts.posts.isEmpty {
                        ForEach((0..<min(entry.posts.posts.count, (widgetFamily == .systemMedium ? 2 : 5)))) { post in
                            PostView(post: entry.posts.posts[post], redacted: false)
                        }
                    }
                    Spacer()
                }.frame(maxHeight: .infinity).background(Color(UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor() )
                                                            .opacity(0.8))
            }
        }
    }

    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
}

// MARK: SwiftUI Previews

struct Hot_Posts_Previews: PreviewProvider {
    static var previews: some View {
        Hot_PostsEntryView(entry: SubredditWithPosts(date: Date(), subreddit: "redacted", posts: SubredditPosts(date: Date(), subreddit: "redacted", posts: getBlankPosts()), imageData: getPreviewData()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }

    static func getBlankPosts() -> [Post] {
        return [Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome Slide is awesome!", image: "", date: 0, imageData: Data()), Post(id: UUID().uuidString, author: "ccrama", subreddit: "slide_ios", title: "Slide is awesome!", image: "", date: 0, imageData: Data())]
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
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .top) {
            Link(destination: URL(string: "slide://redd.it/\(post.id)")!) {
                VStack(alignment: .leading) {
                    HStack {
                        if redacted {
                            Text(post.subreddit).font(.caption2).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.6).redacted(reason: .placeholder).alignmentGuide(.leading) { d in d[.leading] }
                            Text(post.author).font(.caption2).foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.6).redacted(reason: .placeholder).alignmentGuide(.leading) { d in d[.leading] }
                        } else {
                            Text(post.subreddit).font(.caption2).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.6).alignmentGuide(.leading) { d in d[.leading] }
                            Text(post.author).font(.caption2).foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.6).alignmentGuide(.leading) { d in d[.leading] }
                        }
                    }
                    if redacted {
                        Text(post.title).font(.footnote).bold().multilineTextAlignment(.leading).redacted(reason: .placeholder)
                    } else {
                        Text(post.title).font(.footnote).bold().multilineTextAlignment(.leading)
                    }
                }.padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 4))
            }
            Spacer()
            if redacted {
                Image(uiImage: UIImage(data: post.imageData) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40, alignment: .center)
                    .cornerRadius(CGFloat(5))
                    .clipped().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)).redacted(reason: .placeholder).alignmentGuide(.trailing) { d in d[.trailing] }
            } else {
                Image(uiImage: UIImage(data: post.imageData) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40, alignment: .center)
                    .cornerRadius(CGFloat(5))
                    .clipped().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)).alignmentGuide(.trailing) { d in d[.trailing] }
            }
        }
    }
}

struct SubredditViewHorizontal: View {
    var imageData: Data
    var title: String
    var redacted: Bool

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        HStack {
            if redacted {
                Image(uiImage: UIImage(data: imageData) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30, alignment: .center)
                    .clipShape(Circle())
                    .clipped().redacted(reason: .placeholder)
                Text(self.title).font(.headline).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.8).redacted(reason: .placeholder).alignmentGuide(.leading) { d in d[.leading] }
            } else {
                Image(uiImage: UIImage(data: imageData) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30, alignment: .center)
                    .clipShape(Circle())
                    .clipped()
                Text(self.title).font(.headline).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.8).alignmentGuide(.leading) { d in d[.leading] }
            }
        }.padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0))
    }
}
