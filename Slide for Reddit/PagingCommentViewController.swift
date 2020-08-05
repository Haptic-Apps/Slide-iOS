//
//  PagingCommentViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation

class PagingCommentViewController: ColorMuxPagingViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var submissions: [RSubmission] = []
    static weak var savedComment: CommentViewController?
    var vCs: [RSubmission] = []

    override var prefersStatusBarHidden: Bool {
        return SettingValues.fullyHideNavbar
    }
    
    var offline = false
    var reloadCallback: (() -> Void)?

    public init(submissions: [RSubmission], offline: Bool, reloadCallback: @escaping () -> Void) {
        self.submissions = submissions
        self.offline = offline
        self.reloadCallback = reloadCallback
        for sub in submissions {
            self.vCs.append(sub)
        }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    func next() {
        if currentIndex + 1 < vCs.count {
            currentIndex += 1
            let vc = CommentViewController(submission: vCs[currentIndex], single: false)
            setViewControllers([vc],
                                   direction: .forward,
                                   animated: true,
                                   completion: nil)
            vc.refresh(vc)
        }
    }
    
    var firstPage = true
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        self.view.backgroundColor = UIColor.clear
        self.navigationController?.view.backgroundColor = .clear
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    var first = true
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        let firstViewController: CommentViewController
        let sub = self.vCs[0]
        if first && PagingCommentViewController.savedComment != nil && PagingCommentViewController.savedComment!.submission!.getId() == sub.getId() {
            firstViewController = PagingCommentViewController.savedComment!
        } else {
            let comment = CommentViewController.init(submission: sub, single: false)
            comment.offline = offline
            firstViewController = comment
        }
        first = false
        
        if !firstViewController.loaded {
            PagingCommentViewController.savedComment = firstViewController
            firstViewController.forceLoad = true
        }

        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: false,
                           completion: {(_) in
                            firstViewController.setupSwipeGesture()
                           })
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
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
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
        currentIndex = -1
        let id = PagingCommentViewController.savedComment!.submission!.getId()
        for item in vCs {
            currentIndex += 1
            if item.getId() == id {
                break
            }
        }
        if currentIndex == 0 {
            (self.viewControllers?.first as? CommentViewController)?.setupSwipeGesture()
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let id = (viewController as! CommentViewController).submission!.getId()
        var viewControllerIndex = -1
        for item in vCs {
            viewControllerIndex += 1
            if item.getId() == id {
                break
            }
        }

        if viewControllerIndex < 0 || viewControllerIndex > vCs.count {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard vCs.count > previousIndex else {
            return nil
        }
        
        let comment = CommentViewController(submission: vCs[previousIndex], single: false)
        return comment
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let id = (viewController as! CommentViewController).submission!.getId()
        var viewControllerIndex = -1
        for item in vCs {
            viewControllerIndex += 1
            if item.getId() == id {
                break
            }
        }
        
        if viewControllerIndex < 0 || viewControllerIndex > vCs.count {
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
        let comment = CommentViewController(submission: vCs[nextIndex], single: false)
        if nextIndex == 0 {
            comment.setupSwipeGesture()
        }
        return comment
    }
    
}

class ClearVC: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = .clear
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
    }
    
}
