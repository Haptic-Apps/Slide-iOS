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
        if let attr = url{
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
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if((parent) != nil){
            alrController.dismiss(animated: true, completion: nil)
            parent?.doShow(url: url)
        }
        
    }
    
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
         alrController = UIAlertController(title:"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", message: "\(sub.accountsActive) here now\n\(sub.subscribers) subscribers", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        
        let label = UILabel.init(frame: CGRect.init(x: 00, y: 0, width: 500, height: 40))
            label.text =  "        \(sub.displayName)"
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFont(ofSize: 25)
        
        var sideView = UIView()
        sideView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: CGFloat.greatestFiniteMagnitude))
        sideView.backgroundColor = ColorUtil.getColorForSub(sub: sub.displayName)
        sideView.translatesAutoresizingMaskIntoConstraints = false
        
        label.addSubview(sideView)
        
        let metrics=["topMargin": 5,"topMarginS":7.5]
        let views=["side":sideView, "label" : label] as [String : Any]
        var constraint:[NSLayoutConstraint] = []
        
        
        constraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[side(25)]-8-[label]",
                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                    metrics: metrics,
                                                    views: views)
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-(7.5)-[side(25)]-(7.5)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))

        label.addConstraints(constraint)
        sideView.layer.cornerRadius = 12.5
        sideView.clipsToBounds = true

        let margin:CGFloat = 8.0
        let rect = CGRect.init(x: margin, y: margin + 5, width: alrController.view.bounds.size.width - margin * 4.0, height: 300)
        let scrollView = UIScrollView(frame: rect)
        scrollView.backgroundColor = UIColor.clear
        var info: TTTAttributedLabel = TTTAttributedLabel(frame: CGRect(x: 0, y: 40, width: rect.size.width, height: CGFloat.greatestFiniteMagnitude))
        //todo info.delegate = self
        info.isUserInteractionEnabled = true
        info.numberOfLines = 0
        info.backgroundColor = .clear
        info.delegate = self
        
        if(!sub.description.isEmpty()){
            let html = sub.descriptionHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
            do {
                let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                let font = FontGenerator.fontOfSize(size: 16, submission: false)
                let attr2 = NSMutableAttributedString.init(string: "\n\n\n")
                attr2.append(attr.reconstruct(with: font, color: UIColor.darkGray, linkColor: ColorUtil.accentColorForSub(sub: sub.displayName)))
                let contentInfo = CellContent.init(string:LinkParser.parse(attr2), width: rect.size.width)
                info.setText(contentInfo.attributedString)
                info.frame.size.height = (contentInfo.textHeight)
                let activeLinkAttributes = NSMutableDictionary()
                activeLinkAttributes[NSForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: sub.displayName)
                info.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
                info.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
                scrollView.contentSize = CGSize.init(width: rect.size.width, height: info.frame.size.height + 50)
                scrollView.addSubview(info)
                scrollView.addSubview(label)
            } catch {
            }
            //todo parentController?.registerForPreviewing(with: self, sourceView: info)
        }
        
        alrController.view.addSubview(scrollView)
        
        let subscribed = sub.userIsSubscriber || parent!.subChanged && !sub.userIsSubscriber ? "Unsubscribe" : "Subscribe"
        var somethingAction = UIAlertAction(title: subscribed, style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in self.subscribe(sub)})
        alrController.addAction(somethingAction)
        
        somethingAction = UIAlertAction(title: "Submit a post", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in print("something")})
        alrController.addAction(somethingAction)
        
        somethingAction = UIAlertAction(title: "Subreddit moderators", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in print("something")})
        alrController.addAction(somethingAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
        
        alrController.addAction(cancelAction)
        
        parent?.present(alrController, animated: true, completion:{})
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
            
            parent?.present(alrController, animated: true, completion:{})
            
        }
    }

}
