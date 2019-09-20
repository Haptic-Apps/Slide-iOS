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
import YYText

class FriendCellView: UICollectionViewCell, UIGestureRecognizerDelegate {
    
    var title = YYLabel()
    var icon = UIImageView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let topmargin = 0
        let bottommargin = 2
        let leftmargin = 0
        let rightmargin = 0
        
        let f = self.contentView.frame
        let fr = f.inset(by: UIEdgeInsets(top: CGFloat(topmargin), left: CGFloat(leftmargin), bottom: CGFloat(bottommargin), right: CGFloat(rightmargin)))
        self.contentView.frame = fr
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.layoutMargins = UIEdgeInsets.init(top: 2, left: 0, bottom: 0, right: 0)
        self.title = YYLabel(frame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: CGFloat.greatestFiniteMagnitude))
        title.numberOfLines = 0
        title.lineBreakMode = NSLineBreakMode.byWordWrapping
        title.font = FontGenerator.fontOfSize(size: 18, submission: true)
        title.textColor = ColorUtil.theme.fontColor
        
        self.icon = UIImageView(image: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.getCopy(withSize: CGSize.square(size: 20), withColor: ColorUtil.theme.fontColor))
        self.contentView.addSubviews(title, icon)

        self.contentView.backgroundColor = ColorUtil.theme.foregroundColor
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

        let authorString = NSMutableAttributedString(string: "\u{00A0}\u{00A0}\(AccountController.formatUsername(input: friend.name, small: false))\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): boldFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor]))
        let authorStringNoFlair = NSMutableAttributedString(string: "\(AccountController.formatUsername(input: friend.name, small: false))\u{00A0}", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): boldFont, convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor]))
        
        let spacer = NSMutableAttributedString.init(string: "  ")
        let userColor = ColorUtil.getColorForUser(name: friend.name)
        var authorSmall = false
        if AccountController.currentName == friend.name {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: UIColor.init(hexString: "#FFB74D"), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 1, length: authorString.length - 1))
        } else if userColor != ColorUtil.baseColor {
            authorString.addAttributes([NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: userColor, cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white], range: NSRange.init(location: 1, length: authorString.length - 1))
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
            let tagString = NSMutableAttributedString.init(string: "\u{00A0}\(tag!)\u{00A0}", attributes: [NSAttributedString.Key.font: FontGenerator.boldFontOfSize(size: 12, submission: true), NSAttributedString.Key(rawValue: YYTextBackgroundBorderAttributeName) : YYTextBorder(fill: UIColor(rgb: 0x2196f3), cornerRadius: 3), NSAttributedString.Key.foregroundColor: UIColor.white])
            infoString.append(spacer)
            infoString.append(tagString)
        }
        
        let messageClick = UITapGestureRecognizer(target: self, action: #selector(MessageCellView.doReply(sender:)))
        messageClick.delegate = self
        self.addGestureRecognizer(messageClick)
        
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"

        let endString = NSMutableAttributedString(string: "\nFriend since \(df.string(from: friend.friendSince as Date))", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: false), convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor]))
        
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

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
