//
//  UIBezierPath+Helpers.swift
//  Tusker
//
//  Created by Shadowfacts on 6/25/20.
//  Copyright © 2020 Shadowfacts. All rights reserved.
//

import UIKit

extension UIBezierPath {
    
    /// Create a new UIBezierPath that wraps around the given array of rectangles.
    /// This is not a convex hull aglorithm. What this does is it takes a set of rectangles
    /// and draws a line around the outer borders of the combined shape.
    convenience init(wrappingAround rects: [CGRect]) {
        precondition(rects.count > 0)
        let rects = rects.sorted { $0.minY < $1.minY }
        
        self.init()
        
        // start at the top left corner
        self.move(to: CGPoint(x: rects.first!.minX, y: rects.first!.minY))
        
        // walk down the left side
        var prevLeft = rects.first!.minX
        for rect in rects where !rect.minX.isEqual(to: prevLeft) {
            self.addLine(to: CGPoint(x: prevLeft, y: rect.minY))
            self.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            prevLeft = rect.minX
        }
        
        // ensure at the bottom left if not already
        let bottomLeft = CGPoint(x: rects.last!.minX, y: rects.last!.maxY)
        if !self.currentPoint.equalTo(bottomLeft) {
            self.addLine(to: bottomLeft)
        }
        
        // across the bottom of the last rect
        self.addLine(to: CGPoint(x: rects.last!.maxX, y: rects.last!.maxY))
        
        // walk up the right side
        var prevRight = rects.last!.maxX
        for rect in rects.reversed() where !rect.maxX.isEqual(to: prevRight) {
            self.addLine(to: CGPoint(x: prevRight, y: rect.maxY))
            self.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            prevRight = rect.maxX
        }
        
        // ensure at the top right if not already
        let topRight = CGPoint(x: rects.first!.maxX, y: rects.first!.minY)
        if !self.currentPoint.equalTo(topRight) {
            self.addLine(to: topRight)
        }
        
        // across the top of the first rect
        self.addLine(to: CGPoint(x: rects.first!.minX, y: rects.first!.minY))
    }
    
}
