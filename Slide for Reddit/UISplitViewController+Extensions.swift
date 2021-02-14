//
//  UISplitViewController+Extensions.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 2/13/21.
//  Copyright © 2021 Haptic Apps. All rights reserved.
//

import Foundation

extension UISplitViewController {
    open override var childForStatusBarHidden: UIViewController? {
        return viewControllers.last
    }
}
