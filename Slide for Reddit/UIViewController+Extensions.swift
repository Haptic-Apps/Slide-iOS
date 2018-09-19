//
//  UIViewController+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/6/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UIViewController {    
    func topMostViewController() -> UIViewController {
        // Handling Modal views/Users/carloscrane/Desktop/Slide for Reddit/Slide for Reddit/SettingValues.swift
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topMostViewController()
        }
            // Handling UIViewController's added as subviews to some other views.
        else {
            for view in self.view.subviews {
                // Key property which most of us are unaware of / rarely use.
                if let subViewController = view.next {
                    if subViewController is UIViewController {
                        let viewController = subViewController as! UIViewController
                        return viewController.topMostViewController()
                    }
                }
            }
            return self
        }
    }
    
    func setupBaseBarColors(_ overrideColor: UIColor? = nil) {
        navigationController?.navigationBar.barTintColor = overrideColor ?? ColorUtil.getColorForSub(sub: "", true)
        navigationController?.navigationBar.tintColor = SettingValues.reduceColor ? ColorUtil.fontColor : UIColor.white
        let textAttributes = [NSForegroundColorAttributeName: SettingValues.reduceColor ? ColorUtil.fontColor : .white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        if SettingValues.reduceColor && ColorUtil.theme.isLight() {
            UIApplication.shared.statusBarStyle = .default
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }
    }
}
