//
//  BottomMenuPresentationManager.swift
//  Slide for Reddit
//
//  Created by Jonathan Cole on 8/20/18.
//  Based on https://gist.github.com/chrisco314/3b58040015ed857498c761a3ea524161
//

import Anchorage
import UIKit

class BottomMenuPresentationController: UIPresentationController, UIViewControllerTransitioningDelegate {

    private var interactive = false
    private var dismissInteractionController: PanGestureInteractionController?
    weak var tableView: UITableView?
    weak var scrollView: UIScrollView?

    lazy private var backgroundView = UIView()

    init(presentedViewController: UIViewController, presenting: UIViewController) {
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }
    
}

extension BottomMenuPresentationController {

    @objc func backgroundViewTapped(_ sender: AnyObject) {
        presentingViewController.dismiss(animated: true, completion: nil)
    }

}

// MARK: - UIPresentationController
extension BottomMenuPresentationController {
    override func presentationTransitionWillBegin() {
        
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        
        if #available(iOS 11, *) {
            let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
            let blurView = UIVisualEffectView(frame: backgroundView.frame)
            blurEffect.setValue(5, forKeyPath: "blurRadius")
            blurView.effect = blurEffect
            backgroundView.insertSubview(blurView, at: 0)
            blurView.horizontalAnchors == backgroundView.horizontalAnchors
            blurView.verticalAnchors == backgroundView.verticalAnchors
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundViewTapped))
        backgroundView.addGestureRecognizer(tapGesture)

        containerView?.addSubview(backgroundView)
        backgroundView.horizontalAnchors == containerView!.horizontalAnchors
        backgroundView.verticalAnchors == containerView!.verticalAnchors
        
        backgroundView.alpha = 0
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.backgroundView.alpha = 1
            }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
            self?.backgroundView.alpha = 0
            }, completion: nil)
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            backgroundView.removeFromSuperview()
        }
        dismissInteractionController = PanGestureInteractionController(view: containerView!)
        dismissInteractionController?.tableView = tableView
        dismissInteractionController?.scrollView = scrollView
        dismissInteractionController?.callbacks.didBeginPanning = { [weak self] in
            self?.interactive = true
            self?.presentingViewController.dismiss(animated: true, completion: nil)
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        interactive = false
        if completed {
            backgroundView.removeFromSuperview()
        }
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return CGRect()
        }

        let verticalCoveragePercent: CGFloat = 0.85
        let horizontalCoveragePercent: CGFloat = 0.95

        // Make smaller on iPad
        var width = containerView.bounds.size.width * (UIDevice.current.userInterfaceIdiom == .pad ? 0.75 : horizontalCoveragePercent)
        if width < 250 {
            width = containerView.bounds.size.width * horizontalCoveragePercent
        }
        let height = containerView.bounds.size.height * verticalCoveragePercent

        let xOrigin = (containerView.bounds.size.width - width) / 2
        let yOrigin = containerView.bounds.size.height * (1.0 - verticalCoveragePercent)

        return CGRect(x: xOrigin, y: yOrigin, width: width, height: height)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension BottomMenuPresentationController {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return self
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactive ? dismissInteractionController : nil
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInTransition()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInTransition(reverse: true, interactive: interactive)
    }
}

class SlideInTransition: NSObject, UIViewControllerAnimatedTransitioning {

    let duration: TimeInterval = 0.3
    let reverse: Bool
    let interactive: Bool

