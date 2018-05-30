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
        
        let image = UIImage(named: "roundicon")!.convertToGrayScale()
        imageView.image = image
        
        self.view.addSubview(imageView)
        self.view.addSubview(label)

    }
}
extension UIImage {
    func convertToGrayScale() -> UIImage {
        let filter: CIFilter = CIFilter(name: "CIPhotoEffectMono")!
        filter.setDefaults()
        filter.setValue(CoreImage.CIImage(image: self)!, forKey: kCIInputImageKey)

        return UIImage(cgImage:CIContext(options: nil).createCGImage(filter.outputImage!, from: filter.outputImage!.extent)!)
    }
}
