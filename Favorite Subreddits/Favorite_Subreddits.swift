//
//  Favorite_Subreddits.swift
//  Favorite Subreddits
//
//  Created by Carlos Crane on 9/11/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Combine
import WidgetKit
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
        var imageData: Data?
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        if let data = shared?.data(forKey: "rawall") {
            imageData = data
        }

        return SubredditEntry(date: Date(), subreddit: "all", imageData: imageData ?? Data())
    }

    func getSnapshot(for configuration: TimelineSubredditIntent, in context: Context, completion: @escaping (SubredditEntry) -> Void) {
        var imageData: Data?
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        if let data = shared?.data(forKey: "rawall") {
            imageData = data
        }

        let entry = SubredditEntry(date: Date(), subreddit: configuration.title ?? "all", imageData: imageData ?? Data())
        completion(entry)
    }

    func getTimeline(for configuration: TimelineSubredditIntent, in context: Context, completion: @escaping (Timeline<SubredditEntry>) -> Void) {
        var entries: [SubredditEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
            var imageData: Data?
            if let data = shared?.data(forKey: "raw" + (configuration.title?.lowercased() ?? "")) {
                imageData = data
            } else if let url = URL(string: shared?.string(forKey: configuration.title?.lowercased() ?? "") ?? "") {
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
            
            let entry = SubredditEntry(date: entryDate, subreddit: configuration.title ?? "all", imageData: imageData ?? Data())
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SubredditEntry: TimelineEntry {
    let date: Date
    let subreddit: String
    let imageData: Data
}

struct SubredditView: View {
    var imageData: Data
    var title: String

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        VStack {
            Image(uiImage: UIImage(data: imageData) ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50, alignment: .center)
                .clipShape(Circle())
                .clipped()
            Text(self.title).font(.headline).bold().foregroundColor(colorScheme == .light ? .primary : .white).opacity(0.8)
        }.widgetURL(URL(string: "slide://www.reddit.com/r/\(title)")).frame(maxWidth: .infinity)
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
            HStack {
                if widgetFamily == .systemMedium {
                    SubredditView(imageData: entry.imageData, title: getTitle(item: 0))
                    SubredditView(imageData: entry.imageData, title: getTitle(item: 1))
                    SubredditView(imageData: entry.imageData, title: getTitle(item: 2))
                } else {
                    SubredditView(imageData: entry.imageData, title: entry.subreddit)
                }
            }
        }.frame(maxHeight: .infinity)
        .background(Color(widgetFamily == .systemSmall ? UIImage(data: entry.imageData)?.averageColor ?? getSchemeColor() : getSchemeColor())
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

@main
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
        .configurationDisplayName("Favorite Subreddits")
        .description("Quick links to your favorite Slide subreddits")
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
        Favorite_SubredditsEntryView(entry: SubredditEntry(date: Date(), subreddit: "all", imageData: getPreviewData()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
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
