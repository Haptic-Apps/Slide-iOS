//
// Created by Carlos Crane on 2/11/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import Foundation

public class ColorMuxPagingViewController: UIPageViewController, UIScrollViewDelegate {
    public var color1, color2: UIColor?
    public var viewToMux: UIView?
    public var navToMux: UINavigationBar?
    private weak var match: UICollectionView?
    public var dontMatch = false
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for view in self.view.subviews {
            if !(view is UICollectionView) {
                if let scrollView = view as? UIScrollView {
                    scrollView.delegate = self
                    if let nav = self.navigationController?.interactivePopGestureRecognizer {
                        scrollView.panGestureRecognizer.require(toFail: nav)
                    }
                }
            }
        }
    }
    
    public func requireFailureOf(_ gesture: UIGestureRecognizer) {
        for view in self.view.subviews {
            if !(view is UICollectionView) {
                if let scrollView = view as? UIScrollView {
                    scrollView.delaysContentTouches = false
                    scrollView.panGestureRecognizer.require(toFail: gesture)
                }
            }
        }
    }
    
    public func matchScroll(scrollView: UICollectionView) {
        self.match = scrollView
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let point = scrollView.contentOffset
        var percentComplete: CGFloat
        percentComplete = abs(point.x - self.view.frame.size.width) / self.view.frame.size.width

        if let color1 = color1, let color2 = color2 {
            if !color2.cgColor.__equalTo(color1.cgColor) {
                let lerpedColor = ColorMuxPagingViewController.fadeFromColor(fromColor: color1, toColor: color2, withPercentage: percentComplete)
                if !lerpedColor.cgColor.__equalTo(color1.cgColor) && percentComplete > 0.1 && percentComplete != 1 {
                    viewToMux?.backgroundColor = lerpedColor
                    navToMux?.barTintColor = lerpedColor
                }
            }
        }
        
        if let currentIndex = (self as? MainViewController)?.currentIndex, let totalCount = (self as? MainViewController)?.finalSubs.count {
            if currentIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width {
                scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
            } else if currentIndex == totalCount - 1 && scrollView.contentOffset.x > scrollView.bounds.size.width {
                scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
            }
            if let strongMatch = match, !dontMatch {
                var currentBackgroundOffset = strongMatch.contentOffset
                            
                //Translate percentage of current view translation to the parent scroll view, add in original offset
                //currentBackgroundOffset.x = ((currentY - (CGFloat(currentIndex) * strongMatch.collectionViewLayout.itemSize.width)) / (scrollView.frame.size.width - 140 )) * parent.frame.size.width
                var offsetX = (strongMatch.superview!.frame.origin.x / 2) - ((strongMatch.superview!.frame.maxX - strongMatch.superview!.frame.size.width) / 2) //Collectionview left offset for profile icon
                currentBackgroundOffset.x = offsetX + ((scrollView.contentOffset.x / scrollView.frame.size.width) * (strongMatch.collectionViewLayout as! UICollectionViewFlowLayout).itemSize.width) + (strongMatch.collectionViewLayout as! UICollectionViewFlowLayout).itemSize.width * CGFloat(currentIndex - 1)
                print(currentBackgroundOffset)
                strongMatch.contentOffset = currentBackgroundOffset
                strongMatch.layoutIfNeeded()
            }

        }
    }
        
    //From https://stackoverflow.com/a/25167681/3697225
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if let currentIndex = (self as? MainViewController)?.currentIndex, let totalCount = (self as? MainViewController)?.finalSubs.count {
            if currentIndex == 0 && scrollView.contentOffset.x <= scrollView.bounds.size.width {
                targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
            } else if currentIndex == totalCount - 1 && scrollView.contentOffset.x >= scrollView.bounds.size.width {
                targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
            }
        }
    }

    static func fadeFromColor(fromColor: UIColor, toColor: UIColor, withPercentage: CGFloat) -> UIColor {
        var fromRed: CGFloat = 0.0
        var fromGreen: CGFloat = 0.0
        var fromBlue: CGFloat = 0.0
        var fromAlpha: CGFloat = 0.0

        fromColor.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)

        var toRed: CGFloat = 0.0
        var toGreen: CGFloat = 0.0
        var toBlue: CGFloat = 0.0
        var toAlpha: CGFloat = 0.0

        toColor.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)

        // Calculate the actual RGBA values of the fade color
        let red = (toRed - fromRed) * withPercentage + fromRed
        let green = (toGreen - fromGreen) * withPercentage + fromGreen
        let blue = (toBlue - fromBlue) * withPercentage + fromBlue

        // Return the fade color
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

}
extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0

        return String(format: "#%06x", rgb)
    }
}
