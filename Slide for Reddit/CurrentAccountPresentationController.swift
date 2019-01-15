//
//  CurrentAccountPresentationController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 1/11/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import Then
import UIKit

class CurrentAccountPresentationController: UIPresentationController {

    fileprivate var dimmingView: UIVisualEffectView!

    // Mirror Manager params here

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {

        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)

        setupDimmingView()
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
        dimmingView.frame = frameOfPresentedViewInContainerView
    }

    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: parentSize.width, height: parentSize.height)
    }

    override func presentationTransitionWillBegin() {
        let accountView = presentedViewController as! CurrentAccountViewController

        if let containerView = containerView {
            containerView.insertSubview(dimmingView, at: 0)
//            accountView.view.removeFromSuperview() // TODO: Risky?
            containerView.addSubview(accountView.view)
        }

        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.effect = self.blurEffect
            })
        } else {
            dimmingView.effect = blurEffect
        }
    }

    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.effect = nil
            })
        } else {
            dimmingView.effect = nil
        }
    }

    lazy var blurEffect: UIBlurEffect = {
        return UIBlurEffect(style: .dark)
    }()

}

// MARK: - Private
private extension CurrentAccountPresentationController {
    func setupDimmingView() {
        dimmingView = UIVisualEffectView(frame: UIScreen.main.bounds).then {
            $0.effect = nil
        }
    }
}
