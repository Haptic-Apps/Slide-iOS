//
//  CurrentAccountPresentationAnimator.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 1/11/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import UIKit

final class CurrentAccountPresentationAnimator: NSObject {

    let isPresentation: Bool
    var interactionController: CurrentAccountDismissInteraction?

    init(isPresentation: Bool, interactionController: CurrentAccountDismissInteraction?) {
        self.isPresentation = isPresentation
        self.interactionController = interactionController
        super.init()
    }
}

extension CurrentAccountPresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresentation ? 0.4 : 0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresentation ? UITransitionContextViewControllerKey.to
            : UITransitionContextViewControllerKey.from
        guard let controller = transitionContext.viewController(forKey: key)! as? CurrentAccountViewController else {
            fatalError("Presented view controller must be an instance of CurrentAccountViewController!")
        }

        controller.view.layoutSubviews()

        let presentedContentViewFrame = controller.contentView.frame
        var dismissedContentViewFrame = presentedContentViewFrame
        dismissedContentViewFrame.origin.y = transitionContext.containerView.frame.size.height + controller.outOfBoundsHeight
        let initialContentViewFrame = isPresentation ? dismissedContentViewFrame : presentedContentViewFrame
        let finalContentViewFrame = isPresentation ? presentedContentViewFrame : dismissedContentViewFrame
        controller.contentView.frame = initialContentViewFrame

        // Use this offset for any other elements you need to vertically animate alongside the content view
        let deltaY = dismissedContentViewFrame.origin.y - presentedContentViewFrame.origin.y

        let presentedUpperButtonStackFrame = controller.upperButtonStack.frame
        var dismissedUpperButtonStackFrame = presentedUpperButtonStackFrame
        dismissedUpperButtonStackFrame.origin.y += deltaY
        let initialUpperButtonStackFrame = isPresentation ? dismissedUpperButtonStackFrame : presentedUpperButtonStackFrame
        let finalUpperButtonStackFrame = isPresentation ? presentedUpperButtonStackFrame : dismissedUpperButtonStackFrame
        controller.upperButtonStack.frame = initialUpperButtonStackFrame

        var curve = UIView.AnimationOptions.curveEaseInOut
        var spring = CGFloat(0.7)
        var initial = CGFloat(1.4)
        if let interactionController = interactionController,
            interactionController.interactionInProgress {
            curve = UIView.AnimationOptions.curveLinear
            spring = 0
            initial = 0
        }
        if !isPresentation {
            spring = 0
        }
        if spring == 0 {
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                           delay: 0,
                           options: curve,
                           animations: {
                            controller.closeButton.alpha = self.isPresentation ? 1 : 0
                            controller.settingsButton.alpha = self.isPresentation ? 1 : 0
                            controller.contentView.frame = finalContentViewFrame
                            controller.upperButtonStack.frame = finalUpperButtonStackFrame
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })

        } else {
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                delay: 0,
                usingSpringWithDamping: spring,
                initialSpringVelocity: initial,
                options: curve,
                animations: {
                controller.closeButton.alpha = self.isPresentation ? 1 : 0
                controller.settingsButton.alpha = self.isPresentation ? 1 : 0
                controller.contentView.frame = finalContentViewFrame
                controller.upperButtonStack.frame = finalUpperButtonStackFrame
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}