    init(reverse: Bool = false, interactive: Bool = false) {
        self.reverse = reverse
        self.interactive = interactive
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        let viewControllerKey = reverse ? UITransitionContextViewControllerKey.from : UITransitionContextViewControllerKey.to
        let viewControllerToAnimate = transitionContext.viewController(forKey: viewControllerKey)!
        guard let viewToAnimate = viewControllerToAnimate.view else { return }

        var offsetFrame = viewToAnimate.bounds
        var width = UIScreen.main.bounds.width * (UIDevice.current.userInterfaceIdiom == .pad ? 0.75 : 0.95)
        if width < 250 {
            width = UIScreen.main.bounds.width * 0.95
        }

        offsetFrame.origin.x = (UIScreen.main.bounds.width - width) / 2
        offsetFrame.origin.y = transitionContext.containerView.bounds.height

        if !reverse {
            transitionContext.containerView.addSubview(viewToAnimate)
            viewToAnimate.frame = offsetFrame
        }
        
        let options: UIView.AnimationOptions = interactive ? [.curveLinear] : [.curveEaseInOut]
        let animateBlock = { [weak self] in
            if self!.reverse {
                viewToAnimate.frame = offsetFrame
            } else {
                viewToAnimate.frame = transitionContext.finalFrame(for: viewControllerToAnimate)
            }
        }
        
        let completionBlock: (Bool) -> Void = { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        if interactive {
            UIView.animate(withDuration: duration, delay: 0.001, options: options,
                           animations: animateBlock, completion: completionBlock)
        } else {
            UIView.animate(withDuration: duration,
                           delay: 0.001,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0.45,
                           options: .curveEaseInOut,
                           animations: animateBlock,
                           completion: completionBlock)
        }
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
}

public class PanGestureInteractionController: UIPercentDrivenInteractiveTransition {
    struct Callbacks {
        var didBeginPanning: (() -> Void)?
    }
    var callbacks = Callbacks()

    let gestureRecognizer: UIPanGestureRecognizer
    
    weak var tableView: UITableView? {
        didSet {
            self.gestureRecognizer.delegate = self
        }
    }
    
    weak var scrollView: UIScrollView? {
        didSet {
            self.gestureRecognizer.delegate = self
        }
    }
        
    // MARK: Initialization
    init(view: UIView) {
        gestureRecognizer = UIPanGestureRecognizer()
        view.addGestureRecognizer(gestureRecognizer)

        super.init()
        self.completionCurve = .easeInOut
        gestureRecognizer.delegate = self
        gestureRecognizer.addTarget(self, action: #selector(viewPanned(sender:)))
    }

    // MARK: User interaction
    @objc func viewPanned(sender: UIPanGestureRecognizer) {
        
        sender.view?.endEditing(true)
        
        switch sender.state {
        case .began:
            callbacks.didBeginPanning?()
        case .changed:
            update(percentCompleteForTranslation(translation: sender.translation(in: sender.view)))
        case .ended:
            let velocity = sender.velocity(in: sender.view).y
            if sender.shouldRecognizeForDirection(.down) && (percentComplete > 0.25 || velocity > 350) {
                finish()
            } else {
                cancel()
            }
        case .cancelled:
            cancel()
        default:
            return
        }
    }

    private func percentCompleteForTranslation(translation: CGPoint) -> CGFloat {
        let panDistance = CGPoint(x: 0, y: gestureRecognizer.view!.bounds.size.height)
        return (translation * panDistance) / (panDistance.magnitude * panDistance.magnitude)
    }
}

extension PanGestureInteractionController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let scrollView = scrollView {
            return scrollView.contentOffset.y == 0
        } else {
            return tableView?.contentOffset.y ?? 0 == 0
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard otherGestureRecognizer is UIPanGestureRecognizer else {
            return false
        }
        if let scrollView = scrollView {
            return scrollView.contentOffset.y == 0
        } else {
            return tableView?.contentOffset.y ?? 0 == 0
        }
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return (gestureRecognizer is UIPanGestureRecognizer && (gestureRecognizer as! UIPanGestureRecognizer).velocity(in: scrollView ?? tableView!).y < 0) ? false : true
    }

}

extension UIPanGestureRecognizer {

    private func angle(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        // TODO | - Not sure if this is correct
        return atan2(a.y, a.x) - atan2(b.y, b.x)
    }

    private func shouldRecognizeForDirection() -> Bool {
        guard let view = view else {
            return false
        }

        let a = angle(velocity(in: view), CGPoint(x: 0, y: 1))
        return abs(a) < CGFloat.pi / 4 // Angle should be within 45 degrees
    }
}
