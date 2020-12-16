//
//  MessageCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import reddift
import UIKit


class MessageCellView: UICollectionViewCell, UIGestureRecognizerDelegate, TextDisplayStackViewDelegate {
    
    func linkTapped(url: URL, text: String) {
        if !text.isEmpty {
            self.parentViewController?.showSpoiler(text)
        } else {
            self.parentViewController?.doShow(url: url, heroView: nil, finalSize: nil, heroVC: nil, link: SubmissionObject())
        }
    }

    func linkLongTapped(url: URL) {
        longBlocking = true
        
        let alertController = DragDownAlertMenu(title: "Link options", subtitle: url.absoluteString, icon: url.absoluteString)
        
        alertController.addAction(title: "Share URL", icon: UIImage(sfString: SFSymbol.squareAndArrowUp, overrideString: "share")!.menuIcon()) {
            let shareItems: Array = [url]
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.contentView
            self.parentViewController?.present(activityViewController, animated: true, completion: nil)
        }
        
        alertController.addAction(title: "Copy URL", icon: UIImage(sfString: SFSymbol.docOnDocFill, overrideString: "copy")!.menuIcon()) {
            UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
            BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parentViewController)
        }
        
        alertController.addAction(title: "Open in default app", icon: UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")!.menuIcon()) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        
        let open = OpenInChromeController.init()
        if open.isChromeInstalled() {
            alertController.addAction(title: "Open in Chrome", icon: UIImage(named: "world")!.menuIcon()) {
                open.openInChrome(url, callbackURL: nil, createNewTab: true)
            }
        }
        
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        } else if SettingValues.hapticFeedback {
            AudioServicesPlaySystemSound(1519)
        }
        
