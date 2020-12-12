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
            self.navigationController?.navigationBar.standardAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: SettingValues.reduceColor ? ColorUtil.theme.fontColor : UIColor.white]
            self.navigationController?.navigationBar.standardAppearance.shadowColor = UIColor.clear

            self.navigationController?.navigationBar.compactAppearance = UINavigationBarAppearance()
            self.navigationController?.navigationBar.compactAppearance?.configureWithOpaqueBackground()
            self.navigationController?.navigationBar.compactAppearance?.backgroundColor = overrideColor ?? ColorUtil.getColorForSub(sub: "", true)
            self.navigationController?.navigationBar.compactAppearance?.titleTextAttributes = [NSAttributedString.Key.foregroundColor: SettingValues.reduceColor ? ColorUtil.theme.fontColor : UIColor.white]
        } else {
            navigationController?.navigationBar.barTintColor = overrideColor ?? ColorUtil.getColorForSub(sub: "", true)
            let textAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): SettingValues.reduceColor ? ColorUtil.theme.fontColor : .white]
            navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary(textAttributes)
        }
        
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()
        
        navigationController?.navigationBar.tintColor = SettingValues.reduceColor ? ColorUtil.theme.fontColor : UIColor.white
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

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}
