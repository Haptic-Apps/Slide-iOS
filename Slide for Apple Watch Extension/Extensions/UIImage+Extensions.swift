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
        
        let maxWidth = size.width
        let maxHeight = size.height
        
        let imgWidth = self.size.width
        let imgHeight = self.size.height

        let widthRatio = maxWidth / imgWidth
        let heightRatio = maxHeight / imgHeight
        
        let bestRatio = min(widthRatio, heightRatio)

        let newWidth = imgWidth * bestRatio,
            newHeight = imgHeight * bestRatio

        let biggerSize = CGSize(width: newWidth + 20 + (abs(size.width - newWidth) / 2), height: newHeight + 20 + (abs(size.height - newHeight) / 2))

        UIGraphicsBeginImageContextWithOptions(biggerSize, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint(x: 10 + (abs(size.width - newWidth) / 2), y: 10 + (abs(size.height - newHeight) / 2)), size: biggerSize))
        
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
