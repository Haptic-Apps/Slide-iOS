//
//  SwipeDownModalVC.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/5/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import SDWebImage

class SwipeDownModalVC: ColorMuxPagingViewController {
    var panGestureRecognizer: UIPanGestureRecognizer?
    var panGestureRecognizer2: UIPanGestureRecognizer?
    public var background: UIView?

    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    var viewToMove: UIView?
    
    var didStartPan : (_ panStart: Bool) -> Void = { _ in }
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SDImageCache.shared.config.shouldCacheImagesInMemory = true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        SDImageCache.shared.config.shouldCacheImagesInMemory = false
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        panGestureRecognizer2 = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        panGestureRecognizer!.delegate = self
        panGestureRecognizer!.direction = .vertical
        if #available(iOS 13.4, *) {
            panGestureRecognizer!.allowedScrollTypesMask = .continuous
        }
        
        panGestureRecognizer2!.direction = .horizontal
        panGestureRecognizer!.cancelsTouchesInView = false
        
        view.addGestureRecognizer(panGestureRecognizer!)
        view.addGestureRecognizer(panGestureRecognizer2!)

        background = UIView()
        background!.frame = self.view.frame
        background!.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        background!.backgroundColor = .black
        
        if !(self is ShadowboxViewController) {
            background!.alpha = 0.6
        }

        self.view.insertSubview(background!, at: 0)
        let blurView = UIVisualEffectView(frame: UIScreen.main.bounds)
        blurEffect.setValue(5, forKeyPath: "blurRadius")
        blurView.effect = blurEffect
        view.insertSubview(blurView, at: 0)
    }
    
    @objc func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)
        guard let viewToMove = viewToMove else { return }
        
        if panGesture.state == .began {
            originalPosition = viewToMove.frame.origin
            currentPositionTouched = panGesture.location(in: view)
            didStartPan(true)
        } else if panGesture.state == .changed {
            if originalPosition == nil {
                originalPosition = viewToMove.frame.origin
            }
            viewToMove.frame.origin = CGPoint(
                x: 0,
                y: originalPosition!.y + translation.y
            )
            let progress = translation.y / (self.view.frame.size.height / 2)
            self.view.alpha = 1 - (abs(progress) * 1.3)
            
        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: view)
            
            let down = panGesture.velocity(in: view).y > 0
            if abs(velocity.y) >= 1000 || abs(self.view.frame.origin.y) > self.view.frame.size.height / 2 {
                
                UIView.animate(withDuration: 0.2, animations: {
                    viewToMove.frame.origin = CGPoint(
                        x: viewToMove.frame.origin.x,
                        y: viewToMove.frame.size.height * (down ? 1 : -1) )
                    
                    self.view.alpha = 0.1
                    
                }, completion: { (isCompleted) in
                    if isCompleted {
                        self.dismiss(animated: false, completion: nil)
                    }
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    viewToMove.frame.origin = self.originalPosition ?? CGPoint.zero
                    self.view.alpha = 1
                    self.background?.alpha = 1
                })
            }
        }
    }

}

extension UIView {
    // Returns true if the class is a subclass of or is identical to the given class
    func hasParentOfClass(_ theClass: UIView.Type) -> Bool {
        if type(of: self).isSubclass(of: theClass) {
            return true
        }

        return superview?.hasParentOfClass(theClass) ?? false
    }
}

extension SwipeDownModalVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        // Reject the touch if it lands in a UIControl.
        if let view = touch.view {
            return !view.hasParentOfClass(UIControl.self)
        } else {
            return true
        }

    }
}
