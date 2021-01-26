//
//  SiriShortcuts.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/13/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import CoreServices
import CoreSpotlight
import Foundation

// Open a subreddit
@available(iOS 12.0, *)
extension SingleSubredditViewController {
    public static func openSubredditActivity(subreddit: String) -> NSUserActivity {
        let activity = NSUserActivity(activityType: subredditIntent)
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(subredditIntent)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        activity.title = subreddit
        activity.userInfo = ["TYPE": "SUBREDDIT"]
        attributes.contentDescription = "Open r/\(subreddit) in Slide"
        activity.contentAttributeSet = attributes

        return activity
    }
}

// View inbox
@available(iOS 12.0, *)
extension InboxViewController {
    public static func openInboxActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: inboxIntent)
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(inboxIntent)
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        
        let attributes = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        activity.title = "Reddit Inbox"
        activity.userInfo = ["TYPE": "INBOX"]
        attributes.contentDescription = "Open Reddit Inbox"
        activity.contentAttributeSet = attributes

        return activity
    }
}

extension AppDelegate {
    // Siri Shortcuts integration
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if (userActivity.userInfo?["TYPE"] as? NSString) ?? "" == "SUBREDDIT" {
            VCPresenter.openRedditLink("/r/\(userActivity.title ?? "")", window?.rootViewController as? UINavigationController, window?.rootViewController)
        } else if (userActivity.userInfo?["TYPE"] as? NSString) ?? "" == "INBOX" {
            VCPresenter.showVC(viewController: InboxViewController(), popupIfPossible: false, parentNavigationController: window?.rootViewController as? UINavigationController, parentViewController: window?.rootViewController)
        } else if let url = userActivity.webpageURL {
            _ = handleURL(url)
        }
        return true
    }
}
