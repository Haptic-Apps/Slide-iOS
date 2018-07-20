//
//  SingleContentViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 8/2/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import UIKit

class SingleContentViewController: SwipeDownModalVC, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var vCs: [UIViewController] = [ClearVC()]
    var baseURL: URL?
    var lqURL: URL?
    public init(url: URL, lq: URL?, _ commentCallback: (() -> Void)?) {
        self.baseURL = url
        self.lqURL = lq
        let media = ModalMediaViewController(model: EmbeddableMediaDataModel(baseURL: baseURL, lqURL: lq, text: nil, inAlbum: false))
        media.embeddedVC.commentCallback = commentCallback

        self.vCs.append(media)//todo change this
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        self.navigationController?.view.backgroundColor = UIColor.clear
        let firstViewController = vCs[1]
        
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: false,
                           completion: nil)
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating: Bool, previousViewControllers: [UIViewController], transitionCompleted: Bool) {
        if(pageViewController.viewControllers?.first == vCs[0]) {
            self.dismiss(animated: true, completion: nil)
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
