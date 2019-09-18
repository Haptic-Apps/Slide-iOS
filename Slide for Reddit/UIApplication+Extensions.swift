//
//  UIApplication+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/6/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

extension UIApplication {

    var statusBarView: UIView? {
        return statusBarUIView as? UIView
    }
    
}
extension UIApplication {
    public var isSplitOrSlideOver: Bool {
        guard let w = self.delegate?.window, let window = w else {
            return false
        }
        return !window.frame.equalTo(window.screen.bounds)
    }
    
    public var isSlideOver: Bool {
        guard let w = self.delegate?.window, let window = w else {
            return false
        }
        return window.frame.size.height != window.screen.bounds.size.height
    }
}
