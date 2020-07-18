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

let kSWToLayerShadowRadius = 5
let kSWToLayerShadowOpacity = 0.5
let kSWFromLayerShadowOpacity = 0.1
let kSWPushTransitionDuration = 0.2

class SwipeForwardAnimatedTransitioning {
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let toView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to).view
        let fromView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from).view
        
        let containerViewWidth = containerView.frame.size.width
        var snapshotToView = toView.snapshotView(afterScreenUpdates: true)
        
        containerView.addSubview(snapshotToView)
        
        let fromViewFinalFrame = fromView.frame
        fromViewFinalFrame.origin.x = -containerViewWidth/3.f
        
        let toViewFinalFrame = toView.frame
        toViewFinalFrame.origin.x = containerViewWidth
        
        snapshotToView.frame = toViewFinalFrame
        snapshotToView.layer.shadowRadius = kSWToLayerShadowRadius
        snapshotToView.layer.shadowOpacity = kSWFromLayerShadowOpacity
        
        let shadowFrame = snapshotToView.layer.bounds
        let shadowPath = UIBezierPath(rect: shadowFrame).cgPath
        snapshotToView.layer.shadowPath = shadowPath
        
        let anim = CABasicAnimation(keyPath: "shadowOpacity")
        anim.fromValue = NSNumber(value: kSWFromLayerShadowOpacity)
        anim.toValue = NSNumber(value: kSWToLayerShadowOpacity)
        anim.duration = CFTimeInterval(transitionDuration(using: transitionContext))
        snapshotToView.layer.add(anim, forKey: "shadowOpacity")
        snapshotToView.layer.shadowOpacity = kSWToLayerShadowOpacity

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveLinear, animations: {
            // Move views to final frames
            snapshotToView.frame = fromView.frame
            fromView.frame = fromViewFinalFrame
        }) { finished in
            snapshotToView.layer.shadowOpacity = 0

            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

            // If transition was not cancelled, actually add the toView to our view hierarchy
            if !transitionContext.transitionWasCancelled {
                containerView.addSubview(toView)
                snapshotToView.removeFromSuperview()
            }
        }
    }
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return kSWPushTransitionDuration
    }
}
