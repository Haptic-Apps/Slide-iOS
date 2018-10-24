//
// Created by Carlos Crane on 2/11/18.
// Copyright (c) 2018 Haptic Apps. All rights reserved.
//

import Foundation

public class ColorMuxPagingViewController: UIPageViewController, UIScrollViewDelegate {
    public var color1, color2: UIColor?
    public var viewToMux: UIView?
    public var navToMux: UINavigationBar?
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for view in self.view.subviews {
            if !(view is UICollectionView) {
                if let scrollView = view as? UIScrollView {
                    scrollView.delegate = self
                }
            }
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let point = scrollView.contentOffset

        var percentComplete: CGFloat
        percentComplete = fabs(point.x - self.view.frame.size.width) / self.view.frame.size.width

        if viewToMux != nil && color1 != nil && color2 != nil {
            let color = ColorMuxPagingViewController.fadeFromColor(fromColor: color1!, toColor: color2!, withPercentage: percentComplete)
            if percentComplete > 0.1 && percentComplete != 1 {
                viewToMux!.backgroundColor = color
            }
        }

        if navToMux != nil {
            let color = ColorMuxPagingViewController.fadeFromColor(fromColor: color1!, toColor: color2!, withPercentage: percentComplete)
            if percentComplete > 0 {
                navToMux!.barTintColor = color
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

        //calculate the actual RGBA values of the fade colour
        let red = (toRed - fromRed) * withPercentage + fromRed
        let green = (toGreen - fromGreen) * withPercentage + fromGreen
        let blue = (toBlue - fromBlue) * withPercentage + fromBlue
        let alpha = (toAlpha - fromAlpha) * withPercentage + fromAlpha

        // return the fade colour
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
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
