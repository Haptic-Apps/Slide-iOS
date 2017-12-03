//
//  PlaceholderViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 11/12/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class PlaceholderViewController : UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        
        self.view.backgroundColor = ColorUtil.backgroundColor
        
        let imageView = UIImageView(frame: CGRect(x: (self.view.frame.size.width / 2) - 62.5, y: (self.view.frame.size.height / 2) - 62.5, width: 125, height: 125))
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel.init(frame: CGRect(x: (self.view.frame.size.width / 2) - 75, y: (self.view.frame.size.height / 2) + 8, width: 150, height: 150))
        label.text = "SELECT A POST"
        label.textColor = ColorUtil.fontColor
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textAlignment = .center
        
        let image = UIImage(named: "roundicon")
        imageView.image = image
        
        self.view.addSubview(imageView)
        self.view.addSubview(label)

    }
}
extension UIImage {
    func convertedToGrayImage() -> UIImage? {
        let width = self.size.width
        let height = self.size.height
        let rect = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        
        guard let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        
        guard let cgImage = cgImage else { return nil }
        
        context.draw(cgImage, in: rect)
        guard let imageRef = context.makeImage() else { return nil }
        let newImage = UIImage(cgImage: imageRef.copy()!)
        
        return newImage
    }
}

