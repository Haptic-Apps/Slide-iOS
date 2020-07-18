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
let kSWGestureVelocityThreshold = 800

typealias SWNavigationControllerPushCompletion = () -> Void

class SwipeForwardNavigationController: UINavigationController {
    private var percentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition?
    private var interactivePushGestureRecognizer: UIScreenEdgePanGestureRecognizer?
    private var pushableViewControllers: [AnyHashable]?
 /* View controllers we can push onto the navigation stack by pulling in from the right screen edge. */    // Extra state used to implement completion blocks on pushViewController:
    private var pushCompletion: SWNavigationControllerPushCompletion?
    private var pushedViewController: UIViewController?
    
    init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        setup()
    }

    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        setup()
    }
    
    func setup() {
        pushableViewControllers = [AnyHashable]()

        delegate = self
        pushAnimatedTransitioningClass = SWPushAnimatedTransitioning.self
    }

    func viewDidLoad() {
        super.viewDidLoad()

        interactivePushGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleRightSwipe(_:)))
        interactivePushGestureRecognizer.edges = UIRectEdge.right
        interactivePushGestureRecognizer.delegate = self
        view.addGestureRecognizer(interactivePushGestureRecognizer)

        // To ensure swipe-back is still recognized
        interactivePopGestureRecognizer?.delegate = self
    }

    func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        pushableViewControllers.removeAll()
    }

    func handleRightSwipe(_ swipeGestureRecognizer: UIScreenEdgePanGestureRecognizer?) {
        let progress = abs(-(swipeGestureRecognizer?.translation(in: view).x ?? 0.0) / view.frame.size.width) // 1.0 When the pushable vc has been pulled into place

        // Start, update, or finish the interactive push transition
        switch swipeGestureRecognizer?.state {
            case .began:
                pushNextViewControllerFromRight()
            case .changed:
                percentDrivenInteractiveTransition.update(progress)
            case .ended:
                // Figure out if we should finish the transition or not
                handleEdgeSwipeEnded(withProgress: progress, velocity: swipeGestureRecognizer?.velocity(in: view).x)
            case .failed:
                percentDrivenInteractiveTransition.cancelInteractiveTransition()
            case .cancelled, .possible:
                fallthrough
            default:
                break
        }
    }

    func handleEdgeSwipeEnded(withProgress progress: CGFloat, velocity: CGFloat) {
        // kSWGestureVelocityThreshold threshold indicates how hard the finger has to flick left to finish the push transition
        if velocity < 0 && (progress > 0.5 || velocity < -kSWGestureVelocityThreshold) {
            percentDrivenInteractiveTransition.finishInteractiveTransition()
        } else {
            percentDrivenInteractiveTransition.cancelInteractiveTransition()
        }
    }
}

extension SwipeForwardNavigationController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        var shouldBegin = false

        if gestureRecognizer == interactivePushGestureRecognizer {
            shouldBegin = pushableViewControllers.count > 0 && !((pushableViewControllers.last as? UIViewController) == topViewController)
        } else {
            shouldBegin = viewControllers.count > 1
        }

        return shouldBegin
    }
}
    
extension SwipeForwardNavigationController {
    //  Converted to Swift 5.1 by Swiftify v5.1.31847 - https://swiftify.com/
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
        let poppedViewControllers = popToViewController(viewController, animated: animated)
        self.pushableViewControllers = poppedViewControllers.reverseObjectEnumerator().allObjects

        return poppedViewControllers
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let poppedViewControllers = super.popToRootViewController(animated: true)

        if let all = ((poppedViewControllers as NSArray?)?.reverseObjectEnumerator()).allObjects {
            pushableViewControllers = all
        }

        return poppedViewControllers
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        
        self.pushableViewControllers?.removeAll()
    }

    func push(_ viewController: UIViewController?, animated: Bool, completion: SWNavigationControllerPushCompletion) {
        pushedViewController = viewController
        pushCompletion = completion
        if let viewController = viewController {
            super.pushViewController(viewController, animated: animated)
        }
    }

    func pushNextViewControllerFromRight() {
        let pushedViewController = pushableViewControllers.last as? UIViewController

        if pushedViewController != nil && visibleViewController != nil && visibleViewController?.isBeingPresented == nil && visibleViewController?.isBeingDismissed == nil {
            push(pushedViewController, animated: true) {
                self.pushableViewControllers.removeLast()
            }
        }
    }
}

extension SwipeForwardNavigationController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        // If we are either pulling in a new VC onto the stack or we have a custom pushAnimatedTransitioningClass that we want to use to transition
        if operation == .push && (((navigationController as? SWNavigationController)?.interactivePushGestureRecognizer()).state() == .began || (pushAnimatedTransitioningClass != SWPushAnimatedTransitioning.self)) {
            return pushAnimatedTransitioningClass.init()
        } else if operation == .pop && popAnimatedTransitioningClass {
            return popAnimatedTransitioningClass.init()
        }

        return nil
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        let navController = navigationController as? SWNavigationController
        if navController?.interactivePushGestureRecognizer.state == .began {
            navController?.percentDrivenInteractiveTransition = UIPercentDrivenInteractiveTransition()
            navController?.percentDrivenInteractiveTransition.completionCurve = .easeOut
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
        if pushCompletion && pushedViewController == viewController {
            pushCompletion()
        }

        pushCompletion = nil
        pushedViewController = nil
    }
}
