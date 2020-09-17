//
//  FavoriteSubredditsWidget.swift
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
                }.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
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

// MARK: - SwiftUI Previews

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

// MARK: - Views

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
            Link(destination: URL(string: "slide://www.reddit.com/r/\(title)")!) {
                HStack {
                    VStack(alignment: .leading) {
                            Image(uiImage: UIImage(data: imageData) ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 30, height: 30, alignment: .center)
                                .clipShape(Circle())
                                .clipped()
                            Text(self.title).font(.caption).foregroundColor(colorScheme == .light ? .primary : .white).padding(EdgeInsets(top: 4, leading: 4, bottom: 0, trailing: 0))
                    }.padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    Spacer()
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(UIImage(data: imageData)?.averageColor ?? getSchemeColor()).opacity(0.8).cornerRadius(15))
            }.alignmentGuide(.leading) { d in d[.leading] }
        }
    }

    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
}
