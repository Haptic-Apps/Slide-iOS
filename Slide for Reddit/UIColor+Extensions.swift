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

    private struct StaticVars {
        static let randomColorBlock: @convention(block) (AnyObject?) -> CGColor = { (_: AnyObject?) -> (CGColor) in
            return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [
                CGFloat(Float(arc4random()) / Float(UINT32_MAX)), // R
                CGFloat(Float(arc4random()) / Float(UINT32_MAX)), // G
                CGFloat(Float(arc4random()) / Float(UINT32_MAX)), // B
                1.0, // A
                ])!
        }
    }

    private static let rzl_swizzleImplementation: Void = {

        var classCount = objc_getClassList(nil, 0)
        var allClasses = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(classCount))
        var autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses)
        classCount = objc_getClassList(autoreleasingAllClasses, classCount)

        var modifiedClassCount = 0

        for i in 0 ..< classCount {
            if let currentClass: AnyClass = allClasses[Int(i)] {
                let _super: AnyClass? = class_getSuperclass(currentClass)
                let _supersuper: AnyClass? = class_getSuperclass(_super)
                if currentClass == UIColor.self || _super == UIColor.self || _supersuper == UIColor.self {
                    if let originalMethod = class_getInstanceMethod(currentClass.self, #selector(getter: cgColor)) {
//                        print(String(describing: currentClass), currentClass)
                        method_setImplementation(originalMethod, imp_implementationWithBlock(unsafeBitCast(StaticVars.randomColorBlock, to: AnyObject.self)))
                        modifiedClassCount += 1
                    }
                }
            }
        }

        print("Swizzled UIColor class derivatives: \(modifiedClassCount)")

    }()

    /**
     Swaps all UIColor.cgColor getter calls for a function block that returns a random color. This has the
     effect of randomizing all UIColors every time their getter is called.
     */
    public static func 💀() {
        _ = self.rzl_swizzleImplementation
    }
    
    public var redValue: CGFloat {
        if cgColor.components != nil && cgColor.components!.count >= 1 {
            return cgColor.components! [0]
        }
        return 0
    }
    
    public var greenValue: CGFloat {
        if cgColor.components != nil && cgColor.components!.count >= 2 {
            return cgColor.components! [1]
        }
        return 0
    }
    
    public var blueValue: CGFloat {
        if cgColor.components != nil && cgColor.components!.count >= 3 {
            return cgColor.components! [2]
        }
        return 0
    }
    
    public var alphaValue: CGFloat {
        if cgColor.components != nil && cgColor.components!.count >= 4 {
            return cgColor.components! [3]
        }
        return 0
    }
}
