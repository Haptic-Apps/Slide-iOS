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
import YYText
import UIKit
import XLActionController

class CommentCellView: UICollectionViewCell, UIGestureRecognizerDelegate, TextDisplayStackViewDelegate {
    
    var longBlocking = false
    func linkTapped(url: URL, text: String) {
        if !text.isEmpty {
            self.parentViewController?.showSpoiler(text)
        } else {
            self.parentViewController?.doShow(url: url, heroView: nil, heroVC: nil)
        }
    }

    func linkLongTapped(url: URL) {
        longBlocking = true
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = url.absoluteString
        alertController.addAction(Action(ActionData(title: "Share URL", image: UIImage(named: "share")!.menuIcon()), style: .default, handler: { _ in
            let shareItems: Array = [url]
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.contentView
            self.parentViewController?.present(activityViewController, animated: true, completion: nil)
        }))
        
        alertController.addAction(Action(ActionData(title: "Copy URL", image: UIImage(named: "copy")!.menuIcon()), style: .default, handler: { _ in
            UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
            BannerUtil.makeBanner(text: "URL Copied", seconds: 5, context: self.parentViewController)
        }))
        
        alertController.addAction(Action(ActionData(title: "Open externally", image: UIImage(named: "nav")!.menuIcon()), style: .default, handler: { _ in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionStrong()
        } else if SettingValues.hapticFeedback {
            AudioServicesPlaySystemSound(1519)
        }
        self.parentViewController?.present(alertController, animated: true, completion: nil)
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
        
        text.verticalAnchors == contentView.verticalAnchors + CGFloat(8)
        text.horizontalAnchors == contentView.horizontalAnchors + CGFloat(8)
        self.contentView.backgroundColor = ColorUtil.foregroundColor
    }
    
    func setComment(comment: RComment, parent: MediaViewController, nav: UIViewController?, width: CGFloat) {
        text.tColor = ColorUtil.accentColorForSub(sub: comment.subreddit)
        parentViewController = parent
        if navViewController == nil && nav != nil {
            navViewController = nav
        }
        let titleText = CommentCellView.getTitle(comment)
        self.comment = comment
       
        let commentClick = UITapGestureRecognizer(target: self, action: #selector(CommentCellView.openComment(sender:)))
        commentClick.delegate = self
        self.addGestureRecognizer(commentClick)
        
        text.setTextWithTitleHTML(titleText, htmlString: comment.htmlText)
    }
    
    public static func getTitle(_ comment: RComment) -> NSAttributedString {
        let titleText = NSMutableAttributedString.init(string: comment.submissionTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 18, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor]))
        
        let commentClick = UITapGestureRecognizer(target: self, action: #selector(CommentCellView.openComment(sender:)))
        
        var uC: UIColor
        switch ActionStates.getVoteDirection(s: comment) {
        case .down:
            uC = ColorUtil.downvoteColor
        case .up:
            uC = ColorUtil.upvoteColor
        default:
            uC = ColorUtil.fontColor
        }
        
        let attrs = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): uC] as [String: Any]
        
        let attrs2 = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor] as [String: Any]
        
        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: comment.created, numericDates: true))  •  ", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs2))
        
        let boldString = NSMutableAttributedString(string: "\(comment.score)pts", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs))
        let subString = NSMutableAttributedString(string: "r/\(comment.subreddit)")
        let color = ColorUtil.getColorForSub(sub: comment.subreddit)
        if color != ColorUtil.baseColor {
            subString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange.init(location: 0, length: subString.length))
        } else {
            subString.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorUtil.fontColor, range: NSRange.init(location: 0, length: subString.length))
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
    
    var comment: RComment?
    public var parentViewController: (UIViewController & MediaVCDelegate)?
    public var navViewController: UIViewController?
    
    @objc func openComment(sender: UITapGestureRecognizer? = nil) {
        VCPresenter.openRedditLink(self.comment!.permalink, parentViewController?.navigationController, parentViewController)
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
