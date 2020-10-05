//
//  HotPostsTileWidget.swift
//  Slide Widgets
//
//  Created by Carlos Crane on 10/4/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif
import SwiftUI

struct Hot_Posts_Tile: Widget {
    let kind: String = "Hot_Posts_Tile"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SingleSubredditIntent.self, provider: HotPostsProvider()) { entry in
            Hot_Posts_TileEntryView(entry: entry)
        }
        .configurationDisplayName("Hot Posts")
        .description("Shows hot posts from a Subreddit.")
    }
}

struct Hot_Posts_TileEntryView: View {
    var entry: HotPostsProvider.Entry
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        if entry.subreddit == "redacted" {
            if widgetFamily == .systemSmall {
                VStack(alignment: .leading) {
                    SubredditViewHorizontal(imageData: entry.imageData, title: entry.subreddit, redacted: true, fontColor: entry.colorful ? .white : Color(getSchemeFontColor())).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(
                    ZStack(alignment: .bottomLeading) {
                        Color.clear
                        VStack(alignment: .leading) {
                            HStack {
                                Text(entry.posts.posts.first!.subreddit).font(.caption).bold().foregroundColor(.white).opacity(0.6).redacted(reason: .placeholder).alignmentGuide(.leading) { d in d[.leading] }
                            }
                            Text(entry.posts.posts.first!.title).font(.system(.footnote)).bold().multilineTextAlignment(.leading).lineLimit(3).lineSpacing(-15).redacted(reason: .placeholder).foregroundColor(entry.colorful ? Color.white : Color(getSchemeFontColor()))
                        }.padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 4)).widgetURL(URL(string: "slide://redd.it/\(entry.posts.posts.first!.id)")!)
                    }
                    .background(
                        Image(uiImage: UIImage(data: entry.posts.posts.first!.imageData) ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(CGFloat(5))
                        .clipped().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)).blur(radius: 3).opacity(0.5)
                        .background(
                            Color(entry.colorful ? UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor() : getSchemeColor()))
                                .opacity(0.8))
                )
            } else {
                VStack(alignment: .leading) {
                    SubredditViewHorizontal(imageData: entry.imageData, title: entry.subreddit, redacted: false, fontColor: Color(getSchemeFontColor())).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    Spacer()
                    VStack(alignment: .leading) {
                        ForEach(getPosts().chunked(into: 2), id: \.self) { posts in
                            HStack(alignment: .top, spacing: 8) {
                                ForEach(posts) { post in
                                    PostTileView(post: post, colorful: entry.colorful, redacted: true).cornerRadius(15)
                                }
                            }
                        }
                    }.padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(entry.colorful ? UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor() : getSchemeColor()))

            }
        } else {
            if widgetFamily == .systemSmall {
                VStack(alignment: .leading) {
                    SubredditViewHorizontal(imageData: entry.imageData, title: entry.subreddit, redacted: false, fontColor: entry.colorful ? .white : Color(getSchemeFontColor())).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(
                    ZStack(alignment: .bottomLeading) {
                        Color.clear
                        VStack(alignment: .leading) {
                            HStack {
                                Text(entry.posts.posts.first!.subreddit).font(.caption).bold().foregroundColor(.white).opacity(0.6).alignmentGuide(.leading) { d in d[.leading] }
                            }
                            Text(entry.posts.posts.first!.title).font(.system(.footnote)).bold().multilineTextAlignment(.leading).lineLimit(3).lineSpacing(-15).foregroundColor(entry.colorful ? Color.white : Color(getSchemeFontColor()))
                        }.padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 4)).widgetURL(URL(string: "slide://redd.it/\(entry.posts.posts.first!.id)")!)
                    }
                    .background(
                        Image(uiImage: UIImage(data: entry.posts.posts.first!.imageData) ?? UIImage())
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .cornerRadius(CGFloat(5))
                        .clipped().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)).blur(radius: 3).opacity(0.5)
                        .background(
                            Color(entry.colorful ? UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor() : getSchemeColor()))
                                .opacity(0.8))
                )
            } else {
                VStack(alignment: .leading) {
                    SubredditViewHorizontal(imageData: entry.imageData, title: entry.subreddit, redacted: false, fontColor: Color(getSchemeFontColor())).padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                    Spacer()
                    VStack(alignment: .leading) {
                        ForEach(getPosts().chunked(into: 2), id: \.self) { posts in
                            HStack(alignment: .top, spacing: 8) {
                                ForEach(posts) { post in
                                    PostTileView(post: post, colorful: entry.colorful, redacted: false).cornerRadius(15)
                                }
                            }
                        }
                    }.padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(entry.colorful ? UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor() : getSchemeColor()))
            }
        }
    }
    
    func getPosts() -> [Post] {
        var posts = [Post]()
        for i in 0..<(min(entry.posts.posts.count, widgetFamily == .systemLarge ? 4 : 2)) {
            posts.append(entry.posts.posts[i])
        }
        
        return posts
    }

    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
    
    func getSchemeFontColor() -> UIColor {
        return colorScheme == .light ? .black : .white
    }
}

struct PostTileView: View {
    var post: Post
    var colorful: Bool
    var redacted: Bool
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        Link(destination: URL(string: "slide://redd.it/\(post.id)")!) {
            if redacted {
                ZStack(alignment: .bottomLeading) {
                    Color.clear
                    VStack(alignment: .leading) {
                        HStack {
                            Text(post.subreddit).font(.caption).bold().redacted(reason: .placeholder).foregroundColor(Color(getSchemeFontColor())).opacity(0.6).alignmentGuide(.leading) { d in d[.leading] }
                        }
                        Text(post.title).font(.system(.footnote)).bold().redacted(reason: .placeholder).multilineTextAlignment(.leading).lineLimit(3).lineSpacing(-15).foregroundColor(Color(getSchemeFontColor()))
                    }.padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 4))
                }
                .background(
                    Image(uiImage: UIImage(data: post.imageData) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(CGFloat(5))
                    .clipped().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)).blur(radius: 3).opacity(0.3)
                    .background(
                        Color(getSchemeColor())) //todo get subreddit color
                            .opacity(0.8))
            } else {
                ZStack(alignment: .bottomLeading) {
                    Color.clear
                    VStack(alignment: .leading) {
                        HStack {
                            Text(post.subreddit).font(.caption).bold().foregroundColor(Color(getSchemeFontColor())).opacity(0.6).alignmentGuide(.leading) { d in d[.leading] }
                        }
                        Text(post.title).font(.system(.footnote)).bold().multilineTextAlignment(.leading).lineLimit(3).lineSpacing(-15).foregroundColor(Color(getSchemeFontColor()))
                    }.padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 4))
                }
                .background(
                    Image(uiImage: UIImage(data: post.imageData) ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(CGFloat(5))
                    .clipped().padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)).blur(radius: 3).opacity(0.3)
                    .background(
                        Color(getSchemeColor())) //todo get subreddit color
                            .opacity(0.8))
            }
        }
    }
    
    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
    
    func getSchemeFontColor() -> UIColor {
        return colorScheme == .light ? .black : .white
    }
}

// MARK: SwiftUI Previews

struct Hot_Posts_Tile_Previews: PreviewProvider {
    static var previews: some View {
        Hot_PostsEntryView(entry: SubredditWithPosts(date: Date(), subreddit: "redacted", colorful: true, posts: SubredditPosts(date: Date(), subreddit: "redacted", posts: getBlankPosts()), imageData: getPreviewData()))
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
