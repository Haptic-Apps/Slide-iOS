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
        IntentConfiguration(kind: kind, intent: SubredditsProvider.Intent.self, provider: SubredditsProvider()) { entry in
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
        GeometryReader { geometry in
            switch widgetFamily {
            case .systemSmall:
                SmallWidgetView(imageData: entry.imageData[entry.subreddits[0]] ?? Data(), title: entry.subreddits[0])
                    .background(Color(UIImage(data: entry.imageData[entry.subreddits[0]] ?? Data())?.averageColor ?? getSchemeColor()).opacity(colorScheme == .dark ? 0.4 : 0.7).background(Color(.black)))
            default:
                MediumWidgetView(entry: entry)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                    .background(Color(getSchemeColor()))
            }
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

// MARK: - Widget Views

//Unused
private struct SmallWidgetViewCentered: View {
    var imageData: Data
    var title: String

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @ViewBuilder
    var body: some View {
        //Full size small widget
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .center, spacing: 0) {
                Image(uiImage: UIImage(data: imageData) ?? UIImage())
                    .resizable()
                    .frame(width: 50, height: 50, alignment: .center)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(Circle())
                    .clipped()
                Text(self.title)
                    .font(Font.subheadline.leading(.tight)).bold()
                    .foregroundColor(colorScheme == .light ? .primary : .white)
                    .opacity(0.8)
                    .padding(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))
                    .frame(maxWidth: .infinity)
            }.frame(maxHeight: .infinity)
        }
        .widgetURL(URL(string: "slide://www.reddit.com/r/\(title)"))
        .frame(maxWidth: .infinity)
    }
}

private struct SmallWidgetView: View {
    var imageData: Data
    var title: String

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @ViewBuilder
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Image(uiImage: UIImage(data: imageData) ?? UIImage())
                    .resizable()
                    .frame(width: 50, height: 50, alignment: .center)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(Circle())
                    .clipped()
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
                Spacer()
                Text(self.title)
                    .font(.system(.headline)).bold()
                    .foregroundColor(colorScheme == .light ? .primary : .white)
                    .opacity(0.8)
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 10, trailing: 0))
            }
            Spacer()
        }
        .widgetURL(URL(string: "slide://www.reddit.com/r/\(title)"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MediumWidgetView: View {
    var entry: SubredditsProvider.Entry

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(entry.subreddits.chunked(into: 2), id: \.self) { subreddits in
                HStack(alignment: .top, spacing: 8) {
                    ForEach(subreddits, id: \.self) { key in
                        SubredditView(imageData: entry.imageData[key] ?? Data(), title: key)
                            .cornerRadius(15)
                    }
                }
            }
        }
        .padding(8)
    }

}

// MARK: - Component Views

private struct SubredditView: View {
    var imageData: Data
    var title: String

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @ViewBuilder
    var body: some View {
        //Grid widget
        Link(destination: URL(string: "slide://www.reddit.com/r/\(title)")!) {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {
                        Image(uiImage: UIImage(data: imageData) ?? UIImage())
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(
                                maxWidth: min(30, geometry.size.height * 0.75),
                                maxHeight: min(30, geometry.size.height * 0.75),
                                alignment: .leading)
                                // TODOccrama: .leading is an issue here. .center works but we want left alignment.
                            .clipShape(Circle())
                            .clipped()
                        Spacer()
                    }
                    Spacer()
                    HStack(alignment: .center, spacing: 0) {
                        Spacer()
                            .frame(width: 4)
                        Text(self.title)
                            .font(Font.caption.leading(.tight))
                            .foregroundColor(colorScheme == .light ? .primary : .white)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        .background(Color(UIImage(data: imageData)?.averageColor ?? getSchemeColor()).opacity(0.8))
    }

    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
