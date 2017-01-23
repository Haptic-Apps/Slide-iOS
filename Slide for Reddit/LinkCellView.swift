//
//  LinkCellViewTableViewCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/26/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

//
//  LinkCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/24/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import UZTextView
import AMScrollingNavbar
import ImageViewer
import TTTAttributedLabel

protocol LinkCellViewDelegate: class {
    func upvote(_ cell: LinkCellView)
    func downvote(_ cell: LinkCellView)
    func save(_ cell: LinkCellView)
    func more(_ cell: LinkCellView)
    func reply(_ cell: LinkCellView)
}

class LinkCellView: UITableViewCell, UIViewControllerPreviewingDelegate, UZTextViewDelegate {
    
    func upvote(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.delegate {
            delegate.upvote(self)
        }
    }
    
    func reply(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.delegate {
            delegate.reply(self)
        }
    }

    func downvote(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.delegate {
            delegate.downvote(self)
        }
    }
    func more(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.delegate {
            delegate.more(self)
        }
    }
    func save(sender: UITapGestureRecognizer? = nil) {
        if let delegate = self.delegate {
            delegate.save(self)
        }
    }
    
    
    var bannerImage = UIImageView()
    var thumbImage = UIImageView()
    var title = TTTAttributedLabel.init(frame: CGRect.zero)
    var score = UILabel()
    var box = UIStackView()
    var buttons = UIStackView()
    var comments = UILabel()
    var textView = UZTextView()
    var save = UIImageView()
    var upvote = UIImageView()
    var reply = UIImageView()
    var downvote = UIImageView()
    var more = UIImageView()
    var delegate: LinkCellViewDelegate? = nil
    
    func textView(_ textView: UZTextView, didLongTapLinkAttribute value: Any?) {
        if let attr = value as? [String: Any]{
            if let url = attr[NSLinkAttributeName] as? URL {
                if parentViewController != nil{
                    let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
                    sheet.addAction(
                        UIAlertAction(title: "Close", style: .cancel) { (action) in
                            sheet.dismiss(animated: true, completion: nil)
                        }
                    )
                    var open = OpenInChromeController.init()
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
                    parentViewController?.present(sheet, animated: true, completion: nil)
                }
            }
        }
    }
    
