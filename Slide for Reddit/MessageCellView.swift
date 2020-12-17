//
//  MessageCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import UIKit

protocol MessageCellViewDelegate: class {
    func doReply(to message: MessageObject, cell: MessageCellView)
    func showMenu(for message: MessageObject, cell: MessageCellView)
}

class MessageCellView: UICollectionViewCell {
    var text: TextDisplayStackView!
    var single = false
    var longBlocking = false
    var content: NSAttributedString?
    var hasText = false
    var full = false
    weak var textDelegate: TextDisplayStackViewDelegate?
    weak var delegate: MessageCellViewDelegate?
    var timer: Timer?
    var cancelled = false
    var lsC: [NSLayoutConstraint] = []
    var message: MessageObject?
    var hasConfigured = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureViews() {
        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)
        self.text = TextDisplayStackView.init(fontSize: 16, submission: false, color: ColorUtil.accentColorForSub(sub: ""), width: frame.width - 16, delegate: textDelegate)
        self.contentView.addSubview(text)
        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    func configureGestures() {
        self.contentView.addTapGestureRecognizer { [weak self] (_) in
            guard let self = self, let message = self.message else { return }
            self.delegate?.doReply(to: message, cell: self)
        }
        self.contentView.addLongTapGestureRecognizer { [weak self] (_) in
            guard let self = self, let message = self.message else { return }
            self.delegate?.showMenu(for: message, cell: self)
        }
    }
    
    func configureLayout() {
        text.topAnchor /==/ contentView.topAnchor + CGFloat(8)
        text.bottomAnchor /<=/ contentView.bottomAnchor + CGFloat(8)
        text.rightAnchor /==/ contentView.rightAnchor - CGFloat(8)
    }
    
    func setMessage(message: MessageObject, width: CGFloat) {
        if !hasConfigured {
            hasConfigured = true
            self.configureViews()
            self.configureLayout()
            self.configureGestures()
        }

        self.message = message

        let titleText = MessageCellView.getTitleText(message: message)
        text.estimatedWidth = self.contentView.frame.size.width - 16 - (message.subject.hasPrefix("re:") ? 30 : 0)
        text.setTextWithTitleHTML(titleText, htmlString: message.htmlBody)

        self.text.removeConstraints(lsC)
        if message.subject.hasPrefix("re:") {
            lsC = batch {
                self.text.leftAnchor /==/ self.contentView.leftAnchor + 38
            }
        } else {
            lsC = batch {
                self.text.leftAnchor /==/ self.contentView.leftAnchor + 8
            }
        }
    }

    public static func getTitleText(message: MessageObject) -> NSAttributedString {
        let titleText = NSMutableAttributedString(string: message.wasComment ? message.submissionTitle?.unescapeHTML ?? "" : message.subject.unescapeHTML, attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 18, submission: false), NSAttributedString.Key.foregroundColor: !ActionStates.isRead(s: message) ? GMColor.red500Color() : ColorUtil.theme.fontColor])
        
        let endString = NSMutableAttributedString(string: "\(DateFormatter().timeSince(from: message.created as NSDate, numericDates: true))  •  from \(message.author)", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor, NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false)])
        
        var color = ColorUtil.getColorForSub(sub: message.subreddit)
        if color == ColorUtil.baseColor {
            color = ColorUtil.theme.fontColor
        }

        let subString = NSMutableAttributedString(string: "r/\(message.subreddit)", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false), NSAttributedString.Key.foregroundColor: color])
        
        let infoString = NSMutableAttributedString()
        infoString.append(endString)
        if !message.subreddit.isEmpty {
            infoString.append(NSAttributedString.init(string: "  •  ", attributes: [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor, NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false)]))
            infoString.append(subString)
        }
        
        titleText.append(NSAttributedString(string: "\n"))
        titleText.append(infoString)
        return titleText
    }
}
