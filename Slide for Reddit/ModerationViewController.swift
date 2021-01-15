//
//  InboxViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import UIKit

class ModerationViewController: TabsContentPagingViewController {
    var subreddit: String
        
    public init(_ subreddit: String) {
        self.subreddit = subreddit
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

        self.session = (UIApplication.shared.delegate as! AppDelegate).session
        self.titles = ["Mod Mail", "Mod Mail Unread"]
        vCs.append(ContentListingViewController.init(dataSource: ModMailContributionLoader(false, sub: subreddit)))
        vCs.append(ContentListingViewController.init(dataSource: ModMailContributionLoader(true, sub: subreddit)))

        titles.append("Mod Queue")
        vCs.append(ContentListingViewController.init(dataSource: ModQueueContributionLoader(subreddit: subreddit)))

        titles.append("Mod Log")
        vCs.append(ContentListingViewController.init(dataSource: ModlogContributionLoader(subreddit: subreddit)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func appearOthers() {
        self.title = "r/\(subreddit)"
    }

    @objc func new(_ sender: AnyObject) {
        VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(completion: {(_) in
            DispatchQueue.main.async(execute: { () -> Void in
                BannerUtil.makeBanner(text: "Message sent!", seconds: 3, context: self)
            })
        })), parentVC: self)
    }

    @objc func read(_ sender: AnyObject) {
        do {
            try session?.markAllMessagesAsRead(completion: { (result) in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "All messages marked as read", seconds: 5, context: self)
                    }
                default:
                    break
                }
            })
        } catch {

        }
    }
}
