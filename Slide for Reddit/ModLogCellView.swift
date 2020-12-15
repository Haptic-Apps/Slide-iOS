//
//  ModLogCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 11/17/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import reddift
import UIKit


class ModlogCellView: UICollectionViewCell, UIGestureRecognizerDelegate, TextDisplayStackViewDelegate {
    var logItem: ModLogObject?
    public weak var parentViewController: (UIViewController & MediaVCDelegate)?
    public weak var navViewController: UIViewController?

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
            let vc = ProfileInfoViewController(accountNamed: profile, parent: parent)
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
        
        self.text.leftAnchor /==/ self.contentView.leftAnchor + 8

        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    var lsC: [NSLayoutConstraint] = []

    func setLogItem(logItem: ModLogObject, parent: UIViewController & MediaVCDelegate, nav: UIViewController?, width: CGFloat) {
        parentViewController = parent
        if navViewController == nil && nav != nil {
            navViewController = nav
        }
        self.logItem = logItem

        let messageClick = UITapGestureRecognizer(target: self, action: #selector(ModlogCellView.didClick(sender:)))
        let messageLongClick = UILongPressGestureRecognizer(target: self, action: #selector(ModlogCellView.showMenu(_:)))
        messageLongClick.minimumPressDuration = 0.36
        messageLongClick.delegate = self
        messageLongClick.cancelsTouchesInView = false
        messageClick.delegate = self
        self.addGestureRecognizer(messageClick)
        self.addGestureRecognizer(messageLongClick)

        let titleText = ModlogCellView.getTitleText(item: logItem)
        text.estimatedWidth = self.contentView.frame.size.width - 16
        text.setTextWithTitleHTML(titleText, htmlString: logItem.targetTitle)
    }
    
    @objc func didClick(sender: AnyObject) {
        guard let logItem = logItem else { return }
        let url = "https://www.reddit.com\(logItem.permalink)"
        VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.initPercent(string: url)!), popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
    }

    var timer: Timer?
    var cancelled = false
    
    public static func getTitleText(item: ModLogObject) -> NSAttributedString {
        let titleText = NSMutableAttributedString.init(string: "\(item.action)- \(item.details)", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 18, submission: false), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        let endString = NSMutableAttributedString(string: "\(DateFormatter().timeSince(from: item.created as NSDate, numericDates: true))  •  removed by \(item.mod)", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor, NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false)])
        
        var color = ColorUtil.getColorForSub(sub: item.subreddit)
        if color == ColorUtil.baseColor {
            color = ColorUtil.theme.fontColor
        }

        let subString = NSMutableAttributedString(string: "r/\(item.subreddit)", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false), NSAttributedString.Key.foregroundColor: color])
        
        let infoString = NSMutableAttributedString()
        infoString.append(endString)
        infoString.append(NSAttributedString.init(string: "  •  ", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor, NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false)]))
        infoString.append(subString)
        
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
            if let item = self.logItem {
                let alertController = DragDownAlertMenu(title: "Modlog Item", subtitle: item.targetTitle.unescapeHTML, icon: nil)

                alertController.addAction(title: "View author profile", icon: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()) {
                    let url = "https://www.reddit.com/u/\(item.targetAuthor)"
                    VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.initPercent(string: url)!), popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
                }

                alertController.addAction(title: "View original content", icon: UIImage(sfString: SFSymbol.bubbleLeftAndBubbleRightFill, overrideString: "comments")!.menuIcon()) {
                    let url = "https://www.reddit.com\(item.permalink)"
                    VCPresenter.showVC(viewController: RedditLink.getViewControllerForURL(urlS: URL.initPercent(string: url)!), popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
                }

                alertController.show(parentViewController)
            }
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
}
