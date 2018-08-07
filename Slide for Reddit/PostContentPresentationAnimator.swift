//
//  PostContentPresentationAnimator.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import AVFoundation
import UIKit

final class PostContentPresentationAnimator: NSObject {
    // MARK: - Properties
    let isPresentation: Bool

    let sourceImageView: UIView

    // MARK: - Initializers
    init(isPresentation: Bool, sourceImageView: UIView) {
        self.isPresentation = isPresentation
        self.sourceImageView = sourceImageView
        super.init()
    }
}

extension PostContentPresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    private func transformFromRect(from source: CGRect, toRect destination: CGRect) -> CGAffineTransform {
        return CGAffineTransform.identity
            .translatedBy(x: destination.midX - source.midX, y: destination.midY - source.midY)
            .scaledBy(x: destination.width / source.width, y: destination.height / source.height)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresentation ? UITransitionContextViewControllerKey.to
            : UITransitionContextViewControllerKey.from

        let animationDuration = transitionDuration(using: transitionContext)

        let controller = transitionContext.viewController(forKey: key)!

        if isPresentation {
            transitionContext.containerView.addSubview(controller.view)
        }

        let presentingViewController = transitionContext.viewController(forKey: .from)!
        let presentedViewController = transitionContext.viewController(forKey: .to)!

        // Animate picture

        if let vc = presentedViewController as? ModalMediaViewController {

            let image = (sourceImageView as! UIImageView).image!
            let fromRect = vc.view.convert(sourceImageView.bounds, from: sourceImageView)

            if let embeddedVC = vc.embeddedVC as? ImageMediaViewController {

                presentingViewController.view.layoutIfNeeded()

                let inner = AVMakeRect(aspectRatio: embeddedVC.imageView.bounds.size, insideRect: embeddedVC.view.bounds)
                let toRect = vc.view.convert(inner, from: embeddedVC.scrollView)

                let newTransform = transformFromRect(from: toRect, toRect: fromRect)

                embeddedVC.scrollView.transform = embeddedVC.scrollView.transform.concatenating(newTransform)
                let storedZ = embeddedVC.scrollView.layer.zPosition
                embeddedVC.scrollView.layer.zPosition = sourceImageView.layer.zPosition

                UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                    embeddedVC.scrollView.transform = CGAffineTransform.identity
                    embeddedVC.scrollView.layer.zPosition = storedZ
                })

            } else if let embeddedVC = vc.embeddedVC as? VideoMediaViewController {

                if embeddedVC.isYoutubeView {

                } else {
                    presentingViewController.view.layoutIfNeeded()

                    let translatedView = embeddedVC.progressView.isHidden ? embeddedVC.videoView : embeddedVC.progressView

                    let inner = AVMakeRect(aspectRatio: translatedView.bounds.size, insideRect: embeddedVC.view.bounds)
                    let toRect = vc.view.convert(inner, from: embeddedVC.view)

                    let newTransform = transformFromRect(from: toRect, toRect: fromRect)
                    let storedZ = translatedView.layer.zPosition
                    translatedView.layer.zPosition = sourceImageView.layer.zPosition

                    translatedView.transform = translatedView.transform.concatenating(newTransform)
                    UIView.animate(withDuration: animationDuration) {
                        translatedView.transform = CGAffineTransform.identity
                        translatedView.layer.zPosition = storedZ
                    }
                }
            }
        }

        // Animate alpha
        
        var isVideo = false
        if let vc = controller as? ModalMediaViewController, vc.embeddedVC is VideoMediaViewController {
            isVideo = true
        }

        let initialAlpha: CGFloat = isPresentation ? 0.0 : 1.0
        let finalAlpha: CGFloat = isPresentation ? (isVideo ? 1.0 : 0.6) : 0.0

        // Use a special animation chain for certain types of presenting VCs
        if let vc = controller as? ModalMediaViewController,
            let embed = vc.embeddedVC as? EmbeddableMediaViewController {

            vc.background?.alpha = initialAlpha
            vc.blurView?.alpha = initialAlpha
            embed.bottomButtons.alpha = initialAlpha
            embed.navigationBar.alpha = initialAlpha
            UIView.animate(withDuration: animationDuration, animations: {
                vc.background?.alpha = finalAlpha
                embed.bottomButtons.alpha = 1
                embed.navigationBar.alpha = 1
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })

        } else {
            controller.view.alpha = initialAlpha
            UIView.animate(withDuration: animationDuration, animations: {
                controller.view.alpha = finalAlpha
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        }
    }
}
