//
//  UITabBarController+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/6/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UITabBarController {
    override func topMostViewController() -> UIViewController {
        return self.selectedViewController!.topMostViewController()
    }
}
