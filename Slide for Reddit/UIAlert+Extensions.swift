//
//  UIAlert+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 2/3/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import Foundation
import SDCAlertView

extension AlertController {
    public func addCancelButton() {
        if self.preferredStyle == .actionSheet {
            let cancelAction = AlertAction(title: "Cancel", style: .preferred, handler: nil)
            self.addAction(cancelAction)
        } else {
            let cancelAction = AlertAction(title: "Cancel", style: .preferred, handler: nil)
            self.addAction(cancelAction)
        }
    }
    public func addCloseButton() {
        if self.preferredStyle == .actionSheet {
            let cancelAction = AlertAction(title: "Close", style: .preferred, handler: nil)
            self.addAction(cancelAction)
        } else {
            let cancelAction = AlertAction(title: "Close", style: .preferred, handler: nil)
            self.addAction(cancelAction)
        }
    }
}
extension UIAlertController {
    
    public func addCancelButton() {
        if self.preferredStyle == .actionSheet {
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            self.addAction(cancelAction)
        } else {
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            self.addAction(cancelAction)
        }
    }
    
    private struct AssociatedKeys {
        static var blurStyleKey = "UIAlertController.blurStyleKey"
    }
    
    public var cancelButtonColor: UIColor? {
        return ColorUtil.theme.foregroundColor
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
        print(self.title)
        if self.actions.count == 1 && self.actions[0].title == "OK" {
            return
        }
        if self.view.tag != -1 {
            objc_setAssociatedObject(self, &AssociatedKeys.blurStyleKey, ColorUtil.theme.isLight ? UIBlurEffect.Style.light : UIBlurEffect.Style.dark, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            view.tag = -1
            view.setNeedsLayout()
            view.layoutIfNeeded()
            self.view.tintColor = ColorUtil.baseAccent
            let titleFont = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor]
            let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor]
            
            let titleAttrString = NSMutableAttributedString(string: title ?? "", attributes: titleFont)
            let messageAttrString = NSMutableAttributedString(string: message ?? "", attributes: messageFont)
            
            self.setValue(titleAttrString, forKey: "attributedTitle")
            if !(message?.isEmpty ?? true) {
                self.setValue(messageAttrString, forKey: "attributedMessage")
            }
            if let firstSubview = self.view.subviews.first, let alertContentView = firstSubview.subviews.first {
                for view in alertContentView.subviews {
                    view.backgroundColor = ColorUtil.theme.foregroundColor.withAlphaComponent(0.6)
                }
            }
        }
        visualEffectView?.effect = UIBlurEffect(style: ColorUtil.theme.isLight ? UIBlurEffect.Style.light : UIBlurEffect.Style.dark)
        if self.preferredStyle == .actionSheet && UIDevice.current.userInterfaceIdiom != .pad {
            cancelActionView?.backgroundColor = ColorUtil.theme.foregroundColor
        }
    }
}

extension UIView {
    var recursiveSubviews: [UIView] {
        var subviews = self.subviews.compactMap({ $0 })
        subviews.forEach { subviews.append(contentsOf: $0.recursiveSubviews) }
        return subviews
    }
}

class CancelButtonViewController: UIViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let cancelView = UILabel().then {
            $0.text = "Cancel"
            $0.font = UIFont.boldSystemFont(ofSize: 20)
            $0.textColor = ColorUtil.baseAccent
            $0.clipsToBounds = true
            $0.backgroundColor = ColorUtil.theme.foregroundColor  
            $0.textAlignment = .center
        }
        self.view.addSubview(cancelView)
        cancelView.edgeAnchors == self.view.edgeAnchors
    }
}
