//
//  Sidebar.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/9/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import TTTAttributedLabel
import reddift
import MaterialComponents.MaterialSnackbar

class Sidebar: NSObject, TTTAttributedLabelDelegate  {
    
    var parent: MediaViewController?
    var subname = ""
    
    init(parent: MediaViewController, subname: String){
        self.parent = parent
        self.subname = subname
    }

    func attributedLabel(_ label: TTTAttributedLabel!, didLongPressLinkWith url: URL!, at point: CGPoint) {
        if (url) != nil{
            if parent != nil{
                let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
                sheet.addAction(
                    UIAlertAction(title: "Close", style: .cancel) { (action) in
                        sheet.dismiss(animated: true, completion: nil)
                    }
                )
                let open = OpenInChromeController.init()
                if(open.isChromeInstalled()){
                    sheet.addAction(
                        UIAlertAction(title: "Open in Chrome", style: .default) { (action) in
                            open.openInChrome(url, callbackURL: nil, createNewTab: true)
                        }
                    )
                }
                sheet.addAction(
                    UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                        sheet.dismiss(animated: true, completion: nil)
                    }
                )
                sheet.addAction(
                    UIAlertAction(title: "Open", style: .default) { (action) in
                        /* let controller = WebViewController(nibName: nil, bundle: nil)
                         controller.url = url
                         let nav = UINavigationController(rootViewController: controller)
                         self.present(nav, animated: true, completion: nil)*/
                    }
                )
                sheet.addAction(
                    UIAlertAction(title: "Copy URL", style: .default) { (action) in
                        UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                        sheet.dismiss(animated: true, completion: nil)
                    }
                )
                
                parent?.present(sheet, animated: true, completion: nil)
            }
        }
    }

    var inner: MediaViewController?
    var subInfo: Subreddit?

    func displaySidebar(){
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.about(subname, completion: { (result) in
                switch result {
                case .success(let r):
                    self.subInfo = r
                    DispatchQueue.main.async {
                        self.doDisplaySidebar(r)
                    }
                default:
                    DispatchQueue.main.async{
                        let message = MDCSnackbarMessage()
                        message.text = "Subreddit sidebar not found"
                        MDCSnackbarManager.show(message)
                    }
                    break
                }
            })
        } catch {
        }
    }

    var alrController = UIAlertController()

    func doDisplaySidebar(_ sub: Subreddit){
        inner = SubSidebarViewController(sub: sub, parent: parent!)
        let bottomSheet: MDCBottomSheetController = MDCBottomSheetController(contentViewController: inner!)
        parent?.present(bottomSheet, animated: true, completion: nil)
    }

    func subscribe(_ sub: Subreddit){
        if(parent!.subChanged && !sub.userIsSubscriber || sub.userIsSubscriber){
            //was not subscriber, changed, and unsubscribing again
            Subscriptions.unsubscribe(sub.displayName, session: (UIApplication.shared.delegate as! AppDelegate).session!)
            parent!.subChanged = false
            let message = MDCSnackbarMessage()
            message.text = "Unsubscribed"
            MDCSnackbarManager.show(message)
        } else {
            let alrController = UIAlertController.init(title: "Subscribe to \(sub.displayName)", message: nil, preferredStyle: .actionSheet)
            if(AccountController.isLoggedIn){
                let somethingAction = UIAlertAction(title: "Add to sub list and subscribe", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                    Subscriptions.subscribe(sub.displayName, true, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                    self.parent!.subChanged = true
                    let message = MDCSnackbarMessage()
                    message.text = "Subscribed"
                    MDCSnackbarManager.show(message)
                })
                alrController.addAction(somethingAction)
            }
            
            let somethingAction = UIAlertAction(title: "Add to sub list", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                Subscriptions.subscribe(sub.displayName, false, session: (UIApplication.shared.delegate as! AppDelegate).session!)
                self.parent!.subChanged = true
                let message = MDCSnackbarMessage()
                message.text = "Added"
                MDCSnackbarManager.show(message)
            })
            alrController.addAction(somethingAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
            
            alrController.addAction(cancelAction)
            alrController.modalPresentationStyle = .popover
            if let presenter = alrController.popoverPresentationController {
                presenter.sourceView = parent!.view
                presenter.sourceRect = parent!.view.bounds
            }

            parent?.present(alrController, animated: true, completion:{})
            
        }
    }

}
