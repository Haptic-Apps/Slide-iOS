//
//  PostContentPresentationAnimator.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

final class PostContentPresentationAnimator: NSObject {
    // MARK: - Properties
    let isPresentation: Bool

    // MARK: - Initializers
    init(isPresentation: Bool) {
        self.isPresentation = isPresentation
        super.init()
    }
}

extension PostContentPresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresentation ? UITransitionContextViewControllerKey.to
            : UITransitionContextViewControllerKey.from

        let controller = transitionContext.viewController(forKey: key)!

        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }

        let initialAlpha: CGFloat = isPresentation ? 0.0 : 1.0
        let finalAlpha: CGFloat = isPresentation ? 1.0 : 0.0

        let animationDuration = transitionDuration(using: transitionContext)

        // Use a special animation chain for certain types of presenting VCs
        if let vc = controller as? ModalMediaViewController,
            let _ = vc.embeddedVC as? ImageMediaViewController {

            controller.view.alpha = initialAlpha
            UIView.animate(withDuration: animationDuration, animations: {
                controller.view.alpha = finalAlpha
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })

        } else {
            controller.view.alpha = initialAlpha
            UIView.animate(withDuration: animationDuration, animations: {
                controller.view.alpha = finalAlpha
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        }
    }
}
