//
//  CommentCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/7/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//


import UIKit
import reddift
import TTTAttributedLabel

class CommentCellView: UICollectionViewCell, UIGestureRecognizerDelegate, TTTAttributedLabelDelegate {
    
    var title = UILabel()
    var textView = TTTAttributedLabel.init(frame: CGRect.zero)
    var info = UILabel()
    var single = false

    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        parentViewController?.doShow(url: url)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var topmargin = 0
        var bottommargin = 2
        var leftmargin = 0
        var rightmargin = 0
        
        let f = self.contentView.frame
        let fr = UIEdgeInsetsInsetRect(f, UIEdgeInsetsMake(CGFloat(topmargin), CGFloat(leftmargin), CGFloat(bottommargin), CGFloat(rightmargin)))
        self.contentView.frame = fr
    }

    var content: NSAttributedString?
    var hasText = false
    
    var full = false
    var estimatedHeight = CGFloat(0)
    
    func estimateHeight() ->CGFloat {
        if(estimatedHeight == 0){
            let framesetterB = CTFramesetterCreateWithAttributedString(content!)
            let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: width - 16, height: CGFloat.greatestFiniteMagnitude), nil)

            estimatedHeight =  CGFloat(24) + CGFloat(!hasText ? 0 : textSizeB.height)
        }
        return estimatedHeight
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)

        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude));
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = FontGenerator.fontOfSize(size: 18, submission: false)

        title.textColor = ColorUtil.fontColor
        
        self.textView = TTTAttributedLabel(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        self.textView.delegate = self
        self.textView.isUserInteractionEnabled = true
        self.textView.numberOfLines = 0
        self.textView.backgroundColor = .clear
        
        self.info = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude));
        info.numberOfLines = 0
        info.font = FontGenerator.fontOfSize(size: 12, submission: false)
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
    
    override func updateConstraints() {
        super.updateConstraints()
        
        let metrics=["horizontalMargin":75,"top":0,"bottom":0,"separationBetweenLabels":0,"labelMinHeight":75]
        let views=["label":title, "body": textView, "info": info] as [String : Any]
        
        
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[label]-8-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: metrics,
                                                                       views: views))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[body]-8-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: metrics,
                                                                       views: views))
        
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[info]-8-|",
                                                                       options: NSLayoutFormatOptions(rawValue: 0),
                                                                       metrics: metrics,
                                                                       views: views))
        
        if(!lsC.isEmpty){
            self.contentView.removeConstraints(lsC)
        }

        lsC = []
        lsC.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[label]-4-[info]-4-[body]-8-|",
                                                              options: NSLayoutFormatOptions(rawValue: 0),
                                                              metrics: metrics,
                                                              views: views))
        self.contentView.addConstraints(lsC)

        
    }
    
    var lsC: [NSLayoutConstraint] = []
    
    func setComment(comment: RComment, parent: MediaViewController, nav: UIViewController?, width: CGFloat){
        parentViewController = parent
        if(navViewController == nil && nav != nil){
            navViewController = nav
        }
        title.text = comment.submissionTitle
        self.comment = comment
        title.sizeToFit()
       
        
        let commentClick = UITapGestureRecognizer(target: self, action: #selector(CommentCellView.openComment(sender:)))
        commentClick.delegate = self
        self.addGestureRecognizer(commentClick)
        
        
        title.sizeToFit()
        
        var uC : UIColor
        switch(ActionStates.getVoteDirection(s: comment)){
        case .down:
            uC = ColorUtil.downvoteColor
            break
        case .up:
            uC = ColorUtil.upvoteColor
            break
        default:
            uC = ColorUtil.fontColor
            break
        }
        
        let attrs = [NSFontAttributeName : FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: uC] as [String : Any]
        let endString = NSMutableAttributedString(string:"  •  \(DateFormatter().timeSince(from: comment.created, numericDates: true))  •  ")
        
        let boldString = NSMutableAttributedString(string: "\(comment.score)pts", attributes:attrs)
        let subString = NSMutableAttributedString(string: "r/\(comment.subreddit)")
        let color = ColorUtil.getColorForSub(sub: comment.subreddit)
        if(color != ColorUtil.baseColor){
            subString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: subString.length))
        }
        
        let infoString = NSMutableAttributedString()
        infoString.append(boldString)
        infoString.append(endString)
        infoString.append(subString)

        info.attributedText = infoString
        
        let accent = ColorUtil.accentColorForSub(sub: ((comment).subreddit))
        if(!comment.body.isEmpty()){
            var html = comment.htmlText
            do {
                html = WrapSpoilers.addSpoilers(html)
                html = WrapSpoilers.addTables(html)
                let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                let font = FontGenerator.fontOfSize(size: 16, submission: false)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: accent)
                content = LinkParser.parse(attr2, accent)
                textView.setText(content)
                let framesetterB = CTFramesetterCreateWithAttributedString(content!)
                let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: width - 16, height: CGFloat.greatestFiniteMagnitude), nil)
                textView.frame.size.height = textSizeB.height
                hasText = true
            } catch {
            }
        }
    }
    
    var registered: Bool = false
    var currentLink: URL?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var comment : RComment?
    public var parentViewController: UIViewController & MediaVCDelegate?
    public var navViewController: UIViewController?
    
    
    
    func openComment(sender: UITapGestureRecognizer? = nil){
        let comment = CommentViewController.init(submission: (self.comment?.linkid.substring(3, length: (self.comment?.linkid.length)! - 3))! , comment: self.comment!.id, context: 3, subreddit: (self.comment?.subreddit)!)
        VCPresenter.showVC(viewController: comment, popupIfPossible: true, parentNavigationController: parentViewController?.navigationController, parentViewController: parentViewController)
    }
}
