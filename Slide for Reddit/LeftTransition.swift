//
//  LeftTransition.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/3/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

// Code based on https://stackoverflow.com/a/33960412/3697225

import UIKit

class LeftTransition: NSObject, UIViewControllerAnimatedTransitioning {
    var dismiss = false
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // Get the two view controllers
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let containerView = transitionContext.containerView
        
        var originRect = containerView.bounds
        originRect.origin = CGPoint.init(x: (originRect).width, y: 0)
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        
        if dismiss {
            containerView.bringSubview(toFront: fromVC.view)
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: { () -> Void in
                fromVC.view.frame = originRect
            }, completion: { (_ ) -> Void in
                fromVC.view.removeFromSuperview()
                transitionContext.completeTransition(true )
            })
        } else {
            toVC.view.frame = originRect
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                                       animations: { () -> Void in
                                        toVC.view.center = containerView.center
            }) {
                (_) -> Void in
                fromVC.view.removeFromSuperview()
                transitionContext.completeTransition(true )
            }
        }
    }
}
