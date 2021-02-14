//
//  UIButton+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/6/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

private let minimumHitArea = CGSize(width: 100, height: 100)
//https://stackoverflow.com/a/50127204/3697225
extension UIButton {
    func leftImage(image: UIImage, renderMode: UIImage.RenderingMode) {
        self.setImage(image.withRenderingMode(renderMode), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: image.size.width / 2, bottom: 0, right: image.size.width / 2)
        self.contentHorizontalAlignment = .left
        self.imageView?.contentMode = .scaleAspectFit
    }

    func rightImage(image: UIImage, renderMode: UIImage.RenderingMode) {
        self.setImage(image.withRenderingMode(renderMode), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: image.size.width / 2, bottom: 0, right: 0)
        self.contentHorizontalAlignment = .right
        self.imageView?.contentMode = .scaleAspectFit
    }
    
    convenience init(buttonImage: UIImage?, toolbar: Bool = false) { // TODO accessibility here too
        self.init(type: .custom)
        if toolbar {
            self.setImage(buttonImage?.navIcon(), for: UIControl.State.normal)
            self.frame = CGRect.init(x: 0, y: 0, width: 44, height: 44)
        } else {
            self.setImage(buttonImage?.toolbarIcon(), for: UIControl.State.normal)
            self.frame = CGRect.init(x: 0, y: 0, width: 30, height: 44)
        }
        self.imageView?.contentMode = .center
    }
}
extension UIBarButtonItem {
    func addTargetForAction(target: AnyObject, action: Selector) {
        self.target = target
        self.action = action
    }
}
