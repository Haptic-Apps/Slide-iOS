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
        if (banner != nil) {
            banner?.cancel()
        }
        if let context = context {
            banner = BannerUtil.init().makeBanner(text: text, color: color, seconds: seconds, context: context, top: top, callback: callback)
        }
    }

    func makeBanner(text: String, color: UIColor = ColorUtil.accentColorForSub(sub: ""), seconds: TimeInterval, context: UIViewController, top: Bool, callback: (() -> Void)? = nil) -> BannerUtil {
        var bottommargin = CGFloat(56)
        if (context.navigationController != nil && !context.navigationController!.isToolbarHidden) {
            bottommargin += 48
        }
        var xmargin = CGFloat(12)
        if(UIScreen.main.bounds.width > 350){
            xmargin += (UIScreen.main.bounds.width - 350) / 2
        }
        let frame = CGRect.init(x: xmargin, y: top ? 72 : UIScreen.main.bounds.height - bottommargin, width: UIScreen.main.bounds.width - (xmargin * 2), height: 48)
        print(frame)
        popup = UILabel.init(frame: frame)
        popup.backgroundColor = color
        popup.textAlignment = .center
        popup.isUserInteractionEnabled = true
        popup.text = text
        popup.numberOfLines = 0
        popup.font = UIFont.systemFont(ofSize: 15)
        popup.textColor = .white

        popup.elevate(elevation: 2)
        popup.layer.cornerRadius = 5
        popup.clipsToBounds = true
        popup.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        popup.isUserInteractionEnabled = true
        context.view.superview?.addSubview(popup)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            self.popup.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }) { (done) in
            if let callback = callback {
                self.popup.addTapGestureRecognizer {
                    callback()
                    self.cancel()
                }
            }

        }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseInOut], animations: {
                if (!self.cancelled) {
                    self.popup.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
                }
            }) { (done) in
                if (!self.cancelled) {
                    self.popup.removeFromSuperview()
                    BannerUtil.banner = nil
                }
            }
        }
        return self
    }
}
