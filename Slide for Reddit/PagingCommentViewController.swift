//
//  PagingCommentViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import reddift

class PagingCommentViewController: ColorMuxPagingViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    static weak var savedComment: CommentViewController?
    var submissionDataSource: SubmissionsDataSource
    var startIndex: Int

    override var prefersStatusBarHidden: Bool {
        return SettingValues.hideStatusBar
    }
    
    var offline = false
    var reloadCallback: (() -> Void)?

    public init(submissionDataSource: SubmissionsDataSource, currentIndex: Int, reloadCallback: @escaping () -> Void) {
        self.submissionDataSource = submissionDataSource
        self.startIndex = currentIndex
        self.reloadCallback = reloadCallback

        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    func next() {
        if currentIndex + 1 < submissionDataSource.content.count {
            currentIndex += 1
            let vc = CommentViewController(submission: submissionDataSource.content[currentIndex + startIndex], single: false)
            setViewControllers([vc],
                                   direction: .forward,
                                   animated: true,
                                   completion: nil)
            vc.refresh(vc)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if UIColor.isLightTheme && SettingValues.reduceColor {
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
        
        submissionDataSource.delegate = self
    }
    
    var first = true
    override func viewDidLoad() {
        super.viewDidLoad()
        if SettingValues.commentGesturesMode.shouldPage() {
            self.dataSource = self
        }
        self.delegate = self
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        let firstViewController: CommentViewController
        let sub = self.submissionDataSource.content[startIndex]
        if first && PagingCommentViewController.savedComment != nil && PagingCommentViewController.savedComment!.submission!.id == sub.id {
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
                           })
    }
    
    // From https://stackoverflow.com/a/25167681/3697225
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if currentIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndex + startIndex == submissionDataSource.content.count - 1 && scrollView.contentOffset.x > scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }
    
    // From https://stackoverflow.com/a/25167681/3697225
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if currentIndex == 0 && scrollView.contentOffset.x <= scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndex + startIndex == submissionDataSource.content.count - 1 && scrollView.contentOffset.x >= scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }

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
        let id = PagingCommentViewController.savedComment!.submission!.id
        for item in startIndex..<submissionDataSource.content.count {
            currentIndex += 1
            if submissionDataSource.content[item].id == id {
                break
            }
        }
        
        if currentIndex + startIndex == submissionDataSource.content.count - 2 {
            submissionDataSource.getData(reload: false)
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let id = (viewController as! CommentViewController).submission!.id
        var viewControllerIndex = -1
        for item in startIndex..<submissionDataSource.content.count {
            viewControllerIndex += 1
            if submissionDataSource.content[item].id == id {
                break
            }
        }

        if viewControllerIndex < 0 || viewControllerIndex + startIndex > submissionDataSource.content.count {
            return nil
        }
        
        var previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard submissionDataSource.content.count - startIndex > previousIndex else {
            return nil
        }
        
        if submissionDataSource.content[previousIndex + startIndex].author == "PAGE_SEPARATOR" {
            previousIndex -= 1
        }

        let comment = CommentViewController(submission: submissionDataSource.content[ startIndex + previousIndex], single: false)
        return comment
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let id = (viewController as! CommentViewController).submission!.id

        var viewControllerIndex = -1
        for item in startIndex..<submissionDataSource.content.count {
            viewControllerIndex += 1
            if submissionDataSource.content[item].id == id {
                break
            }
        }

        if viewControllerIndex < 0 || viewControllerIndex + startIndex > submissionDataSource.content.count {
            return nil
        }

        if !(viewController as! CommentViewController).loaded {
            (viewController as! CommentViewController).refresh(viewController)
        }
        
        var nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = submissionDataSource.content.count
        
        guard orderedViewControllersCount != startIndex + nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > startIndex + nextIndex else {
            return nil
        }
        
        if submissionDataSource.content[nextIndex + startIndex].author == "PAGE_SEPARATOR" {
            nextIndex += 1
        }

        let comment = CommentViewController(submission: submissionDataSource.content[startIndex + nextIndex], single: false)
        return comment
    }
    
}

class ClearVC: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = .clear
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
    }
    
}

extension PagingCommentViewController: SubmissionDataSouceDelegate {
    func showIndicator() {
    }
    
    func generalError(title: String, message: String) {
    }
    
    func loadSuccess(before: Int, count: Int) {
        DispatchQueue.main.async {
            self.setViewControllers([self.viewControllers?[0] ?? UIViewController()],
                                    direction: .forward,
                                    animated: false,
                                    completion: nil)
        }
    }
    
    func preLoadItems() {
    }
    
    func doPreloadImages(values: [SubmissionObject]) {
    }
    
    func loadOffline() {
    }
    
    func emptyState(_ listing: Listing) {
    }
    
    func vcIsGallery() -> Bool {
        return false
    }
}
