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
        guard let sourceImageView = sourceImageView else {
            fatalError("SourceImageView must be specified!")
        }

        let presentationController = PostContentPresentationController(presentedViewController: presented,
                                                                   presenting: presenting,
                                                                   sourceImageView: sourceImageView)
        return presentationController
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let sourceImageView = sourceImageView else {
            fatalError("SourceImageView must be specified!")
        }
        return PostContentPresentationAnimator(isPresentation: true, sourceImageView: sourceImageView)
    }

    func animationController(forDismissed dismissed: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            guard let sourceImageView = sourceImageView else {
                fatalError("SourceImageView must be specified!")
            }
            return PostContentPresentationAnimator(isPresentation: false, sourceImageView: sourceImageView)
    }
}
