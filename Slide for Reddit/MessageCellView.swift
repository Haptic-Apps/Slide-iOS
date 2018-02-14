//
//  MessageCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//


import UIKit
import reddift
import UZTextView
import MaterialComponents.MaterialSnackbar
import AudioToolbox
import XLActionController

class MessageCellView: UITableViewCell, UIViewControllerPreviewingDelegate, UZTextViewDelegate {

    var title = UILabel()
    var textView = UZTextView()
    var info = UILabel()
    var single = false

    func textView(_ textView: UZTextView, didLongTapLinkAttribute value: Any?) {
        if let attr = value as? [String: Any] {
            if let url = attr[NSLinkAttributeName] as? URL {
                if parentViewController != nil {
                    let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
                    sheet.addAction(
                            UIAlertAction(title: "Close", style: .cancel) { (action) in
                                sheet.dismiss(animated: true, completion: nil)
                            }
                    )
                    let open = OpenInChromeController.init()
                    if (open.isChromeInstalled()) {
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
                    //todo make this work on ipad
                    parentViewController?.present(sheet, animated: true, completion: nil)
                }
            }
        }
    }

    func selectionDidEnd(_ textView: UZTextView) {
    }

    func selectionDidBegin(_ textView: UZTextView) {
    }

    func didTapTextDoesNotIncludeLinkTextView(_ textView: UZTextView) {
    }


    func textView(_ textView: UZTextView, didClickLinkAttribute value: Any?) {
        if let attr = value as? [String: Any] {
            if let url = attr[NSLinkAttributeName] as? URL {
                parentViewController?.doShow(url: url)
            }
        }
    }

    var content: CellContent?
    var hasText = false

    var full = false
    var estimatedHeight = CGFloat(0)

    func estimateHeight() -> CGFloat {
        if (estimatedHeight == 0) {
            estimatedHeight = CGFloat(24) + CGFloat(!hasText ? 0 : (content?.textHeight)!)
        }
        return estimatedHeight
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.title = UILabel(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude));
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = FontGenerator.fontOfSize(size: 18, submission: true)
        title.textColor = ColorUtil.fontColor

        self.textView = UZTextView(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        self.textView.delegate = self
        self.textView.isUserInteractionEnabled = true
        self.textView.backgroundColor = .clear

        self.info = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
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

    init(message: RMessage, parent: MediaViewController, width: CGFloat) {
        super.init(style: .default, reuseIdentifier: "none")
        self.single = true
        self.title = UILabel(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude));
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = FontGenerator.fontOfSize(size: 18, submission: true)
        title.textColor = ColorUtil.fontColor

        self.textView = UZTextView(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        self.textView.delegate = self
        self.textView.isUserInteractionEnabled = true
        self.textView.backgroundColor = .clear

        self.info = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
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
        self.setMessage(message: message, parent: parent, nav: parent.navigationController, width: width)
    }

    var lsC: [NSLayoutConstraint] = []

    func setMessage(message: RMessage, parent: MediaViewController, nav: UIViewController?, width: CGFloat) {
        parentViewController = parent
        if (navViewController == nil && nav != nil) {
            navViewController = nav
        }
        if (message.wasComment) {
            title.text = message.linkTitle
        } else {
            title.text = message.subject
        }
        self.message = message
        if (!ActionStates.isRead(s: message)) {
            title.textColor = GMColor.red500Color()
        } else {
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

        let subString = NSMutableAttributedString(string: "/r/\(message.subreddit)")
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
            content = CellContent.init(string: LinkParser.parse(attr2, ColorUtil.accentColorForSub(sub: "")), width: (width - 16 - (message.subject.hasPrefix("re:") ? 30 : 0)))
            textView.attributedString = content?.attributedString
            textView.frame.size.height = (content?.textHeight)!
            hasText = true
        } catch {
        }
        parentViewController?.registerForPreviewing(with: self, sourceView: textView)


        let metrics = ["height": content?.textHeight] as [String: Any]
        let views = ["label": title, "body": textView, "info": info] as [String: Any]
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

        } else {
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
        lsC.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[label]-4-[info]-4-[body(height)]-8-|",
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
            alertController.headerData = "Message from /u/\(self.message!.author)"


            alertController.addAction(Action(ActionData(title: "/u/\(self.message!.author)'s profile", image: UIImage(named: "profile")!.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20))), style: .default, handler: { action in

                let prof = ProfileViewController.init(name: self.message!.author)
                VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController);
            }))

