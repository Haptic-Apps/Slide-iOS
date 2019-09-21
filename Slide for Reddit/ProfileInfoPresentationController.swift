//
//  ProfileInfoPresentationController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/15/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import Then
import UIKit

class ProfileInfoPresentationController: UIPresentationController {

    fileprivate var dimmingView: UIVisualEffectView!
    fileprivate var backgroundView: UIView!

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
        backgroundView.frame = frameOfPresentedViewInContainerView
    }

    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: parentSize.width, height: parentSize.height)
    }

    override func presentationTransitionWillBegin() {
        let accountView = presentedViewController as! ProfileInfoViewController

        if let containerView = containerView {
            containerView.insertSubview(dimmingView, at: 0)
            containerView.insertSubview(backgroundView, at: 0)
//            accountView.view.removeFromSuperview() // TODO: Risky?
            containerView.addSubview(accountView.view)
        }

        if presentedViewController.transitionCoordinator != nil {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.dimmingView.effect = self.blurEffect
            })
        } else {
            dimmingView.effect = blurEffect
        }
    }

    override func dismissalTransitionWillBegin() {
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.dimmingView.alpha = 0
                self.backgroundView.alpha = 0
            }, completion: { _ in
                self.dimmingView.alpha = 1
                self.backgroundView.alpha = 0.7
            })
        } else {
            dimmingView.effect = nil
        }
    }

    lazy var blurEffect: UIBlurEffect = {
        return (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init().then {
            $0.setValue(5, forKeyPath: "blurRadius")
        }
    }()

}

// MARK: - Private
private extension ProfileInfoPresentationController {
    func setupDimmingView() {
        backgroundView = UIView(frame: UIScreen.main.bounds).then {
            $0.backgroundColor = .black
            $0.alpha = 0.7
        }
        dimmingView = UIVisualEffectView(frame: UIScreen.main.bounds).then {
            $0.effect = nil
        }
    }
}
