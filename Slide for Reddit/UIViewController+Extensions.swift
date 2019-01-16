//
//  UIViewController+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/6/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UIViewController {
    func setupBaseBarColors(_ overrideColor: UIColor? = nil) {
        navigationController?.navigationBar.barTintColor = overrideColor ?? ColorUtil.getColorForSub(sub: "", true)
        navigationController?.navigationBar.tintColor = SettingValues.reduceColor ? ColorUtil.fontColor : UIColor.white
        let textAttributes = [convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): SettingValues.reduceColor ? ColorUtil.fontColor : .white]
        navigationController?.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary(textAttributes)
        if SettingValues.reduceColor && ColorUtil.theme.isLight() {
            UIApplication.shared.statusBarStyle = .default
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
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
