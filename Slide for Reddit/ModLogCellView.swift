//
//  ModLogCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 11/17/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import reddift
import UIKit

protocol ModlogCellViewDelegate: class {
    func didClick(on modLogObject: ModLogObject)
    func showMenu(for modLogObject: ModLogObject)
}

class ModlogCellView: UICollectionViewCell {
    var logItem: ModLogObject?
    weak var delegate: ModlogCellViewDelegate?
    weak var textDelegate: TextDisplayStackViewDelegate?
    var text: TextDisplayStackView!
    var single = false
    var content: NSAttributedString?
    var hasText = false
    var full = false
    var lsC: [NSLayoutConstraint] = []
    var hasConfigured = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureGestures() {
        self.contentView.addTapGestureRecognizer { [weak self] (_) in
            guard let self = self, let item = self.logItem else { return }
            self.delegate?.didClick(on: item)
        }
        self.contentView.addLongTapGestureRecognizer { [weak self] (_) in
            guard let self = self, let item = self.logItem else { return }
            self.delegate?.showMenu(for: item)
        }
    }
    
    func configureViews() {
        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)
        self.text = TextDisplayStackView(fontSize: 16, submission: false, color: ColorUtil.accentColorForSub(sub: ""), width: frame.width - 16, delegate: textDelegate)
        self.contentView.addSubview(text)

        self.contentView.backgroundColor = UIColor.foregroundColor
    }
    
    func configureLayout() {
        text.topAnchor /==/ contentView.topAnchor + CGFloat(8)
        text.bottomAnchor /<=/ contentView.bottomAnchor + CGFloat(8)
        text.rightAnchor /==/ contentView.rightAnchor - CGFloat(8)
        
        self.text.leftAnchor /==/ self.contentView.leftAnchor + 8
    }

    func setLogItem(logItem: ModLogObject, width: CGFloat) {
        if !hasConfigured {
            hasConfigured = true
            self.configureViews()
            self.configureLayout()
            self.configureGestures()
        }

        self.logItem = logItem

        let titleText = ModlogCellView.getTitleText(item: logItem)
        text.estimatedWidth = self.contentView.frame.size.width - 16
        text.setTextWithTitleHTML(titleText, htmlString: logItem.targetTitle)
    }
    
    var timer: Timer?
    var cancelled = false
    
    public static func getTitleText(item: ModLogObject) -> NSAttributedString {
        let titleText = NSMutableAttributedString.init(string: "\(item.action)- \(item.details)", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 18, submission: false), NSAttributedString.Key.foregroundColor: UIColor.fontColor])
        
        let endString = NSMutableAttributedString(string: "\(DateFormatter().timeSince(from: item.created as NSDate, numericDates: true))  •  removed by \(item.mod)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false)])
        
        var color = ColorUtil.getColorForSub(sub: item.subreddit)
        if color == ColorUtil.baseColor {
            color = UIColor.fontColor
        }

        let subString = NSMutableAttributedString(string: "r/\(item.subreddit)", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false), NSAttributedString.Key.foregroundColor: color])
        
        let infoString = NSMutableAttributedString()
        infoString.append(endString)
        infoString.append(NSAttributedString.init(string: "  •  ", attributes: [NSAttributedString.Key.foregroundColor: UIColor.fontColor, NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 16, submission: false)]))
        infoString.append(subString)
        
        titleText.append(NSAttributedString(string: "\n"))
        titleText.append(infoString)
        return titleText
    }
}
