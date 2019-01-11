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
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresentation ? UITransitionContextViewControllerKey.to
            : UITransitionContextViewControllerKey.from
        guard let controller = transitionContext.viewController(forKey: key)! as? CurrentAccountViewController else {
            fatalError("Presented view controller must be an instance of CurrentAccountViewController!")
        }

        controller.view.layoutSubviews()

        let yForPuttingContentTopEdgeAtScreenBottom = transitionContext.containerView.frame.size.height + (controller.contentView.frame.origin.y - controller.accountImageView.frame.origin.y) // Height of picture frame outside of contentView

        let presentedContentViewFrame = controller.contentView.frame
        var dismissedContentViewFrame = presentedContentViewFrame
        dismissedContentViewFrame.origin.y = yForPuttingContentTopEdgeAtScreenBottom

        let initialContentViewFrame = isPresentation ? dismissedContentViewFrame : presentedContentViewFrame
        let finalContentViewFrame = isPresentation ? presentedContentViewFrame : dismissedContentViewFrame

        let presentedUpperButtonStackFrame = controller.upperButtonStack.frame
        var dismissedUpperButtonStackFrame = presentedUpperButtonStackFrame
        dismissedUpperButtonStackFrame.origin.y = yForPuttingContentTopEdgeAtScreenBottom - (controller.contentView.frame.origin.y - controller.upperButtonStack.frame.origin.y)

        let initialUpperButtonStackFrame = isPresentation ? dismissedUpperButtonStackFrame : presentedUpperButtonStackFrame
        let finalUpperButtonStackFrame = isPresentation ? presentedUpperButtonStackFrame : dismissedUpperButtonStackFrame

        controller.contentView.frame = initialContentViewFrame
        controller.upperButtonStack.frame = initialUpperButtonStackFrame

        var curve = UIViewAnimationOptions.curveEaseInOut
        if let interactionController = interactionController,
            interactionController.interactionInProgress {
            curve = UIViewAnimationOptions.curveLinear
        }

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
    }
}
