//
//  MessageCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import AudioToolbox
import reddift
import TTTAttributedLabel
import UIKit
import XLActionController

class MessageCellView: UICollectionViewCell, UIGestureRecognizerDelegate, TTTAttributedLabelDelegate {

    var title = UILabel()
    var textView = TTTAttributedLabel.init(frame: CGRect.zero)
    var info = UILabel()
    var single = false

    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        parentViewController?.doShow(url: url)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let topmargin = 0
        let bottommargin = 2
        let leftmargin = 0
        let rightmargin = 0
        
        let f = self.contentView.frame
        let fr = UIEdgeInsetsInsetRect(f, UIEdgeInsets(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin)))
        self.contentView.frame = fr
    }

    var content: NSAttributedString?
    var hasText = false

    var full = false
    var estimatedHeight = CGFloat(0)

    func estimateHeight() -> CGFloat {
        if (estimatedHeight == 0) {
            let framesetterB = CTFramesetterCreateWithAttributedString(content!)
            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: width - 16 - (message!.subject.hasPrefix("re:") ? 22 : 0), height: CGFloat.greatestFiniteMagnitude), nil)
            estimatedHeight = CGFloat(24) + CGFloat(!hasText ? 0 : textSizeB.height)
        }
        return estimatedHeight
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)
        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = FontGenerator.fontOfSize(size: 18, submission: true)
        title.textColor = ColorUtil.fontColor

        self.textView = TTTAttributedLabel(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        self.textView.delegate = self
        self.textView.isUserInteractionEnabled = true
        self.textView.numberOfLines = 0
        self.textView.backgroundColor = .clear

        self.info = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        info.numberOfLines = 0
        info.font = FontGenerator.fontOfSize(size: 12, submission: true)
        info.textColor = ColorUtil.fontColor
        info.alpha = 0.87

        title.translatesAutoresizingMaskIntoConstraints = false
        info.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(title)
        self.contentView.addSubview(textView)
        self.contentView.addSubview(info)

        self.contentView.backgroundColor = ColorUtil.foregroundColor

        self.updateConstraints()

    }
    
    var lsC: [NSLayoutConstraint] = []

    func setMessage(message: RMessage, parent: UIViewController & MediaVCDelegate, nav: UIViewController?, width: CGFloat) {
        parentViewController = parent
        if (navViewController == nil && nav != nil) {
            navViewController = nav
        }
        if (message.wasComment) {
            title.text = message.linkTitle
        }
        else {
            title.text = message.subject
        }
        self.message = message
        if (!ActionStates.isRead(s: message)) {
            title.textColor = GMColor.red500Color()
        }
        else {
            title.textColor = ColorUtil.fontColor
        }
        title.sizeToFit()

        if (!lsC.isEmpty) {
            self.contentView.removeConstraints(lsC)
        }

        let messageClick = UITapGestureRecognizer(target: self, action: #selector(MessageCellView.doReply(sender:)))
        let messageLongClick = UILongPressGestureRecognizer(target: self, action: #selector(MessageCellView.showMenu(_:)))
        messageLongClick.minimumPressDuration = 0.25
        messageLongClick.delegate = self
        messageClick.delegate = self
        self.addGestureRecognizer(messageClick)
        self.addGestureRecognizer(messageLongClick)

        let endString = NSMutableAttributedString(string: "\(DateFormatter().timeSince(from: message.created, numericDates: true))  •  from \(message.author)")

        let subString = NSMutableAttributedString(string: "r/\(message.subreddit)")
        let color = ColorUtil.getColorForSub(sub: message.subreddit)
        if (color != ColorUtil.baseColor) {
            subString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: subString.length))
        }

        let infoString = NSMutableAttributedString()
        infoString.append(endString)
        if (!message.subreddit.isEmpty) {
            infoString.append(NSAttributedString.init(string: "  •  "))
            infoString.append(subString)
        }

        info.attributedText = infoString

        let accent = ColorUtil.accentColorForSub(sub: "")
        let html = message.htmlBody
        do {
            let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
            let font = FontGenerator.fontOfSize(size: 16, submission: false)
            let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: accent)
            content = LinkParser.parse(attr2, ColorUtil.accentColorForSub(sub: ""))
            textView.setText(content)
            let framesetterB = CTFramesetterCreateWithAttributedString(content!)
            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: width - 16 - (message.subject.hasPrefix("re:") ? 22 : 0), height: CGFloat.greatestFiniteMagnitude), nil)

            textView.frame.size.height = textSizeB.height
            hasText = true
        }
        catch {
        }

        let metrics = ["height": textView.frame.size.height] as [String: Any]
        let views = ["label": title, "body": textView, "info": info] as [String: Any]
        if(!lsC.isEmpty) {
            self.contentView.removeConstraints(lsC)
        }
        lsC = []
        if (message.subject.hasPrefix("re:")) {
            lsC.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-38-[label]-8-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: metrics,
                    views: views))

            lsC.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-38-[body]-8-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: metrics,
                    views: views))

            lsC.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-38-[info]-8-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: metrics,
                    views: views))

        }
        else {
            lsC.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[label]-8-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: metrics,
                    views: views))

            lsC.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[body]-8-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: metrics,
                    views: views))

            lsC.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[info]-8-|",
                    options: NSLayoutFormatOptions(rawValue: 0),
                    metrics: metrics,
                    views: views))
        }
        lsC.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-16-[label]-4-[info]-4-[body]-16-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        self.contentView.addConstraints(lsC)

    }

    var timer: Timer?
    var cancelled = false

    func showLongMenu() {
        timer!.invalidate()
        AudioServicesPlaySystemSound(1519)
        if (!self.cancelled) {
            //todo show menu
            //read reply full thread

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
                if (ActionStates.isRead(s: self.message!)) {
                    let session = (UIApplication.shared.delegate as! AppDelegate).session
                    do {
                        try session?.markMessagesAsUnread([(self.message?.name.contains("_"))! ? (self.message?.name)! : ((self.message?.wasComment)! ? "t1_" : "t4_") + (self.message?.name)!], completion: { (result) in
                            if (result.error != nil) {
                                print(result.error!.description)
                            }
                        })
                    }
                    catch {

                    }
                    self.title.textColor = GMColor.red500Color()
                    ActionStates.setRead(s: self.message!, read: false)

                }
                else {
                    let session = (UIApplication.shared.delegate as! AppDelegate).session
                    do {
                        try session?.markMessagesAsRead([(self.message?.name.contains("_"))! ? (self.message?.name)! : ((self.message?.wasComment)! ? "t1_" : "t4_") + (self.message?.name)!], completion: { (result) in
                            if (result.error != nil) {
                                print(result.error!.description)
                            }
                        })
                    }
                    catch {

                    }
                    self.title.textColor = ColorUtil.fontColor
                    ActionStates.setRead(s: self.message!, read: true)

                }
            }))
            if (self.message!.wasComment) {
                alertController.addAction(Action(ActionData(title: "Full thead", image: UIImage(named: "comments")!.menuIcon()), style: .default, handler: { _ in
                    let url = "https://www.reddit.com\(self.message!.context)"
                    VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: url)!), popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
                }))
            }

            VCPresenter.presentAlert(alertController, parentVC: parentViewController!)

        }
    }

    func showMenu(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.began) {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.25,
                    target: self,
                    selector: #selector(self.showLongMenu),
                    userInfo: nil,
                    repeats: false)
        }
        if (sender.state == UIGestureRecognizerState.ended) {
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
    public var parentViewController: UIViewController & MediaVCDelegate?
    public var navViewController: UIViewController?

    func doReply(sender: UITapGestureRecognizer? = nil) {
        if (!ActionStates.isRead(s: message!)) {
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            do {
                try session?.markMessagesAsRead([(message?.name.contains("_"))! ? (message?.name)! : ((message?.wasComment)! ? "t1_" : "t4_") + (message?.name)!], completion: { (result) in
                    if (result.error != nil) {
                        print(result.error!.description)
                    }
                })
            }
            catch {

            }
            title.textColor = ColorUtil.fontColor
            ActionStates.setRead(s: message!, read: true)
        }
        else {
            if (message?.wasComment)! {
                let url = "https://www.reddit.com\(message!.context)"
                let vc = RedditLink.getViewControllerForURL(urlS: URL.init(string: url)!)
                VCPresenter.showVC(viewController: vc, popupIfPossible: true, parentNavigationController: parentViewController?.navigationController, parentViewController: parentViewController)
            }
            else {
                VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(message: message, completion: {(_) in
                    DispatchQueue.main.async(execute: { () -> Void in
                        BannerUtil.makeBanner(text: "Message sent!", seconds: 3, context: self.parentViewController)
                    })
                })), parentVC: parentViewController!)
            }
        }
    }

    let overlayTransitioningDelegate = OverlayTransitioningDelegate()

    private func prepareOverlayVC(overlayVC: UIViewController) {
        overlayVC.transitioningDelegate = overlayTransitioningDelegate
        overlayVC.modalPresentationStyle = .custom
    }

}
