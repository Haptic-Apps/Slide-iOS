//
//  SwipeForwardAnimatedTransitioning.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/18/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//  Swift code based on Christopher Wendel  https://github.com/CEWendel/SWNavigationController/blob/master/SWNavigationController/PodFiles/SWPushAnimatedTransitioning.m
//

import UIKit

let kSWToLayerShadowRadius = CGFloat(5)
let kSWToLayerShadowOpacity = CGFloat(0.25)
let kSWFromLayerShadowOpacity = CGFloat(0.1)
let kSWPushTransitionDuration = CGFloat(0.2)

class SwipeForwardAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        if let toView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)?.view, let fromView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)?.view {
            
            let containerViewWidth = containerView.frame.size.width
            var snapshotToView = toView.snapshotView(afterScreenUpdates: true)
            
            if snapshotToView != nil {
                containerView.addSubview(snapshotToView!)
                
                var fromViewFinalFrame = fromView.frame
                fromViewFinalFrame.origin.x = -containerViewWidth/3.0
                
                var toViewFinalFrame = toView.frame
                toViewFinalFrame.origin.x = containerViewWidth
                
                snapshotToView!.frame = toViewFinalFrame
                snapshotToView!.layer.shadowRadius = kSWToLayerShadowRadius
                snapshotToView!.layer.shadowOpacity = Float(kSWFromLayerShadowOpacity)
                
                let shadowFrame = snapshotToView!.layer.bounds
                let shadowPath = UIBezierPath(rect: shadowFrame).cgPath
                snapshotToView!.layer.shadowPath = shadowPath
                
                let anim = CABasicAnimation(keyPath: "shadowOpacity")
                anim.fromValue = kSWFromLayerShadowOpacity
                anim.toValue = kSWToLayerShadowOpacity
                anim.duration = CFTimeInterval(transitionDuration(using: transitionContext))
                snapshotToView!.layer.add(anim, forKey: "shadowOpacity")
                snapshotToView!.layer.shadowOpacity = Float(kSWToLayerShadowOpacity)

                UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut) {
                    // Move views to final frames
                    snapshotToView!.frame = fromView.frame
                    fromView.frame = fromViewFinalFrame

                } completion: { (finished) in
                    snapshotToView!.layer.shadowOpacity = 0

                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

                    // If transition was not cancelled, actually add the toView to our view hierarchy
                    if !transitionContext.transitionWasCancelled {
                        containerView.addSubview(toView)
                        snapshotToView!.removeFromSuperview()
                    }
                }
            }
        }
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return TimeInterval(kSWPushTransitionDuration)
    }
}
