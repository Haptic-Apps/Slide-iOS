//
//  UIImage+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UIImage {

    func getCopy(withSize size: CGSize) -> UIImage {
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen

        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }

    func getCopy(withColor color: UIColor) -> UIImage {
        var image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.set()
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    func getCopy(withSize size: CGSize, withColor color: UIColor) -> UIImage {
        return self.getCopy(withSize: size).getCopy(withColor: color)
    }

    // TODO: These should make only one copy and do in-place operations on those
    func navIcon() -> UIImage {
        return self.getCopy(withSize: CGSize(width: 25, height: 25), withColor: ColorUtil.fontColor)
    }

    func smallIcon() -> UIImage {
        return self.getCopy(withSize: CGSize(width: 12, height: 12), withColor: ColorUtil.fontColor)
    }

    func toolbarIcon() -> UIImage {
        return self.getCopy(withSize: CGSize(width: 25, height: 25), withColor: ColorUtil.fontColor)
    }

    func menuIcon() -> UIImage {
        return self.getCopy(withSize: CGSize(width: 20, height: 20), withColor: ColorUtil.fontColor)
    }
}
