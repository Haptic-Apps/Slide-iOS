//
//  CGSize+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/28/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

extension CGSize {
    static func square(size: CGFloat) -> CGSize {
        return CGSize(width: size, height: size)
    }
    static func square(size: Int) -> CGSize {
        return CGSize(width: size, height: size)
    }
    static func square(size: Double) -> CGSize {
        return CGSize(width: size, height: size)
    }
}
