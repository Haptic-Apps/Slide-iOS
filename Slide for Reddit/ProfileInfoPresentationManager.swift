//
//  ProfileInfoPresentationManager.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/15/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import UIKit

class ProfileInfoPresentationManager: NSObject {

}

extension ProfileInfoPresentationManager: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let presentationController = ProfileInfoPresentationController(presentedViewController: presented,
                                                                          presenting: presenting)
        return presentationController
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let accountVC = presented as? ProfileInfoViewController else {
            return nil
        }
        return ProfileInfoPresentationAnimator(isPresentation: true, interactionController: accountVC.interactionController)
    }

    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            guard let accountVC = dismissed as? ProfileInfoViewController else {
                return nil
            }
            return ProfileInfoPresentationAnimator(isPresentation: false, interactionController: accountVC.interactionController)
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let animator = animator as? ProfileInfoPresentationAnimator,
            let interactionController = animator.interactionController,
            interactionController.interactionInProgress
            else {
                return nil
        }
        return interactionController
    }
}
