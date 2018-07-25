//
// Copyright 2014 Scott Logic
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import UIKit

class BouncyViewControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var isPresenting: Bool = false
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.8
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fromView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)?.view
        let toView = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)?.view
        
        var center: CGPoint?
        
        if isPresenting {
            center = toView!.center
            toView!.center = CGPoint.init(x: center!.x, y: toView!.bounds.size.height)
            transitionContext.containerView.addSubview(toView!)
        } else {
            center = CGPoint.init(x: toView!.center.x, y: toView!.bounds.size.height + fromView!.bounds.size.height)
        }
        
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                                   delay: 0, usingSpringWithDamping: 300, initialSpringVelocity: 10.0, options: UIViewAnimationOptions.curveEaseInOut,
                                   animations: {
                                    if self.isPresenting {
                                        toView!.center = center!
                                        fromView!.transform = CGAffineTransform.identity.scaledBy(x: 0.92, y: 0.92)
                                    } else {
                                        fromView!.center = center!
                                        toView!.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
                                    }
        }, completion: {_ in
            if !self.isPresenting {
                fromView!.removeFromSuperview()
            }
            
            transitionContext.completeTransition(true)
        })
    }
}
