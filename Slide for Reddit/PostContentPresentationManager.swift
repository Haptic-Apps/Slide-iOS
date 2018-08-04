//
//  PostContentPresentationManager.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

class PostContentPresentationManager: NSObject {
    var sourceImageView: UIView?
}

extension PostContentPresentationManager: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        if let sourceImageView = sourceImageView {
            let presentationController = PostContentPresentationController(presentedViewController: presented,
                                                                       presenting: presenting,
                                                                       sourceImageView: sourceImageView)
            return presentationController
        } else {
            fatalError("SourceImageView must be specified!")
        }
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PostContentPresentationAnimator(isPresentation: true)
    }

    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            return PostContentPresentationAnimator(isPresentation: false)
    }
}
