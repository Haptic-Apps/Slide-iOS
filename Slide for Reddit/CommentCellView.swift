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

protocol CommentCellViewDelegate: class {
    func openComment(_ comment: CommentObject)
}

class CommentCellView: UICollectionViewCell, UIGestureRecognizerDelegate {
    var longBlocking = false
    var text: TextDisplayStackView!
    var single = false
    weak var delegate: CommentCellViewDelegate?
    weak var textDelegate: TextDisplayStackViewDelegate?
    var registered: Bool = false
    var currentLink: URL?
    var comment: CommentObject?
    var hasText = false
    var full = false
    var hasConfigured = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureGestures() {
        self.contentView.addTapGestureRecognizer { [weak self] (_) in
            guard let self = self, let comment = self.comment else { return }
            self.delegate?.openComment(comment)
        }
        //TODO add long press menu
    }
    
    func configureViews() {
        self.text = TextDisplayStackView(fontSize: 16, submission: false, color: ColorUtil.accentColorForSub(sub: ""), width: frame.width - 16, delegate: textDelegate)
        self.contentView.addSubview(text)
        
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    func configureLayout() {
        text.topAnchor /==/ contentView.topAnchor + CGFloat(8)
        text.bottomAnchor /<=/ contentView.bottomAnchor + CGFloat(8)
        text.horizontalAnchors /==/ contentView.horizontalAnchors + CGFloat(8)
    }

    func setComment(comment: CommentObject, width: CGFloat) {
        if !hasConfigured {
            hasConfigured = true
            self.configureViews()
            self.configureLayout()
            self.configureGestures()
        }
        
        text.tColor = ColorUtil.accentColorForSub(sub: comment.subreddit)
        text.estimatedWidth = self.contentView.frame.size.width - 16

        let titleText = CommentCellView.getTitle(comment)
        self.comment = comment
       
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
}
