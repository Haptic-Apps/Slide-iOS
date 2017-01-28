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
        let link = self.link!
        let color = ColorUtil.accentColorForSub(sub: ((link).subreddit))
        if(!link.htmlBody.isEmpty){
            let html = link.htmlBody
            do {
                let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                let font = FontGenerator.fontOfSize(size: 16, submission: false)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: color)
                content = CellContent.init(string:LinkParser.parse(attr2), width:(width - 24 - (thumb ? 75 : 0)))
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
            print("Height is \(height)")
            estimatedHeight = CGFloat((he < 75 && thumb || he < 75 && !big) ? 75 : he) + CGFloat(56) + CGFloat(!hasText || !full ? 0 : (content?.textHeight)!) +  CGFloat(big && !thumb ? height + 20 : 0)
            print("Est height is \(estimatedHeight)")
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
        bannerImage.clipsToBounds = true
        bannerImage.contentMode = UIViewContentMode.scaleAspectFill
        
        self.title = TTTAttributedLabel(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude));
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = FontGenerator.fontOfSize(size: 18, submission: true)
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
        comments.font = FontGenerator.fontOfSize(size: 12, submission: true)
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
    
    func refreshLink(_ submission: RSubmission){
        self.link = submission
        let attributedTitle = NSMutableAttributedString(string: submission.title, attributes: [NSFontAttributeName: title.font, NSForegroundColorAttributeName: ColorUtil.fontColor])
        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(submission.flair)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(submission.gilded) ", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: ColorUtil.fontColor])
        
        let locked = NSMutableAttributedString.init(string: "\u{00A0}LOCKED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        
        let archived = NSMutableAttributedString.init(string: "\u{00A0}ARCHIVED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        
        let spacer = NSMutableAttributedString.init(string: "  ")
        if(!submission.flair.isEmpty){
            attributedTitle.append(spacer)
            attributedTitle.append(flairTitle)
        }
        
        if(submission.gilded > 0){
            attributedTitle.append(spacer)
            attributedTitle.append(spacer)
            let gild = NSMutableAttributedString.init(string: "G", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
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
        let attrs = [NSFontAttributeName : FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: ColorUtil.fontColor] as [String: Any]
        
        let endString = NSMutableAttributedString(string:"  •  \(DateFormatter().timeSince(from: submission.created, numericDates: true))\((submission.isEdited ? ("(edit \(DateFormatter().timeSince(from: submission.edited, numericDates: true))))") : ""))  •  \(submission.author)", attributes: [NSFontAttributeName : FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: ColorUtil.fontColor])
        
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
        title.sizeToFit()
        
        let comment = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openComment(sender:)))
        comment.delegate = self
        self.addGestureRecognizer(comment)
        
        
        title.sizeToFit()
        refresh()
        
        let more = History.commentsSince(s: submission)
        let commentText = NSMutableAttributedString(string: " \(submission.commentCount)" + (more > 0 ? " (+\(more))" : ""), attributes: [NSFontAttributeName: comments.font, NSForegroundColorAttributeName: comments.textColor])
        
        comments.attributedText = commentText
        comments.addImage(imageName: "comments", afterLabel: false)
        
    }
    
    
    
    var link: RSubmission?
    
    func setLink(submission: RSubmission, parent: MediaViewController, nav: UIViewController?){
        parentViewController = parent
        full = parent is CommentViewController
        self.link = submission
        if(navViewController == nil && nav != nil){
            navViewController = nav
        }
        let attributedTitle = NSMutableAttributedString(string: submission.title, attributes: [NSFontAttributeName: title.font, NSForegroundColorAttributeName: ColorUtil.fontColor])
        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(submission.flair)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(submission.gilded) ", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: ColorUtil.fontColor])
       
        let locked = NSMutableAttributedString.init(string: "\u{00A0}LOCKED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])

        let archived = NSMutableAttributedString.init(string: "\u{00A0}ARCHIVED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])

        let spacer = NSMutableAttributedString.init(string: "  ")
        if(!submission.flair.isEmpty){
            attributedTitle.append(spacer)
            attributedTitle.append(flairTitle)
        }
        
        if(submission.gilded > 0){
            attributedTitle.append(spacer)
            let gild = NSMutableAttributedString.init(string: "G", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
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
        let attrs = [NSFontAttributeName : FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: ColorUtil.fontColor] as [String: Any]
        
        let endString = NSMutableAttributedString(string:"  •  \(DateFormatter().timeSince(from: submission.created, numericDates: true))\((submission.isEdited ? ("(edit \(DateFormatter().timeSince(from: submission.edited, numericDates: true))))") : ""))  •  \(submission.author)", attributes: [NSFontAttributeName : FontGenerator.fontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: ColorUtil.fontColor])
        
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
        
                
        full = parent is CommentViewController
        addTouch(view: save, action: #selector(LinkCellView.save(sender:)))
        addTouch(view: upvote, action: #selector(LinkCellView.upvote(sender:)))
        addTouch(view: downvote, action: #selector(LinkCellView.downvote(sender:)))
        addTouch(view: more, action: #selector(LinkCellView.more(sender:)))
        addTouch(view: reply, action: #selector(LinkCellView.reply(sender:)))
        thumb = submission.thumbnail
        big = submission.banner
        //todo test if big image
        //todo test if self and hideSelftextLeadImage, don't show anything
        //test if should be LQ, get LQ image instead of banner image
        if(bigConstraint != nil){
            self.contentView.removeConstraint(bigConstraint!)
        }
        
        height = submission.height
        let type = ContentType.getContentType(baseUrl: submission.url!)

        
        if(thumb && type == .SELF){
            thumb = false
        }
        
        let fullImage = ContentType.fullImage(t: type)
        
        if(!fullImage && height < 50){
            big = false
            thumb = true
        } else if(big && (SettingValues.bigPicCropped /*|| full*/)){
            height = 200
        } else if(big){
            let h = getHeightFromAspectRatio(imageHeight: height, imageWidth: submission.width)
            if(h == 0){
                height = 200
            } else {
                height  = h
            }
        }
        
        if(type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big){
            big = false
            thumb = false
        }
        
        if(height < 50){
            thumb = true
            big = false
        }
        
        let shouldShowLq = SettingValues.lqEnabled && false && submission.lQ //eventually check for network connection type
        if (type == ContentType.CType.SELF && SettingValues.hideImageSelftext
            || SettingValues.noImages && submission.isSelf) {
            big = false
            thumb = false
        }
        
        print("Big is \(big) and height is \(height)")
        
        if(big || !submission.thumbnail){
            thumb = false
        }
        
        if(thumb && !big){
            addTouch(view: thumbImage, action: #selector(LinkCellView.openLink(sender:)))
            if(submission.thumbnailUrl == "nsfw"){
                thumbImage.image = UIImage.init(named: "nsfw")
            } else if(submission.thumbnailUrl == "link"){
                thumbImage.image = UIImage.init(named: "link")
            } else {
                thumbImage.sd_setImage(with: URL.init(string: submission.thumbnailUrl))
            }
        } else {
            thumbImage.sd_setImage(with: URL.init(string: ""))
            self.thumbImage.frame.size.width = 0
        }
        

        if(big){
            let imageSize = CGSize.init(width:submission.width, height:submission.height);
            var aspect = imageSize.width / imageSize.height
            if(aspect == 0 || aspect > 10000 || aspect.isNaN){
                aspect = 1
            }
            print("Aspect is \(aspect)")
            bigConstraint = NSLayoutConstraint(item: bannerImage, attribute:  NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: bannerImage, attribute: NSLayoutAttribute.height, multiplier: aspect, constant: 0.0)
            bannerImage.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openLink(sender:)))
            tap.delegate = self
            bannerImage.addGestureRecognizer(tap)
            if(shouldShowLq){
                bannerImage.sd_setImage(with: URL.init(string: submission.lqUrl))
            } else {
            bannerImage.sd_setImage(with: URL.init(string: submission.bannerUrl))
            }
        } else {
            bannerImage.sd_setImage(with: URL.init(string: ""))
        }
        
        let comment = UITapGestureRecognizer(target: self, action: #selector(LinkCellView.openComment(sender:)))
        comment.delegate = self
        self.addGestureRecognizer(comment)
        
        
        title.sizeToFit()
        
        let mo = History.commentsSince(s: submission)
        let commentText = NSMutableAttributedString(string: " \(submission.commentCount)" + (mo > 0 ? "(+\(mo))" : ""), attributes: [NSFontAttributeName: comments.font, NSForegroundColorAttributeName: comments.textColor])
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
        if(thumb && !big){
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
        let link = self.link!
        upvote.tintColor = ColorUtil.fontColor
        save.tintColor = ColorUtil.fontColor
        downvote.tintColor = ColorUtil.fontColor
        var attrs: [String: Any] = [:]
        switch(ActionStates.getVoteDirection(s: link)){
        case .down :
            downvote.tintColor = ColorUtil.downvoteColor
            attrs = ([NSForegroundColorAttributeName: ColorUtil.downvoteColor!, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true)])
            break
        case .up:
            upvote.tintColor = ColorUtil.upvoteColor
            attrs = ([NSForegroundColorAttributeName: ColorUtil.upvoteColor!, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true)])
            break
        default:
            attrs = ([NSForegroundColorAttributeName: ColorUtil.fontColor, NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true)])
            break
        }
        
        let subScore = NSMutableAttributedString(string: (link.score>=10000) ? String(format: " %0.1fk", (Double(link.score)/Double(1000))) : " \(link.score)", attributes: attrs)

        if(full){
            let scoreRatio =
                NSMutableAttributedString(string: (SettingValues.upvotePercentage && full && link.upvoteRatio > 0) ?
                    " (\(Int(link.upvoteRatio * 100))%)" : "", attributes: [NSFontAttributeName: comments.font, NSForegroundColorAttributeName: comments.textColor] )
            
            var attrsNew: [String: Any] = [:]
            if (scoreRatio.length > 0 ) {
                let numb = (link.upvoteRatio)
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
        
        if(ActionStates.isSaved(s: link)){
            save.tintColor = UIColor.flatYellow()
        }
        if(History.getSeen(s: link) && !full){
            self.contentView.alpha = 0.9
        } else {
            self.contentView.alpha = 1
        }
    }
    
    var registered: Bool = false
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
        let font = FontGenerator.fontOfSize(size: fontSize, submission: true) //set accordingly to your font, you might pass it in the function
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
