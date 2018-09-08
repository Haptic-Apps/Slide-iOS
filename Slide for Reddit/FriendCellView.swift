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
import TTTAttributedLabel
import UIKit
import XLActionController

class FriendCellView: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var title = UILabel()
    var icon = UIImageView()
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)
        self.title = UILabel(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = FontGenerator.fontOfSize(size: 18, submission: true)
        title.textColor = ColorUtil.fontColor
        
        self.icon = UIImageView(image: UIImage(named: "profile")!.getCopy(withSize: CGSize.square(size: 20), withColor: ColorUtil.fontColor))
        self.contentView.addSubviews(title, icon)

        self.contentView.backgroundColor = ColorUtil.foregroundColor
        self.setupConstraints()
        
        self.contentView.addTapGestureRecognizer {
            let prof = ProfileViewController.init(name: self.friend?.name ?? "")
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: self.parentViewController?.navigationController, parentViewController: self.parentViewController)
        }
    }
    
    func setupConstraints() {
        self.title.leftAnchor == self.icon.rightAnchor + 8
        self.title.rightAnchor == self.contentView.rightAnchor - 8
        self.title.verticalAnchors == self.contentView.verticalAnchors
        self.icon.leftAnchor == self.contentView.leftAnchor + 8
        self.icon.heightAnchor == 30
        self.icon.widthAnchor == 30
        self.icon.verticalAnchors == self.contentView.verticalAnchors + 20
    }
    
    func setFriend(friend: RFriend, parent: UIViewController & MediaVCDelegate) {
        parentViewController = parent
        self.friend = friend
        let boldFont = FontGenerator.boldFontOfSize(size: 14, submission: false)

        let authorString = NSMutableAttributedString(string: "\u{00A0}\u{00A0}\(AccountController.formatUsername(input: friend.name, small: false))\u{00A0}", attributes: [NSFontAttributeName: boldFont, NSForegroundColorAttributeName: ColorUtil.fontColor])
        let authorStringNoFlair = NSMutableAttributedString(string: "\(AccountController.formatUsername(input: friend.name, small: false))\u{00A0}", attributes: [NSFontAttributeName: boldFont, NSForegroundColorAttributeName: ColorUtil.fontColor])
        
        let spacer = NSMutableAttributedString.init(string: "  ")
        let userColor = ColorUtil.getColorForUser(name: friend.name)
        var authorSmall = false
        if AccountController.currentName == friend.name {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), NSFontAttributeName: boldFont, NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 2, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 1, length: authorString.length - 1))
        } else if userColor != ColorUtil.baseColor {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: userColor, NSFontAttributeName: boldFont, NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 2, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 1, length: authorString.length - 1))
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
        if !tag.isEmpty {
            let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: [NSFontAttributeName: boldFont, NSForegroundColorAttributeName: ColorUtil.fontColor])
            tagString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: tagString.length))
            infoString.append(spacer)
            infoString.append(tagString)
        }
        
        let messageClick = UITapGestureRecognizer(target: self, action: #selector(MessageCellView.doReply(sender:)))
        messageClick.delegate = self
        self.addGestureRecognizer(messageClick)
        
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"

        let endString = NSMutableAttributedString(string: "\nFriend since \(df.string(from: friend.friendSince as Date))", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])
        
        infoString.append(endString)
        title.attributedText = infoString
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var friend: RFriend?
    public var parentViewController: (UIViewController & MediaVCDelegate)?
    public var navViewController: UIViewController?
}
