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
import UIKit.UIGestureRecognizerSubclass

class ShadowboxViewController: SwipeDownModalVC, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var baseSubmissions: [RSubmission] = []
    var paginator: Paginator
    var sort: LinkSortType
    var time: TimeFilterWithin
    var subreddit: String
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
    
    public init(submissions: [RSubmission], subreddit: String, index: Int, paginator: Paginator, sort: LinkSortType, time: TimeFilterWithin) {
        self.subreddit = subreddit
        self.sort = sort
        self.time = time
        self.index = index
        self.paginator = paginator
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        self.baseSubmissions = submissions
        
        let s = baseSubmissions[index]
        let firstViewController = ShadowboxLinkViewController(url: self.getURLToLoad(s), content: s, parent: self)
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

        doButtons()
        self.view.addSubview(navigationBar)
        
        navigationBar.topAnchor == self.view.safeTopAnchor
        navigationBar.horizontalAnchors == self.view.horizontalAnchors
    }
    
    @objc func color() {
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
    }
    
    func doButtons() {
        navItem = UINavigationItem(title: "")
        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.navIcon().getCopy(withColor: .white), for: UIControl.State.normal)
        close.addTarget(self, action: #selector(self.exit), for: UIControl.Event.touchUpInside)
        close.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let closeB = UIBarButtonItem.init(customView: close)
        navItem?.leftBarButtonItem = closeB
        
        let shadowbox = UIButton.init(type: .custom)
        shadowbox.setImage(UIImage.init(named: !SettingValues.blackShadowbox ? "colors" : "nocolors")?.navIcon().getCopy(withColor: .white), for: UIControl.State.normal)
        shadowbox.addTarget(self, action: #selector(self.color), for: UIControl.Event.touchUpInside)
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
    
    var loading = false
    var nomore = false
    func loadMore() {
        if !loading {
            do {
                loading = true
                var path: SubredditURLPath = Subreddit.init(subreddit: self.subreddit)
                
                if subreddit.hasPrefix("/m/") {
                    path = Multireddit.init(name: subreddit.substring(3, length: subreddit.length - 3), user: AccountController.currentName)
                }
                if subreddit.contains("/u/") {
                    path = Multireddit.init(name: subreddit.split("/")[3], user: subreddit.split("/")[1])
                }
                
                try (UIApplication.shared.delegate as? AppDelegate)?.session?.getList(paginator, subreddit: path, sort: sort, timeFilterWithin: time, completion: { (result) in
                    switch result {
                    case .failure:
                        print(result.error!)
                        //Loading failed, ignore
                    case .success(let listing):
                        let newLinks = listing.children.compactMap({ $0 as? Link })
                        var converted: [RSubmission] = []
                        for link in newLinks {
                            let newRS = RealmDataWrapper.linkToRSubmission(submission: link)
                            converted.append(newRS)
                        }
                        
                        let values = PostFilter.filter(converted, previous: self.baseSubmissions, baseSubreddit: self.subreddit).map { $0 as! RSubmission }
                        
                        self.baseSubmissions += values
                        self.paginator = listing.paginator
                        self.nomore = !listing.paginator.hasMore() || values.isEmpty
                        
                        DispatchQueue.main.async {
                            self.setViewControllers([self.currentVc],
                                                    direction: .forward,
                                                    animated: false ,
                                                    completion: nil)
                        }
                    }
                })
            } catch {
                print(error)
            }
            
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let id = (viewController as! ShadowboxLinkViewController).submission.getId()
        var viewControllerIndex = -1
        
        for item in baseSubmissions {
            viewControllerIndex += 1
            if item.getId() == id {
                break
            }
        }
        
        if viewControllerIndex < 0 || viewControllerIndex > baseSubmissions.count {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard baseSubmissions.count > previousIndex else {
            return nil
        }
        
        let s = baseSubmissions[previousIndex]
        let shadowbox = ShadowboxLinkViewController(url: self.getURLToLoad(s), content: s, parent: self)
        if !shadowbox.populated {
            shadowbox.populateContent()
            shadowbox.populated = true
        }
        
        return shadowbox
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let id = (viewController as! ShadowboxLinkViewController).submission.getId()
        var viewControllerIndex = -1
        
        for item in baseSubmissions {
            viewControllerIndex += 1
            if item.getId() == id {
                break
            }
        }
        
        if viewControllerIndex < 0 || viewControllerIndex > baseSubmissions.count {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = baseSubmissions.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        if nextIndex == baseSubmissions.count - 2 && !loading {
            loadMore()
        }
        
        let s = baseSubmissions[nextIndex]
        let shadowbox = ShadowboxLinkViewController(url: self.getURLToLoad(s), content: s, parent: self)
        if !shadowbox.populated {
            shadowbox.populateContent()
            shadowbox.populated = true
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
