//
//  UIAlert+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 2/3/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import Foundation
extension UIAlertController {
    
    private struct AssociatedKeys {
        static var blurStyleKey = "UIAlertController.blurStyleKey"
    }
    
    public var cancelButtonColor: UIColor? {
        return ColorUtil.foregroundColor
    }
    
    private var visualEffectView: UIVisualEffectView? {
        if let presentationController = presentationController, presentationController.responds(to: Selector(("popoverView"))), let view = presentationController.value(forKey: "popoverView") as? UIView // We're on an iPad and visual effect view is in a different place.
        {
            return view.recursiveSubviews.compactMap({ $0 as? UIVisualEffectView }).first
        }
        
        return view.recursiveSubviews.compactMap({ $0 as? UIVisualEffectView }).first
    }
    
    private var cancelActionView: UIView? {
        return view.recursiveSubviews.compactMap({
            $0 as? UILabel }
            ).first(where: {
                $0.text == actions.first(where: { $0.style == .cancel })?.title
            })?.superview?.superview
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if self.view.tag != -1 {
            objc_setAssociatedObject(self, &AssociatedKeys.blurStyleKey, ColorUtil.theme.isLight() ? UIBlurEffect.Style.light : UIBlurEffect.Style.dark, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            view.tag = -1
            view.setNeedsLayout()
            view.layoutIfNeeded()
            self.view.tintColor = ColorUtil.baseAccent
            let titleFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18), NSAttributedString.Key.foregroundColor: ColorUtil.fontColor]
            let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12), NSAttributedString.Key.foregroundColor: ColorUtil.fontColor]
            
            let titleAttrString = NSMutableAttributedString(string: title ?? "", attributes: titleFont)
            let messageAttrString = NSMutableAttributedString(string: message ?? "", attributes: messageFont)
            
            self.setValue(titleAttrString, forKey: "attributedTitle")
            self.setValue(messageAttrString, forKey: "attributedMessage")
            let backView = self.view.subviews.last?.subviews.last
            backView?.layer.cornerRadius = 8
            backView?.backgroundColor = ColorUtil.backgroundColor
        }
        visualEffectView?.effect = UIBlurEffect(style: ColorUtil.theme.isLight() ? UIBlurEffect.Style.light : UIBlurEffect.Style.dark)
        //cancelActionView?.superview?.backgroundColor = cancelButtonColor
    }
}

extension UIView {
    
    var recursiveSubviews: [UIView] {
        var subviews = self.subviews.compactMap({ $0 })
        subviews.forEach { subviews.append(contentsOf: $0.recursiveSubviews) }
        return subviews
    }
}
