//
//  ProfileInfoDismissInteraction.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/15/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import UIKit

class ProfileInfoDismissInteraction: UIPercentDrivenInteractiveTransition {
    var interactionInProgress = false

    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!
    private var storedHeight: CGFloat = 400

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
        let vc = viewController as! ProfileInfoViewController

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
            shouldCompleteTransition = progress > 0.5 || velocity.y > 1000
            update(progress)
        case .cancelled:
            interactionInProgress = false
            cancel()
        case .ended:
            interactionInProgress = false
            shouldCompleteTransition ? finish() : cancel()
        default:
            break
        }
    }

}