    func textView(_ textView: UZTextView, didClickLinkAttribute value: Any?) {
        print("Clicked")
        if((parentViewController) != nil){
            if let attr = value as? [String: Any] {
                if let url = attr[NSLinkAttributeName] as? URL {
                    parentViewController?.doShow(url: url)
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
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        let pointForTargetViewmore: CGPoint = more.convert(point, from: self)
        if more.bounds.contains(pointForTargetViewmore) {
            return more
        }
        let pointForTargetViewdownvote: CGPoint = downvote.convert(point, from: self)
        if downvote.bounds.contains(pointForTargetViewdownvote) {
            return downvote
        }
        
        let pointForTargetViewupvote: CGPoint = upvote.convert(point, from: self)
        if upvote.bounds.contains(pointForTargetViewupvote) {
            return upvote
        }
        let pointForTargetViewsave: CGPoint = save.convert(point, from: self)
        if save.bounds.contains(pointForTargetViewsave) {
            return save
        }
        let pointForTargetViewreply: CGPoint = reply.convert(point, from: self)
        if reply.bounds.contains(pointForTargetViewreply) {
            return reply
        }

        
        return super.hitTest(point, with: event)
    }
    
    var content: CellContent?
    var hasText = false
    func showBody(width: CGFloat){
        full = true
        let color = ColorUtil.accentColorForSub(sub: ((link)?.subreddit)!)
        if(link?.selftextHtml != nil){
            let html = link?.selftextHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
            do {
                let attr = try NSMutableAttributedString(data: (html?.data(using: .unicode)!)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: color)
                content = CellContent.init(string:attr2, width:(width - 24 - (thumb ? 75 : 0)))
                textView.attributedString = content?.attributedString
                textView.frame.size.height = (content?.textHeight)!
                hasText = true
            } catch {
            }
            parentViewController?.registerForPreviewing(with: self, sourceView: textView)
        }
    }
    
    var full = false
    var estimatedHeight = CGFloat(0)
    
    func estimateHeight() ->CGFloat {
        if(estimatedHeight == 0){
            title.sizeToFit()
            let he = title.frame.size.height
            estimatedHeight = CGFloat((he < 75 && thumb || he < 75 && !big) ? 75 : he) + CGFloat(56) + CGFloat(!hasText || !full ? 0 : (content?.textHeight)!) +  CGFloat(big && !thumb ? height + 40 : 0)
        }
        return estimatedHeight
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.thumbImage = UIImageView(frame: CGRect(x: 0, y: 8, width: 75, height: 75))
        thumbImage.layer.cornerRadius = 5;
        thumbImage.clipsToBounds = true;
        thumbImage.contentMode = .scaleAspectFill
        
        self.bannerImage = UIImageView(frame: CGRect(x: 0, y: 8, width: CGFloat.greatestFiniteMagnitude, height: 0))
        bannerImage.clipsToBounds = true;
        bannerImage.contentMode = UIViewContentMode.scaleAspectFit
        
        self.title = TTTAttributedLabel(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude));
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = UIFont.systemFont(ofSize: 18, weight: 1.15)
        title.textColor = ColorUtil.fontColor
        
        self.upvote = UIImageView(frame: CGRect(x: 0, y:0, width: 20, height: 20))
        upvote.image = UIImage.init(named: "upvote")?.withRenderingMode(.alwaysTemplate)
        upvote.tintColor = ColorUtil.fontColor
        
        self.reply = UIImageView(frame: CGRect(x: 0, y:0, width: 20, height: 20))
        reply.image = UIImage.init(named: "reply")?.withRenderingMode(.alwaysTemplate)
        reply.tintColor = ColorUtil.fontColor

        self.save = UIImageView(frame: CGRect(x: 0, y:0, width: 20, height: 20))
        save.image = UIImage.init(named: "save")?.withRenderingMode(.alwaysTemplate)
        save.tintColor = ColorUtil.fontColor
        
        self.downvote = UIImageView(frame: CGRect(x: 0, y:0, width: 20, height: 20))
        downvote.image = UIImage.init(named: "downvote")?.withRenderingMode(.alwaysTemplate)
        downvote.tintColor = ColorUtil.fontColor
        
        self.more = UIImageView(frame: CGRect(x: 0, y:0, width: 20, height: 20))
        more.image = UIImage.init(named: "ic_more_vert_white")?.withRenderingMode(.alwaysTemplate)
        more.tintColor = ColorUtil.fontColor
        
        
        self.textView = UZTextView(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        self.textView.delegate = self
        self.textView.isUserInteractionEnabled = true
        self.textView.backgroundColor = .clear
        
        self.score = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        score.numberOfLines = 1
        
        self.comments = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        comments.numberOfLines = 1
        comments.font = UIFont.systemFont(ofSize: 12)
        comments.textColor = ColorUtil.fontColor
        
        self.box = UIStackView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        self.buttons = UIStackView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        
        bannerImage.translatesAutoresizingMaskIntoConstraints = false
        thumbImage.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        score.translatesAutoresizingMaskIntoConstraints = false
        comments.translatesAutoresizingMaskIntoConstraints = false
        box.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        upvote.translatesAutoresizingMaskIntoConstraints = false
        downvote.translatesAutoresizingMaskIntoConstraints = false
        more.translatesAutoresizingMaskIntoConstraints = false
        save.translatesAutoresizingMaskIntoConstraints = false
        reply.translatesAutoresizingMaskIntoConstraints = false
        buttons.translatesAutoresizingMaskIntoConstraints = false
        addTouch(view: save, action: #selector(LinkCellView.save(sender:)))
        addTouch(view: upvote, action: #selector(LinkCellView.upvote(sender:)))
        addTouch(view: reply, action: #selector(LinkCellView.reply(sender:)))
        addTouch(view: downvote, action: #selector(LinkCellView.downvote(sender:)))
        addTouch(view: more, action: #selector(LinkCellView.more(sender:)))
        
        self.contentView.addSubview(bannerImage)
        self.contentView.addSubview(thumbImage)
        self.contentView.addSubview(title)
        self.contentView.addSubview(textView)
        box.addSubview(score)
        box.addSubview(comments)
        buttons.addSubview(reply)
        buttons.addSubview(save)
        buttons.addSubview(upvote)
        buttons.addSubview(downvote)
        buttons.addSubview(more)
        self.contentView.addSubview(box)
        self.contentView.addSubview(buttons)
        
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        self.updateConstraints()
        
        buttons.isUserInteractionEnabled = true
        
    }
    
    func addTouch(view: UIView, action: Selector){
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: action)
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    var thumb = true
    var height:Int = 0
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let metrics=["horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"labelMinHeight":75,  "bannerHeight": height] as [String: Int]
        let views=["label":title, "body": textView, "image": thumbImage, "score": score, "comments": comments, "banner": bannerImage, "box": box] as [String : Any]
        let views2=["buttons":buttons, "upvote": upvote, "downvote": downvote, "reply": reply,"more": more, "save": save] as [String : Any]
        
        box.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[score(>=20)]-8-[comments(>=20)]",
                                                          options: NSLayoutFormatOptions(rawValue: 0),
                                                          metrics: metrics,
                                                          views: views))
        
        box.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[score(20)]-|",
                                                          options: NSLayoutFormatOptions(rawValue: 0),
                                                          metrics: metrics,
                                                          views: views))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[buttons]-12-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: metrics,
                                                                       views: views2))
        
        box.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[comments(20)]-|",
                                                          options: NSLayoutFormatOptions(rawValue: 0),
                                                          metrics: metrics,
                                                          views: views))
        
        if(full){
        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[reply(20)]-8-[save(20)]-8-[upvote(20)]-8-[downvote(20)]-8-[more(20)]-0-|",
                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                              metrics: metrics,
                                                              views: views2))
        } else {
            buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[save(20)]-8-[upvote(20)]-8-[downvote(20)]-8-[more(20)]-0-|",
                                                                  options: NSLayoutFormatOptions(rawValue: 0),
                                                                  metrics: metrics,
                                                                  views: views2))
        }
        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[upvote(20)]-|",
                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                              metrics: metrics,
                                                              views: views2))
        
        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[downvote(20)]-|",
                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                              metrics: metrics,
                                                              views: views2))
        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[save(20)]-|",
                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                              metrics: metrics,
                                                              views: views2))
        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[more(20)]-|",
                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                              metrics: metrics,
                                                              views: views2))
        buttons.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[reply(20)]-|",
                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                              metrics: metrics,
                                                              views: views2))

    }
    
    func getHeightFromAspectRatio(imageHeight:Int, imageWidth: Int) -> Int {
        let ratio = Double(imageHeight)/Double(imageWidth)
        let width = Double(contentView.frame.size.width);
        return Int(width * ratio)
        
    }
    
    var big = false
    var bigConstraint : NSLayoutConstraint?
    var thumbConstraint : [NSLayoutConstraint] = []
    
    func refreshLink(_ submission: Link){
        let attributedTitle = NSMutableAttributedString(string: submission.title, attributes: [NSFontAttributeName: title.font, NSForegroundColorAttributeName: ColorUtil.fontColor])
        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(submission.linkFlairText.isEmpty ? submission.linkFlairCssClass : submission.linkFlairText)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(submission.gilded) ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor])
        
        let locked = NSMutableAttributedString.init(string: "\u{00A0}LOCKED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        
        let archived = NSMutableAttributedString.init(string: "\u{00A0}ARCHIVED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        
        let spacer = NSMutableAttributedString.init(string: "  ")
        if(!(submission.linkFlairText.isEmpty ? submission.linkFlairCssClass : submission.linkFlairText).isEmpty){
            attributedTitle.append(spacer)
            attributedTitle.append(flairTitle)
        }
        
        if(submission.gilded > 0){
            attributedTitle.append(spacer)
            attributedTitle.append(spacer)
            let gild = NSMutableAttributedString.init(string: "G", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
            attributedTitle.append(gild)
            if(submission.gilded > 1){
                attributedTitle.append(gilded)
            }
        }
        
        if(submission.stickied){
            attributedTitle.append(spacer)
            attributedTitle.append(pinned)
        }
        
        if(submission.locked){
            attributedTitle.append(locked)
        }
        if(submission.archived){
            attributedTitle.append(archived)
        }
        
        attributedTitle.append(NSAttributedString.init(string: "\n\n"))
        let attrs = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor] as [String: Any]
        
        let endString = NSMutableAttributedString(string:"  •  \(DateFormatter().timeSince(from: NSDate.init(timeIntervalSince1970: TimeInterval.init(submission.createdUtc)), numericDates: true))\((submission.edited > 0 ? ("(edit \(DateFormatter().timeSince(from: NSDate.init(timeIntervalSince1970: TimeInterval.init(submission.edited)), numericDates: true)))") : ""))  •  \(submission.author)", attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor])
        
        let boldString = NSMutableAttributedString(string:"/r/\(submission.subreddit)", attributes:attrs)
        
        let color = ColorUtil.getColorForSub(sub: submission.subreddit)
        if(color != ColorUtil.baseColor){
            boldString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: boldString.length))
        }
        
        let infoString = NSMutableAttributedString()
        infoString.append(boldString)
        infoString.append(endString)
        attributedTitle.append(infoString)
        
        title.attributedText = attributedTitle
        link = submission
        title.sizeToFit()
        
        let comment = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openComment(sender:)))
        comment.delegate = self
        self.addGestureRecognizer(comment)
        
        
        title.sizeToFit()
        refresh()
        
        let more = History.commentsSince(s: submission)
        let commentText = NSMutableAttributedString(string: " \(submission.numComments)" + (more > 0 ? " (+\(more))" : ""), attributes: [NSFontAttributeName: comments.font, NSForegroundColorAttributeName: comments.textColor])
        
        comments.attributedText = commentText
        comments.addImage(imageName: "comments", afterLabel: false)
        
    }
    
    func setLink(submission: Link, parent: MediaViewController, nav: UIViewController?){
        parentViewController = parent
        full = parent is CommentViewController
        if(navViewController == nil && nav != nil){
            navViewController = nav
        }
        let attributedTitle = NSMutableAttributedString(string: submission.title, attributes: [NSFontAttributeName: title.font, NSForegroundColorAttributeName: ColorUtil.fontColor])
        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(submission.linkFlairText.isEmpty ? submission.linkFlairCssClass : submission.linkFlairText)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(submission.gilded) ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor])
       
        let locked = NSMutableAttributedString.init(string: "\u{00A0}LOCKED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])

        let archived = NSMutableAttributedString.init(string: "\u{00A0}ARCHIVED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])

        let spacer = NSMutableAttributedString.init(string: "  ")
        if(!(submission.linkFlairText.isEmpty ? submission.linkFlairCssClass : submission.linkFlairText).isEmpty){
            attributedTitle.append(spacer)
            attributedTitle.append(flairTitle)
        }
        
        if(submission.gilded > 0){
            attributedTitle.append(spacer)
            let gild = NSMutableAttributedString.init(string: "G", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
            attributedTitle.append(gild)
            if(submission.gilded > 1){
                attributedTitle.append(gilded)
            }
        }
        
        if(submission.stickied){
            attributedTitle.append(spacer)
            attributedTitle.append(pinned)
        }
        
        if(submission.locked){
            attributedTitle.append(locked)
        }
        if(submission.archived){
            attributedTitle.append(archived)
        }
        
        attributedTitle.append(NSAttributedString.init(string: "\n\n"))
        let attrs = [NSFontAttributeName : UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor] as [String: Any]
        
        let endString = NSMutableAttributedString(string:"  •  \(DateFormatter().timeSince(from: NSDate.init(timeIntervalSince1970: TimeInterval.init(submission.createdUtc)), numericDates: true))\((submission.edited > 0 ? ("(edit \(DateFormatter().timeSince(from: NSDate.init(timeIntervalSince1970: TimeInterval.init(submission.edited)), numericDates: true)))") : ""))  •  \(submission.author)", attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor])
        
        let boldString = NSMutableAttributedString(string:"/r/\(submission.subreddit)", attributes:attrs)
        
        let color = ColorUtil.getColorForSub(sub: submission.subreddit)
        if(color != ColorUtil.baseColor){
            boldString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: boldString.length))
        }
        
        let infoString = NSMutableAttributedString()
        infoString.append(boldString)
        infoString.append(endString)
        attributedTitle.append(infoString)
        
        title.attributedText = attributedTitle
        link = submission
        title.sizeToFit()
        reply.isHidden = true
        
        if(submission.archived || !AccountController.isLoggedIn){
            upvote.isHidden = true
            downvote.isHidden = true
            save.isHidden = true
            reply.isHidden = true
        } else {
            upvote.isHidden = false
            downvote.isHidden = false
            save.isHidden = false
            if(full){
                reply.isHidden = false
            }
        }
        
        let type = ContentType.getContentType(submission: submission)
        
        let fullImage = ContentType.fullImage(t: type)
        
        var thumbUsed = false
        var forceThumb = false
        var json: JSONDictionary? = nil
        json = submission.baseJson
        
        let cropImage = false
        //setting eventually
        let noImages = false //setting eventually
        var w: Int = 0
        var h: Int = 0
        thumb = false
        big = false //same as setVisibility(gone)
        let bigPicCropped = false //setting
        let hideSelftextLeadImage = false //setting
        let imgurLq = true //setting
        var url: String = ""
        var loadLq = false //check internet vs settings
        
        var preview  = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["url"] as? String)
        if(bigConstraint != nil){
            self.contentView.removeConstraint(bigConstraint!)
        }
        
        full = false
        
        if (type == ContentType.CType.SELF && hideSelftextLeadImage
            || noImages && submission.isSelf) {
            big = false
            thumb = false
        } else {
            if (preview != nil && !(preview?.isEmpty())!) {
                preview = preview?.replacingOccurrences(of: "&amp;", with: "&")
                w = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["width"] as? Int)!
                h = (((((json?["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["height"] as? Int)!
                if (false) { //reduce height if full, currently broken though
                    if (!fullImage && height<50 && type != ContentType.CType.SELF) {
                        forceThumb = true;
                    } else if (cropImage) {
                        height = 200
                    } else {
                        let h2 = getHeightFromAspectRatio(imageHeight: h, imageWidth: w);
                        if (h2 != 0) {
                            height = h2
                        } else {
                            height = 200
                        }
                    }
                } else if (bigPicCropped) {
                    if (!fullImage && height < 50) {
                        forceThumb = true;
                    } else {
                        height = 200
                    }
                } else if (fullImage || height >= 50) {
                    let h2 = getHeightFromAspectRatio(imageHeight: h, imageWidth: w);
                    if (h2 != 0) {
                        height = h2
                    } else {
                        height = 200
                    }
                } else {
                    forceThumb = true;
                }
                
            }
            
            let thumbnailType = ContentType.getThumbnailType(submission: submission)
            
            if (noImages && loadLq) {
                big = false
                if (!full && !submission.isSelf) {
                    thumb = true
                }
                thumbImage.sd_setImage(with: URL.init(string: submission.thumbnail), placeholderImage: UIImage.init(named: "web"))
                thumbUsed = true;
            } else if (submission.over18
                && thumbnailType == .NSFW) {
                big = false
                if (!full || forceThumb) {
                    thumb = true
                }
                if (submission.isSelf && full) {
                    thumb = false
                } else {
                    thumbImage.sd_setImage(with: URL.init(string: submission.thumbnail), placeholderImage: UIImage.init(named: "nsfw"))
                    thumbUsed = true;
                }
            } else if (type != .IMAGE
                && type != .SELF
                && (!submission.thumbnail.isEmpty() && (thumbnailType != .URL)) || submission.thumbnail.isEmpty() && !submission.isSelf) {
                
                big = false
                if (!full) {
                    thumb = true
                }
                
                thumbImage.sd_setImage(with: URL.init(string: submission.thumbnail), placeholderImage: UIImage.init(named: "web"))
                thumbUsed = true;
            } else if (type == .IMAGE && !submission.thumbnail.isEmpty()) {
                /*todo this && submission.getThumbnails() != null
                 && submission.getThumbnails().getVariations() != null
                 && submission.getThumbnails().getVariations().length > 0*/
                if (loadLq && false) {
                    
                    if (ContentType.isImgurImage(uri: submission.url!)) {
                        url = (submission.url?.absoluteString)!
                        /* do hashurl = url.substring(0, url.lastIndexOf(".")) + (SettingValues.imgurLq ? "m"
                         : "h") + url.substring(url.lastIndexOf("."), url.length());*/
                    } else {
                        /* do this let length = submission.getThumbnails().getVariations().length;
                         url = Html.fromHtml(
                         submission.getThumbnails().getVariations()[length / 2].getUrl())
                         .toString(); //unescape url characters*/
                    }
                    
                } else {
                    if (preview != nil && !(preview?.isEmpty)!) { //Load the preview image which has probably already been cached in memory instead of the direct link
                        url = preview!
                    } else {
                        url = (submission.url?.absoluteString)!
                    }
                }
                
                //todo isPicsEnabled(sub)
                if (!full && false || forceThumb) {
                    
                    if (!submission.isSelf || full) {
                        if (!full) {
                            thumb = true
                        }
                        if (!full) {
                            thumbImage.sd_setImage(with: URL.init(string: submission.thumbnail), placeholderImage: UIImage.init(named: "web"))
                        }
                    } else {
                        thumb = false
                    }
                    big = false
                } else {
                    if (!full) {
                        bannerImage.sd_setImage(with: URL.init(string: url))
                    }
                    big = true
                    if (!full) {
                        thumb = false
                    }
                }
            } else if (preview != nil) {
                //todo submission.getThumbnails().getVariations().length != 0
                if (loadLq && true) {
                    if (ContentType.isImgurImage(uri: submission.url!)) {
                        url = (submission.url?.absoluteString)!
                        url = url.substring(0, length: url.lastIndexOf(".")!) + (imgurLq ? "m"
                            : "h") + url.substring(url.lastIndexOf(".")!, length: url.length - url.lastIndexOf(".")!);
                    } else {
                        /*todo get half preview
                         int length = submission.getThumbnails().getVariations().length;
                         url = Html.fromHtml(
                         submission.getThumbnails().getVariations()[length / 2].getUrl())
                         .toString(); //unescape url characters*/
                        url = preview!
                    }
                } else {
                    url = preview!
                }
                
                //todo is pic enabled
                if (true && !full || forceThumb) {
                    
                    if (!full) {
                        thumb = true
                    }
                    thumbImage.sd_setImage(with: URL.init(string: submission.thumbnail), placeholderImage: UIImage.init(named: "web"))
                    big = false
                    
                } else {
                    if (!full) {
                        bannerImage.sd_setImage(with: URL.init(string: url))
                    }
                    big = true
                    if (!full) {
                        thumb = false
                    }
                }
            } else if (!(thumbnailType == .URL || (thumbnailType != .NSFW))) {
                
                if (!full) {
                    thumb  = true
                }
                thumbImage.sd_setImage(with: URL.init(string: submission.thumbnail), placeholderImage: UIImage.init(named: "web"))
                big = false
            } else {
                thumb = false
                big = false
            }
        }
        if(thumb && type == .SELF){
            thumb = false
        }
        
        full = parent is CommentViewController
        addTouch(view: save, action: #selector(LinkCellView.save(sender:)))
        addTouch(view: upvote, action: #selector(LinkCellView.upvote(sender:)))
        addTouch(view: downvote, action: #selector(LinkCellView.downvote(sender:)))
        addTouch(view: more, action: #selector(LinkCellView.more(sender:)))
        addTouch(view: reply, action: #selector(LinkCellView.reply(sender:)))

        
        if(!thumb){
            thumbImage.sd_setImage(with: URL.init(string: ""))
            self.thumbImage.frame.size.width = 0
        } else {
            addTouch(view: thumbImage, action: #selector(LinkCellView.openLink(sender:)))
        }
        
        if(big){
            let imageSize = CGSize.init(width:w, height:h);
            var aspect = imageSize.width / imageSize.height
            if(aspect == 0 || aspect > 10000 || aspect.isNaN){
                aspect = 1
            }
            bigConstraint = NSLayoutConstraint(item: bannerImage, attribute:  NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: bannerImage, attribute: NSLayoutAttribute.height, multiplier: aspect, constant: 0.0)
            
            bannerImage.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLink(sender:)))
            tap.delegate = self
            bannerImage.addGestureRecognizer(tap)
        } else {
            bannerImage.sd_setImage(with: URL.init(string: ""))
        }
        
        let comment = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openComment(sender:)))
        comment.delegate = self
        self.addGestureRecognizer(comment)
        
        
        title.sizeToFit()
        
        let mo = History.commentsSince(s: submission)
        let commentText = NSMutableAttributedString(string: " \(submission.numComments)" + (mo > 0 ? "(+\(mo))" : ""), attributes: [NSFontAttributeName: comments.font, NSForegroundColorAttributeName: comments.textColor])
        comments.attributedText = commentText
        comments.addImage(imageName: "comments", afterLabel: false)
        
        if(!registered && !full){
            parent.registerForPreviewing(with: self, sourceView: self.contentView)
            registered = true
        }
        
        let metrics=["horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"labelMinHeight":75,  "bannerHeight": height] as [String: Int]
        let views=["label":title, "body": textView, "image": thumbImage, "score": score, "comments": comments, "banner": bannerImage, "buttons":buttons, "box": box] as [String : Any]
        
        if(!thumbConstraint.isEmpty){
            self.contentView.removeConstraints(thumbConstraint)
            thumbConstraint = []
        }
        if(thumb){
            print("thumb")

            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[image(75)]",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[label]-8-[image(75)]-12-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[body]-8-[image(75)]-12-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[label(>=60)]-10-[box]-8-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[buttons]-8-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            
            self.contentView.addConstraints(thumbConstraint)
        } else if(big) {
            print("big")
            
            if(bigConstraint != nil){
                thumbConstraint.append(bigConstraint!)
            }

            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-[image(0)]",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[label]-12-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[body]-12-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-4-[banner]-8@999-[label]-10@999-[box]-8-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[buttons]-8-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[banner]-12-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            
            self.contentView.addConstraints(thumbConstraint)
        } else {
            print("body")
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[image(0)]",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[label]-12-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-12-[body]-12-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[label]-4@1000-[body]-10@1000-[box]-8-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            thumbConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[buttons]-8-|",
                                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                                              metrics: metrics,
                                                                              views: views))
            self.contentView.addConstraints(thumbConstraint)
            
        }
        refresh()
        
    }
    
    func refresh(){
        upvote.tintColor = ColorUtil.fontColor
        save.tintColor = ColorUtil.fontColor
        downvote.tintColor = ColorUtil.fontColor
        var attrs: [String: Any] = [:]
        switch(ActionStates.getVoteDirection(s: link!)){
        case .down :
            downvote.tintColor = ColorUtil.downvoteColor
            attrs = ([NSForegroundColorAttributeName: ColorUtil.downvoteColor!, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12)])
            break
        case .up:
            upvote.tintColor = ColorUtil.upvoteColor
            attrs = ([NSForegroundColorAttributeName: ColorUtil.upvoteColor!, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12)])
            break
        default:
            attrs = ([NSForegroundColorAttributeName: ColorUtil.fontColor, NSFontAttributeName: UIFont.systemFont(ofSize: 12)])
            break
        }
        
        let subScore = NSMutableAttributedString(string: (link!.score>=10000) ? String(format: " %0.1fk", (Double(link!.score)/Double(1000))) : " \(link!.score)", attributes: attrs)

        if(full){
            let scoreRatio =
                NSMutableAttributedString(string: (SettingValues.upvotePercentage && full && link!.upvoteRatio > 0) ?
                    " (\(Int(link!.upvoteRatio * 100))%)" : "", attributes: [NSFontAttributeName: comments.font, NSForegroundColorAttributeName: comments.textColor] )
            
            var attrsNew: [String: Any] = [:]
            if (scoreRatio.length > 0 ) {
                let numb = (link!.upvoteRatio)
                if (numb <= 0.5) {
                    if (numb <= 0.1) {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.blue500Color()]
                    } else if (numb <= 0.3) {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.blue400Color()]
                    } else {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.blue300Color()]
                    }
                } else {
                    if (numb >= 0.9) {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.orange500Color()]
                    } else if (numb >= 0.7) {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.orange400Color()]
                    } else {
                        attrsNew = [NSForegroundColorAttributeName: GMColor.orange300Color()]
                    }
                }
            }
            
            scoreRatio.addAttributes(attrsNew, range: NSRange.init(location: 0, length: scoreRatio.length))
            
            subScore.append(scoreRatio)
        }
        
        score.attributedText = subScore
        score.addImage(imageName: "upvote", afterLabel: false)
        
        if(ActionStates.isSaved(s: link!)){
            save.tintColor = UIColor.flatYellow()
        }
        if(History.getSeen(s: link!) && !full){
            self.contentView.alpha = 0.9
        } else {
            self.contentView.alpha = 1
        }
    }
    
    var registered: Bool = false
    
    var previewActionItems: [UIPreviewActionItem] {
        
        var toReturn: [UIPreviewAction] = []
        
        let likeAction = UIPreviewAction(title: "Share", style: .default) { (action, viewController) -> Void in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [self.link?.url! ?? ""], applicationActivities: nil);
            let currentViewController:UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }
        toReturn.append(likeAction)
        
        let deleteAction = UIPreviewAction(title: "Open in Safari", style: .default) { (action, viewController) -> Void in
            UIApplication.shared.open((self.link?.url!)!, options: [:], completionHandler: nil)
        }
        toReturn.append(deleteAction)
        
        if(AccountController.isLoggedIn){
            
            let upvote = UIPreviewAction(title: "Upvote", style: .default){ (action, viewController) -> Void in
                self.upvote()
            }
            toReturn.append(upvote)
        }
        let comments = UIPreviewAction(title: "Comments", style: .default){ (action, viewController) -> Void in
            self.openComment()
        }
        toReturn.append(comments)
        return toReturn
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        if(full){
            let locationInTextView = textView.convert(location, to: textView)
            
            if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
                previewingContext.sourceRect = textView.convert(rect, from: textView)
                if let controller = parentViewController?.getControllerForUrl(baseUrl: url){
                    return controller
                }
            }
        } else {
            if let controller = parentViewController?.getControllerForUrl(baseUrl: (link?.url)!){
                return controller
            }
        }
        return nil
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
        if(viewControllerToCommit is GalleryViewController){
            parentViewController?.presentImageGallery(viewControllerToCommit as! GalleryViewController)
        } else {
            parentViewController?.show(viewControllerToCommit, sender: parentViewController )
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var link : Link?
    public var parentViewController: MediaViewController?
    public var navViewController: UIViewController?
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    func openLink(sender: UITapGestureRecognizer? = nil){
        (parentViewController)?.setLink(lnk: link!)
    }
    
    func openComment(sender: UITapGestureRecognizer? = nil){
        if(!full){
            if(parentViewController is SubredditLinkViewController){
                (parentViewController as! SubredditLinkViewController).savedIndex = (self.superview?.superview as! UITableView).indexPath(for: self)!
            }
            let comment = CommentViewController(submission: link!)
            (self.navViewController as? UINavigationController)?.pushViewController(comment, animated: true)
        }
    }
    
    public static var imageDictionary: NSMutableDictionary = NSMutableDictionary.init()
    
}
extension UILabel
{
    func addImage(imageName: String, afterLabel bolAfterLabel: Bool = false)
    {
        let attachment: NSTextAttachment = textAttachment(fontSize: self.font.pointSize, imageName: imageName)
        let attachmentString: NSAttributedString = NSAttributedString(attachment: attachment)
        
        if (bolAfterLabel)
        {
            let strLabelText: NSMutableAttributedString = NSMutableAttributedString.init(attributedString: self.attributedText!)
            strLabelText.append(attachmentString)
            
            self.attributedText = strLabelText
        }
        else
        {
            let strLabelText: NSMutableAttributedString = NSMutableAttributedString.init(attributedString: self.attributedText!)
            let mutableAttachmentString: NSMutableAttributedString = NSMutableAttributedString(attributedString: attachmentString)
            mutableAttachmentString.append(strLabelText)
            
            self.attributedText = mutableAttachmentString
        }
        self.baselineAdjustment = .alignCenters
    }
    func textAttachment(fontSize: CGFloat, imageName: String) -> NSTextAttachment {
        let font = UIFont.systemFont(ofSize: fontSize) //set accordingly to your font, you might pass it in the function
        let textAttachment = NSTextAttachment()
        let image = LinkCellView.imageDictionary.object(forKey: imageName)
        if(image != nil){
            textAttachment.image = image as? UIImage
        } else {
            let img = UIImage(named: imageName)?.withColor(tintColor: ColorUtil.fontColor).imageResize(sizeChange: CGSize.init(width: self.font.pointSize, height: self.font.pointSize))
            textAttachment.image = img
            LinkCellView.imageDictionary.setObject(img!, forKey: imageName as NSCopying)
        }
        let mid = font.descender + font.capHeight
        textAttachment.bounds = CGRect(x: 0, y: font.descender - fontSize / 2 + mid + 2, width: fontSize, height: fontSize).integral
        return textAttachment
    }
    func removeImage()
    {
        let text = self.text
        self.attributedText = nil
        self.text = text
    }
    
    
}
extension UIImage {
    func withColor(tintColor: UIColor) -> UIImage {
        var image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        tintColor.set()
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
