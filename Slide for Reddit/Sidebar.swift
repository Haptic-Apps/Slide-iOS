//
//  Sidebar.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/9/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift
import YYText

class Sidebar: NSObject {
    
    var parent: (UIViewController & MediaVCDelegate)?
    var subname = ""
    
    init(parent: UIViewController & MediaVCDelegate, subname: String) {
        self.parent = parent
        self.subname = subname
    }
    
    var inner: SubSidebarViewController?
    var subInfo: Subreddit?

    func displaySidebar() {
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.about(subname, completion: { (result) in
                switch result {
                case .success(let r):
                    self.subInfo = r
                    DispatchQueue.main.async {
                        self.doDisplaySidebar(r)
                    }
                default:
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Subreddit sidebar not found", seconds: 3, context: self.parent)
                    }
                }
            })
        } catch {
        }
    }

    var alrController = UIAlertController()
    var menuPresentationController: BottomMenuPresentationController?

    func doDisplaySidebar(_ sub: Subreddit) {
        guard let parent = parent else { return }
        inner = SubSidebarViewController(sub: sub, parent: parent)
        
        if #available(iOS 13.0, *) {
            VCPresenter.presentAlert(UINavigationController(rootViewController: inner!), parentVC: parent)
        } else {
            VCPresenter.showVC(viewController: inner!, popupIfPossible: false, parentNavigationController: parent.navigationController, parentViewController: parent)
        }
    }

    func subscribe(_ sub: Subreddit) {
        if parent!.subChanged && !sub.userIsSubscriber || sub.userIsSubscriber {
            //was not subscriber, changed, and unsubscribing again
            Subscriptions.unsubscribe(sub.displayName, session: (UIApplication.shared.delegate as! AppDelegate).session!)
            parent!.subChanged = false
            BannerUtil.makeBanner(text: "Unsubscribed", seconds: 5, context: self.parent, top: true)
        } else {
            let alrController = DragDownAlertMenu(title: "Follow r/\(sub.displayName)", subtitle: "", icon: nil, themeColor: ColorUtil.accentColorForSub(sub: sub.displayName), full: true)
            if AccountController.isLoggedIn {
                alrController.addAction(title: "Subscribe", icon: nil) {
                    Subscriptions.subscribe(sub.displayName, true, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                    self.parent!.subChanged = true
                    BannerUtil.makeBanner(text: "Subscribed", seconds: 5, context: self.parent, top: true)
                }
            }
            
            alrController.addAction(title: "Casually subscribe", icon: nil) {
                Subscriptions.subscribe(sub.displayName, false, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                self.parent!.subChanged = true
                BannerUtil.makeBanner(text: "Added to subscription list", seconds: 5, context: self.parent, top: true)
            }

            alrController.show(parent)
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}
