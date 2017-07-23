//
//  PagingCommentViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import Foundation
import PagingMenuController

class PagingCommentViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var submissions: [RSubmission] = []
    var vCs: [UIViewController] = [ClearVC()]
    

    public init(submissions: [RSubmission]){
        self.submissions = submissions
        for sub in submissions {
            let comment = CommentViewController.init(submission: sub, single: false)
            self.vCs.append(comment)
        }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
      //  self.navigationController?.interactivePopGestureRecognizer?.delegate = self

    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        self.navigationController?.view.backgroundColor = .clear

        self.view.backgroundColor = .clear
         let firstViewController = vCs[1]
        
        (firstViewController as! CommentViewController).refresh(firstViewController)
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)

    }
    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]){
        print("Transitioning")
        if(pendingViewControllers[0] == vCs[0]){
            if(self.navigationController!.modalPresentationStyle == .formSheet){
                self.navigationController?.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
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
        
        (viewController as! CommentViewController).refresh(viewController)
        
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
    }
    
}
