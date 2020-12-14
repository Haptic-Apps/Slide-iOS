//
//  TabsContentPagingViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/13/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Anchorage
import Foundation
import reddift

protocol TabsContentPagingViewControllerDelegate: class {
    func shouldUpdateButtons()
}

class TabsContentPagingViewController: ColorMuxPagingViewController, UIPageViewControllerDataSource, UINavigationControllerDelegate {
    var vCs: [UIViewController] = []
    var lastPosition: CGFloat = 0
    var time: Double = 0
    var tabBar: TabsPagingTitleCollectionView!
    var isReload = false
    var session: Session?
    var selected = false
    var stickyBelow = UIView()
    var shouldScroll: Bool = true
    var openTo = 0
    var del: TabsContentPagingViewControllerDelegate?

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
        self.navigationController?.delegate = self
        navigationController?.setNavigationBarHidden(false, animated: true)
        setupBaseBarColors()
        appearOthers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        doToolbarOffset()
    }
    
    func appearOthers() {
        
    }

    func close() {
        self.navigationController?.popViewController(animated: true)
    }
    
    deinit {
        self.vCs = []
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = navigationController {
            if navigationController.viewControllers.count == 1 {
                navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Close", style: .done, target: self, action: #selector(closeButtonPressed))
            }
        }

        var items: [String] = []
        for i in titles {
            items.append(i)
        }

        tabBar?.removeFromSuperview()
        tabBar = TabsPagingTitleCollectionView(withTabs: titles, delegate: self)
        tabBar.backgroundColor = ColorUtil.theme.foregroundColor
        
        if let nav = self.navigationController as? SwipeForwardNavigationController {
            nav.fullWidthBackGestureRecognizer.require(toFail: tabBar.collectionView.panGestureRecognizer)
        }
        matchScroll(scrollView: tabBar.collectionView)
        for view in self.view.subviews {
            if !(view is UICollectionView) {
                if let scrollView = view as? UIScrollView {
                    tabBar.parentScroll = scrollView
                }
            }
        }
        
        stickyBelow = UIView().then {
            $0.backgroundColor = ColorUtil.baseAccent
            $0.layer.cornerRadius = 2.5
            $0.clipsToBounds = true
        }

        self.view.addSubview(tabBar)
        tabBar.collectionView?.addSubview(stickyBelow)
        tabBar.sizeToFit()
        tabBar.collectionView.setNeedsLayout()
        tabBar.collectionView.setNeedsDisplay()
        
        stickyBelow.layer.zPosition = -1
        tabBar.sendSubviewToBack(stickyBelow)

        tabBar.heightAnchor /==/ 48
        setupBaseBarColors()

        self.edgesForExtendedLayout = UIRectEdge.all
    
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false

        var isModal13 = false
        if #available(iOS 13, *), (self.navigationController?.viewControllers[0] == self) {
            isModal13 = true
        }
        let topAnchorOffset = (self.navigationController?.navigationBar.frame.size.height ?? 64) + (isModal13 ? 0 : UIApplication.shared.statusBarFrame.height)
        if #available(iOS 13, *) {
            tabBar.topAnchor /==/ self.view.topAnchor + topAnchorOffset
        } else {
            tabBar.topAnchor /==/ self.view.topAnchor
        }

        tabBar.horizontalAnchors /==/ self.view.horizontalAnchors
        tabBar.sizeToFit()
                
        if self is InboxViewController {
            time = History.getInboxSeen()
            History.inboxSeen()
        }
        
        view.backgroundColor = ColorUtil.theme.backgroundColor

        self.dataSource = self
        self.delegate = self

        self.navigationController?.view.backgroundColor = UIColor.clear
        
        currentIndex = openTo
        let firstViewController = vCs[openTo]

        for view in view.subviews {
            if view is UIScrollView {
                (view as! UIScrollView).delegate = self
                break
            }
        }

        doToolbarOffset()

        setViewControllers([firstViewController],
                direction: .forward,
                animated: true,
                completion: nil)
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        self.lastPosition = scrollView.contentOffset.x

        if currentIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndex == vCs.count - 1 && scrollView.contentOffset.x > scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }

    //From https://stackoverflow.com/a/25167681/3697225
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if currentIndex == 0 && scrollView.contentOffset.x <= scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndex == vCs.count - 1 && scrollView.contentOffset.x >= scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }
}

extension TabsContentPagingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = vCs.firstIndex(of: viewController) else {
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
        guard let viewControllerIndex = vCs.firstIndex(of: viewController) else {
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
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else {
            return
        }
        let page = vCs.firstIndex(of: self.viewControllers!.first!)

        currentIndex = page!
    }
}

extension TabsContentPagingViewController: PagingTitleDelegate {
    func didSelect(_ subreddit: String) {
        currentIndex = titles.firstIndex(of: subreddit) ?? 0
        
        UIView.animate(withDuration: 0.4, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.doToolbarOffset()
        }, completion: { [weak self] (_)in
            self?.dontMatch = false
        })

        let firstViewController = vCs[currentIndex]
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: false,
                           completion: nil)
    }
    
    func doToolbarOffset() {
        guard let tabBar = tabBar else { return }
        var currentBackgroundOffset = tabBar.collectionView.contentOffset
        
        let layout = (tabBar.collectionView.collectionViewLayout as! WrappingHeaderFlowLayout)

        let currentWidth = layout.widthAt(currentIndex)
        
        let insetX = (tabBar.collectionView.superview!.frame.origin.x / 2) - ((tabBar.collectionView.superview!.frame.maxX - tabBar.collectionView.superview!.frame.size.width) / 2)
        let offsetX = layout.offsetAt(currentIndex - 1) + // Width of all cells to left
            (currentWidth / 2) - // Width of current cell
            (self.tabBar!.collectionView.frame.size.width / 2) +
            insetX -
            (12)
        
        currentBackgroundOffset.x = offsetX
        self.tabBar.collectionView.contentOffset = currentBackgroundOffset

        stickyBelow.frame = CGRect(x: offsetX + (tabBar.collectionView.frame.size.width - currentWidth) / 2, y: tabBar.frame.size.height - 5, width: currentWidth, height: 5)
        //self.tabBar.collectionView.layoutIfNeeded()
    }

    func didSetWidth() {
    }
}

// MARK: - Actions
extension TabsContentPagingViewController {
    @objc func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
}
