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

    @ViewBuilder
    var body: some View {
                switch widgetFamily {
                case .systemSmall:
                    SubredditView(imageData: entry.imageData[entry.subreddits[0]] ?? Data(), title: entry.subreddits[0])
                        .background(Color(UIImage(data: entry.imageData[entry.subreddits[0]] ?? Data())?.averageColor ?? getSchemeColor()))
                default:
                    Group {
                        GeometryReader { geometry in
                            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 8), count: 2), alignment: .leading, spacing: 8) {
                                ForEach(entry.subreddits, id: \.self) { key in
                                    SubredditView(imageData: entry.imageData[key] ?? Data(), title: key, small: true)
                                        .cornerRadius(15)
                                        .frame(height: (geometry.size.height / 2) - (8 / 2))
                                }
                            }
                            .background(Color.red)
                        }
                    }.padding(8)
                }
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
        Group {
            Favorite_SubredditsEntryView(entry: SubredditEntry(date: Date(), subreddits: ["all", "frontpage", "popular", "slide_ios"], imageData: getPlaceholderData(["all", "frontpage", "popular", "slide_ios"])))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            Favorite_SubredditsEntryView(entry: SubredditEntry(date: Date(), subreddits: ["all", "frontpage", "popular", "slide_ios"], imageData: getPlaceholderData(["all", "frontpage", "popular", "slide_ios"])))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            Favorite_SubredditsEntryView(entry: SubredditEntry(date: Date(), subreddits: ["all", "frontpage", "popular", "slide_ios"], imageData: getPlaceholderData(["all", "frontpage", "popular", "slide_ios"])))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
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

    @ViewBuilder
    var body: some View {
        if !small {
            //Full size small widget
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    Image(uiImage: UIImage(data: imageData) ?? UIImage())
                        .resizable()
                        .frame(width: 50, height: 50, alignment: .center)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(Circle())
                        .clipped()
                    Spacer()
                }
                Spacer()
                Text(self.title)
                    .font(Font.subheadline.leading(.tight)).bold()
                    .foregroundColor(colorScheme == .light ? .primary : .white)
                    .opacity(0.8)
                    .background(Color.red)
            }
            .widgetURL(URL(string: "slide://www.reddit.com/r/\(title)"))
            .frame(maxWidth: .infinity)
            .background(Color.green)
        } else {
            //Grid widget
            GeometryReader { geometry in
            Link(destination: URL(string: "slide://www.reddit.com/r/\(title)")!) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {
                        Image(uiImage: UIImage(data: imageData) ?? UIImage())
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: min(50, geometry.size.height * 0.5), maxHeight: min(50, geometry.size.height * 0.5), alignment: .leading) // TODOccrama: .leading is an issue here. .center works but we want left alignment.
                            .clipShape(Circle())
                            .clipped()
                            .background(Color.red)
                        Spacer()
                    }
                    Spacer()
                    HStack(alignment: .center, spacing: 0) {
                        Spacer()
                            .frame(width: 8)
                        Text(self.title)
                            .font(Font.caption.leading(.tight))
                            .foregroundColor(colorScheme == .light ? .primary : .white)
                            .lineLimit(1)
                    }
                }
                .background(Color.green)
            }
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIImage(data: imageData)?.averageColor ?? getSchemeColor()).opacity(0.8))
        }
    }

    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
}