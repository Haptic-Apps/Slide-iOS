//
//  UZTextViewCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/31/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import UZTextView
import ImageViewer
import TTTAttributedLabel

protocol UZTextViewCellDelegate: class {
    func pushedMoreButton(_ cell: CommentDepthCell)
    func pushedSingleTap(_ cell: CommentDepthCell)
}

class CommentDepthCell: UITableViewCell, UZTextViewDelegate, UIViewControllerPreviewingDelegate {
    var textView: UZTextView = UZTextView()
    var moreButton: UIButton = UIButton()
    var sideView: UIView = UIView()
    var sideViewSpace: UIView = UIView()
    var rightSideViewSpace: UIView = UIView()
    var topViewSpace: UIView = UIView()
    var title: TTTAttributedLabel = TTTAttributedLabel.init(frame: CGRect.zero)
    var c: UIView = UIView()
    var children: UILabel = UILabel()
    var menu: UIView = UIView()
    var comment:Comment?
    var depth:Int = 0
    
    func textView(_ textView: UZTextView, didLongTapLinkAttribute value: Any?) {
        if let attr = value as? [String: Any]{
            if let url = attr[NSLinkAttributeName] as? URL {
                if parent != nil{
                    let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
                    sheet.addAction(
                        UIAlertAction(title: "Close", style: .cancel) { (action) in
                            sheet.dismiss(animated: true, completion: nil)
                        }
                    )
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
    }
    
    var parent: MediaViewController?
    
    func textView(_ textView: UZTextView, didClickLinkAttribute value: Any?) {
        if((parent) != nil){
            if let attr = value as? [String: Any] {
                if let url = attr[NSLinkAttributeName] as? URL {
                    parent?.doShow(url: url)
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
    
    func upvote(){
        
    }
    
    var delegate: UZTextViewCellDelegate? = nil
    var content: Thing? = nil
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.textView = UZTextView(frame: CGRect(x: 75, y: 8, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        self.textView.delegate = self
        self.textView.isUserInteractionEnabled = true
        self.textView.backgroundColor = .clear
        
        self.title = TTTAttributedLabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        title.numberOfLines = 0
        title.font = UIFont.systemFont(ofSize: 12)
        title.textColor = ColorUtil.fontColor
        
        self.children = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 15))
        children.numberOfLines = 1
        children.font = UIFont.boldSystemFont(ofSize: 12)
        children.textColor = UIColor.white
        children.layer.shadowOffset = CGSize(width: 0, height: 0)
        children.layer.shadowOpacity = 0.4
        children.layer.shadowRadius = 4
        let padding = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        
        
        
        self.moreButton = UIButton(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        self.menu = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 0))
        
        self.sideView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        self.sideViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        self.topViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 4))
        self.rightSideViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        
        self.c = children.withPadding(padding: padding)
        c.alpha = 0
        c.backgroundColor = ColorUtil.accentColorForSub(sub: "")
        c.layer.cornerRadius = 4
        c.clipsToBounds = true
        
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        sideView.translatesAutoresizingMaskIntoConstraints = false
        sideViewSpace.translatesAutoresizingMaskIntoConstraints = false
        topViewSpace.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        menu.translatesAutoresizingMaskIntoConstraints = false
        children.translatesAutoresizingMaskIntoConstraints = false
        c.translatesAutoresizingMaskIntoConstraints = false
        rightSideViewSpace.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(textView)
        self.contentView.addSubview(moreButton)
        self.contentView.addSubview(sideView)
        self.contentView.addSubview(sideViewSpace)
        self.contentView.addSubview(topViewSpace)
        self.contentView.addSubview(title)
        self.contentView.addSubview(menu)
        self.contentView.addSubview(c)
        self.contentView.addSubview(rightSideViewSpace)
        
        moreButton.addTarget(self, action: #selector(CommentDepthCell.pushedMoreButton(_:)), for: UIControlEvents.touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.pushedSingleTap(_:)))
        tap.cancelsTouchesInView = false
        self.contentView.addGestureRecognizer(tap)
        
        self.contentView.isUserInteractionEnabled = true
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        sideViewSpace.backgroundColor = ColorUtil.backgroundColor
        topViewSpace.backgroundColor = ColorUtil.backgroundColor
        
        self.clipsToBounds = true
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var sideConstraint: [NSLayoutConstraint]?
    
    func collapse(childNumber: Int){
        children.text = "+\(childNumber)"
        UIView.animate(withDuration: 0.4, delay: 0.0, options:
            UIViewAnimationOptions.curveEaseOut, animations: {
                self.c.alpha = 1
        }, completion: { finished in
        })
        
    }
    
    func expand(){
        UIView.animate(withDuration: 0.4, delay: 0.0, options:
            UIViewAnimationOptions.curveEaseOut, animations: {
                self.c.alpha = 0
        }, completion: { finished in
        })
        
    }
    
    func updateDepthConstraints(){
        if(sideConstraint != nil){
            self.contentView.removeConstraints(sideConstraint!)
        }
        let metrics=["topMargin": topMargin, "ntopMargin": -topMargin, "horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"labelMinHeight":75, "sidewidth":4*(depth ), "width":sideWidth]
        let views=["text":textView, "title": title, "right": rightSideViewSpace, "menu":menu, "topviewspace":topViewSpace, "more": moreButton, "side":sideView, "cell":self.contentView, "sideviewspace":sideViewSpace] as [String : Any]
        
        
        sideConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-8)-[sideviewspace(sidewidth)]-0-[side(width)]",
                                                        options: NSLayoutFormatOptions(rawValue: 0),
                                                        metrics: metrics,
                                                        views: views)
        sideConstraint!.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-8)-[sideviewspace(sidewidth)]-0-[side(width)]-8-[title]-2-[right(4)]-0-|",
                                                                          options: NSLayoutFormatOptions(rawValue: 0),
                                                                          metrics: metrics,
                                                                          views: views))
        self.contentView.addConstraints(sideConstraint!)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let metrics=["topMargin": topMargin, "ntopMargin": -topMargin, "horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"labelMinHeight":75, "sidewidth":4*(depth ), "width":sideWidth]
        let views=["text":textView, "title": title, "children":c, "right": rightSideViewSpace, "menu":menu, "topviewspace":topViewSpace, "more": moreButton, "side":sideView, "cell":self.contentView, "sideviewspace":sideViewSpace] as [String : Any]
        
        
        
        contentView.bounds = CGRect.init(x: 0,y: 0, width: contentView.frame.size.width , height: contentView.frame.size.height + CGFloat(topMargin))
        
        var constraint:[NSLayoutConstraint] = []
        constraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-8)-[sideviewspace]-0-[side]-10-[text]-2-[right(4)]-0-|",
                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                    metrics: metrics,
                                                    views: views)
        
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-8)-[sideviewspace]-0-[side]-8-[title]-2-[right(4)]-0-|",
                                                                     options: NSLayoutFormatOptions(rawValue: 0),
                                                                     metrics: metrics,
                                                                     views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[topviewspace]-0-|",
                                                                     options: NSLayoutFormatOptions(rawValue: 0),
                                                                     metrics: metrics,
                                                                     views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[menu]-0-|",
                                                                     options: NSLayoutFormatOptions(rawValue: 0),
                                                                     metrics: metrics,
                                                                     views: views))
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topviewspace(topMargin)]-2-[title]-4-[text]-2-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-2-[more]-2-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-4-[children]",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "H:[children]-4-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topviewspace(topMargin)]-(ntopMargin)-[side]-(-1)-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topviewspace(topMargin)]-(ntopMargin)-[sideviewspace]-0-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        constraint.append(contentsOf:NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[right]-0-|",
                                                                    options: NSLayoutFormatOptions(rawValue: 0),
                                                                    metrics: metrics,
                                                                    views: views))
        
        
        self.contentView.addConstraints(constraint)
        updateDepthConstraints()
        
        
    }
    var sideWidth: Int = 0
    var topMargin: Int = 0
    
    func setMore(more: More, depth: Int){
        self.depth = depth
        c.alpha = 0
        rightSideViewSpace.backgroundColor = ColorUtil.foregroundColor
        if (depth - 1 > 0) {
            sideWidth = 4
            topMargin = 1
            let i22 = depth - 2;
            if (i22 % 5 == 0) {
                sideView.backgroundColor = UIColor.flatBlue()
            } else if (i22 % 4 == 0) {
                sideView.backgroundColor = UIColor.flatGreen()
            } else if (i22 % 3 == 0) {
                sideView.backgroundColor = UIColor.flatYellow()
            } else if (i22 % 2 == 0) {
                sideView.backgroundColor = UIColor.flatOrange()
            } else {
                sideView.backgroundColor = UIColor.flatRed()
            }
        } else {
            topMargin = 8
            sideWidth = 0
        }
        
        title.text = ""
        let attr = NSMutableAttributedString(string: "Load \(more.count) more")
        let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
        let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: .white)
        textView.attributedString = attr2
        updateDepthConstraints()
    }
    
    func more(){
        let alertController = UIAlertController(title: "Comment by /u/\(comment?.author)", message: "", preferredStyle: .actionSheet)
        
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        
        alertController.addAction(cancelActionButton)
        
        let profile: UIAlertAction = UIAlertAction(title: "/u/\(comment!.author)'s profile", style: .default) { action -> Void in
            self.parent!.show(ProfileViewController.init(name: self.comment!.author), sender: self.parent!)
        }
        
        alertController.addAction(profile)
        if(AccountController.isLoggedIn){
            
            let save: UIAlertAction = UIAlertAction(title: "Save", style: .default) { action -> Void in
                //todo save
            }
            
            alertController.addAction(save)
        }
        
        let report: UIAlertAction = UIAlertAction(title: "Report", style: .default) { action -> Void in
            //todo report
        }
        
        alertController.addAction(report)
        
        
        parent?.present(alertController, animated: true, completion: nil)
    }
    func setComment(comment: Comment, depth: Int, parent: MediaViewController, hiddenCount: Int, date: Double, author: String?){
        self.comment = comment
        if(self.parent == nil){
            self.parent = parent
        }
        if(date != 0 && date < Double(comment.createdUtc)){
            self.rightSideViewSpace.backgroundColor = ColorUtil.getColorForSub(sub: comment.subreddit)
        } else {
            self.rightSideViewSpace.backgroundColor = ColorUtil.foregroundColor
        }
        
        if(hiddenCount > 0){
            c.alpha = 1
            children.text = "+\(hiddenCount)"
        } else {
            c.alpha = 0
        }
        
        self.depth = depth
        if (depth - 1 > 0) {
            sideWidth = 4
            topMargin = 1
            let i22 = depth - 2;
            if (i22 % 5 == 0) {
                sideView.backgroundColor = UIColor.flatBlue()
            } else if (i22 % 4 == 0) {
                sideView.backgroundColor = UIColor.flatGreen()
            } else if (i22 % 3 == 0) {
                sideView.backgroundColor = UIColor.flatYellow()
            } else if (i22 % 2 == 0) {
                sideView.backgroundColor = UIColor.flatOrange()
            } else {
                sideView.backgroundColor = UIColor.flatRed()
            }
        } else {
            //topMargin = 8
            topMargin = 1
            sideWidth = 0
        }
        
        refresh(comment: comment, submissionAuthor: author)
        
        if(!registered){
            parent.registerForPreviewing(with: self, sourceView: textView)
            registered = true
        }
        updateDepthConstraints()
        
    }
    
    func refresh(comment: Comment, submissionAuthor: String?){
        var color: UIColor
        
        switch(ActionStates.getVoteDirection(s: comment)){
        case .down:
            color = ColorUtil.downvoteColor!
            break
        case .up:
            color = ColorUtil.upvoteColor!
            break
        default:
            color = ColorUtil.fontColor
            break
        }
        
        
        let scoreString = NSMutableAttributedString(string: (comment.scoreHidden ? "[score hidden]" : "\(getScoreText(comment: comment))"), attributes: [NSForegroundColorAttributeName: color])
        
        let endString = NSMutableAttributedString(string:"  •  \(DateFormatter().timeSince(from: NSDate.init(timeIntervalSince1970: TimeInterval.init(comment.createdUtc)), numericDates: true))",  attributes: [NSForegroundColorAttributeName: ColorUtil.fontColor])
        
        
        let authorString = NSMutableAttributedString(string: "\u{00A0}\(comment.author)\u{00A0}", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor])
        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(comment.authorFlairText.isEmpty ? comment.authorFlairCssClass : comment.authorFlairText)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(comment.gilded) ", attributes: [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12)])
        
        let spacer = NSMutableAttributedString.init(string: "  ")
        var userColor = ColorUtil.getColorForUser(name: comment.author)
        if (comment.distinguished == "admin") {
            
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#E57373"), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (comment.distinguished == "special") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#F44336"), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (comment.distinguished == "moderator") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#81C784"), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (AccountController.currentName == comment.author) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if(submissionAuthor != nil && comment.author == submissionAuthor) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#64B5F6"), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (false ) { //user colors
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#64B5F6"), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 12), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        }
        
        let infoString = NSMutableAttributedString(string: "\u{00A0}")
        infoString.append(authorString)
        infoString.append(NSAttributedString(string:"  •  ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12), NSForegroundColorAttributeName: ColorUtil.fontColor]))
        infoString.append(scoreString)
        infoString.append(endString)
        
        if(!(comment.authorFlairText.isEmpty ? comment.authorFlairCssClass : comment.authorFlairText).isEmpty){
            infoString.append(spacer)
            infoString.append(flairTitle)
        }
        
        if(comment.stickied){
            infoString.append(spacer)
            infoString.append(pinned)
        }
        if(comment.gilded > 0){
            infoString.append(spacer)
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "gold")?.imageResize(sizeChange: CGSize.init(width: 15, height: 15))
            let attachmentString = NSAttributedString(attachment: attachment)
            infoString.append(attachmentString)
            if(comment.gilded > 1){
                infoString.append(gilded)
            }
        }
        

        
        title.attributedText = infoString
    }
    
    func setIsContext(){
        rightSideViewSpace.backgroundColor = GMColor.yellow500Color()
    }
    
    func getScoreText(comment: Comment) -> Int {
        var submissionScore = comment.score
        switch (ActionStates.getVoteDirection(s: comment)) {
        case .up:
            if(comment.likes != .up){
                if(comment.likes == .down){
                    submissionScore += 1
                }
                submissionScore += 1
            }
            break
        case .down:
            if(comment.likes != .down){
                if(comment.likes == .up){
                    submissionScore -= 1
                }
                submissionScore -= 1
            }
            break
        case .none:
            if(comment.likes == .up && comment.author == AccountController.currentName){
                submissionScore -= 1
            }
        }
        return submissionScore
    }
    
    var registered:Bool = false
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let locationInTextView = textView.convert(location, to: textView)
        
        if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
            previewingContext.sourceRect = textView.convert(rect, from: textView)
            if let controller = parent?.getControllerForUrl(url: url){
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
            parent?.presentImageGallery(viewControllerToCommit as! GalleryViewController)
        } else {
        parent?.show(viewControllerToCommit, sender: parent )
        }
    }
    
    var menuShowing: Bool = false
    
    func showMenu(){
        menuShowing = true
        let color = ColorUtil.getColorForSub(sub: (comment?.subreddit)!)
        let colorNew = color.withAlphaComponent(0.5)
        self.contentView.backgroundColor = colorNew
        self.contentView.layoutIfNeeded() // force any pending operations to finish
        
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.menu.frame.size.height = 50
            self.menu.layoutIfNeeded()
        })
        menu.backgroundColor = color
        contentView.addSubview(menu)
    }
    
    func pushedMoreButton(_ sender: AnyObject?) {
        if let delegate = self.delegate {
            delegate.pushedMoreButton(self)
        }
    }
    
    func longPressed(_ sender: AnyObject?) {
        if let delegate = self.delegate {
        }
    }
    
    func pushedSingleTap(_ sender: AnyObject?) {
        if let delegate = self.delegate {
            delegate.pushedSingleTap(self)
        }
    }
    
    class func margin() -> UIEdgeInsets {
        return UIEdgeInsetsMake(5, 0, 25, 0)
    }
    
}
extension UIView {
    func withPadding(padding: UIEdgeInsets) -> UIView {
        let container = UIView()
        self.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self)
        container.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "|-(\(padding.left))-[view]-(\(padding.right))-|"
            , options: [], metrics: nil, views: ["view": self]))
        container.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-(\(padding.top))-[view]-(\(padding.bottom))-|",
            options: [], metrics: nil, views: ["view": self]))
        return container
    }
}
