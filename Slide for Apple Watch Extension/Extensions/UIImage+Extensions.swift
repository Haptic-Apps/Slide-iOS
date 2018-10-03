//
//  UIImage+Extensions.swift
//  Slide for Apple Watch Extension
//
//  Created by Carlos Crane on 10/3/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UIImage {
    func getCopy(withSize size: CGSize) -> UIImage {
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen
        let biggerSize = CGSize(width: size.width + 20, height: size.height + 20)
        UIGraphicsBeginImageContextWithOptions(biggerSize, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint(x: 10, y: 10), size: size))
        
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
}
