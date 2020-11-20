//
//  BadgeLayoutManager.swift
//  Slide for Reddit
//
//  Created by Rajdeep Kwatra on 11/5/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//
//  Code based off https://github.com/rajdeep/proton/blob/d1a3c855fdabd487ed01c1d6dadff559a5843f28/Proton/Sources/Core/LayoutManager.swift
//

import UIKit
import Foundation

class BadgeLayoutManager: NSLayoutManager {
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage = textStorage,
            let currentCGContext = UIGraphicsGetCurrentContext() else {
                return
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage.enumerateAttribute(.badgeColor, in: characterRange) { attr, bgStyleRange, _ in
            var rects = [CGRect]()
            if let backgroundStyle = attr as? UIColor {
                let bgStyleGlyphRange = self.glyphRange(forCharacterRange: bgStyleRange, actualCharacterRange: nil)
                enumerateLineFragments(forGlyphRange: bgStyleGlyphRange) { _, usedRect, textContainer, lineRange, _ in
                    let rangeIntersection = NSIntersectionRange(bgStyleGlyphRange, lineRange)
                    var rect = self.boundingRect(forGlyphRange: rangeIntersection, in: textContainer)
                    // Glyphs can take space outside of the line fragment, and we cannot draw outside of it.
                    // So it is best to restrict the height just to the line fragment.
                    rect.origin.y = usedRect.origin.y
                    rect.size.height = usedRect.height
                    let insetTop = CGFloat.zero
                    rects.append(rect.offsetBy(dx: 0, dy: insetTop))
                }
                drawBackground(backgroundStyle: backgroundStyle, rects: rects, currentCGContext: currentCGContext)
            }
        }
    }

