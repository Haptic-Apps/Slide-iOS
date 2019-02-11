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
import XLActionController

class Sidebar: NSObject, YYTextViewDelegate {
    
    var parent: (UIViewController & MediaVCDelegate)?
    var subname = ""
    
    init(parent: UIViewController & MediaVCDelegate, subname: String) {
        self.parent = parent
        self.subname = subname
    }

    func textView(_ textView: YYTextView, didLongPress highlight: YYTextHighlight, in characterRange: NSRange, rect: CGRect) {
        if let url = highlight.attributes?[NSAttributedString.Key.link.rawValue] as? URL {
            if parent != nil {
                let alertController: BottomSheetActionController = BottomSheetActionController()
                alertController.headerData = url.absoluteString
                
                alertController.addAction(Action(ActionData(title: "Copy URL", image: UIImage(named: "copy")!.menuIcon()), style: .default, handler: { _ in
                    UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                }))
                
                alertController.addAction(Action(ActionData(title: "Open externally", image: UIImage(named: "nav")!.menuIcon()), style: .default, handler: { _ in
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }))
                let open = OpenInChromeController.init()
                if open.isChromeInstalled() {
                    alertController.addAction(Action(ActionData(title: "Open in Chrome", image: UIImage(named: "world")!.menuIcon()), style: .default, handler: { _ in
                        _ = open.openInChrome(url, callbackURL: nil, createNewTab: true)
                    }))
                }
                parent?.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func textView(_ textView: YYTextView, shouldLongPress highlight: YYTextHighlight, in characterRange: NSRange) -> Bool {
        return highlight.attributes?.contains(where: { (tuple) -> Bool in
            tuple.key == NSAttributedString.Key.link.rawValue
        }) ?? false
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
        VCPresenter.showVC(viewController: inner!, popupIfPossible: false, parentNavigationController: parent.navigationController, parentViewController: parent)
    }

    func subscribe(_ sub: Subreddit) {
        if parent!.subChanged && !sub.userIsSubscriber || sub.userIsSubscriber {
            //was not subscriber, changed, and unsubscribing again
            Subscriptions.unsubscribe(sub.displayName, session: (UIApplication.shared.delegate as! AppDelegate).session!)
            parent!.subChanged = false
            BannerUtil.makeBanner(text: "Unsubscribed", seconds: 5, context: self.parent, top: true)
        } else {
            let alrController = UIAlertController.init(title: "Subscribe to \(sub.displayName)", message: nil, preferredStyle: .actionSheet)
            if AccountController.isLoggedIn {
                let somethingAction = UIAlertAction(title: "Add to sub list and subscribe", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
                    Subscriptions.subscribe(sub.displayName, true, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                    self.parent!.subChanged = true
                    BannerUtil.makeBanner(text: "Subscribed", seconds: 5, context: self.parent, top: true)
                })
                alrController.addAction(somethingAction)
            }
            
            let somethingAction = UIAlertAction(title: "Add to sub list", style: UIAlertAction.Style.default, handler: {(_: UIAlertAction!) in
                Subscriptions.subscribe(sub.displayName, false, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                self.parent!.subChanged = true
                BannerUtil.makeBanner(text: "Added to subscription list", seconds: 5, context: self.parent, top: true)
            })
            alrController.addAction(somethingAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (_: UIAlertAction!) in print("cancel") })
            
            alrController.addAction(cancelAction)
            alrController.modalPresentationStyle = .popover
            if let presenter = alrController.popoverPresentationController {
                presenter.sourceView = parent!.view
                presenter.sourceRect = parent!.view.bounds
            }

            parent?.present(alrController, animated: true, completion: {})
            
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}
