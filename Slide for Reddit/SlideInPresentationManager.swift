//
//  SlideInPresentationManager.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

enum PresentationDirection {
    case left
    case top
    case right
    case bottom
}

class SlideInPresentationManager: NSObject {

    var direction = PresentationDirection.left
    var coverageRatio: CGFloat = 0.66

}

extension SlideInPresentationManager: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        let presentationController = SlideInPresentationController(presentedViewController: presented,
                                                                   presenting: presenting,
                                                                   direction: direction,
                                                                   coverageRatio: coverageRatio)
        return presentationController
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInPresentationAnimator(direction: direction, isPresentation: true)
    }

    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return SlideInPresentationAnimator(direction: direction, isPresentation: false)
    }
}
