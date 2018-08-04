//
//  PostContentPresentationController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import AVFoundation
import UIKit

class PostContentPresentationController: UIPresentationController {

    private var sourceImageView: UIView

    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         sourceImageView: UIView) {
        self.sourceImageView = sourceImageView

        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    func transformFromRect(from source: CGRect, toRect destination: CGRect) -> CGAffineTransform {
        return CGAffineTransform.identity
            .translatedBy(x: destination.midX - source.midX, y: destination.midY - source.midY)
            .scaledBy(x: destination.width / source.width, y: destination.height / source.height)
    }

    override func presentationTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            return
        }

        if let vc = self.presentedViewController as? ModalMediaViewController {

            let image = (sourceImageView as! UIImageView).image!
            let fromRect = vc.view.convert(sourceImageView.bounds, from: sourceImageView)

            if let embeddedVC = vc.embeddedVC as? ImageMediaViewController {

                presentingViewController.view.layoutIfNeeded()

                let inner = AVMakeRect(aspectRatio: embeddedVC.imageView.bounds.size, insideRect: embeddedVC.view.bounds)
                let toRect = vc.view.convert(inner, from: embeddedVC.scrollView)

                let newTransform = transformFromRect(from: toRect, toRect: fromRect)

                embeddedVC.scrollView.transform = embeddedVC.scrollView.transform.concatenating(newTransform)
                coordinator.animate(alongsideTransition: { _ in
                    embeddedVC.scrollView.transform = CGAffineTransform.identity
                })

            } else if let embeddedVC = vc.embeddedVC as? VideoMediaViewController {

                if embeddedVC.isYoutubeView {

                } else {
                    presentingViewController.view.layoutIfNeeded()

                    let inner = AVMakeRect(aspectRatio: image.size, insideRect: embeddedVC.view.bounds)
                    let toRect = vc.view.convert(inner, from: embeddedVC.view)

                    let newTransform = transformFromRect(from: toRect, toRect: fromRect)

                    embeddedVC.videoView.transform = embeddedVC.videoView.transform.concatenating(newTransform)
                    coordinator.animate(alongsideTransition: { _ in
                        embeddedVC.videoView.transform = CGAffineTransform.identity
                    })
                }
            }
        }
    }

}
