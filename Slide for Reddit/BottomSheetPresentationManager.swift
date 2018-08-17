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
        //        return DismissAnimator()
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

        // Hide the keyboard
        if let menuVC = menuViewController as? NavigationSidebarViewController, menuVC.header.search.isFirstResponder {
            menuVC.header.search.resignFirstResponder()
        }

        //        menuViewController!.view.center =
        // how much distance have we panned in reference to the parent view?
        let translation = sender.translation(in: menuViewController!.view!)

        // do some math to translate this to a percentage based value
        let d = translation.y / menuViewController!.view!.bounds.height

        // now lets deal with different states that the gesture recognizer sends
        switch sender.state {
        case .began:
            menuViewController?.dismiss(animated: true, completion: nil)
        case .changed:
            self.update(d)
        default: // .Ended, .Cancelled, .Failed ...
            if d > 0.15 {
                // threshold crossed: finish
                self.finish()
            } else {
                // threshold not met: cancel
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

        let animationDuration = transitionDuration(using: transitionContext)
        controller.view.frame = initialFrame
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.45, options: .curveEaseInOut, animations: {
            controller.view.frame = finalFrame
        }) {
            (finished) in
            // tell our transitionContext object that we've finished animating
            if transitionContext.transitionWasCancelled {
                transitionContext.completeTransition(false)
            } else {
                transitionContext.completeTransition(finished)
            }

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
