//
//  FriendCellView.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/8/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import reddift
import UIKit

protocol FriendCellViewDelegate: class {
    func showProfile(name: String)
}

class FriendCellView: UICollectionViewCell, UIGestureRecognizerDelegate {
    var titleView: TitleUITextView!
    var icon = UIImageView()
    var friend: FriendModel?
    weak var delegate: FriendCellViewDelegate?

    init(delegate: FriendCellViewDelegate) {
        super.init(frame: CGRect.zero)
        self.delegate = delegate
        
        self.configureViews()
        self.configureLayout()
        
        self.contentView.addTapGestureRecognizer { [weak self] (_) in
            guard let self = self else { return }
            if let name = self.friend?.name {
                self.delegate?.showProfile(name: name)
            }
        }
    }
    
    func configureViews() {
        let layout = BadgeLayoutManager()
        let storage = NSTextStorage()
        storage.addLayoutManager(layout)
        let initialSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        let container = NSTextContainer(size: initialSize)
        container.widthTracksTextView = true
        layout.addTextContainer(container)
        self.titleView = TitleUITextView(delegate: nil, textContainer: container)
        self.titleView.doSetup()
        
        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)
        
        self.icon = UIImageView(image: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.getCopy(withSize: CGSize.square(size: 20), withColor: ColorUtil.theme.fontColor))
        self.contentView.addSubviews(titleView, icon)

        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
    }
    
    func configureGestures() {
        self.contentView.addTapGestureRecognizer { [weak self] (_) in
            guard let self = self, let friend = self.friend else { return }
            self.delegate?.showProfile(name: friend.name)
        }
    }
    
    func configureLayout() {
        self.titleView.leftAnchor /==/ self.icon.rightAnchor + 8
        self.titleView.rightAnchor /==/ self.contentView.rightAnchor - 8
        self.titleView.verticalAnchors /==/ self.contentView.verticalAnchors
        self.icon.leftAnchor /==/ self.contentView.leftAnchor + 8
        self.icon.heightAnchor /==/ 30
        self.icon.widthAnchor /==/ 30
        self.icon.verticalAnchors /==/ self.contentView.verticalAnchors + 20
    }
    
    func setFriend(friend: FriendModel) {
        self.friend = friend
        let boldFont = FontGenerator.boldFontOfSize(size: 14, submission: false)

        let authorString = NSMutableAttributedString(string: "\u{00A0}\u{00A0}\(AccountController.formatUsername(input: friend.name, small: false))\u{00A0}", attributes: [NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        let authorStringNoFlair = NSMutableAttributedString(string: "\(AccountController.formatUsername(input: friend.name, small: false))\u{00A0}", attributes: [NSAttributedString.Key.font: boldFont, NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        let spacer = NSMutableAttributedString.init(string: "  ")
        let userColor = ColorUtil.getColorForUser(name: friend.name)
        var authorSmall = false
        if AccountController.currentName == friend.name {
            authorString.addAttributes([.badgeColor: UIColor(hexString: "#FFB74D"), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 1, length: authorString.length - 1))
        } else if userColor != ColorUtil.baseColor {
            authorString.addAttributes([.badgeColor: userColor, NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 1, length: authorString.length - 1))
        } else {
            authorSmall = true
        }
        
        let infoString: NSMutableAttributedString
        if authorSmall {
            infoString = authorStringNoFlair
        } else {
            infoString = authorString
        }
        
        let tag = ColorUtil.getTagForUser(name: friend.name)
        if tag != nil {
            let tagString = NSMutableAttributedString.init(string: "\u{00A0}\(tag!)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), .badgeColor: UIColor(rgb: 0x2196f3),  NSAttributedString.Key.foregroundColor: UIColor.white])
            infoString.append(spacer)
            infoString.append(tagString)
        }
                
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"

        let endString = NSMutableAttributedString(string: "\nFriend since \(df.string(from: friend.friendSince as Date))", attributes: [NSAttributedString.Key.font: FontGenerator.fontOfSize(size: 12, submission: false), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        infoString.append(endString)
        titleView.attributedText = infoString
        titleView.layoutTitleImageViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
