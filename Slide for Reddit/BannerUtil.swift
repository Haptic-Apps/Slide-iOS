//
//  BannerUtil.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

public class BannerUtil {
    public var popup = UILabel()
    public var cancelled = false
    public static var banner: BannerUtil?

    public func cancel() {
        self.cancelled = true
        popup.removeFromSuperview()
    }

    public static func makeBanner(text: String, color: UIColor = ColorUtil.accentColorForSub(sub: ""), seconds: TimeInterval, context: UIViewController?, top: Bool = false, callback: (() -> Void)? = nil) {
        if banner != nil {
            banner?.cancel()
        }
        if let context = context {
            banner = BannerUtil.init().makeBanner(text: text, color: color, seconds: seconds, context: context, top: top, callback: callback)
        }
    }

    func makeBanner(text: String, color: UIColor = ColorUtil.accentColorForSub(sub: ""), seconds: TimeInterval, context: UIViewController, top: Bool, callback: (() -> Void)? = nil) -> BannerUtil {
        var bottommargin = CGFloat(56)
        var topmargin = CGFloat(72)
        if context.navigationController != nil && !context.navigationController!.isToolbarHidden {
            bottommargin += 48
        }
        if #available(iOS 11.0, *) {
            if let window = UIApplication.shared.keyWindow {
                bottommargin += window.safeAreaInsets.bottom
                topmargin += window.safeAreaInsets.top
            }
        }

        var xmargin = CGFloat(12)
        if UIScreen.main.bounds.width > 350 {
            xmargin += (UIScreen.main.bounds.width - 350) / 2
        }
        let frame = CGRect.init(x: xmargin, y: top ? topmargin : UIScreen.main.bounds.height - bottommargin, width: UIScreen.main.bounds.width - (xmargin * 2), height: 48 + ((text.contains("\n")) ? 24 : 0))
        popup = UILabel.init(frame: frame)
        popup.backgroundColor = color
        popup.textAlignment = .center
        popup.isUserInteractionEnabled = true
        
        let textParts = text.components(separatedBy: "\n")
        
        let finalText: NSMutableAttributedString!
        if textParts.count > 1 {
            let firstPart = NSMutableAttributedString.init(string: textParts[0], attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
            let secondPart = NSMutableAttributedString.init(string: "\n" + textParts[1], attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.systemFont(ofSize: 12)])
            firstPart.append(secondPart)
            finalText = firstPart
        } else {
            finalText = NSMutableAttributedString.init(string: text, attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
        }
        popup.attributedText = finalText
        popup.numberOfLines = 0
        popup.elevate(elevation: 2)
        popup.layer.cornerRadius = 5
        popup.clipsToBounds = true
        popup.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        popup.isUserInteractionEnabled = true
        context.view.superview?.addSubview(popup)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            self.popup.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }, completion: { _ in
            if let callback = callback {
                self.popup.addTapGestureRecognizer {
                    callback()
                    self.cancel()
                }
            }
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseInOut], animations: {
                if !self.cancelled {
                    self.popup.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
                }
            }, completion: { _ in
                if !self.cancelled {
                    self.popup.removeFromSuperview()
                    BannerUtil.banner = nil
                }
            })
        }
        return self
    }
}
