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
    var innerView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

    func configureGestures() {
        self.innerView.addTapGestureRecognizer { [weak self] (_) in
            guard let self = self, let message = self.message else { return }
            self.delegate?.doReply(to: message, cell: self)
        }
        let long = self.innerView.addLongTapGestureRecognizerReturn { [weak self] (_) in
            guard let self = self, let message = self.message else { return }
            self.delegate?.showMenu(for: message, cell: self)
        }
        self.text?.parentLongPress = long
    }
    
    func configureLayout() {
        text.topAnchor /==/ innerView.topAnchor + CGFloat(6)
        text.bottomAnchor /==/ innerView.bottomAnchor + CGFloat(6)
        text.horizontalAnchors /==/ innerView.horizontalAnchors + CGFloat(4)
        text.verticalCompressionResistancePriority = .required
        innerView.edgeAnchors /==/ self.edgeAnchors + 2
    }
    
    func setMessage(message: MessageObject, width: CGFloat) {
        if !hasConfigured {
            hasConfigured = true
            self.configureViews()
            self.configureLayout()
            self.configureGestures()
        }

        self.message = message
        
        text.estimatedWidth = self.contentView.frame.size.width - 12
        text.tColor = ColorUtil.accentColorForSub(sub: message.subreddit)

        let titleText = MessageCellView.getTitleText(message: message)
       
        text.setTextWithTitleHTML(titleText, htmlString: message.htmlBody, images: true)
    }
    
    public static func getTitleText(message: MessageObject) -> NSAttributedString {
        let fontSize = 12 + CGFloat(SettingValues.postFontOffset)
        let titleFont = FontGenerator.boldFontOfSize(size: 12, submission: true)
        var attrs = [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: UIColor.fontColorOverlaid(withForeground: true, 0.24)] as [NSAttributedString.Key: Any]

        var infoString: NSMutableAttributedString
        if message.wasComment {
            let color = ColorUtil.getColorForSub(sub: message.subreddit)
            var iconString = NSMutableAttributedString()
            if (Subscriptions.icon(for: message.subreddit) != nil) && SettingValues.subredditIcons {
                if let urlAsURL = URL(string: Subscriptions.icon(for: message.subreddit.lowercased())!.unescapeHTML) {
                    let attachment = AsyncTextAttachmentNoLoad(imageURL: urlAsURL, delegate: nil, rounded: true, backgroundColor: color)
                    attachment.bounds = CGRect(x: 0, y: 0, width: 24, height: 24)
                    iconString.append(NSAttributedString(attachment: attachment))
                    attrs[.baselineOffset] = (((24 - fontSize) / 2) - (titleFont.descender / 2))
                }
                let tapString = NSMutableAttributedString(string: "  r/\(message.subreddit)", attributes: attrs)
                tapString.addAttributes([.urlAction: URL(string: "https://www.reddit.com/r/\(message.subreddit)")!], range: NSRange(location: 0, length: tapString.length))

                iconString.append(tapString)
            } else {
                if color != ColorUtil.baseColor {
                    let preString = NSMutableAttributedString(string: "⬤  ", attributes: [NSAttributedString.Key.font: titleFont, NSAttributedString.Key.foregroundColor: color])
                    iconString = preString
                    let tapString = NSMutableAttributedString(string: "r/\(message.subreddit)", attributes: attrs)
                    tapString.addAttributes([.urlAction: URL(string: "https://www.reddit.com/r/\(message.subreddit)")!], range: NSRange(location: 0, length: tapString.length))
                    iconString.append(tapString)
                } else {
                    let tapString = NSMutableAttributedString(string: "r/\(message.subreddit)", attributes: attrs)
                    tapString.addAttributes([.urlAction: URL(string: "https://www.reddit.com/r/\(message.subreddit)")!], range: NSRange(location: 0, length: tapString.length))
                    iconString = tapString
                }
            }
            
            var authorAttributes: [NSAttributedString.Key: Any] = attrs
            let userColor = ColorUtil.getColorForUser(name: message.author)
            
            if AccountController.currentName == message.author {
                authorAttributes[.badgeColor] = UIColor.init(hexString: "#FFB74D")
                authorAttributes[.foregroundColor] = UIColor.white
            } else if userColor != ColorUtil.baseColor {
                authorAttributes[.badgeColor] = userColor
                authorAttributes[.foregroundColor] = UIColor.white
            }

            let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: message.author, small: false))\u{00A0}", attributes: authorAttributes)

            let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: message.created as NSDate, numericDates: true))  •  from ", attributes: attrs)
            endString.append(authorString)
            
            if !ActionStates.isRead(s: message) {
                attrs[.foregroundColor] = GMColor.red500Color()
            }
            attrs[.font] = FontGenerator.boldFontOfSize(size: 16, submission: true)
            endString.append(NSAttributedString(string: "\n\(message.submissionTitle?.unescapeHTML ?? message.subject.unescapeHTML)", attributes: attrs))
            
            infoString = NSMutableAttributedString()
            infoString.append(iconString)
            infoString.append(endString)
        } else {
            var authorAttributes: [NSAttributedString.Key: Any] = attrs
            let userColor = ColorUtil.getColorForUser(name: message.author)
            
            if AccountController.currentName == message.author {
                authorAttributes[.badgeColor] = UIColor.init(hexString: "#FFB74D")
                authorAttributes[.foregroundColor] = UIColor.white
            } else if userColor != ColorUtil.baseColor {
                authorAttributes[.badgeColor] = userColor
                authorAttributes[.foregroundColor] = UIColor.white
            }

            let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: message.author, small: false))\u{00A0}", attributes: authorAttributes)

            let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: message.created as NSDate, numericDates: true))  •  from ", attributes: attrs)
            endString.append(authorString)
            
            if message.isNew {
                attrs[.foregroundColor] = GMColor.red500Color()
            }
            attrs[.font] = FontGenerator.fontOfSize(size: 16, submission: true)
            endString.append(NSAttributedString(string: "\n\(message.subject.unescapeHTML)", attributes: attrs))
            
            infoString = NSMutableAttributedString()
            infoString.append(endString)

        }
        
        return infoString
    }
}
