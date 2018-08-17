//
//  SlideInPresentationManager.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

class BottomSheetPresentationManager: UIPercentDrivenInteractiveTransition, UIGestureRecognizerDelegate {
    var direction = PresentationDirection.left
    var coverageRatio: CGFloat = 0.66
    var presenting: Bool = false

    /// True when the pan gesture is active.
    fileprivate var interactive: Bool = false

    weak var draggingView: UIView? {
        didSet {
            self.draggingView?.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
       return scrollView?.contentOffset.y ?? 0 == 0
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UIPanGestureRecognizer
    }
    
    weak var scrollView: UITableView? {
        didSet {
            self.panGestureRecognizer.delegate = self
        }
    }

    weak var menuViewController: UIViewController?

    fileprivate var panGestureRecognizer: UIPanGestureRecognizerWithInitialTouch!

    override init() {
        super.init()

        panGestureRecognizer = UIPanGestureRecognizerWithInitialTouch(target: self, action: #selector(handlePan(_:)))
        panGestureRecognizer.direction = .vertical
    }
}

extension BottomSheetPresentationManager: UIViewControllerTransitioningDelegate {
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
        self.presenting = true
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}

// MARK: - Actions
extension BottomSheetPresentationManager {

    @objc func handlePan(_ sender: UIPanGestureRecognizerWithInitialTouch) {
        // Ignore the gesture if it didn't originate in the draggable area of the view
        //guard let draggingView = draggingView,
       //     draggingView.frame.contains(sender.initialTouchLocation) else {
       //         return
       // }

        guard let menuVC = menuViewController as? NavigationSidebarViewController,
            let menuView = menuVC.view else {
            return
        }

        // Hide the keyboard if it's out
        if menuVC.header.search.isFirstResponder {
            menuVC.header.search.resignFirstResponder()
        }

        switch sender.state {
        case .began:
            self.interactive = true
            menuVC.dismiss(animated: true, completion: nil)

        case .changed:
            let translation = sender.translation(in: menuView)
            let progress = translation.y / menuView.bounds.height
            self.update(progress)

        default:
            self.interactive = false

            let velocity = sender.velocity(in: menuView).y
            if percentComplete > 0.3 || velocity > 350 {
                self.finish()
            } else {
                self.cancel()
            }
        }

    }

}

extension BottomSheetPresentationManager: UIViewControllerAnimatedTransitioning {
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = presenting ? UITransitionContextViewControllerKey.to
            : UITransitionContextViewControllerKey.from

        let controller = transitionContext.viewController(forKey: key)!

        if presenting {
            transitionContext.containerView.addSubview(controller.view)
        }

        let presentedFrame = transitionContext.finalFrame(for: controller)
        var dismissedFrame = presentedFrame
        switch direction {
        case .left:
            dismissedFrame.origin.x = -presentedFrame.width
        case .right:
            dismissedFrame.origin.x = transitionContext.containerView.frame.size.width
        case .top:
            dismissedFrame.origin.y = -presentedFrame.height
        case .bottom:
            dismissedFrame.origin.y = transitionContext.containerView.frame.size.height
        }

        let initialFrame = presenting ? dismissedFrame : presentedFrame
        let finalFrame = presenting ? presentedFrame : dismissedFrame

        // Runs when the animation finishes
        let completionBlock: (Bool) -> Void = { (finished) in
            // tell our transitionContext object that we've finished animating
            if transitionContext.transitionWasCancelled {
                if self.interactive {
                    transitionContext.cancelInteractiveTransition()
                }
                transitionContext.completeTransition(false)
            } else {
                if self.interactive {
                    finished ? transitionContext.finishInteractiveTransition() : transitionContext.cancelInteractiveTransition()
                }
                transitionContext.completeTransition(finished)
            }
        }

        // Put what you want to animate here.
        let animationBlock: () -> Void = {
            controller.view.frame = finalFrame
        }

        // Set up for the animation
        let animationDuration = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame

        // Perform a different animation based on whether we're interactive (performing a gesture) or not
        if interactive {
            // Do a linear animation so we match our dragging with our transition
            UIView.animate(withDuration: animationDuration,
                           delay: 0,
                           options: .curveLinear,
                           animations: animationBlock,
                           completion: completionBlock)

        } else {
            // Do a spring animation with easing
            UIView.animate(withDuration: animationDuration,
                           delay: 0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.45,
                           options: .curveEaseInOut,
                           animations: animationBlock,
                           completion: completionBlock)
        }

    }
}

// https://stackoverflow.com/a/43925463/7138792
class UIPanGestureRecognizerWithInitialTouch: UIPanGestureRecognizer {
    var initialTouchLocation: CGPoint!

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        initialTouchLocation = touches.first!.location(in: view)
    }
}