        if parentViewController != nil {
            alertController.show(parentViewController!)
        }
    }
    
    func previewProfile(profile: String) {
        if let parent = self.parentViewController {
            let vc = ProfileInfoViewController(accountNamed: profile)
            vc.modalPresentationStyle = .custom
            vc.transitioningDelegate = ProfileInfoPresentationManager()
            parent.present(vc, animated: true)
        }
    }

    var text: TextDisplayStackView!
    var single = false

    var longBlocking = false
    override func layoutSubviews() {
        super.layoutSubviews()
        let topmargin = 0
        let bottommargin = 2
        let leftmargin = 0
        let rightmargin = 0
        
        let f = self.contentView.frame
        let fr = f.inset(by: UIEdgeInsets(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin)))
        self.contentView.frame = fr
    }

    var content: NSAttributedString?
    var hasText = false

    var full = false

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)
        self.text = TextDisplayStackView.init(fontSize: 16, submission: false, color: ColorUtil.accentColorForSub(sub: ""), width: frame.width - 16, delegate: self)
        self.contentView.addSubview(text)
        
        text.topAnchor /==/ contentView.topAnchor + CGFloat(8)
        text.bottomAnchor /<=/ contentView.bottomAnchor + CGFloat(8)
        text.rightAnchor /==/ contentView.rightAnchor - CGFloat(8)
        
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    var lsC: [NSLayoutConstraint] = []

    func setMessage(message: MessageObject, parent: UIViewController & MediaVCDelegate, nav: UIViewController?, width: CGFloat) {
        parentViewController = parent
        if navViewController == nil && nav != nil {
            navViewController = nav
        }
        self.message = message

        let messageClick = UITapGestureRecognizer(target: self, action: #selector(MessageCellView.doReply(sender:)))
        let messageLongClick = UILongPressGestureRecognizer(target: self, action: #selector(MessageCellView.showMenu(_:)))
        messageLongClick.minimumPressDuration = 0.36
        messageLongClick.delegate = self
        messageLongClick.cancelsTouchesInView = false
        messageClick.delegate = self
        self.addGestureRecognizer(messageClick)
        self.addGestureRecognizer(messageLongClick)

        let titleText = MessageCellView.getTitleText(message: message)
        text.estimatedWidth = self.contentView.frame.size.width - 16 - (message.subject.hasPrefix("re:") ? 30 : 0)
        text.setTextWithTitleHTML(titleText, htmlString: message.htmlBody)

        self.text.removeConstraints(lsC)
        if message.subject.hasPrefix("re:") {
            lsC = batch {
                self.text.leftAnchor /==/ self.contentView.leftAnchor + 38
            }
        } else {
            lsC = batch {
                self.text.leftAnchor /==/ self.contentView.leftAnchor + 8
            }
        }
    }

    var timer: Timer?
    var cancelled = false
    
    public static func getTitleText(message: MessageObject) -> NSAttributedString {
        let titleText = NSMutableAttributedString(string: message.wasComment ? message.submissionTitle?.unescapeHTML ?? "" : message.subject.unescapeHTML, attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 18, submission: false), NSAttributedString.Key.foregroundColor: !ActionStates.isRead(s: message) ? GMColor.red500Color() : ColorUtil.theme.fontColor])
        
        let endString = NSMutableAttributedString(string: "\(DateFormatter().timeSince(from: message.created as NSDate, numericDates: true))  •  from \(message.author)", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor, NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false)])
        
        var color = ColorUtil.getColorForSub(sub: message.subreddit)
        if color == ColorUtil.baseColor {
            color = ColorUtil.theme.fontColor
        }

        let subString = NSMutableAttributedString(string: "r/\(message.subreddit)", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false), NSAttributedString.Key.foregroundColor: color])
        
        let infoString = NSMutableAttributedString()
        infoString.append(endString)
        if !message.subreddit.isEmpty {
            infoString.append(NSAttributedString.init(string: "  •  ", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor, NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false)]))
            infoString.append(subString)
        }
        
        titleText.append(NSAttributedString(string: "\n"))
        titleText.append(infoString)
        return titleText
    }

    @objc func showLongMenu() {
        timer!.invalidate()
        if longBlocking {
            self.longBlocking = false
            return
        }
        if !self.cancelled {
           // TODO: - show menu
            //read reply full thread
            if #available(iOS 10.0, *) {
                HapticUtility.hapticActionStrong()
            } else if SettingValues.hapticFeedback {
                AudioServicesPlaySystemSound(1519)
            }
            let alertController = DragDownAlertMenu(title: "Message from u/\(self.message!.author)", subtitle: self.message!.subject, icon: nil)

            alertController.addAction(title: "\(AccountController.formatUsernamePosessive(input: self.message!.author, small: false)) profile", icon: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()) {
                let prof = ProfileViewController.init(name: self.message!.author)
                VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
            }

            alertController.addAction(title: "Reply to message", icon: UIImage(sfString: SFSymbol.arrowshapeTurnUpLeftFill, overrideString: "reply")!.menuIcon()) {
                self.doReply()
            }

            alertController.addAction(title: ActionStates.isRead(s: self.message!) ? "Mark as unread" : "Mark as read", icon: ActionStates.isRead(s: self.message!) ? UIImage(sfString: SFSymbol.eyeSlashFill, overrideString: "seen")!.menuIcon() : UIImage(sfString: SFSymbol.eyeFill, overrideString: "seen")!.menuIcon()) {
                if ActionStates.isRead(s: self.message!) {
                    let session = (UIApplication.shared.delegate as! AppDelegate).session
                    do {
                        try session?.markMessagesAsUnread([(self.message?.name.contains("_"))! ? (self.message?.name)! : ((self.message?.wasComment)! ? "t1_" : "t4_") + (self.message?.name)!], completion: { (result) in
                            if result.error != nil {
                                print(result.error!.description)
                            }
                        })
                    } catch {
                        
                    }
                    ActionStates.setRead(s: self.message!, read: false)
                    let titleText = MessageCellView.getTitleText(message: self.message!)
                    self.text.setTextWithTitleHTML(titleText, htmlString: self.message!.htmlBody)
                    
                } else {
                    let session = (UIApplication.shared.delegate as! AppDelegate).session
                    do {
                        try session?.markMessagesAsRead([(self.message?.name.contains("_"))! ? (self.message?.name)! : ((self.message?.wasComment)! ? "t1_" : "t4_") + (self.message?.name)!], completion: { (result) in
                            if result.error != nil {
                                print(result.error!.description)
                            }
                        })
                    } catch {
                        
                    }
                    ActionStates.setRead(s: self.message!, read: true)
                    let titleText = MessageCellView.getTitleText(message: self.message!)
                    self.text.setTextWithTitleHTML(titleText, htmlString: self.message!.htmlBody)
                }
            }

            if self.message!.wasComment {
                alertController.addAction(title: "View comment thread", icon: UIImage(sfString: SFSymbol.bubbleLeftAndBubbleRightFill, overrideString: "comments")!.menuIcon()) {
                    let url = "https://www.reddit.com\(self.message!.context ?? "")"
                    VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.initPercent(string: url)!), popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
                }
            }

            alertController.show(parentViewController)
        }
    }

    @objc func showMenu(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.36,
                    target: self,
                    selector: #selector(self.showLongMenu),
                    userInfo: nil,
                    repeats: false)
        }
        if sender.state == UIGestureRecognizer.State.ended {
            timer!.invalidate()
            cancelled = true
            longBlocking = false
        }
    }

    var registered: Bool = false
    var currentLink: URL?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var message: MessageObject?
    public weak var parentViewController: (UIViewController & MediaVCDelegate)?
    public weak var navViewController: UIViewController?

    @objc func doReply(sender: UITapGestureRecognizer? = nil) {
        if !ActionStates.isRead(s: message!) {
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            do {
                try session?.markMessagesAsRead([(message?.name.contains("_"))! ? (message?.name)! : ((message?.wasComment)! ? "t1_" : "t4_") + (message?.name)!], completion: { (result) in
                    if result.error != nil {
                        print(result.error!.description)
                    } else {
                        NotificationCenter.default.post(name: .accountRefreshRequested, object: nil, userInfo: nil)
                    }
                })
            } catch {
            }
            ActionStates.setRead(s: message!, read: true)
            let titleText = MessageCellView.getTitleText(message: self.message!)
            self.text.setTextWithTitleHTML(titleText, htmlString: self.message!.htmlBody)

        } else {
            if (message?.wasComment)! {
                let url = "https://www.reddit.com\(message!.context ?? "")"
                let vc = RedditLink.getViewControllerForURL(urlS: URL.initPercent(string: url)!)
                VCPresenter.showVC(viewController: vc, popupIfPossible: true, parentNavigationController: parentViewController?.navigationController, parentViewController: parentViewController)
            } else {
                VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(message: message, completion: {(_) in
                    DispatchQueue.main.async(execute: { () -> Void in
                        BannerUtil.makeBanner(text: "Message sent!", seconds: 3, context: self.parentViewController)
                    })
                })), parentVC: parentViewController!)
            }
        }
    }
}
