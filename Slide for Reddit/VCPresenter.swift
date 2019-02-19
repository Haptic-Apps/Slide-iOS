//
//  VCPresenter.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/19/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Foundation
import SafariServices

public class VCPresenter {

    public static func showVC(viewController: UIViewController, popupIfPossible: Bool, parentNavigationController: UINavigationController?, parentViewController: UIViewController?) {

        if viewController is SFHideSafariViewController {
            parentViewController?.present(viewController, animated: true)
            return
        }
        
        if (viewController is PagingCommentViewController || viewController is CommentViewController) && parentViewController?.splitViewController != nil && !(parentViewController is CommentViewController) {
            (parentViewController!.splitViewController)?.showDetailViewController(UINavigationController(rootViewController: viewController), sender: nil)
            return
        } else if (parentViewController?.splitViewController != nil) || ((parentNavigationController != nil && parentNavigationController!.modalPresentationStyle != .pageSheet) && popupIfPossible && UIApplication.shared.statusBarOrientation.isLandscape) || parentNavigationController == nil {
            
            if viewController is SingleSubredditViewController {
                (viewController as! SingleSubredditViewController).isModal = true
            }

            let newParent = TapBehindModalViewController.init(rootViewController: viewController)

            newParent.navigationBar.shadowImage = UIImage()
            newParent.navigationBar.isTranslucent = false

            let button = UIButtonWithContext.init(type: .custom)
            button.parentController = newParent
            button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            button.setImage(UIImage.init(named: "close")!.navIcon(), for: UIControl.State.normal)
            button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            button.addTarget(self, action: #selector(VCPresenter.handleCloseNav(controller:)), for: .touchUpInside)

            let barButton = UIBarButtonItem.init(customView: button)

            //Let's figure out how to present it
            let small: Bool = popupIfPossible && UIScreen.main.traitCollection.userInterfaceIdiom == .pad && UIApplication.shared.statusBarOrientation != .portrait

            if small {
                newParent.modalPresentationStyle = .pageSheet
                newParent.modalTransitionStyle = .crossDissolve
            } else {
                newParent.modalPresentationStyle = .fullScreen
                newParent.modalTransitionStyle = .crossDissolve
            }

            viewController.navigationItem.leftBarButtonItems = [barButton]

            parentViewController!.present(newParent, animated: true, completion: nil)
            if viewController is SFHideSafariViewController {
                newParent.setNavigationBarHidden(true, animated: false)
            }
            if !(viewController is SingleSubredditViewController) {
                viewController.setupBaseBarColors()
            }
        } else {
            let button = UIButtonWithContext.init(type: .custom)
            button.accessibilityLabel = "Back"
            button.accessibilityTraits = UIAccessibilityTraits.button
            button.parentController = parentNavigationController!
            button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            button.setImage(UIImage.init(named: "back")!.navIcon(), for: UIControl.State.normal)
            button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            button.addTarget(self, action: #selector(VCPresenter.handleBackButton(controller:)), for: .touchUpInside)

            let barButton = UIBarButtonItem.init(customView: button)

            parentNavigationController!.pushViewController(viewController, animated: true)

            viewController.navigationItem.leftBarButtonItem = barButton

            viewController.navigationController?.interactivePopGestureRecognizer?.delegate = DefaultGestureDelegate()
            viewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }

    }

    public static func proDialogShown(feature: Bool, _ parentViewController: UIViewController) -> Bool {
        if (feature && !SettingValues.isPro) || (!feature && !SettingValues.isPro) {
            let viewController = SettingsPro()
            let newParent = TapBehindModalViewController.init(rootViewController: viewController)
            newParent.navigationBar.shadowImage = UIImage()
            newParent.navigationBar.isTranslucent = false
            newParent.closeCallback = {
                if parentViewController is MediaViewController {
                    (parentViewController as! MediaViewController).setAlphaOfBackgroundViews(alpha: 1)
                } else if parentViewController is MediaTableViewController {
                    (parentViewController as! MediaTableViewController).setAlphaOfBackgroundViews(alpha: 1)
                }
            }
            let button = UIButtonWithContext.init(type: .custom)
            button.parentController = newParent
            button.contextController = parentViewController
            button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            button.setImage(UIImage.init(named: "close")!.navIcon(), for: UIControl.State.normal)
            button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            button.addTarget(self, action: #selector(VCPresenter.handleCloseNav(controller:)), for: .touchUpInside)
            
            let barButton = UIBarButtonItem.init(customView: button)
            
            newParent.modalPresentationStyle = .popover
            newParent.view.backgroundColor = ColorUtil.backgroundColor
            if let popover = newParent.popoverPresentationController {
                popover.sourceView = parentViewController.view
                popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                popover.backgroundColor = ColorUtil.backgroundColor
                
                popover.sourceRect = CGRect(x: parentViewController.view.bounds.midX, y: parentViewController.view.bounds.midY, width: 0, height: 0)
                if parentViewController is MediaViewController {
                    popover.delegate = (parentViewController as! MediaViewController)
                } else if parentViewController is MediaTableViewController {
                    popover.delegate = (parentViewController as! MediaTableViewController)
                }
            }
            
            viewController.navigationItem.leftBarButtonItems = [barButton]
        
            parentViewController.present(newParent, animated: true, completion: nil)
            return true
        }
        return false
    }

    public static func donateDialog(_ parentViewController: UIViewController) {
        let viewController = SettingsDonate()
        let newParent = TapBehindModalViewController.init(rootViewController: viewController)
        newParent.navigationBar.shadowImage = UIImage()
        newParent.navigationBar.isTranslucent = false
        newParent.closeCallback = {
            if parentViewController is MediaViewController {
                (parentViewController as! MediaViewController).setAlphaOfBackgroundViews(alpha: 1)
            } else if parentViewController is MediaTableViewController {
                (parentViewController as! MediaTableViewController).setAlphaOfBackgroundViews(alpha: 1)
            }
        }
        let button = UIButtonWithContext.init(type: .custom)
        button.parentController = newParent
        button.contextController = parentViewController
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage.init(named: "close")!.navIcon(), for: UIControl.State.normal)
        button.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        button.addTarget(self, action: #selector(VCPresenter.handleCloseNav(controller:)), for: .touchUpInside)
        
        let barButton = UIBarButtonItem.init(customView: button)
        
        newParent.modalPresentationStyle = .popover
        newParent.view.backgroundColor = ColorUtil.backgroundColor
        if let popover = newParent.popoverPresentationController {
            popover.sourceView = parentViewController.view
            popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popover.backgroundColor = ColorUtil.backgroundColor

            popover.sourceRect = CGRect(x: parentViewController.view.bounds.midX, y: parentViewController.view.bounds.midY, width: 0, height: 0)
            if parentViewController is MediaViewController {
                popover.delegate = (parentViewController as! MediaViewController)
            } else if parentViewController is MediaTableViewController {
                popover.delegate = (parentViewController as! MediaTableViewController)
            }
        }
        
        viewController.navigationItem.leftBarButtonItems = [barButton]
        
        parentViewController.present(newParent, animated: true, completion: nil)
    }

    @objc public static func handleBackButton(controller: UIButtonWithContext) {
        controller.parentController!.popViewController(animated: true)
    }

    @objc public static func handleCloseNav(controller: UIButtonWithContext) {
        if controller.contextController is MediaViewController {
            (controller.contextController as! MediaViewController).setAlphaOfBackgroundViews(alpha: 1)
        } else if controller.contextController is MediaTableViewController {
            (controller.contextController as! MediaTableViewController).setAlphaOfBackgroundViews(alpha: 1)
        }
        controller.parentController!.dismiss(animated: true)
    }

    public static func presentAlert(_ alertController: UIViewController, parentVC: UIViewController) {
        parentVC.present(alertController, animated: true, completion: nil)
    }

    public static func openRedditLink(_ link: String, _ parentNav: UINavigationController?, _ parentVC: UIViewController?) {
        let vc = RedditLink.getViewControllerForURL(urlS: URL.init(string: link)!)
        showVC(viewController: vc, popupIfPossible: true, parentNavigationController: parentNav, parentViewController: parentVC)

    }
}

public class DefaultGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

}

public class UIButtonWithContext: UIButton {
    public var parentController: UINavigationController?
    public var contextController: UIViewController?
}
