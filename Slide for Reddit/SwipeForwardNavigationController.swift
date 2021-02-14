//
//  SwipeForwardNavigationController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/18/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//
//  Swift code based on Christopher Wendel  https://github.com/CEWendel/SWNavigationController/blob/master/SWNavigationController/PodFiles/SWNavigationController.m
//

import UIKit
typealias SWNavigationControllerPushCompletion = () -> Void

class SwipeForwardNavigationController: UINavigationController {
    private var percentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition?
    public var interactivePushGestureRecognizer: UIScreenEdgePanGestureRecognizer?
    public var pushableViewControllers: [UIViewController] = []
 /* View controllers we can push onto the navigation stack by pulling in from the right screen edge. */    // Extra state used to implement completion blocks on pushViewController:
    public var pushCompletion: SWNavigationControllerPushCompletion?
    private var pushedViewController: UIViewController?
    public var fullWidthBackGestureRecognizer = UIPanGestureRecognizer()

    var pushAnimatedTransitioningClass: SwipeForwardAnimatedTransitioning?
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var childForHomeIndicatorAutoHidden: UIViewController? {
        return nil
    }

    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)

        setup()
    }
    
    override var childForStatusBarHidden: UIViewController? {
        return topViewController
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        setup()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        setup()
    }
    
    func setup() {
        pushableViewControllers = [UIViewController]()

        delegate = self
        pushAnimatedTransitioningClass = SwipeForwardAnimatedTransitioning()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        interactivePushGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleRightSwipe(_:)))
        interactivePushGestureRecognizer?.edges = UIRectEdge.right
        interactivePushGestureRecognizer?.delegate = self
        view.addGestureRecognizer(interactivePushGestureRecognizer!)
        
        // To ensure swipe-back is still recognized
        interactivePopGestureRecognizer?.delegate = self
        
        if let interactivePopGestureRecognizer = interactivePopGestureRecognizer, let targets = interactivePopGestureRecognizer.value(forKey: "targets") {
            fullWidthBackGestureRecognizer.setValue(targets, forKey: "targets")
            fullWidthBackGestureRecognizer.delegate = self
            fullWidthBackGestureRecognizer.require(toFail: interactivePushGestureRecognizer!)
            view.addGestureRecognizer(fullWidthBackGestureRecognizer)
            if #available(iOS 13.4, *) {
                fullWidthBackGestureRecognizer.allowedScrollTypesMask = .continuous
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.splitViewController?.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        if let last = pushableViewControllers.last as? SplitMainViewController {
            pushableViewControllers.removeAll()
            pushableViewControllers.append(last)
        } else {
            pushableViewControllers.removeAll()
        }
    }

    @objc func handleRightSwipe(_ swipeGestureRecognizer: UIScreenEdgePanGestureRecognizer?) {
        let view = self.view!
        let progress = abs(-(swipeGestureRecognizer?.translation(in: view).x ?? 0.0) / view.frame.size.width) // 1.0 When the pushable vc has been pulled into place

        // Start, update, or finish the interactive push transition
        switch swipeGestureRecognizer?.state {
        case .began:
            pushNextViewControllerFromRight(nil)
        case .changed:
            percentDrivenInteractiveTransition?.update(progress)
        case .ended:
            // Figure out if we should finish the transition or not
            handleEdgeSwipeEnded(withProgress: progress, velocity: swipeGestureRecognizer?.velocity(in: view).x ?? 0)
        case .failed:
            percentDrivenInteractiveTransition?.cancel()
        case .cancelled, .possible:
            fallthrough
        default:
            break
        }
    }
    
    @objc func handleRightSwipeFull(_ swipeGestureRecognizer: UIPanGestureRecognizer?) {
        let view = self.view!
        let progress = abs(-(swipeGestureRecognizer?.translation(in: view).x ?? 0.0) / view.frame.size.width) // 1.0 When the pushable vc has been pulled into place

        // Start, update, or finish the interactive push transition
        switch swipeGestureRecognizer?.state {
        case .began:
            pushNextViewControllerFromRight(nil)
        case .changed:
            percentDrivenInteractiveTransition?.update(progress)
        case .ended:
            // Figure out if we should finish the transition or not
            handleEdgeSwipeEnded(withProgress: progress, velocity: swipeGestureRecognizer?.velocity(in: view).x ?? 0)
        case .failed:
            percentDrivenInteractiveTransition?.cancel()
        case .cancelled, .possible:
            fallthrough
        default:
            break
        }
    }

    func handleEdgeSwipeEnded(withProgress progress: CGFloat, velocity: CGFloat) {
        // kSWGestureVelocityThreshold threshold indicates how hard the finger has to flick left to finish the push transition
        if velocity < 0 && (progress > 0.5 || velocity < -500) {
            percentDrivenInteractiveTransition?.finish()
        } else {
            percentDrivenInteractiveTransition?.cancel()
        }
    }
}

