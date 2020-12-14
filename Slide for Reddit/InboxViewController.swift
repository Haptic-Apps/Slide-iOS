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

class InboxViewController: TabsContentPagingViewController {
    public static let inboxIntent = "me.ccrama.redditslide.OpenInbox"
    var content: [MessageWhere] = []
    
    static func doDefault() -> [MessageWhere] {
        return [MessageWhere.inbox, MessageWhere.messages, MessageWhere.unread]
    }

    public init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        self.session = (UIApplication.shared.delegate as! AppDelegate).session

        self.content = InboxViewController.doDefault()
        self.titles = self.content.map { $0.description }
        for place in content {
            vCs.append(ContentListingViewController.init(dataSource: InboxContributionLoader(whereContent: place)))
        }
        self.title = "Inbox"
        self.shouldScroll = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func appearOthers() {
        UIApplication.shared.applicationIconBadgeNumber = 0

        let edit = UIButton(buttonImage: UIImage(sfString: SFSymbol.pencil, overrideString: "edit"))
        edit.addTarget(self, action: #selector(self.new(_:)), for: UIControl.Event.touchUpInside)
        let editB = UIBarButtonItem.init(customView: edit)

        let read = UIButton(buttonImage: UIImage(sfString: SFSymbol.eyeFill, overrideString: "seen"))
        read.addTarget(self, action: #selector(self.read(_:)), for: UIControl.Event.touchUpInside)
        let readB = UIBarButtonItem.init(customView: read)

        self.title = "Inbox"
        navigationItem.rightBarButtonItems = [editB, readB]
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
