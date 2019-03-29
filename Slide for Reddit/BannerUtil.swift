//
//  BannerUtil.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 6/26/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

public class BannerUtil {
    public var popup = UILabel()
    public var cancelled = false
    public static var banner: BannerUtil?
    var originalPosition = CGPoint.zero
    var currentPositionTouched = CGPoint.zero

    public func cancel() {
        self.cancelled = true
        popup.removeFromSuperview()
    }

    public static func makeBanner(text: String, color: UIColor = ColorUtil.accentColorForSub(sub: ""), seconds: TimeInterval, context: UIViewController?, top: Bool = false, callback: (() -> Void)? = nil) {
        if banner != nil {
            banner?.cancel()
        }
        if let context = context {
            banner = BannerUtil.init().makeBanner(text: text, color: color, seconds: seconds, context: context, top: top, callback: callback)
        }
    }

    func makeBanner(text: String, color: UIColor = ColorUtil.accentColorForSub(sub: ""), seconds: TimeInterval, context: UIViewController, top: Bool, callback: (() -> Void)? = nil) -> BannerUtil {
        var xmargin = CGFloat(12)
        if UIScreen.main.bounds.width > 350 {
            xmargin += (UIScreen.main.bounds.width - 350) / 2
        }
        popup = UILabel.init(frame: CGRect.zero)
        popup.backgroundColor = color
        popup.textAlignment = .center
        popup.isUserInteractionEnabled = true
        
        let textParts = text.components(separatedBy: "\n")
        
        let finalText: NSMutableAttributedString!
        if textParts.count > 1 {
            let firstPart = NSMutableAttributedString.init(string: textParts[0], attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
            let secondPart = NSMutableAttributedString.init(string: "\n" + textParts[1], attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12)]))
            firstPart.append(secondPart)
            finalText = firstPart
        } else {
            finalText = NSMutableAttributedString.init(string: text, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
        }
        popup.attributedText = finalText
        popup.numberOfLines = 0
        popup.elevate(elevation: 2)
        popup.clipsToBounds = true
        popup.layer.cornerRadius = 10
        popup.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(viewPanned(_:)))
        pan.direction = .vertical
        pan.cancelsTouchesInView = false

        popup.addGestureRecognizer(pan)
        let toView: UIView
      //  if context.navigationController != nil {
      //      toView = context.navigationController!.view
      //  } else {
            toView = context.view
      //  }
        toView.addSubview(popup)
        toView.bringSubviewToFront(popup)
        if top {
            if #available(iOS 11, *) {
                popup.topAnchor == toView.safeTopAnchor + 12
            } else {
                popup.topAnchor == toView.safeTopAnchor + 64
            }
        } else {
            if #available(iOS 11, *) {
                popup.bottomAnchor == toView.safeBottomAnchor - 12
                if context is MainViewController {
                    let bottomOffset = ((context as! MainViewController).menuNav?.bottomOffset ?? 0)
                    popup.bottomAnchor == toView.bottomAnchor - bottomOffset - 12 - (!SettingValues.hiddenFAB ? 12 : 0)
                } else if context is SingleSubredditViewController && !(context as! SingleSubredditViewController).single {
                    popup.bottomAnchor == toView.bottomAnchor - 64 - 12 - (SettingValues.hiddenFAB ? 12 : 0)
                }
            } else {
                popup.bottomAnchor == toView.safeBottomAnchor - 56
                if context is MainViewController {
                    let bottomOffset = ((context as! MainViewController).menuNav?.bottomOffset ?? 0)
                    popup.bottomAnchor == toView.bottomAnchor - bottomOffset - 56 - (!SettingValues.hiddenFAB ? 12 : 0)
                } else if context is SingleSubredditViewController && !(context as! SingleSubredditViewController).single {
                    popup.bottomAnchor == toView.bottomAnchor - 64 - 56 - (SettingValues.hiddenFAB ? 12 : 0)
                }
            }
        }
        popup.horizontalAnchors == toView.horizontalAnchors + 12 + xmargin
        popup.widthAnchor == (UIScreen.main.bounds.width - (2 * (12 + xmargin)))
        popup.heightAnchor == (CGFloat(48) + CGFloat((text.contains("\n")) ? 24 : 0))
        popup.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
            self.popup.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
        }, completion: { _ in
            if let callback = callback {
                self.popup.addTapGestureRecognizer {
                    callback()
                    self.cancel()
                }
            }
        })
        
        if seconds > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: [.curveEaseInOut], animations: {
                    if !self.cancelled {
                        self.popup.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
                    }
                }, completion: { _ in
                    if !self.cancelled {
                        self.popup.removeFromSuperview()
                        BannerUtil.banner = nil
                    }
                })
            }
        }
        return self
    }
}

extension BannerUtil {
    @objc func viewPanned(_ panGesture: UIPanGestureRecognizer) {
        let viewToMove = popup

        let translation = panGesture.translation(in: viewToMove)
        
        if panGesture.state == .began {
            originalPosition = viewToMove.frame.origin
            currentPositionTouched = panGesture.location(in: viewToMove)
        } else if panGesture.state == .changed {
            viewToMove.frame.origin = CGPoint(
                x: originalPosition.x,
                y: translation.y + originalPosition.y
            )
            let progress = abs(translation.y) / viewToMove.frame.size.height
            viewToMove.alpha = 1.5 - progress
        } else if panGesture.state == .ended {
            let velocity = panGesture.velocity(in: viewToMove)
            
            let down = panGesture.velocity(in: viewToMove.superview ?? viewToMove).y > 0
            if abs(velocity.y) >= 1000 || abs(viewToMove.frame.origin.y - originalPosition.y) > viewToMove.frame.size.height / 2 {
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                    viewToMove.alpha = 0
                    viewToMove.frame.origin = CGPoint(
                        x: viewToMove.frame.origin.x,
                        y: (viewToMove.frame.size.height * (down ? 1 : -1)) + self.originalPosition.y)
                    
                }, completion: { (isCompleted) in
                    if isCompleted {
                        self.cancel()
                    }
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    viewToMove.frame.origin = self.originalPosition
                })
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
