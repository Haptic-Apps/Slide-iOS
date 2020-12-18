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
    var innerView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureGestures() {
        self.innerView.addTapGestureRecognizer { [weak self] (_) in
            guard let self = self, let comment = self.comment else { return }
            self.delegate?.openComment(comment)
        }
        //TODO add long press menu
    }
    
    func configureViews() {
        self.text = TextDisplayStackView(fontSize: 16, submission: true, color: ColorUtil.accentColorForSub(sub: ""), width: contentView.frame.width - 12, delegate: textDelegate)
        
        self.innerView = UIView().then {
            $0.backgroundColor = UIColor.foregroundColor
        }
        
        self.innerView.addSubview(text)
        self.addSubview(innerView)
        self.backgroundColor = UIColor.backgroundColor
    }
    
    func configureLayout() {
        text.topAnchor /==/ innerView.topAnchor + CGFloat(6)
        text.bottomAnchor /==/ innerView.bottomAnchor + CGFloat(6)
        text.horizontalAnchors /==/ innerView.horizontalAnchors + CGFloat(4)
        text.verticalCompressionResistancePriority = .required
        innerView.edgeAnchors /==/ self.edgeAnchors + 2
    }

    func setComment(comment: CommentObject, width: CGFloat) {
        if !hasConfigured {
            hasConfigured = true
            self.configureViews()
            self.configureLayout()
            self.configureGestures()
        }
        
        self.contentView.isHidden = true
        
        text.tColor = ColorUtil.accentColorForSub(sub: comment.subreddit)
        text.estimatedWidth = self.contentView.frame.size.width - 12

        let titleText = CommentCellView.getTitle(comment)
        self.comment = comment
       
        text.setTextWithTitleHTML(titleText, htmlString: comment.htmlBody, images: true)
    }
    
    public static func getTitle(_ comment: CommentObject) -> NSAttributedString {
        var uC: UIColor
        switch ActionStates.getVoteDirection(s: comment) {
        case .down:
            uC = ColorUtil.downvoteColor
        case .up:
            uC = ColorUtil.upvoteColor
        default:
            uC = UIColor.fontColor
        }
        
        let color = ColorUtil.getColorForSub(sub: comment.subreddit)
        let fontSize = 12 + CGFloat(SettingValues.postFontOffset)
        let titleFont = FontGenerator.boldFontOfSize(size: 12, submission: true)
        var attrs = [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: UIColor.fontColor] as [NSAttributedString.Key: Any]

        var iconString = NSMutableAttributedString()
        if (Subscriptions.icon(for: comment.subreddit) != nil) && SettingValues.subredditIcons {
            if let urlAsURL = URL(string: Subscriptions.icon(for: comment.subreddit.lowercased())!.unescapeHTML) {
                let attachment = AsyncTextAttachmentNoLoad(imageURL: urlAsURL, delegate: nil, rounded: true, backgroundColor: color)
                attachment.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
                iconString.append(NSAttributedString(attachment: attachment))
                attrs[.baselineOffset] = (((24 - fontSize) / 2) - (titleFont.descender / 2))
            }
            let tapString = NSMutableAttributedString(string: "  r/\(comment.subreddit)", attributes: attrs)
            tapString.addAttributes([.urlAction: URL(string: "https://www.reddit.com/r/\(comment.subreddit)")!], range: NSRange(location: 0, length: tapString.length))

            iconString.append(tapString)
        } else {
            if color != ColorUtil.baseColor {
                let preString = NSMutableAttributedString(string: "⬤  ", attributes: [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: color])
                iconString = preString
                let tapString = NSMutableAttributedString(string: "r/\(comment.subreddit)", attributes: attrs)
                tapString.addAttributes([.urlAction: URL(string: "https://www.reddit.com/r/\(comment.subreddit)")!], range: NSRange(location: 0, length: tapString.length))
                iconString.append(tapString)
            } else {
                let tapString = NSMutableAttributedString(string: "r/\(comment.subreddit)", attributes: attrs)
                tapString.addAttributes([.urlAction: URL(string: "https://www.reddit.com/r/\(comment.subreddit)")!], range: NSRange(location: 0, length: tapString.length))
                iconString = tapString
            }
        }

        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: comment.created as NSDate, numericDates: true))  •  ", attributes: attrs)
        
        let boldString = NSMutableAttributedString(string: "\(comment.score)pts", attributes: attrs)
        boldString.addAttributes([.foregroundColor: uC], range: NSRange(location: 0, length: boldString.length))
        endString.append(boldString)
        
        endString.append(NSAttributedString(string: "  •  \(comment.submissionTitle)", attributes: attrs))
        
        let infoString = NSMutableAttributedString()
        infoString.append(iconString)
        infoString.append(endString)
        
        return infoString
    }
}
