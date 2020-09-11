//
//  Favorite_Subreddits.swift
//  Favorite Subreddits
//
//  Created by Carlos Crane on 9/11/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import WidgetKit
import SwiftUI

struct SubredditsProvider: IntentTimelineProvider {
    public typealias Intent = TimelineSubredditIntent
    public typealias Entry = SubredditEntry
    
    func placeholder(in context: Context) -> SubredditEntry {
        SubredditEntry(date: Date(), subreddit: "all")
    }

    public func snapshot(for configuration: TimelineSubredditIntent, with context: Context, completion: @escaping (SubredditEntry) -> ()) {
        let entry = SubredditEntry(date: Date(), subreddit: configuration.title as? String ?? "all")
        completion(entry)
    }

    public func timeline(for configuration: TimelineSubredditIntent, with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SubredditEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SubredditEntry(date: entryDate, subreddit: configuration.title as? String ?? "all")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SubredditEntry: TimelineEntry {
    let date: Date
    let subreddit: String
}

struct SubredditView: View {
    var icon: Data
    var title: String
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        VStack {
            Image(uiImage: UIImage(data: icon) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50, alignment: .center)
                .clipShape(Circle())
                .clipped()
            Text(title).font(.headline).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.8)
            //Image(uiImage: entry.icons[0])
              //  .clipShape(Circle())
             //   .aspectRatio(contentMode: .fill)
        }.widgetURL(URL(string: "slide://www.reddit.com/r/\(title)")).frame(maxWidth: .infinity)

    }
}

struct Favorite_SubredditsEntryView: View {
    var entry: SubredditsProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        VStack {
            HStack {
                if widgetFamily == .systemMedium {
                    SubredditView(icon: getImage(item: getTitle(item: 0)), title: getTitle(item: 0))
                    SubredditView(icon: getImage(item: getTitle(item: 1)), title: getTitle(item: 1))
                    SubredditView(icon: getImage(item: getTitle(item: 2)), title: getTitle(item: 2))
                } else {
                    SubredditView(icon: getImage(item: entry.subreddit), title: entry.subreddit)
                }
            }
        }.frame(maxHeight: .infinity).background(Color.init(widgetFamily == .systemSmall ? (UIImage(data: getImage(item: entry.subreddit))?.averageColor ?? (colorScheme == .light ? .white : .black)) : (colorScheme == .light ? .white : .black)).opacity(0.8))
    }
    
    func getImage(item: String) -> Data {
        var shared = UserDefaults(suiteName: "group.slide.prefs")
        var subs = shared?.stringArray(forKey: "favorites") ?? []
        return shared?.data(forKey: item) ?? Data()
    }
    
    func getTitle(item: Int) -> String {
        var shared = UserDefaults(suiteName: "group.slide.prefs")
        var subs = shared?.stringArray(forKey: "favorites") ?? [""]
        return subs[item]
    }
}

@main
struct Favorite_Subreddits: Widget {
    let kind: String = "Favorite_Subreddits"

    var body: some WidgetConfiguration {
        
        IntentConfiguration(kind: kind, intent: TimelineSubredditIntent.self, provider: SubredditsProvider()) { entry in
            Favorite_SubredditsEntryView(entry: entry)
        }
        .configurationDisplayName("Favorite Subreddits")
        .description("Quick links to your favorite Slide subreddits")
    }
}

struct Favorite_Subreddits_Previews: PreviewProvider {
    static var previews: some View {
        Favorite_SubredditsEntryView(entry: SubredditEntry(date: Date(), subreddit: "all"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
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
