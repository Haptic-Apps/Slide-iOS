//
//  CurrentAccountWidget.swift
//  Slide Widgets
//
//  Created by Carlos Crane on 10/4/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Foundation

import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif
import SwiftUI

struct Current_Account: Widget {
    /*
     Corresponds to USR_DOMAIN in info.plist, which derives its value
     from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
     */
     func USR_DOMAIN() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
     }

    let kind: String = "Current_Account"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AccountTimeline()) { (entry) in
            Current_AccountEntryView(entry: entry)
        }
        .configurationDisplayName("Your account")
        .description("Quick view of account stats.")
        .supportedFamilies([WidgetFamily.systemSmall])
    }
}

struct Current_AccountEntryView: View {
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }

    var entry: AccountTimeline.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    init(entry: AccountTimeline.Entry) {
        self.entry = entry
    }

    @ViewBuilder
    var body: some View {
        GeometryReader { _ in
            AccountView(imageData: entry.imageData, name: entry.name, karma: entry.karma, inbox: entry.inbox, readLater: entry.readLater)
        }
    }

    func getSchemeColor() -> UIColor {
        return colorScheme == .light ? .white : .black
    }
}

private struct AccountView: View {
    var imageData: Data
    var name: String
    var karma: Int
    var inbox: Int
    var readLater: Int

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @ViewBuilder
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Image(uiImage: UIImage(data: imageData) ?? UIImage())
                        .resizable()
                        .frame(width: 40, height: 40, alignment: .center)
                        .aspectRatio(1, contentMode: .fit)
                        .clipped()
                        .cornerRadius(10)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
                    Spacer()
                    Image(uiImage: UIImage(named: colorScheme == .light ? "slide_dark" : "slide_light") ?? UIImage())
                        .resizable()
                        .frame(width: 30, height: 30, alignment: .center)
                        .aspectRatio(1, contentMode: .fit)
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0))
                }
                Spacer()
                if name != "Guest" {
                    HStack(alignment: .center) {
                        getKarmaImage().foregroundColor(colorScheme == .light ? .primary : .white).font(Font.system(.headline).bold())
                        Text(karma.delimiter)
                            .font(.system(.headline)).bold()
                            .foregroundColor(colorScheme == .light ? .primary : .white)
                            .opacity(0.8)
                    }.padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 0))

                    HStack(alignment: .center) {
                        getInboxImage().foregroundColor(.accentColor).font(.system(.caption))
                        Text(inbox.delimiter)
                            .font(.system(.caption))
                            .foregroundColor(.accentColor)
                            .opacity(0.8)
                    }.padding(EdgeInsets(top: 4, leading: 16, bottom: 0, trailing: 0))

                    HStack(alignment: .center) {
                        getReadLaterImage().foregroundColor(.orange).font(.system(.caption))
                        Text(readLater.delimiter)
                            .font(.system(.caption))
                            .foregroundColor(.orange)
                            .opacity(0.8)
                    }.padding(EdgeInsets(top: 4, leading: 16, bottom: 10, trailing: 0))
                } else {
                    Text("Sign in to Slide to view account stats").font(.system(.subheadline)).padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                }

                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func getKarmaImage() -> Image {
        return Image(systemName: "arrow.up")
    }
    
    func getInboxImage() -> Image {
        return Image(systemName: "tray.fill")
    }

    func getReadLaterImage() -> Image {
        return Image(systemName: "book.fill")
    }
}

extension Int {
    private static var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        return numberFormatter
    }()

    var delimiter: String {
        return Int.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
