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
            constraints.bottom.priority = UILayoutPriority.required - 1
            constraints.trailing.priority = UILayoutPriority.required - 1
        }
        
        return container
    }
    
    // TODO: - Make static
    func flexSpace() -> UIView {
        return UIView().then {
            $0.setContentHuggingPriority(UILayoutPriority(rawValue: 0), for: .horizontal)
            $0.setContentHuggingPriority(UILayoutPriority(rawValue: 0), for: .vertical)
        }
    }
    
    static func flexSpace() -> UIView {
        return UIView().then {
            $0.setContentHuggingPriority(UILayoutPriority(rawValue: 0), for: .horizontal)
            $0.setContentHuggingPriority(UILayoutPriority(rawValue: 0), for: .vertical)
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
        }, completion: {_ in
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveLinear], animations: {
                self.backgroundColor = ColorUtil.theme.foregroundColor
            }, completion: nil)
        })
    }
    
    // https://stackoverflow.com/a/27293815/7138792
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
    
}

// Convenient safe anchor accessors
extension UIView {
    
    var safeTopAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.topAnchor
        } else {
            return topAnchor
        }
    }
    
    var safeBottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.bottomAnchor
        } else {
            return bottomAnchor
        }
    }
    
    var safeLeadingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.leadingAnchor
        } else {
            return leadingAnchor
        }
    }

    var safeLeftAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.leftAnchor
        } else {
            return leftAnchor
        }
    }
    
    var safeTrailingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.trailingAnchor
        } else {
            return trailingAnchor
        }
    }

    var safeRightAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.rightAnchor
        } else {
            return rightAnchor
        }
    }
    
    var safeCenterXAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.centerXAnchor
        } else {
            return centerXAnchor
        }
    }
    
    var safeCenterYAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.centerYAnchor
        } else {
            return centerYAnchor
        }
    }
    
    var safeCenterAnchors: AnchorPair<NSLayoutXAxisAnchor, NSLayoutYAxisAnchor> {
        if #available(iOS 11.0, *) {
            return AnchorPair(first: safeAreaLayoutGuide.centerXAnchor, second: safeAreaLayoutGuide.centerYAnchor)
        } else {
            return centerAnchors
        }
    }
    
    var safeHorizontalAnchors: AnchorPair<NSLayoutXAxisAnchor, NSLayoutXAxisAnchor> {
        if #available(iOS 11.0, *) {
            return AnchorPair(first: safeAreaLayoutGuide.leadingAnchor, second: safeAreaLayoutGuide.trailingAnchor)
        } else {
            return horizontalAnchors
        }
    }

    var safeVerticalAnchors: AnchorPair<NSLayoutYAxisAnchor, NSLayoutYAxisAnchor> {
        if #available(iOS 11.0, *) {
            return AnchorPair(first: safeAreaLayoutGuide.topAnchor, second: safeAreaLayoutGuide.bottomAnchor)
        } else {
            return verticalAnchors
        }
    }

    enum Border {
        case left
        case right
        case top
        case bottom
    }
    
    func setBorder(border: UIView.Border, weight: CGFloat, color: UIColor ) {
        
        let lineView = UIView()
        addSubview(lineView)
        lineView.backgroundColor = color
        lineView.translatesAutoresizingMaskIntoConstraints = false
        
        switch border {
            
        case .left:
            lineView.leftAnchor == leftAnchor - 8
            lineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            lineView.widthAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .right:
            lineView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            lineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            lineView.widthAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .top:
            lineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            lineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            lineView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            lineView.heightAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .bottom:
            lineView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            lineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            lineView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            lineView.heightAnchor.constraint(equalToConstant: weight).isActive = true
        }
    }
    
    //https://stackoverflow.com/a/50189305/3697225
    /**
     * Deactivates immediate constraints that target this view (self + superview)
     */
    func deactivateImmediateConstraints() {
        NSLayoutConstraint.deactivate(self.immediateConstraints)
    }
    /**
     * Deactivates all constrains that target this view
     */
    func deactiveAllConstraints() {
        NSLayoutConstraint.deactivate(self.allConstraints)
    }
    /**
     * Gets self.constraints + superview?.constraints for this particular view
     */
    var immediateConstraints: [NSLayoutConstraint] {
        let constraints = self.superview?.constraints.filter {
            $0.firstItem as? UIView === self || $0.secondItem as? UIView === self
            } ?? []
        return self.constraints + constraints
    }
    /**
     * Crawls up superview hierarchy and gets all constraints that affect this view
     */
    var allConstraints: [NSLayoutConstraint] {
        var view: UIView? = self
        var constraints: [NSLayoutConstraint] = []
        while let currentView = view {
            constraints += currentView.constraints.filter {
                return $0.firstItem as? UIView === self || $0.secondItem as? UIView === self
            }
            view = view?.superview
        }
        return constraints
    }

}
