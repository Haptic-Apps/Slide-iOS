//
//  SlideInPresentationController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

class SlideInPresentationController: UIPresentationController {

    private var dimmingView: UIView!
    private var direction: PresentationDirection
    private var coverageRatio: CGFloat

    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         direction: PresentationDirection,
         coverageRatio: CGFloat) {
        self.direction = direction
        self.coverageRatio = coverageRatio

        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)

        setupDimmingView()
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        switch direction {
        case .left, .right:
            return CGSize(width: parentSize.width * coverageRatio, height: parentSize.height)
        case .bottom, .top:
            return CGSize(width: parentSize.width, height: parentSize.height * coverageRatio)
        }
    }

    override var frameOfPresentedViewInContainerView: CGRect {

        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController,
                          withParentContainerSize: containerView!.bounds.size)

        switch direction {
        case .right:
            frame.origin.x = containerView!.frame.width * (CGFloat(1.0) - coverageRatio)
        case .bottom:
            frame.origin.y = containerView!.frame.height * (CGFloat(1.0) - coverageRatio)
        default:
            frame.origin = .zero
        }
        return frame
    }

    override func presentationTransitionWillBegin() {

        containerView?.insertSubview(dimmingView, at: 0)

        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView]))

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }

}

// MARK: - Private
private extension SlideInPresentationController {
    func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        dimmingView.alpha = 0.0
        let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
        let blurView = UIVisualEffectView(frame: UIScreen.main.bounds)
        blurEffect.setValue(5, forKeyPath: "blurRadius")
        blurView.effect = blurEffect
        dimmingView.insertSubview(blurView, at: 0)

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        dimmingView.addGestureRecognizer(recognizer)
    }

    @objc dynamic func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }
}