    private func drawBackground(backgroundStyle: UIColor, rects: [CGRect], currentCGContext: CGContext) {
        currentCGContext.saveGState()

        let rectCount = rects.count
        let rectArray = rects
        let cornerRadius = CGFloat(3)
        let color = backgroundStyle

        for i in 0..<rectCount {
            var previousRect = CGRect.zero
            var nextRect = CGRect.zero

            let currentRect = rectArray[i]

            if i > 0 {
                previousRect = rectArray[i - 1]
            }

            if i < rectCount - 1 {
                nextRect = rectArray[i + 1]
            }

            let corners = calculateCornersForBackground(previousRect: previousRect, currentRect: currentRect, nextRect: nextRect, cornerRadius: cornerRadius)

            let rectanglePath = UIBezierPath(roundedRect: currentRect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            color.set()

            currentCGContext.setAllowsAntialiasing(true)
            currentCGContext.setShouldAntialias(true)

            currentCGContext.setFillColor(color.cgColor)
            currentCGContext.addPath(rectanglePath.cgPath)
            currentCGContext.drawPath(using: .fill)

            let lineWidth = CGFloat.zero //Stroke
            let overlappingLine = UIBezierPath()

            let leftVerticalJoiningLine = UIBezierPath()
            let rightVerticalJoiningLine = UIBezierPath()

            let leftVerticalJoiningLineShadow = UIBezierPath()
            let rightVerticalJoiningLineShadow = UIBezierPath()

            if previousRect != .zero, (currentRect.maxX - previousRect.minX) > cornerRadius {
                let yDiff = currentRect.minY - previousRect.maxY
                overlappingLine.move(to: CGPoint(x: max(previousRect.minX, currentRect.minX) + lineWidth / 2, y: previousRect.maxY + yDiff/2))
                overlappingLine.addLine(to: CGPoint(x: min(previousRect.maxX, currentRect.maxX) - lineWidth / 2, y: previousRect.maxY + yDiff/2))

                let leftX = max(previousRect.minX, currentRect.minX)
                let rightX = min(previousRect.maxX, currentRect.maxX)

                leftVerticalJoiningLine.move(to: CGPoint(x: leftX, y: previousRect.maxY))
                leftVerticalJoiningLine.addLine(to: CGPoint(x: leftX, y: currentRect.minY))

                rightVerticalJoiningLine.move(to: CGPoint(x: rightX, y: previousRect.maxY))
                rightVerticalJoiningLine.addLine(to: CGPoint(x: rightX, y: currentRect.minY))

                let leftShadowX = max(previousRect.minX, currentRect.minX) + lineWidth
                let rightShadowX = min(previousRect.maxX, currentRect.maxX) - lineWidth

                leftVerticalJoiningLineShadow.move(to: CGPoint(x: leftShadowX, y: previousRect.maxY))
                leftVerticalJoiningLineShadow.addLine(to: CGPoint(x: leftShadowX, y: currentRect.minY))

                rightVerticalJoiningLineShadow.move(to: CGPoint(x: rightShadowX, y: previousRect.maxY))
                rightVerticalJoiningLineShadow.addLine(to: CGPoint(x: rightShadowX, y: currentRect.minY))
            }

            currentCGContext.setShadow(offset: .zero, blur:0, color: UIColor.clear.cgColor)

            // always draw over the overlapping bounds of previous and next rect to hide shadow/borders
            currentCGContext.setStrokeColor(color.cgColor)
            currentCGContext.addPath(overlappingLine.cgPath)
            // account for the spread of shadow
            let blur = (1) * 2
            let offsetHeight = CGFloat(1)
            currentCGContext.setLineWidth(lineWidth + (currentRect.minY - previousRect.maxY) + CGFloat(blur) + offsetHeight + CGFloat(1))
            currentCGContext.drawPath(using: .stroke)
        }
        currentCGContext.restoreGState()
    }

    private func calculateCornersForBackground(previousRect: CGRect, currentRect: CGRect, nextRect: CGRect, cornerRadius: CGFloat) -> UIRectCorner {
        var corners = UIRectCorner()

        if previousRect.minX > currentRect.minX {
            corners.formUnion(.topLeft)
        }

        if previousRect.maxX < currentRect.maxX {
            corners.formUnion(.topRight)
        }

        if currentRect.maxX > nextRect.maxX {
            corners.formUnion(.bottomRight)
        }

        if currentRect.minX < nextRect.minX {
            corners.formUnion(.bottomLeft)
        }

        if nextRect == .zero || nextRect.maxX <= currentRect.minX + cornerRadius {
            corners.formUnion(.bottomLeft)
            corners.formUnion(.bottomRight)
        }

        if previousRect == .zero || (currentRect.maxX <= previousRect.minX + cornerRadius) {
            corners.formUnion(.topLeft)
            corners.formUnion(.topRight)
        }

        return corners
    }

    private func getCornersForBackground(textStorage: NSTextStorage, for charRange: NSRange) -> UIRectCorner {
        let isFirst = (charRange.location == 0)
            || (textStorage.attribute(.badgeColor, at: charRange.location - 1, effectiveRange: nil) == nil)

        let isLast = (charRange.endLocation == textStorage.length) ||
            (textStorage.attribute(.badgeColor, at: charRange.location + charRange.length, effectiveRange: nil) == nil)

        var corners = UIRectCorner()
        if isFirst {
            corners.formUnion(.topLeft)
            corners.formUnion(.bottomLeft)
        }

        if isLast {
            corners.formUnion(.topRight)
            corners.formUnion(.bottomRight)
        }

        return corners
    }
}

extension NSAttributedString.Key {
    static let badgeColor: NSAttributedString.Key = .init("badgeColor")
}

//
//  NSRangeExtensions.swift
//  Proton
//
//  Created by Rajdeep Kwatra on 3/1/20.
//  Copyright © 2020 Rajdeep Kwatra. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
import Foundation
import UIKit

public extension NSRange {

    /// Range with 0 location and length
    static var zero: NSRange {
        return NSRange(location: 0, length: 0)
    }

    var firstCharacterRange: NSRange {
        return NSRange(location: location, length: 1)
    }

    var lastCharacterRange: NSRange {
        return NSRange(location: location + length, length: 1)
    }

    var nextPosition: NSRange {
        return NSRange(location: location + 1, length: 0)
    }

    var endLocation: Int {
        return location + length
    }

    /// Converts the range to `UITextRange` in given `UITextInput`. Returns nil if the range is invalid in the `UITextInput`.
    /// - Parameter textInput: UITextInput to convert the range in.
    func toTextRange(textInput: UITextInput) -> UITextRange? {
        guard let rangeStart = textInput.position(from: textInput.beginningOfDocument, offset: location),
            let rangeEnd = textInput.position(from: rangeStart, offset: length) else {
                return nil
        }
        return textInput.textRange(from: rangeStart, to: rangeEnd)
    }

    /// Checks if the range is valid in given `UITextInput`
    /// - Parameter textInput: UITextInput to validate the range in.
    func isValidIn(_ textInput: UITextInput) -> Bool {
        guard location > 0 else { return false }
        let end = location + length
        let contentLength = textInput.offset(from: textInput.beginningOfDocument, to: textInput.endOfDocument)
        return end < contentLength
    }
}
