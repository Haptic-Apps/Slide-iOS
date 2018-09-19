//
//  ShadowboxViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/5/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import UIKit
import UIKit.UIGestureRecognizerSubclass

class ShadowboxViewController: SwipeDownModalVC, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var vCs: [UIViewController] = []
    var baseSubmissions: [RSubmission] = []
    var subreddit: String

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        color2 = (pendingViewControllers[0] as! ShadowboxLinkViewController).backgroundColor
        color1 = (currentVc as! ShadowboxLinkViewController).backgroundColor
    }
    
    func getURLToLoad(_ submission: RSubmission) -> URL {
        let url = submission.url!
        if ContentType.isGif(uri: url) {
            if !submission.videoPreview.isEmpty() && !ContentType.isGfycat(uri: url) {
                return URL.init(string: submission.videoPreview)!
            } else {
                return url
            }
        } else {
            return url
        }
    }
    
    public init(submissions: [RSubmission], subreddit: String) {
        self.subreddit = subreddit
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        self.baseSubmissions = submissions
        
        for s in baseSubmissions {
            if !(s.nsfw && !SettingValues.nsfwPreviews) {
                self.vCs.append(ShadowboxLinkViewController(url: getURLToLoad(s), content: s, parent: self))
            }
        }
        
        let firstViewController = self.vCs[0]
        currentVc = firstViewController
        
        self.setViewControllers([firstViewController],
                                direction: .forward,
                                animated: true,
                                completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        
    }
    
    var navItem: UINavigationItem?
    var navigationBar = UINavigationBar()
    
    func exit() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        self.navigationController?.view.backgroundColor = UIColor.clear
        viewToMux = self.background
        
        navigationBar = UINavigationBar.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 56))
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = true

        doButtons()
        self.view.addSubview(navigationBar)
        
        navigationBar.topAnchor == self.view.safeTopAnchor
        navigationBar.horizontalAnchors == self.view.horizontalAnchors
    }
    
    func color() {
        SettingValues.blackShadowbox = !SettingValues.blackShadowbox
        UserDefaults.standard.set(SettingValues.blackShadowbox, forKey: SettingValues.pref_blackShadowbox)
        UserDefaults.standard.synchronize()
        doButtons()
        if SettingValues.blackShadowbox {
            UIView.animate(withDuration: 0.25) {
                self.background?.backgroundColor = .black
            }
        } else {
            (currentVc as! ShadowboxLinkViewController).doBackground()
        }
        for vc in vCs {
            if let shadowbox = vc as? ShadowboxLinkViewController {
                shadowbox.doBackground()
            }
        }
    }
    
    func doButtons() {
        navItem = UINavigationItem(title: "")
        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.navIcon(), for: UIControlState.normal)
        close.addTarget(self, action: #selector(self.exit), for: UIControlEvents.touchUpInside)
        close.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let closeB = UIBarButtonItem.init(customView: close)
        navItem?.leftBarButtonItem = closeB
        
        let shadowbox = UIButton.init(type: .custom)
        shadowbox.setImage(UIImage.init(named: !SettingValues.blackShadowbox ? "colors" : "nocolors")?.navIcon(), for: UIControlState.normal)
        shadowbox.addTarget(self, action: #selector(self.color), for: UIControlEvents.touchUpInside)
        shadowbox.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let shadowboxB = UIBarButtonItem.init(customView: shadowbox)
        navItem?.rightBarButtonItem = shadowboxB
        
        navigationBar.setItems([navItem!], animated: false)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating: Bool, previousViewControllers: [UIViewController], transitionCompleted: Bool) {
        guard didFinishAnimating else {
            return
        }
        
        currentVc = self.viewControllers!.first!
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard vCs.count > previousIndex else {
            return nil
        }
        
        return vCs[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = vCs.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }

        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return vCs[nextIndex]
    }
    
    var selected = false
    var currentVc = UIViewController()
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }

}

extension UIPanGestureRecognizer {
    
    override open class func initialize() {
        super.initialize()
        guard self === UIPanGestureRecognizer.self else {
            return
        }
        
        func replace(_ method: Selector, with anotherMethod: Selector, for clаss: AnyClass) {
            let original = class_getInstanceMethod(clаss, method)
            let swizzled = class_getInstanceMethod(clаss, anotherMethod)
            switch class_addMethod(clаss, method, method_getImplementation(swizzled), method_getTypeEncoding(swizzled)) {
            case true:
                class_replaceMethod(clаss, anotherMethod, method_getImplementation(original), method_getTypeEncoding(original))
            case false:
                method_exchangeImplementations(original, swizzled)
            }
        }
        
        let selector1 = #selector(UIPanGestureRecognizer.touchesBegan(_:with:))
        let selector2 = #selector(UIPanGestureRecognizer.swizzling_touchesBegan(_:with:))
        replace(selector1, with: selector2, for: self)
        let selector3 = #selector(UIPanGestureRecognizer.touchesMoved(_:with:))
        let selector4 = #selector(UIPanGestureRecognizer.swizzling_touchesMoved(_:with:))
        replace(selector3, with: selector4, for: self)
    }
    
    @objc private func swizzling_touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        self.swizzling_touchesBegan(touches, with: event)
        guard direction != nil else {
            return
        }
        touchesBegan = true
    }
    
    @objc private func swizzling_touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        self.swizzling_touchesMoved(touches, with: event)
        guard let direction = direction, touchesBegan == true else {
            return
        }
        defer {
            touchesBegan = false
        }
        let forbiddenDirectionsCount = touches
            .flatMap({ ($0.location(in: $0.view) - $0.previousLocation(in: $0.view)).direction })
            .filter({ $0 != direction })
            .count
        if forbiddenDirectionsCount > 0 {
            state = .failed
        }
    }
}

public extension UIPanGestureRecognizer {
    
    public enum Direction: Int {
        
        case horizontal = 0
        case vertical
    }
    
    private struct UIPanGestureRecognizerRuntimeKeys {
        static var directions = "\(#file)+\(#line)"
        static var touchesBegan = "\(#file)+\(#line)"
    }
    
    public var direction: UIPanGestureRecognizer.Direction? {
        get {
            let object = objc_getAssociatedObject(self, &UIPanGestureRecognizerRuntimeKeys.directions)
            return object as? UIPanGestureRecognizer.Direction
        }
        set {
            let policy = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            objc_setAssociatedObject(self, &UIPanGestureRecognizerRuntimeKeys.directions, newValue, policy)
        }
    }
    
    fileprivate var touchesBegan: Bool {
        get {
            let object = objc_getAssociatedObject(self, &UIPanGestureRecognizerRuntimeKeys.touchesBegan)
            return (object as? Bool) ?? false
        }
        set {
            let policy = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            objc_setAssociatedObject(self, &UIPanGestureRecognizerRuntimeKeys.touchesBegan, newValue, policy)
        }
    }
}

fileprivate extension CGPoint {
    
    var direction: UIPanGestureRecognizer.Direction? {
        guard self != .zero else {
            return nil
        }
        switch fabs(x) > fabs(y) {
        case true:  return .horizontal
        case false: return .vertical
        }
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
