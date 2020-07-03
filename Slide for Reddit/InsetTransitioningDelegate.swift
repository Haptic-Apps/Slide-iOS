//
//  InsetTransitioningDelegate.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/10/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit

class InsetTransitioningDelegate: UIPresentationController, UIViewControllerTransitioningDelegate {
    var size: CGSize
    private var interactive = false
    private var dismissInteractionController: PanGestureInteractionControllerModal?
    var scrollView: UIScrollView?

    lazy private var backgroundView = UIView()

    init(preferredSize: CGSize, scroll: UIViewController, presentedViewController: UIViewController, presenting: UIViewController?) {
        self.size = preferredSize
        if scroll is UpdateViewController {
            self.scrollView = (scroll as! UpdateViewController).scrollView
        } else if scroll is SettingsPro {
            self.scrollView = (scroll as! SettingsPro).tableView
        } else if scroll is SettingsThemeChooser {
            self.scrollView = (scroll as! SettingsThemeChooser).tableView
        } else if scroll is WebsiteViewController {
            self.scrollView = (scroll as! WebsiteViewController).webView.scrollView
        }
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    @objc func backgroundViewTapped(_ sender: AnyObject) {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
}

class SlideInTransitionModal: NSObject, UIViewControllerAnimatedTransitioning {

    let duration: TimeInterval = 0.3
    let reverse: Bool
    let interactive: Bool
    var size = CGSize.zero

    init(reverse: Bool = false, interactive: Bool = false, size: CGSize) {
        self.reverse = reverse
        self.size = size
        self.interactive = interactive
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        let viewControllerKey = reverse ? UITransitionContextViewControllerKey.from : UITransitionContextViewControllerKey.to
        let viewControllerToAnimate = transitionContext.viewController(forKey: viewControllerKey)!
        guard let viewToAnimate = viewControllerToAnimate.view else { return }

        var offsetFrame = viewToAnimate.bounds

        offsetFrame.origin.x = (UIScreen.main.bounds.width - size.width) / 2
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

extension InsetTransitioningDelegate {
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
        dismissInteractionController = PanGestureInteractionControllerModal(view: containerView!)
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

        // Make smaller on iPad

        let xOrigin = (containerView.bounds.size.width - size.width) / 2
        let yOrigin = (containerView.bounds.size.height - size.height) / 2

        return CGRect(x: xOrigin, y: yOrigin, width: size.width, height: size.height)
    }
}
public class PanGestureInteractionControllerModal: UIPercentDrivenInteractiveTransition, UIScrollViewDelegate {
    struct Callbacks {
        var didBeginPanning: (() -> Void)?
    }
    private var lastContentOffset: CGFloat = 0

    var callbacks = Callbacks()

    let gestureRecognizer: UIPanGestureRecognizer
    
    weak var tableView: UITableView? {
        didSet {
            self.gestureRecognizer.delegate = self
        }
    }
    
    weak var scrollView: UIScrollView? {
        didSet {
            //self.scrollView?.bounces = false
            //self.scrollView?.delegate = self
            //self.scrollView?.contentOffset = CGPoint.zero
            self.gestureRecognizer.delegate = self
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // The current offset
        let offset = scrollView.contentOffset.y
        if offset > 1 {
            self.scrollView?.bounces = true
        } else {
            self.scrollView?.bounces = false
        }
        // This needs to be in the last line
        lastContentOffset = offset
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
                self.completionSpeed = 0.8
                cancel()
            }
        case .cancelled:
            self.completionSpeed = 0.8
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

extension PanGestureInteractionControllerModal: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let scrollView = scrollView {
            return scrollView.contentOffset.y == 0
        } else {
            return tableView?.contentOffset.y ?? 0 == 0
        }
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer is UIPanGestureRecognizer && scrollView != nil && scrollView!.contentOffset.y == 0 && (scrollView!.frame.contains(otherGestureRecognizer.location(in: scrollView!)))
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return scrollView == nil || tableView == nil || ((gestureRecognizer is UIPanGestureRecognizer && (gestureRecognizer as! UIPanGestureRecognizer).velocity(in: scrollView ?? tableView!).y < 0) ? false : true)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension InsetTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return self
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactive ? dismissInteractionController : nil
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInTransitionModal(size: size)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInTransitionModal(reverse: true, interactive: interactive, size: size)
    }
}
