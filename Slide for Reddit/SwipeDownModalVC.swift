//
//  SwipeDownModalVC.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/5/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation

class SwipeDownModalVC: ColorMuxPagingViewController {
    var panGestureRecognizer: UIPanGestureRecognizer?
    var panGestureRecognizer2: UIPanGestureRecognizer?
    public var background: UIView?

    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    
    var didStartPan : (_ panStart: Bool)->() = { result in}

    override func viewDidLoad() {
        super.viewDidLoad()
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        panGestureRecognizer2 = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
        panGestureRecognizer!.direction = .vertical
        panGestureRecognizer2!.direction = .horizontal
        
        view.addGestureRecognizer(panGestureRecognizer!)
        view.addGestureRecognizer(panGestureRecognizer2!)

        background = UIView()
        background!.frame = self.view.frame
        background!.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        background!.backgroundColor = .black
        
        if(!(self is ShadowboxViewController)){
            background!.alpha = 0.6
        }

        self.view.insertSubview(background!, at: 0)
    }
    
    func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: view)

        if panGesture.state == .began {
            originalPosition = view.center
            currentPositionTouched = panGesture.location(in: view)
            didStartPan(true)
        } else if panGesture.state == .changed {
            view.frame.origin = CGPoint(
                    x: 0,
                    y: translation.y
            )
            let progress = translation.y / (self.view.frame.size.height / 2)
            self.view.alpha = 1 - (abs(progress) * 1.3)

        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: view)

            let down = panGesture.velocity(in: view).y > 0
            if abs(velocity.y) >= 1000 || abs(self.view.frame.origin.y) > self.view.frame.size.height / 2{

                UIView.animate(withDuration: 0.2
                        , animations: {
                    self.view.frame.origin = CGPoint(
                            x: self.view.frame.origin.x,
                            y: self.view.frame.size.height * (down ? 1 : -1) )

                    self.view.alpha = 0.1

                }, completion: { (isCompleted) in
                    if isCompleted {
                        self.dismiss(animated: false, completion: nil)
                    }
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.center = self.originalPosition!
                    self.view.alpha = 1

                })
            }
        }
    }

}
