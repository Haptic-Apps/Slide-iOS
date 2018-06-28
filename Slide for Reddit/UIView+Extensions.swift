//
//  UIView+Extensions.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 6/25/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import Then
import UIKit

extension UIView {

    /// Small convenience function to add several subviews at once.
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }

    func withPadding(padding: UIEdgeInsets) -> UIView {
        let container = UIView()
        container.addSubview(self)

        batch {
            let constraints = self.edgeAnchors == container.edgeAnchors + padding
            constraints.bottom.priority = UILayoutPriorityRequired - 1
            constraints.trailing.priority = UILayoutPriorityRequired - 1
        }

        return container
    }

    // TODO: Make static
    func flexSpace() -> UIView {
        return UIView().then {
            $0.setContentHuggingPriority(0, for: .horizontal)
            $0.setContentHuggingPriority(0, for: .vertical)
        }
    }

    func horizontalSpace(_ space: CGFloat) -> UIView {
        return UIView().then {
            $0.widthAnchor == space
        }
    }

    func blink(color: UIColor) {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveLinear], animations: {
            self.backgroundColor = color
        }, completion: {finished in
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveLinear], animations: {
                self.backgroundColor = ColorUtil.foregroundColor
            }, completion: nil)
        })
    }

}
