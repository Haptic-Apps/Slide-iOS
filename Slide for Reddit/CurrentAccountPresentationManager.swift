//
//  CurrentAccountPresentationManager.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 1/11/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import UIKit

class CurrentAccountPresentationManager: NSObject {

}

extension CurrentAccountPresentationManager: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let presentationController = CurrentAccountPresentationController(presentedViewController: presented,
                                                                          presenting: presenting)
        return presentationController
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let accountVC = presented as? CurrentAccountViewController else {
            return nil
        }
        return CurrentAccountPresentationAnimator(isPresentation: true, interactionController: accountVC.interactionController)
    }

    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            guard let accountVC = dismissed as? CurrentAccountViewController else {
                return nil
            }
            return CurrentAccountPresentationAnimator(isPresentation: false, interactionController: accountVC.interactionController)
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let animator = animator as? CurrentAccountPresentationAnimator,
            let interactionController = animator.interactionController,
            interactionController.interactionInProgress
            else {
                return nil
        }
        return interactionController
    }
}
