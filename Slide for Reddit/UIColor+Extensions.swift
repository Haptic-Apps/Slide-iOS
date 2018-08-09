//
//  UIColor+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/9/18, though he may not wish to take credit for this.
//  Copyright Jon. I spent too long on this. MIT License.
//

import Foundation

/*
 ██████╗  █████╗ ███╗   ██╗ ██████╗ ███████╗██████╗     ███████╗ ██████╗ ███╗   ██╗███████╗
 ██╔══██╗██╔══██╗████╗  ██║██╔════╝ ██╔════╝██╔══██╗    ╚══███╔╝██╔═══██╗████╗  ██║██╔════╝
 ██║  ██║███████║██╔██╗ ██║██║  ███╗█████╗  ██████╔╝      ███╔╝ ██║   ██║██╔██╗ ██║█████╗
 ██║  ██║██╔══██║██║╚██╗██║██║   ██║██╔══╝  ██╔══██╗     ███╔╝  ██║   ██║██║╚██╗██║██╔══╝
 ██████╔╝██║  ██║██║ ╚████║╚██████╔╝███████╗██║  ██║    ███████╗╚██████╔╝██║ ╚████║███████╗
 ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
 */

public extension UIColor {

    private static let swizzleImplementation: Void = {

        let instance: UIColor = UIColor.red // This is a `UICachedDeviceRGBColor` instance
        let _class: AnyClass! = object_getClass(instance)

        let originalMethod = class_getInstanceMethod(_class, #selector(getter: cgColor))
        let swizzledMethod = class_getInstanceMethod(_class, #selector(randomCGColor))

        if let originalMethod = originalMethod, let swizzledMethod = swizzledMethod {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }()

    /**
     Swaps all UIColor.cgColor getter calls for a function block that returns a random color. This has the
     effect of randomizing all UIColors every time their getter is called.
     */
    public static func ruinForever() {
        _ = self.swizzleImplementation
    }

    dynamic func randomCGColor() -> CGColor {
        return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [
            CGFloat(Float(arc4random()) / Float(UINT32_MAX)),
            CGFloat(Float(arc4random()) / Float(UINT32_MAX)),
            CGFloat(Float(arc4random()) / Float(UINT32_MAX)),
            CGFloat(Float(arc4random()) / Float(UINT32_MAX)),
            ])!
    }

}
