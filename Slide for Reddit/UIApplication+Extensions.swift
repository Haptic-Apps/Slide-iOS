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

extension UIDevice {
    public func isMac() -> Bool {
        return false //Disable new Mac features for now
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac || ProcessInfo.processInfo.isMacCatalystApp
        } else if #available(iOS 13.0, *) {
            return ProcessInfo.processInfo.isMacCatalystApp
        } else {
           return false
        }
    }
    
    public func isMacReal() -> Bool {
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac || ProcessInfo.processInfo.isMacCatalystApp
        } else if #available(iOS 13.0, *) {
            return ProcessInfo.processInfo.isMacCatalystApp
        } else {
           return false
        }
    }

    public func respectIpadLayout() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad || isMacReal()
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
