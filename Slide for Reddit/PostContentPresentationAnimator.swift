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
                    UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                        translatedView.transform = CGAffineTransform.identity
                        translatedView.layer.zPosition = storedZ
                    }, completion: nil)
                }
            }
        } else if let vc = presentedViewController as? AnyModalViewController {
            let fromRect = vc.view.convert(sourceImageView.bounds, from: sourceImageView)
            vc.view.layoutIfNeeded()

            let translatedView = vc.videoView!
            
            let inner = AVMakeRect(aspectRatio: translatedView.bounds.size, insideRect: vc.view.bounds)
            let toRect = vc.view.convert(inner, from: vc.view)
            
            let newTransform = transformFromRect(from: toRect, toRect: fromRect)
            let storedZ = translatedView.layer.zPosition
            translatedView.layer.zPosition = sourceImageView.layer.zPosition
            
            translatedView.transform = translatedView.transform.concatenating(newTransform)
            UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                translatedView.transform = CGAffineTransform.identity
                translatedView.layer.zPosition = storedZ
            }, completion: nil)
        }
        
        // Animate alpha
        
        /* unused var isVideo = false
        if let vc = controller as? ModalMediaViewController, vc.embeddedVC is VideoMediaViewController {
            isVideo = true
        }
        
        if presentedViewController is AnyModalViewController {
            isVideo = true
        }*/
        
        let initialAlpha: CGFloat = isPresentation ? 0.0 : 1.0
        // Assume 1, now that photos and videos have black backgrounds
        let finalAlpha: CGFloat = isPresentation ? 1.0 : 0.0
        
        // Use a special animation chain for certain types of presenting VCs
        if let vc = controller as? ModalMediaViewController,
            let embed = vc.embeddedVC {
            vc.background?.alpha = initialAlpha
            vc.blurView?.alpha = initialAlpha
            vc.closeButton.alpha = initialAlpha
            embed.bottomButtons.alpha = initialAlpha
            UIView.animate(withDuration: animationDuration, animations: {
                vc.background?.alpha = finalAlpha
                vc.blurView?.alpha = 1
                vc.closeButton.alpha = 1
                embed.bottomButtons.alpha = 1
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        } else if presentedViewController is AnyModalViewController {
            (presentedViewController as! AnyModalViewController).background?.alpha = initialAlpha
            (presentedViewController as! AnyModalViewController).blurView?.alpha = initialAlpha
            UIView.animate(withDuration: animationDuration, animations: {
                (presentedViewController as! AnyModalViewController).background?.alpha = finalAlpha
                (presentedViewController as! AnyModalViewController).blurView?.alpha = 1
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        } else {
            controller.view.alpha = initialAlpha
            UIView.animate(withDuration: animationDuration, animations: {
                controller.view.alpha = 1
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        }
    }
}
