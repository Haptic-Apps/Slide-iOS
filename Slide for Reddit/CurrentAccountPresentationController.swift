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
    }

    override func size(forChildContentContainer container: UIContentContainer,
                       withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: parentSize.width, height: parentSize.height)
    }

    override func presentationTransitionWillBegin() {
        let accountView = presentedViewController as! CurrentAccountViewController

        if let containerView = containerView {
            containerView.addSubview(dimmingView)
            accountView.view.removeFromSuperview() // TODO: Risky?
            dimmingView.contentView.addSubview(accountView.view)
            dimmingView.edgeAnchors == containerView.edgeAnchors
        }

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.effect = blurEffect
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.effect = self.blurEffect
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.effect = nil
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.effect = nil
        })
    }

    lazy var blurEffect: UIBlurEffect = {
//        let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
//        blurEffect.setValue(5, forKeyPath: "blurRadius")
//        return blurEffect

        return UIBlurEffect(style: .dark)
    }()

}

// MARK: - Private
private extension CurrentAccountPresentationController {
    func setupDimmingView() {
        dimmingView = UIVisualEffectView(frame: UIScreen.main.bounds).then {
            $0.effect = nil
//            $0.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        }

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        dimmingView.addGestureRecognizer(recognizer)
    }

    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }
}