            alertController.addAction(Action(ActionData(title: "Reply", image: UIImage(named: "reply")!.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20))), style: .default, handler: { action in
                self.doReply()
            }))
            alertController.addAction(Action(ActionData(title: ActionStates.isRead(s: self.message!) ? "Mark unread" : "Mark read", image: UIImage(named: "seen")!.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20))), style: .default, handler: { action in
                if (ActionStates.isRead(s: self.message!)) {
                    let session = (UIApplication.shared.delegate as! AppDelegate).session
                    do {
                        try session?.markMessagesAsUnread([(self.message?.name.contains("_"))! ? (self.message?.name)! : ((self.message?.wasComment)! ? "t1_" : "t4_") + (self.message?.name)!], completion: { (result) in
                            if (result.error != nil) {
                                print(result.error!.description)
                            }
                        })
                    } catch {

                    }
                    self.title.textColor = GMColor.red500Color()
                    ActionStates.setRead(s: self.message!, read: false)

                } else {
                    let session = (UIApplication.shared.delegate as! AppDelegate).session
                    do {
                        try session?.markMessagesAsRead([(self.message?.name.contains("_"))! ? (self.message?.name)! : ((self.message?.wasComment)! ? "t1_" : "t4_") + (self.message?.name)!], completion: { (result) in
                            if (result.error != nil) {
                                print(result.error!.description)
                            }
                        })
                    } catch {

                    }
                    self.title.textColor = ColorUtil.fontColor
                    ActionStates.setRead(s: self.message!, read: true)

                }
            }))
            if (self.message!.wasComment) {

                alertController.addAction(Action(ActionData(title: "Full thead", image: UIImage(named: "comments")!.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20))), style: .default, handler: { action in
                    let url = "https://www.reddit.com\(self.message!.context)"
                    VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.init(string: url)!), popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
                }))
            }
            alertController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "close")!.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: 20, height: 20))), style: .default, handler: nil))

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

    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        let locationInTextView = textView.convert(location, to: textView)

        if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
            currentLink = url
            previewingContext.sourceRect = textView.convert(rect, from: textView)
            if let controller = parentViewController?.getControllerForUrl(baseUrl: url) {
                return controller
            }
        }

        return nil
    }

    var previewActionItems: [UIPreviewActionItem] {

        var toReturn: [UIPreviewAction] = []

        let likeAction = UIPreviewAction(title: "Share", style: .default) { (action, viewController) -> Void in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [self.currentLink ?? ""], applicationActivities: nil);
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }
        toReturn.append(likeAction)

        let deleteAction = UIPreviewAction(title: "Open in Safari", style: .default) { (action, viewController) -> Void in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(self.currentLink!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(self.currentLink!)
            }
        }
        toReturn.append(deleteAction)

        return toReturn

    }

    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        if let attr = textView.attributes(at: locationInTextView) {
            if let url = attr[NSLinkAttributeName] as? URL,
               let value = attr[UZTextViewClickedRect] as? CGRect {
                return (url, value)
            }
        }
        return nil
    }


    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        parentViewController?.show(viewControllerToCommit, sender: parentViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var message: RMessage?
    public var parentViewController: MediaViewController?
    public var navViewController: UIViewController?

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }


    func doReply(sender: UITapGestureRecognizer? = nil) {
        if (!ActionStates.isRead(s: message!)) {
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            do {
                try session?.markMessagesAsRead([(message?.name.contains("_"))! ? (message?.name)! : ((message?.wasComment)! ? "t1_" : "t4_") + (message?.name)!], completion: { (result) in
                    if (result.error != nil) {
                        print(result.error!.description)
                    }
                })
            } catch {

            }
            title.textColor = ColorUtil.fontColor
            ActionStates.setRead(s: message!, read: true)
        } else {
            if (message?.wasComment)! {
                let url = "https://www.reddit.com\(message!.context)"
                let vc = RedditLink.getViewControllerForURL(urlS: URL.init(string: url)!)

                VCPresenter.showVC(viewController: vc, popupIfPossible: true, parentNavigationController: parentViewController?.navigationController, parentViewController: parentViewController)
            } else {
                VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(completion: {(message) in
                    DispatchQueue.main.async(execute: { () -> Void in
                        let message = MDCSnackbarMessage()
                        message.text = "Message sent!"
                        MDCSnackbarManager.show(message)
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
