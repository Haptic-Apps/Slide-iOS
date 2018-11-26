//
//  PagingCommentViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import SloppySwiper

class PagingCommentViewController: ColorMuxPagingViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var submissions: [RSubmission] = []
    static weak var savedComment: CommentViewController?
    var vCs: [UIViewController] = []
    var swiper: SloppySwiper?

    public init(submissions: [RSubmission], offline: Bool) {
        self.submissions = submissions
        var first = true
        
        for sub in submissions {
            if first && PagingCommentViewController.savedComment != nil && PagingCommentViewController.savedComment!.submission!.getId() == sub.getId() {
                self.vCs.append(PagingCommentViewController.savedComment!)
            } else {
                let comment = CommentViewController.init(submission: sub, single: false)
                comment.offline = offline
                self.vCs.append(comment)
            }
            first = false
        }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    func next() {
        if currentIndex + 1 < vCs.count {
            currentIndex += 1
            let vc = vCs[currentIndex] as! CommentViewController
            setViewControllers([vc],
                                   direction: .forward,
                                   animated: true,
                                   completion: nil)
            vc.refresh(vc)
        }
    }
    
    public init(comments: [CommentViewController]) {
        for c in comments {
            vCs.append(c)
        }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    var firstPage = true
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        self.view.backgroundColor = UIColor.clear
        self.navigationController?.view.backgroundColor = .clear
        
        if SettingValues.reduceColor && ColorUtil.theme.isLight() {
            UIApplication.shared.statusBarStyle = .default
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        if (SettingValues.commentGesturesMode == .SWIPE_ANYWHERE || SettingValues.commentGesturesMode == .GESTURES) && !(self.navigationController?.delegate is SloppySwiper) {
            swiper = SloppySwiper.init(navigationController: self.navigationController!)
            self.navigationController!.delegate = swiper!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        self.navigationController?.view.backgroundColor = UIColor.clear
        let firstViewController = vCs[0]
        
        for view in view.subviews {
            if view is UIScrollView {
                let scrollView = view as! UIScrollView
                scrollView.delegate = self
                if scrollView.isPagingEnabled && SettingValues.commentGesturesMode != .NONE {
                    scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
                }
                scrollView.panGestureRecognizer.require(toFail: navigationController!.interactivePopGestureRecognizer!)
            }
        }
        
        if !(firstViewController as! CommentViewController).loaded {
            PagingCommentViewController.savedComment = firstViewController as? CommentViewController
            (firstViewController as! CommentViewController).forceLoad = true
        }

        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: true,
                           completion: nil)

    }
    
    //From https://stackoverflow.com/a/25167681/3697225
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndex == submissions.count - 1 && scrollView.contentOffset.x > scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }
    
    //From https://stackoverflow.com/a/25167681/3697225
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if currentIndex == 0 && scrollView.contentOffset.x <= scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndex == submissions.count - 1 && scrollView.contentOffset.x >= scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }

    var currentIndex = 0
    var lastPosition: CGFloat = 0
        
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating: Bool, previousViewControllers: [UIViewController], transitionCompleted: Bool) {
        guard transitionCompleted else { return }
        if !(self.viewControllers!.first! is ClearVC) {
            PagingCommentViewController.savedComment = self.viewControllers!.first as? CommentViewController
            if !PagingCommentViewController.savedComment!.loaded {
                PagingCommentViewController.savedComment!.refresh(pageViewController)
            }

        }
        currentIndex = vCs.index(of: PagingCommentViewController.savedComment!)!
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
        
        if !(viewController as! CommentViewController).loaded {
            (viewController as! CommentViewController).refresh(viewController)
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
    
}

class ClearVC: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = .clear
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
    }
    
}
