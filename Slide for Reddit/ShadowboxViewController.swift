//
//  ShadowboxViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/5/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Anchorage
import AVKit
import reddift
import UIKit

class ShadowboxViewController: SwipeDownModalVC, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var submissionDataSource: SubmissionsDataSource
    var index: Int

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        color2 = (pendingViewControllers[0] as! ShadowboxLinkViewController).backgroundColor
        color1 = (currentVc as! ShadowboxLinkViewController).backgroundColor
    }
    
    func getURLToLoad(_ submission: RSubmission) -> URL? {
        let url = submission.url
        if url != nil && ContentType.isGif(uri: url!) {
            if !submission.videoPreview.isEmpty() && !ContentType.isGfycat(uri: url!) {
                return URL.init(string: submission.videoPreview)!
            } else {
                return url!
            }
        } else {
            return url
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .background).async {
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(false, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
            } catch {
                NSLog(error.localizedDescription)
            }
        }
    }
    
    public init(index: Int, submissionDataSource: SubmissionsDataSource) {
        
        self.submissionDataSource = submissionDataSource
        self.index = index
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        let s = submissionDataSource.content[index]
        let firstViewController = ShadowboxLinkViewController(url: self.getURLToLoad(s), content: s, parent: self)
        currentVc = firstViewController
        (currentVc as! ShadowboxLinkViewController).populateContent()
        
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
        submissionDataSource.delegate = self
    }
    
    var navItem: UINavigationItem?
    var navigationBar = UINavigationBar()
    
    @objc func exit() {
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

        self.view.addSubview(navigationBar)
        
        navigationBar.topAnchor == self.view.safeTopAnchor
        navigationBar.horizontalAnchors == self.view.horizontalAnchors
    }
    
    @objc func color() {
        SettingValues.blackShadowbox = !SettingValues.blackShadowbox
        UserDefaults.standard.set(SettingValues.blackShadowbox, forKey: SettingValues.pref_blackShadowbox)
        UserDefaults.standard.synchronize()
        if SettingValues.blackShadowbox {
            UIView.animate(withDuration: 0.25) {
                self.background?.backgroundColor = .black
            }
        } else {
            (currentVc as! ShadowboxLinkViewController).doBackground()
        }
    }
        
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating: Bool, previousViewControllers: [UIViewController], transitionCompleted: Bool) {
        guard didFinishAnimating else {
            return
        }
        
        currentVc = self.viewControllers!.first!
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let id = (viewController as! ShadowboxLinkViewController).submission.getId()
        var viewControllerIndex = -1
        
        for item in submissionDataSource.content {
            viewControllerIndex += 1
            if item.getId() == id {
                break
            }
        }
        
        if viewControllerIndex < 0 || viewControllerIndex > submissionDataSource.content.count {
            return nil
        }
        
        var previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard submissionDataSource.content.count > previousIndex else {
            return nil
        }
        
        if submissionDataSource.content[previousIndex].author == "PAGE_SEPARATOR" {
            previousIndex -= 1
        }

        let s = submissionDataSource.content[previousIndex]
        let shadowbox = ShadowboxLinkViewController(url: self.getURLToLoad(s), content: s, parent: self)
        if !shadowbox.populated {
            shadowbox.populated = true
            shadowbox.populateContent()
        }
        
        return shadowbox
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let id = (viewController as! ShadowboxLinkViewController).submission.getId()
        var viewControllerIndex = -1
        
        for item in submissionDataSource.content {
            viewControllerIndex += 1
            if item.getId() == id {
                break
            }
        }
        
        if viewControllerIndex < 0 || viewControllerIndex > submissionDataSource.content.count {
            return nil
        }
        
        var nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = submissionDataSource.content.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        if submissionDataSource.content[nextIndex].author == "PAGE_SEPARATOR" {
            nextIndex += 1
        }

        if nextIndex == submissionDataSource.content.count - 2 && !submissionDataSource.loading {
            submissionDataSource.getData(reload: false)
        }
        
        let s = submissionDataSource.content[nextIndex]
        let shadowbox = ShadowboxLinkViewController(url: self.getURLToLoad(s), content: s, parent: self)
        if !shadowbox.populated {
            shadowbox.populated = true
            shadowbox.populateContent()
        }

        return shadowbox
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var selected = false
    var currentVc = UIViewController()
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

}

extension ShadowboxViewController: SubmissionDataSouceDelegate {
    func showIndicator() {
    }
    
    func generalError(title: String, message: String) {
    }
    
    func loadSuccess(before: Int, count: Int) {
        DispatchQueue.main.async {
            self.setViewControllers([self.currentVc],
                                    direction: .forward,
                                    animated: false,
                                    completion: nil)
        }
    }
    
    func preLoadItems() {
    }
    
    func doPreloadImages(values: [RSubmission]) {
    }
    
    func loadOffline() {
    }
    
    func emptyState(_ listing: Listing) {
    }
    
    func vcIsGallery() -> Bool {
        return false
    }
}

private var hasSwizzled = false

extension UIPanGestureRecognizer {
    final public class func swizzle() {
        guard !hasSwizzled else { return }
        
        hasSwizzled = true
        guard self === UIPanGestureRecognizer.self else {
            return
        }
        
        func replace(_ method: Selector, with anotherMethod: Selector, for clаss: AnyClass) {
            let original = class_getInstanceMethod(clаss, method)
            let swizzled = class_getInstanceMethod(clаss, anotherMethod)
            switch class_addMethod(clаss, method, method_getImplementation(swizzled!), method_getTypeEncoding(swizzled!)) {
            case true:
                class_replaceMethod(clаss, anotherMethod, method_getImplementation(original!), method_getTypeEncoding(original!))
            case false:
                method_exchangeImplementations(original!, swizzled!)
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
            .compactMap({ ($0.location(in: $0.view) - $0.previousLocation(in: $0.view)).direction })
            .filter({ $0 != direction })
            .count
        if forbiddenDirectionsCount > 0 {
            state = .failed
        }
    }
}

public extension UIPanGestureRecognizer {
    
    enum Direction: Int {
        
        case horizontal = 0
        case vertical
    }
    
    private struct UIPanGestureRecognizerRuntimeKeys {
        static var directions = "\(#file)+\(#line)"
        static var touchesBegan = "\(#file)+\(#line)"
    }
    
    var direction: UIPanGestureRecognizer.Direction? {
        get {
            let object = objc_getAssociatedObject(self, &UIPanGestureRecognizerRuntimeKeys.directions)
            return object as? UIPanGestureRecognizer.Direction
        }
        set {
            let policy = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            objc_setAssociatedObject(self, &UIPanGestureRecognizerRuntimeKeys.directions, newValue, policy)
        }
    }
    
    private var touchesBegan: Bool {
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

private extension CGPoint {
    
    var direction: UIPanGestureRecognizer.Direction? {
        guard self != .zero else {
            return nil
        }
        switch abs(x) > abs(y) {
        case true:  return .horizontal
        case false: return .vertical
        }
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
