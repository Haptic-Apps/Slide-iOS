//
//  BannerUtil.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import SwiftEntryKit
import UIKit

public class BannerUtil {
    
    public static func makeBanner(text: String, color: UIColor = ColorUtil.accentColorForSub(sub: ""), seconds: TimeInterval, context: UIViewController?, top: Bool = true, callback: (() -> Void)? = nil) {
        BannerUtil.init().makeBanner(text: text, color: color, seconds: seconds, top: top, callback: callback)
    }

    func makeBanner(text: String, color: UIColor = ColorUtil.accentColorForSub(sub: ""), seconds: TimeInterval, top: Bool, callback: (() -> Void)? = nil) {
        let popup = UILabel.init(frame: CGRect.zero)
        popup.textAlignment = .center
        popup.isUserInteractionEnabled = true
        
        let textParts = text.components(separatedBy: "\n")
        
        let finalText: NSMutableAttributedString!
        if textParts.count > 1 {
            let firstPart = NSMutableAttributedString.init(string: textParts[0], attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 12)]))
            let secondPart = NSMutableAttributedString.init(string: "\n" + textParts[1], attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
            firstPart.append(secondPart)
            finalText = firstPart
        } else {
            finalText = NSMutableAttributedString.init(string: text, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
        }
        popup.attributedText = finalText
        popup.numberOfLines = 0
        popup.heightAnchor /==/ 50
        popup.backgroundColor = color
        //popup.roundCorners(UIRectCorner.allCorners, radius: 25)
        popup.clipsToBounds = true
        popup.layer.cornerRadius = 25
        popup.layer.mask?.cornerRadius = 25
        popup.widthAnchor /==/ 250
        popup.layer.masksToBounds = true
        popup.layer.shadowOffset = CGSize.init(width: 0, height: 3)
        popup.layer.shadowColor = UIColor.black.cgColor
        popup.layer.shadowRadius = 2
        popup.layer.shadowOpacity = 0.75
        
        var attributes = EKAttributes.topNote
        attributes.name = text
        if seconds > 0 {
            attributes.displayDuration = seconds
        }
        attributes.position = top ? EKAttributes.Position.top : EKAttributes.Position.bottom
        attributes.screenInteraction = .forward
        attributes.exitAnimation = EKAttributes.Animation(translate: EKAttributes.Animation.Translate.init(duration: 0.15), scale: EKAttributes.Animation.RangeAnimation.init(from: 0.80, to: 1, duration: 0.25), fade: nil)
        attributes.entranceAnimation = EKAttributes.Animation(translate: EKAttributes.Animation.Translate.init(duration: 0.2), scale: EKAttributes.Animation.RangeAnimation.init(from: 0.80, to: 1, duration: 0.25), fade: nil)
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .easeOut)
        attributes.entryBackground = EKAttributes.BackgroundStyle.color(color: EKColor(light: UIColor.clear, dark: UIColor.clear))
        attributes.precedence = .enqueue(priority: .normal)
        attributes.statusBar = .inferred
        //attributes.hapticFeedbackType = color.hexString() == GMColor.red500Color().hexString() ? .warning : .success
        
        if let callback = callback {
            attributes.entryInteraction.customTapActions.append {
                callback()
                SwiftEntryKit.dismiss()
            }
        }

        SwiftEntryKit.display(entry: popup.withPadding(padding: UIEdgeInsets(top: 5, left: 50, bottom: 0, right: 50)), using: attributes)
    }
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
