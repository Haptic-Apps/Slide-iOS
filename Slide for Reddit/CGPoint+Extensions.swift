//
//  CGPoint+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 9/14/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

extension CGPoint {


    static func * (left: CGPoint, right: CGPoint) -> CGFloat {
        return left.x * right.x + left.y * right.y
    }

    /**
     * Returns the length (magnitude) of the vector described by the CGPoint.
     */
    public var magnitude: CGFloat {
        return sqrt(lengthSquare)
    }

    /**
     * Returns the squared length of the vector described by the CGPoint.
     */
    public var lengthSquare: CGFloat {
        return x * x + y * y
    }
}
