//
//  VCPresenter.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/19/18.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import Anchorage
import Foundation
import SafariServices

public class VCPresenter {

    public static func showVC(viewController: UIViewController, popupIfPossible: Bool, parentNavigationController: UINavigationController?, parentViewController: UIViewController?) {

        if viewController is SFHideSafariViewController {
            parentViewController?.present(viewController, animated: true)
            return
        }
        
        if viewController is InboxViewController {
            // Siri Shortcuts integration
            if #available(iOS 12.0, *) {
                let activity = InboxViewController.openInboxActivity()
                viewController.userActivity = activity
                activity.becomeCurrent()
            }
        }
        var override13 = false
        if #available(iOS 13, *) {
            override13 = true
        }
        var parentIs13 = false
        if parentNavigationController != nil {
            if #available(iOS 13.0, *) {
                if parentNavigationController!.modalPresentationStyle == .pageSheet && parentNavigationController!.viewControllers.count == 1 && !(parentNavigationController!.viewControllers[0] is MainViewController || parentNavigationController!.viewControllers[0] is NavigationHomeViewController) {
                    parentIs13 = true
                }
            }
        }
        if (UIDevice.current.userInterfaceIdiom != .pad && viewController is PagingCommentViewController && !parentIs13) || (viewController is WebsiteViewController && parentNavigationController != nil) || viewController is SFHideSafariViewController || SettingValues.disable13Popup {
            override13 = false
        }
        
        
        // Yes, this logic is a mess. I need to redo it sometime...
        let respectedOverride13 = override13
        var shouldPopup = popupIfPossible
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            if viewController is SingleSubredditViewController && SettingValues.disableSubredditPopupIpad {
                shouldPopup = false
            } else if (viewController is CommentViewController || viewController is PagingCommentViewController) && SettingValues.disablePopupIpad {
                shouldPopup = false
            }
        }

        override13 = override13 && (UIDevice.current.userInterfaceIdiom == .pad || (viewController is UIPageViewController || viewController is SettingsViewController))
        
        if (viewController is PagingCommentViewController || viewController is CommentViewController) && (parentViewController?.splitViewController != nil && UIDevice.current.userInterfaceIdiom == .pad && (SettingValues.appMode != .MULTI_COLUMN && SettingValues.appMode != .SINGLE)) && !(parentViewController is CommentViewController) && (!override13 || !parentIs13) {
            (parentViewController!.splitViewController)?.showDetailViewController(SwipeForwardNavigationController(rootViewController: viewController), sender: nil)
            return
        } else if ((!SettingValues.disablePopupIpad) && UIDevice.current.userInterfaceIdiom == .pad && shouldPopup) || ((parentNavigationController != nil && (override13 || parentNavigationController!.modalPresentationStyle != .pageSheet)) && shouldPopup && override13) || parentNavigationController == nil {
            
            if viewController is SingleSubredditViewController {
                (viewController as! SingleSubredditViewController).isModal = true
            }

            let newParent = TapBehindModalViewController.init(rootViewController: viewController)

            newParent.navigationBar.shadowImage = UIImage()
            newParent.navigationBar.isTranslucent = false

            let button = UIButtonWithContext(buttonImage: UIImage(sfString: SFSymbol.xmark, overrideString: "close"))
            button.parentController = newParent
            button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            button.addTarget(self, action: #selector(VCPresenter.handleCloseNav(controller:)), for: .touchUpInside)

            let barButton = UIBarButtonItem.init(customView: button)

            // Let's figure out how to present it
            let small: Bool = shouldPopup && UIScreen.main.traitCollection.userInterfaceIdiom == .pad && UIApplication.shared.statusBarOrientation != .portrait

            if small || override13 || respectedOverride13 {
                newParent.modalPresentationStyle = .pageSheet
                if !override13 && !respectedOverride13 {
                    newParent.modalTransitionStyle = .crossDissolve
                }
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
            let button = UIButtonWithContext(buttonImage: UIImage(sfString: SFSymbol.chevronLeft, overrideString: "close"))
            button.accessibilityLabel = "Back"
            button.accessibilityTraits = UIAccessibilityTraits.button
            button.parentController = parentNavigationController!
            button.addTarget(self, action: #selector(VCPresenter.handleBackButton(controller:)), for: .touchUpInside)

            let barButton = UIBarButtonItem.init(customView: button)

            parentNavigationController!.pushViewController(viewController, animated: true)

            viewController.navigationItem.leftBarButtonItem = barButton

            if !(parentViewController is SplitMainViewController) && !(parentViewController?.parent is SplitMainViewController) {
                viewController.navigationController?.interactivePopGestureRecognizer?.delegate = nil
                viewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            }
        }

    }
    
    public static func presentModally(viewController: UIViewController, _ parentViewController: UIViewController, _ preferredSize: CGSize? = nil) {
        let newParent = TapBehindModalViewController(rootViewController: viewController)
        newParent.navigationBar.shadowImage = UIImage()
        newParent.navigationBar.isTranslucent = false
        newParent.navigationBar.barTintColor = UIColor.foregroundColor
        newParent.view.backgroundColor = UIColor.foregroundColor
        let button = UIButtonWithContext.init(type: .custom)
        button.parentController = newParent
        button.contextController = parentViewController
        button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
        button.setImage(UIImage(sfString: SFSymbol.xmark, overrideString: "close")!.navIcon().getCopy(withSize: CGSize.square(size: 20)), for: UIControl.State.normal)
        button.frame = CGRect.init(x: -10, y: 0, width: 35, height: 35)
        button.clipsToBounds = true
        button.layer.cornerRadius = 35 / 2
        button.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        button.addTarget(self, action: #selector(VCPresenter.handleCloseNav(controller:)), for: .touchUpInside)
        let barButton = UIBarButtonItem.init(customView: button)
        
        newParent.modalPresentationStyle = .custom
        newParent.view.layer.cornerRadius = 25
        newParent.view.layer.masksToBounds = true
        (UIApplication.shared.delegate as? AppDelegate)?.transitionDelegateModal = InsetTransitioningDelegate(preferredSize: preferredSize ?? CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: UIScreen.main.bounds.size.height * 0.6), scroll: viewController, presentedViewController: newParent, presenting: parentViewController)
        if let delegate = (UIApplication.shared.delegate as? AppDelegate)?.transitionDelegateModal {
            newParent.transitioningDelegate = delegate
        }
        newParent.view.backgroundColor = UIColor.foregroundColor
        if let popover = newParent.popoverPresentationController {
            popover.sourceView = parentViewController.view
            popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popover.backgroundColor = UIColor.foregroundColor
            
            popover.sourceRect = CGRect(x: parentViewController.view.bounds.midX, y: parentViewController.view.bounds.midY, width: 0, height: 0)
            if parentViewController is MediaViewController {
                popover.delegate = (parentViewController as! MediaViewController)
            } else if parentViewController is MediaTableViewController {
                popover.delegate = (parentViewController as! MediaTableViewController)
            }
        }
        // TODO deallocate that delegate....
        
        viewController.navigationItem.rightBarButtonItems = [barButton]
        parentViewController.present(newParent, animated: true, completion: nil)
    }

    public static func proDialogShown(feature: Bool, _ parentViewController: UIViewController) -> Bool {
        if (feature && !SettingValues.isPro) || (!feature && !SettingValues.isPro) {
            let viewController = SettingsPro()
            viewController.view.backgroundColor = UIColor.foregroundColor
            let newParent = TapBehindModalViewController.init(rootViewController: viewController)
            newParent.navigationBar.shadowImage = UIImage()
            newParent.navigationBar.isTranslucent = false
            newParent.navigationBar.barTintColor = UIColor.foregroundColor

            newParent.navigationBar.shadowImage = UIImage()
            newParent.navigationBar.isTranslucent = false

            let button = UIButtonWithContext.init(type: .custom)
            button.parentController = newParent
            button.imageView?.contentMode = UIView.ContentMode.scaleAspectFit
            button.setImage(UIImage(sfString: SFSymbol.xmark, overrideString: "close")!.navIcon(), for: UIControl.State.normal)
            button.frame = CGRect.init(x: 0, y: 0, width: 40, height: 40)
            button.addTarget(self, action: #selector(VCPresenter.handleCloseNav(controller:)), for: .touchUpInside)

            let barButton = UIBarButtonItem.init(customView: button)
            barButton.customView?.frame = CGRect.init(x: 0, y: 0, width: 40, height: 40)
            newParent.modalPresentationStyle = .pageSheet

            viewController.navigationItem.rightBarButtonItems = [barButton]

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
        let button = UIButtonWithContext(buttonImage: UIImage(sfString: SFSymbol.xmark, overrideString: "close"))
        button.parentController = newParent
        button.contextController = parentViewController
        button.addTarget(self, action: #selector(VCPresenter.handleCloseNav(controller:)), for: .touchUpInside)
        
        let barButton = UIBarButtonItem.init(customView: button)
        
        newParent.modalPresentationStyle = .popover
        newParent.view.backgroundColor = UIColor.backgroundColor
        if let popover = newParent.popoverPresentationController {
            popover.sourceView = parentViewController.view
            popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popover.backgroundColor = UIColor.backgroundColor

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
       // TODO: - for iOS 13 alertController.modalPresentationStyle = .formSheet
        parentVC.present(alertController, animated: true, completion: nil)
    }

    public static func openRedditLink(_ link: String, _ parentNav: UINavigationController?, _ parentVC: UIViewController?) {
        let vc = RedditLink.getViewControllerForURL(urlS: URL.initPercent(string: link)!)
        if vc is SingleSubredditViewController {
            // Siri Shortcuts integration
            if #available(iOS 12.0, *) {
                let activity = SingleSubredditViewController.openSubredditActivity(subreddit: (vc as! SingleSubredditViewController).sub)
                vc.userActivity = activity
                activity.becomeCurrent()
            }
        }
        if let presented = recursivePresented(parentVC) {
            showVC(viewController: vc, popupIfPossible: true, parentNavigationController: presented.navigationController, parentViewController: presented)
        } else {
            showVC(viewController: vc, popupIfPossible: true, parentNavigationController: parentNav, parentViewController: parentVC)
        }
    }
    
    static func recursivePresented(_ viewController: UIViewController?) -> UIViewController? {
        var currentParent = viewController
        
        while currentParent != nil {
            if currentParent?.presentedViewController != nil {
                currentParent = currentParent?.presentedViewController
            } else {
                return currentParent
            }
        }
        
        return currentParent
    }
}

public class DefaultGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

public class UIButtonWithContext: UIButton {
    weak var parentController: UINavigationController?
    weak var contextController: UIViewController?
}

extension URL {
    static func initPercent(string: String) -> URL? {
        let urlwithPercentEscapes = string.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)
        let url = URL.init(string: urlwithPercentEscapes!)
        return url
    }
}
