//
//  UIViewController+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/6/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UIViewController {
    @objc func setupBaseBarColors(_ overrideColor: UIColor? = nil) {
        if #available(iOS 13, *) {
            self.navigationController?.navigationBar.standardAppearance = UINavigationBarAppearance()
            self.navigationController?.navigationBar.standardAppearance.configureWithOpaqueBackground()
            self.navigationController?.navigationBar.standardAppearance.backgroundColor = overrideColor ?? ColorUtil.getColorForSub(sub: "", true)
            self.navigationController?.navigationBar.standardAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: SettingValues.reduceColor ? UIColor.fontColor : UIColor.white]
            self.navigationController?.navigationBar.standardAppearance.shadowColor = UIColor.clear

            self.navigationController?.navigationBar.compactAppearance = UINavigationBarAppearance()
            self.navigationController?.navigationBar.compactAppearance?.configureWithOpaqueBackground()
            self.navigationController?.navigationBar.compactAppearance?.backgroundColor = overrideColor ?? ColorUtil.getColorForSub(sub: "", true)
            self.navigationController?.navigationBar.compactAppearance?.titleTextAttributes = [NSAttributedString.Key.foregroundColor: SettingValues.reduceColor ? UIColor.fontColor : UIColor.white]
        } else {
            navigationController?.navigationBar.barTintColor = overrideColor ?? ColorUtil.getColorForSub(sub: "", true)
            let textAttributes = [NSAttributedString.Key.foregroundColor: SettingValues.reduceColor ? UIColor.fontColor : .white]
            navigationController?.navigationBar.titleTextAttributes = textAttributes
        }
        
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        
        navigationController?.navigationBar.tintColor = SettingValues.reduceColor ? UIColor.fontColor : UIColor.white
        setNeedsStatusBarAppearanceUpdate()
    }
    
    public func disableDismissalRecognizers() {
        navigationController?.presentationController?.presentedView?.gestureRecognizers?.forEach {
            $0.isEnabled = false
        }
    }

    public func enableDismissalRecognizers() {
        navigationController?.presentationController?.presentedView?.gestureRecognizers?.forEach {
            $0.isEnabled = true
        }
    }
}
