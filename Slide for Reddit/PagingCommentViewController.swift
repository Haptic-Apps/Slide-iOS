//
//  PagingCommentViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import SloppySwiper

class PagingCommentViewController : SwipeDownModalVC, UIPageViewControllerDataSource, UIPageViewControllerDelegate{
    var submissions: [RSubmission] = []
    static weak var savedComment : CommentViewController?
    var vCs: [UIViewController] = []
    var swiper: SloppySwiper?

    public init(submissions: [RSubmission]){
        self.submissions = submissions
        var first = true
        
        for sub in submissions {
            if(first && PagingCommentViewController.savedComment != nil && PagingCommentViewController.savedComment!.submission!.getId() == sub.getId()){
                self.vCs.append(PagingCommentViewController.savedComment!)
            } else {
                let comment = CommentViewController.init(submission: sub, single: false)
                self.vCs.append(comment)
            }
            first = false
        }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    public init(comments: [CommentViewController]){
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
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        self.navigationController?.view.backgroundColor = UIColor.clear
         let firstViewController = vCs[0]
        

        swiper = SloppySwiper.init(navigationController: self.navigationController!)
        self.navigationController!.delegate = swiper!
        for view in view.subviews {
            if (view is UIScrollView){
                var scrollView = view as! UIScrollView
               // swiper!.panRecognizer.require(toFail:scrollView.panGestureRecognizer)
                scrollView.panGestureRecognizer.require(toFail: swiper!.panRecognizer)
            }
        }
        
        
        if(!(firstViewController as! CommentViewController).loaded){
        PagingCommentViewController.savedComment = firstViewController as! CommentViewController

        (firstViewController as! CommentViewController).refresh(firstViewController)
        }

        for view in view.subviews {
            if view is UIScrollView {
                (view as! UIScrollView).delegate =  self
                break
            }
        }
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: true,
                           completion: nil)

    }

    var currentIndex = 0
    var lastPosition : CGFloat = 0
        
    func pageViewController(_ pageViewController : UIPageViewController, didFinishAnimating: Bool, previousViewControllers: [UIViewController], transitionCompleted: Bool) {
        guard transitionCompleted else { return }
        if(!(self.viewControllers!.first! is ClearVC)){
            PagingCommentViewController.savedComment = self.viewControllers!.first as! CommentViewController
        }
            currentIndex = vCs.index(of: PagingCommentViewController.savedComment!)!

    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        self.lastPosition = scrollView.contentOffset.x

        if (currentIndex == vCs.count - 1) && (lastPosition > scrollView.frame.width) {
            scrollView.contentOffset.x = scrollView.frame.width
            return

        } else if currentIndex == 0 && lastPosition < scrollView.frame.width {
            scrollView.contentOffset.x = scrollView.frame.width
            return
        }
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
        
        if(!(viewController as! CommentViewController).loaded){
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

class ClearVC : UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.backgroundColor = .clear
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear
    }
    
}
