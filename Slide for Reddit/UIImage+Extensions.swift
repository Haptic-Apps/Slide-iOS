//
//  UIImage+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UIImage {

    func imageResize(sizeChange: CGSize) -> UIImage {

        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen

        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }

    func withColor(tintColor: UIColor) -> UIImage {
        var image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        tintColor.set()
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    // TODO: Cache these!
    func navIcon() -> UIImage {
        return self.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withColor(tintColor: ColorUtil.fontColor)
    }

    func smallIcon() -> UIImage {
        return self.imageResize(sizeChange: CGSize.init(width: 12, height: 12)).withColor(tintColor: ColorUtil.fontColor)
    }

    func toolbarIcon() -> UIImage {
        return self.imageResize(sizeChange: CGSize.init(width: 25, height: 25)).withColor(tintColor: ColorUtil.fontColor)
    }

    func menuIcon() -> UIImage {
        return self.imageResize(sizeChange: CGSize.init(width: 20, height: 20)).withColor(tintColor: ColorUtil.fontColor)
    }
}
