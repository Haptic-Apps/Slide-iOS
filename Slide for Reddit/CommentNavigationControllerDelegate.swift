//
//  CommentNavigationControllerDelegate.swift
//  Slide for Reddit
//
//  Created by Josiah Agosto on 8/2/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import UIKit

extension CommentViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Fixes bug with corrupt nav stack
        // https://stackoverflow.com/a/39457751/7138792
        navigationController.interactivePopGestureRecognizer?.isEnabled = navigationController.viewControllers.count > 1
        if navigationController.viewControllers.count == 1 {
            self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}
