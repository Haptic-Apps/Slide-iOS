//
//  TapBehindModalViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 11/12/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

//Code from https://stackoverflow.com/a/44171475/3697225

import Anchorage
import Foundation

protocol TapBehindModalViewControllerDelegate {
    func shouldDismiss() -> Bool
}

class TapBehindModalViewController: UINavigationController, UIGestureRecognizerDelegate {
    public var tapOutsideRecognizer: UITapGestureRecognizer!
    public var del: TapBehindModalViewControllerDelegate?
    public var closeCallback: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.tapOutsideRecognizer == nil && ((modalPresentationStyle == .pageSheet || modalPresentationStyle == .popover) || UIDevice.current.userInterfaceIdiom == .pad) {
            self.tapOutsideRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapBehind))
            self.tapOutsideRecognizer.numberOfTapsRequired = 1
            self.tapOutsideRecognizer.cancelsTouchesInView = false
            self.tapOutsideRecognizer.delegate = self
            self.view.window?.addGestureRecognizer(self.tapOutsideRecognizer)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        closeCallback?()
        
        if self.tapOutsideRecognizer != nil {
            self.view.window?.removeGestureRecognizer(self.tapOutsideRecognizer)
            self.tapOutsideRecognizer = nil
        }
    }
    
    func close(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Gesture methods to dismiss this with tap outside
    @objc func handleTapBehind(sender: UITapGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.ended && del?.shouldDismiss() ?? true {
            let location: CGPoint = sender.location(in: self.view)
            
            if !self.view.point(inside: location, with: nil) {
                self.view.window?.removeGestureRecognizer(sender)
                self.close(sender: sender)
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
