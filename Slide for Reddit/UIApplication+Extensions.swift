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
        return statusBarUIView
    }
    
}
extension UIApplication {
    public var isSplitOrSlideOver: Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return false
        }
        if #available(iOS 13, *) {
            guard let window = self.windows.filter({ $0.isKeyWindow }).first else { return false }
            return !(window.frame.width == window.screen.bounds.width)
        }
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