extension SwipeForwardNavigationController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var shouldBegin = false

        if gestureRecognizer == interactivePushGestureRecognizer || (gestureRecognizer == NavigationHomeViewController.edgeGesture && topViewController is NavigationHomeViewController) {
            shouldBegin = pushableViewControllers.count > 0 && !((pushableViewControllers.last) == topViewController)
        } else {
            shouldBegin = viewControllers.count > 1
            
            if gestureRecognizer == fullWidthBackGestureRecognizer {
                let velocity = fullWidthBackGestureRecognizer.velocity(in: view)

                let rad = atan(velocity.y / velocity.x)
                let deg = rad * 180 / CGFloat.pi

                if abs(deg) > 45 && velocity.x > 0 { // Only accept if the angle of the gesture is below 45 degrees (horizontal)
                    shouldBegin = false
                }
            } else if gestureRecognizer == interactivePushGestureRecognizer {
                let velocity = fullWidthBackGestureRecognizer.velocity(in: view)

                let rad = atan(velocity.y / velocity.x)
                let deg = rad * 180 / CGFloat.pi

                if abs(deg) > 45 && velocity.x < 0 { // Only accept if the angle of the gesture is below 45 degrees and in the  (horizontal)
                    shouldBegin = false
                }
            }
        }
        return shouldBegin
    }
}
    
extension SwipeForwardNavigationController {

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        pushableViewControllers.removeAll()

        super.pushViewController(viewController, animated: animated)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        // Dismiss the current view controllers keyboard (if it is displaying one), to avoid first responder problems when pushing back onto the stack
        topViewController?.view.endEditing(true)

        let poppedViewController = super.popViewController(animated: animated)
        if let poppedViewController = poppedViewController {
            pushableViewControllers.append(poppedViewController)
        }
        return poppedViewController
    }
    
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let poppedViewControllers = super.popToViewController(viewController, animated: animated)
        self.pushableViewControllers = poppedViewControllers?.backwards() ?? []

        return poppedViewControllers ?? []
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let poppedViewControllers = super.popToRootViewController(animated: true)

        if let all = poppedViewControllers?.backwards() {
            pushableViewControllers = all
        }

        return poppedViewControllers
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        
        self.pushableViewControllers.removeAll()
    }
    
    func push(_ viewController: UIViewController?, animated: Bool, completion: @escaping SWNavigationControllerPushCompletion) {
        pushedViewController = viewController
        pushCompletion = completion
        if let viewController = viewController {
            super.pushViewController(viewController, animated: animated)
        }
    }
    
    override func collapseSecondaryViewController(_ secondaryViewController: UIViewController, for splitViewController: UISplitViewController) {
        var not14 = true
        if #available(iOS 14, *) {
            not14 = false
        }
        if let secondaryAsNav = secondaryViewController as? UINavigationController, (UIDevice.current.userInterfaceIdiom == .phone || not14) {
            for viewController in secondaryAsNav.viewControllers {
                if !viewControllers.contains(viewController) {
                    viewControllers.append(viewController)
                }
            }
        }
    }

    func pushNextViewControllerFromRight(_ callback: (() -> Void)?) {
        let pushedViewController = pushableViewControllers.last

        if pushedViewController != nil && visibleViewController != nil && visibleViewController?.isBeingPresented == false && visibleViewController?.isBeingDismissed == false {
            push(pushedViewController, animated: (UIApplication.shared.isSplitOrSlideOver && !UIApplication.shared.isMac()) ? false : true) {
                if !self.pushableViewControllers.isEmpty {
                    self.pushableViewControllers.removeLast()
                    callback?()
                }
            }
        }
    }
}

extension SwipeForwardNavigationController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if #available(iOS 13, *) {
            return self // Disable left sidebar
        } else {
            if UIDevice.current.userInterfaceIdiom == .phone {
                guard let primaryNavigation = primaryViewController as? UINavigationController else {
                  return nil
                }
                return decomposeStackForTransitionToRegular(primaryNavigation)
            }
        }
        return nil
    }
    
    func decomposeStackForTransitionToRegular(_ navigationController: UINavigationController) -> UIViewController? {
        var main: UIViewController?
        var newViewControllers = [UIViewController]()
        
        for viewController in navigationController.viewControllers.reversed() { // viewControllers is LIFO, reverse it
            if viewController is MainViewController {
                let newNav = SwipeForwardNavigationController(rootViewController: viewController)
                for previousVC in newViewControllers.reversed() { // put back in LIFO
                    newNav.pushViewController(previousVC, animated: false)
                }
                return newNav
            } else {
                newViewControllers.append(viewController)
            }
        }
        
        for viewController in pushableViewControllers {
            if viewController is MainViewController {
                main = viewController
            }
        }
        if let main = main {
            return SwipeForwardNavigationController(rootViewController: main)
        }
        return nil
    }
}

extension SwipeForwardNavigationController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push && (((navigationController as? SwipeForwardNavigationController)?.interactivePushGestureRecognizer)?.state == .began || NavigationHomeViewController.edgeGesture?.state == .began) {
            return self.pushAnimatedTransitioningClass
        }
        return nil
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        let navController = navigationController as? SwipeForwardNavigationController
        if navController?.interactivePushGestureRecognizer?.state == .began || NavigationHomeViewController.edgeGesture?.state == .began {
            navController?.percentDrivenInteractiveTransition = UIPercentDrivenInteractiveTransition()
            navController?.percentDrivenInteractiveTransition?.completionCurve = .easeOut
        } else {
            navController?.percentDrivenInteractiveTransition = nil
        }

        return navController?.percentDrivenInteractiveTransition
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if pushedViewController != viewController {
            pushedViewController = nil
            pushCompletion = nil
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if (pushCompletion != nil) && pushedViewController == viewController {
            pushCompletion?()
        }

        pushCompletion = nil
        pushedViewController = nil
    }
}
