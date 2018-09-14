//
//  UIPanGestureRecognizer+Utilities.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 9/14/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation

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
        let a = angle(vel, direction.pointVector)
        let toleranceRadians = tolerance * .pi / 180
        return abs(a) < toleranceRadians
        //return abs(a) < CGFloat.pi / 4 // Angle should be within 45 degrees
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

/// Returns angle from a to b in radians.
func angle(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    // TODO | - Not sure if this is correct
    return atan2(a.y, a.x) - atan2(b.y, b.x)
}
