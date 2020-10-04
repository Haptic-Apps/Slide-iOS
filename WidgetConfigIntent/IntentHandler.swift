//
//  IntentHandler.swift
//  WidgetConfigIntent
//
//  Created by Carlos Crane on 10/3/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Intents

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
    // This is the default implementation.  If you want different objects to handle different intents,
    // you can override this and return the handler you want for that particular intent.

        return self
    }
}

@available(iOS 14.0, *)
extension IntentHandler: TimelineSubredditIntentHandling {
    func provideWidgetconfigOptionsCollection(for intent: TimelineSubredditIntent, with completion: @escaping (INObjectCollection<TimelineSubredditINO>?, Error?) -> Void) {
        var widgets = [TimelineSubredditINO]()
        TimelineSubredditProvider.all().forEach { widget in
            let widgetIntentObject = TimelineSubredditINO(identifier: widget.id, display: "\(widget.name)")
            widgets.append(widgetIntentObject)
        }
        completion(INObjectCollection(items: widgets), nil)
    }
}

public struct TimelineSubredditProvider {
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    static func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }

    static func all() -> [TimelineSubredditDetails] {
        let shared = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        let widgetsString = shared?.stringArray(forKey: "widgets")
        var toReturn = [TimelineSubredditDetails]()
        for widget in widgetsString ?? [] {
            toReturn.append(TimelineSubredditDetails(name: widget, subs: shared?.array(forKey: widget) as? [String] ?? ["all", "frontpage", "popular", "slide_ios"], colorful: shared?.bool(forKey: widget + "_color") ?? true))
        }
        if toReturn.isEmpty {
            toReturn.append(TimelineSubredditDetails(name: "Default", subs: ["all", "frontpage", "popular", "slide_ios"], colorful: true))
        }
        return toReturn
    }
}

public struct TimelineSubredditDetails {
    public let name: String
    public let subs: [String]
    public let colorful: Bool
}

// MARK: - Identifiable
extension TimelineSubredditDetails: Identifiable {
    public var id: String {
        name
    }
}
