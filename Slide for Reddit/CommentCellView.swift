//
//  CommentCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/7/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import TTTAttributedLabel
import UIKit

class CommentCellView: UICollectionViewCell, UIGestureRecognizerDelegate, TTTAttributedLabelDelegate {
    
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
        let fr = UIEdgeInsetsInsetRect(f, UIEdgeInsets(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin)))
        self.contentView.frame = fr
    }

    var hasText = false
    var full = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)

        self.text = TextDisplayStackView.init(fontSize: 16, submission: false, color: ColorUtil.accentColorForSub(sub: ""), width: frame.width - 16)
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
        let titleText = NSMutableAttributedString.init(string: comment.submissionTitle, attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 18, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])
        self.comment = comment
       
        let commentClick = UITapGestureRecognizer(target: self, action: #selector(CommentCellView.openComment(sender:)))
        commentClick.delegate = self
        self.addGestureRecognizer(commentClick)
        
        var uC: UIColor
        switch ActionStates.getVoteDirection(s: comment) {
        case .down:
            uC = ColorUtil.downvoteColor
        case .up:
            uC = ColorUtil.upvoteColor
        default:
            uC = ColorUtil.fontColor
        }
        
        let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: uC] as [String: Any]
        
        let attrs2 = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor] as [String: Any]

        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: comment.created, numericDates: true))  •  ", attributes: attrs2)
        
        let boldString = NSMutableAttributedString(string: "\(comment.score)pts", attributes: attrs)
        let subString = NSMutableAttributedString(string: "r/\(comment.subreddit)")
        let color = ColorUtil.getColorForSub(sub: comment.subreddit)
        if color != ColorUtil.baseColor {
            subString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: subString.length))
        } else {
            subString.addAttribute(NSForegroundColorAttributeName, value: ColorUtil.fontColor, range: NSRange.init(location: 0, length: subString.length))
        }
        
        let infoString = NSMutableAttributedString()
        infoString.append(boldString)
        infoString.append(endString)
        infoString.append(subString)

        titleText.append(NSAttributedString.init(string: "\n", attributes: nil))
        titleText.append(infoString)
        
        text.setTextWithTitleHTML(titleText, htmlString: comment.htmlText)
    }
    
    var registered: Bool = false
    var currentLink: URL?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var comment: RComment?
    public var parentViewController: (UIViewController & MediaVCDelegate)?
    public var navViewController: UIViewController?
    
    func openComment(sender: UITapGestureRecognizer? = nil) {
        VCPresenter.openRedditLink(self.comment!.permalink, parentViewController?.navigationController, parentViewController)
    }
}
