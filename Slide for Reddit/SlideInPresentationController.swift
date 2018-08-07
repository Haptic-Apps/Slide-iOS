//
//  SlideInPresentationController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

class SlideInPresentationController: UIPresentationController {

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
}
