//
//  UIWindow+RootViewController.swift
//  Swiftilities
//
//  Created by Nicholas Bonatsakis on 2/5/16.
//  Copyright © 2016 Raizlabs. All rights reserved.
//
import UIKit

/**
 *  UIWindow extension for setting the rootViewController on a UIWindow instance in a safe and animatable way.
 */
public extension UIWindow {

    /**
     Set the rootViewController on this UIWindow instance.
     - parameter viewController: The view controller to set
     - parameter animated:       Whether or not to animate the transition, animation is a cross-fade
     - parameter completion:     Completion block to be invoked after the transition finishes
     */
    @nonobjc func setRootViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void = {}) {
        let previousRootViewController = rootViewController
        let updateViewController = {
            // Disabling animation prevents layout and visual issues during the transition
            UIView.performWithoutAnimation {
                self.rootViewController = viewController
            }
        }
        let removePreviousAndExecuteCompletion = { (_: Bool) in
            // If a view controller is currently presented, it must be dismissed as a separate step
            // than the swapping of the root VC of the window.
            // Failure to do this appears to result in a retain cycle in the orphaned VC stack.
            previousRootViewController?.dismiss(animated: false, completion: nil)
            previousRootViewController?.view.removeFromSuperview()
            completion()
        }
        if animated && previousRootViewController != nil {
            UIView.transition(with: self,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: updateViewController,
                              completion: removePreviousAndExecuteCompletion)
        } else {
            updateViewController()
            removePreviousAndExecuteCompletion(true)
        }
    }
}
