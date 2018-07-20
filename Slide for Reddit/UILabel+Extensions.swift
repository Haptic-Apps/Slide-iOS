//
//  UILabel+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 7/6/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit

extension UILabel {

    func fitFontForSize(minFontSize: CGFloat = 5.0, maxFontSize: CGFloat = 300.0, accuracy: CGFloat = 1.0) {
        var minFontSize = minFontSize
        var maxFontSize = maxFontSize
        assert(maxFontSize > minFontSize)
        layoutIfNeeded()
        let constrainedSize = bounds.size
        while maxFontSize - minFontSize > accuracy {
            let midFontSize: CGFloat = ((minFontSize + maxFontSize) / 2)
            font = font.withSize(midFontSize)
            sizeToFit()
            let checkSize: CGSize = bounds.size
            if checkSize.height < constrainedSize.height && checkSize.width < constrainedSize.width {
                minFontSize = midFontSize
            }
            else {
                maxFontSize = midFontSize
            }
        }
        font = font.withSize(minFontSize)
        sizeToFit()
        layoutIfNeeded()
    }

}
