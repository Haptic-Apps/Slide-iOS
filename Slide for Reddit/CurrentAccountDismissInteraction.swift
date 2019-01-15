//
//  CurrentAccountDismissInteraction.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 1/11/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import UIKit

class CurrentAccountDismissInteraction: UIPercentDrivenInteractiveTransition {
    var interactionInProgress = false

    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!
    private var storedHeight: CGFloat = 1

    init(viewController: UIViewController) {
        super.init()
        self.viewController = viewController
        prepareGestureRecognizer(in: viewController.view)
    }

    private func prepareGestureRecognizer(in view: UIView) {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.direction = UIPanGestureRecognizer.Direction.vertical
        view.addGestureRecognizer(gesture)
    }

    @objc func handleGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let vc = viewController as! CurrentAccountViewController

        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        let velocity = gestureRecognizer.velocity(in: gestureRecognizer.view!.superview!)
        var progress = min(max(0, translation.y), storedHeight) / storedHeight
        progress = max(min(progress, 1), 0) // Clamp between 0 and 1

        switch gestureRecognizer.state {
        case .began:
            interactionInProgress = true
            viewController.dismiss(animated: true, completion: nil)
            storedHeight = vc.contentViewHeight
        case .changed:
            shouldCompleteTransition = progress > 0.25 || velocity.y > 1000
            update(progress)
        case .cancelled:
            interactionInProgress = false
            cancel()
        case .ended:
            interactionInProgress = false
            if shouldCompleteTransition {
                finish()
            } else {
                cancel()
            }
        default:
            break
        }
    }

}