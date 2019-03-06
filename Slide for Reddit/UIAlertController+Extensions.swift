//
//  UIAlertController+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/24/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import SDCAlertView

public extension AlertController {
    func showWindowless() {
        let win = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        win.rootViewController = vc
        win.windowLevel = UIWindow.Level.alert + 1
        win.makeKeyAndVisible()
        vc.present(self, animated: true, completion: nil)
    }
}
public extension UIAlertController {
    func showWindowless() {
        let win = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        win.rootViewController = vc
        win.windowLevel = UIWindow.Level.alert + 1
        win.makeKeyAndVisible()
        vc.present(self, animated: true, completion: nil)
    }
}
