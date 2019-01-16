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
import TTTAttributedLabel
import UIKit
import XLActionController

class MessageCellView: UICollectionViewCell, UIGestureRecognizerDelegate, TTTAttributedLabelDelegate {

    var text = TextDisplayStackView()
    var single = false

    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        parentViewController?.doShow(url: url, heroView: nil, heroVC: nil)
    }
    
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
        self.text = TextDisplayStackView.init(fontSize: 16, submission: false, color: ColorUtil.accentColorForSub(sub: ""), delegate: self, width: frame.width - 16)
        self.contentView.addSubview(text)
        
        text.verticalAnchors == contentView.verticalAnchors + CGFloat(8)
        text.rightAnchor == contentView.rightAnchor - CGFloat(8)
        
        self.contentView.backgroundColor = ColorUtil.foregroundColor
    }
    
    var lsC: [NSLayoutConstraint] = []

    func setMessage(message: RMessage, parent: UIViewController & MediaVCDelegate, nav: UIViewController?, width: CGFloat) {
        parentViewController = parent
        if navViewController == nil && nav != nil {
            navViewController = nav
        }
        self.message = message

        let messageClick = UITapGestureRecognizer(target: self, action: #selector(MessageCellView.doReply(sender:)))
        let messageLongClick = UILongPressGestureRecognizer(target: self, action: #selector(MessageCellView.showMenu(_:)))
        messageLongClick.minimumPressDuration = 0.25
        messageLongClick.delegate = self
        messageClick.delegate = self
        self.addGestureRecognizer(messageClick)
        self.addGestureRecognizer(messageLongClick)

        let titleText = getTitleText(message: message)
        text.setTextWithTitleHTML(titleText, htmlString: message.htmlBody)

        self.text.removeConstraints(lsC)
        if message.subject.hasPrefix("re:") {
            lsC = batch {
                self.text.leftAnchor == self.contentView.leftAnchor + 38
            }
        } else {
            lsC = batch {
                self.text.leftAnchor == self.contentView.leftAnchor + 8
            }
        }
    }

    var timer: Timer?
    var cancelled = false
    
    func getTitleText(message: RMessage) -> NSAttributedString {
        let titleText = NSMutableAttributedString.init(string: message.wasComment ? message.linkTitle : message.subject, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 18, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): !ActionStates.isRead(s: message) ? GMColor.red500Color() : ColorUtil.fontColor]))
        
        let endString = NSMutableAttributedString(string: "\(DateFormatter().timeSince(from: message.created, numericDates: true))  •  from \(message.author)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 16, submission: false)]))
        
        var color = ColorUtil.getColorForSub(sub: message.subreddit)
        if color == ColorUtil.baseColor {
            color = ColorUtil.fontColor
        }

        let subString = NSMutableAttributedString(string: "r/\(message.subreddit)", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 16, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): color]))
        
        let infoString = NSMutableAttributedString()
        infoString.append(endString)
        if !message.subreddit.isEmpty {
            infoString.append(NSAttributedString.init(string: "  •  ", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor, convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 16, submission: false)])))
            infoString.append(subString)
        }
        
        titleText.append(NSAttributedString(string: "\n"))
        titleText.append(infoString)
        return titleText
    }

    @objc func showLongMenu() {
        timer!.invalidate()
        if !self.cancelled {
            //todo show menu
            //read reply full thread
            if #available(iOS 10.0, *) {
                HapticUtility.hapticActionStrong()
            } else if SettingValues.hapticFeedback {
                AudioServicesPlaySystemSound(1519)
            }
            let alertController: BottomSheetActionController = BottomSheetActionController()
            alertController.headerData = "Message from u/\(self.message!.author)"

            alertController.addAction(Action(ActionData(title: "\(AccountController.formatUsernamePosessive(input: self.message!.author, small: false)) profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { _ in

                let prof = ProfileViewController.init(name: self.message!.author)
                VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
            }))

            alertController.addAction(Action(ActionData(title: "Reply", image: UIImage(named: "reply")!.menuIcon()), style: .default, handler: { _ in
                self.doReply()
            }))
            alertController.addAction(Action(ActionData(title: ActionStates.isRead(s: self.message!) ? "Mark unread" : "Mark read", image: UIImage(named: "seen")!.menuIcon()), style: .default, handler: { _ in
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
                    let titleText = self.getTitleText(message: self.message!)
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
                    let titleText = self.getTitleText(message: self.message!)
                    self.text.setTextWithTitleHTML(titleText, htmlString: self.message!.htmlBody)
                }
            }))
            if self.message!.wasComment {
                alertController.addAction(Action(ActionData(title: "Full thread", image: UIImage(named: "comments")!.menuIcon()), style: .default, handler: { _ in
                    let url = "https://www.reddit.com\(self.message!.context)"
                    VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: url)!), popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
                }))
            }

            VCPresenter.presentAlert(alertController, parentVC: parentViewController!)

        }
    }

    @objc func showMenu(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.25,
                    target: self,
                    selector: #selector(self.showLongMenu),
                    userInfo: nil,
                    repeats: false)
        }
        if sender.state == UIGestureRecognizer.State.ended {
            timer!.invalidate()
            cancelled = true
        }
    }

    var registered: Bool = false
    var currentLink: URL?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var message: RMessage?
    public var parentViewController: (UIViewController & MediaVCDelegate)?
    public var navViewController: UIViewController?

    @objc func doReply(sender: UITapGestureRecognizer? = nil) {
        if !ActionStates.isRead(s: message!) {
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            do {
                try session?.markMessagesAsRead([(message?.name.contains("_"))! ? (message?.name)! : ((message?.wasComment)! ? "t1_" : "t4_") + (message?.name)!], completion: { (result) in
                    if result.error != nil {
                        print(result.error!.description)
                    }
                })
            } catch {
            }
            ActionStates.setRead(s: message!, read: true)
            let titleText = self.getTitleText(message: self.message!)
            self.text.setTextWithTitleHTML(titleText, htmlString: self.message!.htmlBody)

        } else {
            if (message?.wasComment)! {
                let url = "https://www.reddit.com\(message!.context)"
                let vc = RedditLink.getViewControllerForURL(urlS: URL.init(string: url)!)
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

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
