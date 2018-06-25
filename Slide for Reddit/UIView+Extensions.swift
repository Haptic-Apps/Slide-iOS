//
//  UIView+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/25/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UIView {

    /// Small convenience function to add several subviews at once.
    func addSubviews(_ views: UIView...) {
        for item in views {
            addSubview(item)
        }
    }

}
