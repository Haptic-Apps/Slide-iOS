//
//  CommentCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/7/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import reddift
import UIKit
import YYText

class CommentCellView: UICollectionViewCell, UIGestureRecognizerDelegate, TextDisplayStackViewDelegate {
    
    var longBlocking = false
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

    var text: TextDisplayStackView!
    var single = false
    
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

    var hasText = false
    var full = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)

        self.text = TextDisplayStackView.init(fontSize: 16, submission: false, color: ColorUtil.accentColorForSub(sub: ""), width: frame.width - 16, delegate: self)
        self.contentView.addSubview(text)
        
        text.topAnchor /==/ contentView.topAnchor + CGFloat(8)
        text.bottomAnchor /<=/ contentView.bottomAnchor + CGFloat(8)
        text.horizontalAnchors /==/ contentView.horizontalAnchors + CGFloat(8)
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    func setComment(comment: CommentObject, parent: MediaViewController, nav: UIViewController?, width: CGFloat) {
        text.tColor = ColorUtil.accentColorForSub(sub: comment.subreddit)
        text.estimatedWidth = self.contentView.frame.size.width - 16
        parentViewController = parent
        if navViewController == nil && nav != nil {
            navViewController = nav
        }
        let titleText = CommentCellView.getTitle(comment)
        self.comment = comment
       
        let commentClick = UITapGestureRecognizer(target: self, action: #selector(CommentCellView.openComment(sender:)))
        commentClick.delegate = self
        self.addGestureRecognizer(commentClick)
        
        text.setTextWithTitleHTML(titleText, htmlString: comment.htmlBody)
    }
    
    public static func getTitle(_ comment: CommentObject) -> NSAttributedString {
        let titleText = NSMutableAttributedString.init(string: comment.submissionTitle, attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 18, submission: false), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
                
        var uC: UIColor
        switch ActionStates.getVoteDirection(s: comment) {
        case .down:
            uC = ColorUtil.downvoteColor
        case .up:
            uC = ColorUtil.upvoteColor
        default:
            uC = ColorUtil.theme.fontColor
        }
        
        let attrs = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: uC] as [NSAttributedString.Key: Any]
        
        let attrs2 = [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor] as [NSAttributedString.Key: Any]
        
        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: comment.created as NSDate, numericDates: true))  •  ", attributes: attrs2)
        
        let boldString = NSMutableAttributedString(string: "\(comment.score)pts", attributes: attrs)
        let subString = NSMutableAttributedString(string: "r/\(comment.subreddit)")
        let color = ColorUtil.getColorForSub(sub: comment.subreddit)
        if color != ColorUtil.baseColor {
            subString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange.init(location: 0, length: subString.length))
        } else {
            subString.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorUtil.theme.fontColor, range: NSRange.init(location: 0, length: subString.length))
        }
        
        let infoString = NSMutableAttributedString()
        infoString.append(boldString)
        infoString.append(endString)
        infoString.append(subString)
        
        titleText.append(NSAttributedString.init(string: "\n", attributes: nil))
        titleText.append(infoString)

        return titleText
    }
    
    var registered: Bool = false
    var currentLink: URL?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var comment: CommentObject?
    public weak var parentViewController: (UIViewController & MediaVCDelegate)?
    public weak var navViewController: UIViewController?
    
    @objc func openComment(sender: UITapGestureRecognizer? = nil) {
        VCPresenter.openRedditLink(self.comment!.permalink, parentViewController?.navigationController, parentViewController)
    }
}
