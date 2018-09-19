//
//  UIPanGestureRecognizer+Utilities.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 9/14/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

// https://stackoverflow.com/a/29179878/7138792
fileprivate extension BinaryInteger {
    var degreesToRadians: CGFloat { return CGFloat(Int(self)) * .pi / 180 }
}
fileprivate extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}


enum PanDirection {
    case left, right, up, down

    var pointVector: CGPoint {
        switch self {
        case .left: return CGPoint(x: -1, y: 0)
        case .right: return CGPoint(x: 1, y: 0)
        case .up: return CGPoint(x: 0, y: -1)
        case .down: return CGPoint(x: 0, y: 1)
        }
    }
}

enum PanAxis {
    case horizontal
    case vertical
}

extension UIPanGestureRecognizer {

    func shouldRecognizeForDirection(_ direction: PanDirection, withAngleToleranceInDegrees tolerance: CGFloat = 45) -> Bool {
        guard let view = view else {
            return false
        }
        
        let vel = velocity(in: view)
        let a = angle(direction.pointVector, vel).radiansToDegrees
        return abs(a) <= tolerance / 2 || abs(a) >= 360 - (tolerance / 2)

    }

    func shouldRecognizeForAxis(_ axis: PanAxis, withAngleToleranceInDegrees tolerance: CGFloat = 45) -> Bool {
        switch axis {
        case .horizontal:
            return shouldRecognizeForDirection(.left, withAngleToleranceInDegrees: tolerance) ||
                shouldRecognizeForDirection(.right, withAngleToleranceInDegrees: tolerance)
        case .vertical:
            return shouldRecognizeForDirection(.up, withAngleToleranceInDegrees: tolerance) ||
                shouldRecognizeForDirection(.down, withAngleToleranceInDegrees: tolerance)
        }
    }

}

/// Returns angle between vector a and vector b in radians.
func angle(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    return atan2(a.y, a.x) - atan2(b.y, b.x)
}
