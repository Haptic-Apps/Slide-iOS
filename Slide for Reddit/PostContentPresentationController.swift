//
//  PostContentPresentationController.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

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
        if let vc = self.presentedViewController as? ModalMediaViewController,
            let embeddedVC = vc.embeddedVC as? ImageMediaViewController {

            presentingViewController.view.layoutIfNeeded()

            guard let coordinator = presentedViewController.transitionCoordinator else {
                return
            }

            let storedTransform = embeddedVC.imageView.transform

            // I'm so sorry

            let image = (sourceImageView as! UIImageView).image!
//            embeddedVC.imageView.image = (sourceImageView as! UIImageView).image
//            embeddedVC.view.layoutIfNeeded()

//            let relative = vc.view.convert(sourceImageView.frame, to: embeddedVC.view)
            let world1 = vc.view.convert(sourceImageView.bounds, from: sourceImageView)
            let f = embeddedVC.scrollView.convert(embeddedVC.imageView.bounds, to: embeddedVC.view)
//            let world2 = vc.view.convert(embeddedVC.imageView.bounds, from: embeddedVC.view)

            let widthScale = vc.view.bounds.size.width / image.size.width
            let heightScale = vc.view.bounds.size.height / image.size.height
            let minScale = min(widthScale, heightScale)

//            var origin = embeddedVC.scrollView.contentOffset
//            var size = embeddedVC.scrollView.bounds.size
//            let scale = CGFloat(1.0) / embeddedVC.scrollView.zoomScale
//            if scale < CGFloat(1.0) {
//                origin.x *= scale
//                origin.y *= scale
//                size.width *= scale
//                size.height *= scale
//            }
//            let visibleRect = CGRect(origin: origin, size: size)

            let inner = CGRect(x: 0, y: (embeddedVC.view.bounds.size.height / 2.0) - ((image.size.height / 2.0) * minScale), width: image.size.width * minScale, height: image.size.height * minScale)
            let world2 = vc.view.convert(inner, from: embeddedVC.scrollView)

            // OR: embeddedVC.scrollView.convert(embeddedVC.scrollView.bounds, to: embeddedVC.scrollView)

            //let world2 = visibleRect
//            let relative = sourceImageView.convert(sourceImageView.bounds, to: embeddedVC.scrollView)
            //let relative = presentedView!.convert(sourceImageView.frame, from: embeddedVC.view)

//            let newTransform = storedTransform.concatenating(CGAffineTransform(translationX: -1000, y: 0))//.concatenating(CGAffineTransform(rotationAngle: CGFloat.pi))
//            let newTransform = transformFromRect(from: embeddedVC.imageView.frame, toRect: relative)

            let newTransform = transformFromRect(from: world2, toRect: world1)

//            let newTransform = transformFromRect(from: world1, toRect: <#T##CGRect#>)

//            let stored3DTransform = embeddedVC.imageView.layer.transform
//            let new3DTransform = CATransform3DMakeAffineTransform(newTransform)

            embeddedVC.scrollView.transform = newTransform //storedTransform.concatenating(newTransform)
            coordinator.animate(alongsideTransition: { _ in
                embeddedVC.scrollView.transform = CGAffineTransform.identity
            })

        }
    }

}
