//
//  CollectionsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 9/15/19.
//  Copyright © 2019 Haptic Apps. All rights reserved.
//

import Foundation

import Anchorage
import MaterialComponents.MaterialTabs
import reddift
import UIKit

class CollectionsViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    var isReload = false
    var session: Session?
    
    var titles = Collections.getAllCollections()

    var vCs: [UIViewController] = []

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

    public init() {
        self.session = (UIApplication.shared.delegate as! AppDelegate).session

        for place in titles {
            vCs.append(ContentListingViewController(dataSource: CollectionsContributionLoader(collectionTitle: place)))
        }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.delegate = self
        self.title = "Collections"
        UIApplication.shared.applicationIconBadgeNumber = 0
        navigationController?.setNavigationBarHidden(false, animated: true)
        setupBaseBarColors()
    }

    var time: Double = 0

    func close() {
        self.navigationController?.popViewController(animated: true)
    }

    var tabBar = MDCTabBar()

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

        tabBar = MDCTabBar.init(frame: CGRect.zero)
        tabBar.backgroundColor = ColorUtil.getColorForSub(sub: "", true)
        tabBar.itemAppearance = .titles
        tabBar.selectedItemTintColor = (SettingValues.reduceColor ? ColorUtil.theme.fontColor : UIColor.white)
        tabBar.unselectedItemTintColor = (SettingValues.reduceColor ? ColorUtil.theme.fontColor : UIColor.white).withAlphaComponent(0.45)

        tabBar.items = titles.enumerated().map { index, source in
            return UITabBarItem(title: source.description, image: nil, tag: index)
        }
        tabBar.delegate = self
        tabBar.inkColor = UIColor.clear
        tabBar.selectedItem = tabBar.items[0]
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: "NONE")

        self.view.addSubview(tabBar)
        tabBar.heightAnchor |==| 48
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
            tabBar.topAnchor |==| self.view.topAnchor + topAnchorOffset
        } else {
            tabBar.topAnchor |==| self.view.topAnchor
        }

        tabBar.horizontalAnchors |==| self.view.horizontalAnchors
        tabBar.sizeToFit()
        
        time = History.getInboxSeen()
        History.inboxSeen()
        view.backgroundColor = ColorUtil.theme.backgroundColor
        // set up style before super view did load is executed
        // -

        self.dataSource = self
        self.delegate = self

        self.navigationController?.view.backgroundColor = UIColor.clear
        let firstViewController = vCs[0]

        for view in view.subviews {
            if view is UIScrollView {
                (view as! UIScrollView).delegate = self
                break
            }
        }

        if self.navigationController?.interactivePopGestureRecognizer != nil {
            for view in view.subviews {
                if let scrollView = view as? UIScrollView {
                    scrollView.panGestureRecognizer.require(toFail: self.navigationController!.interactivePopGestureRecognizer!)
                }
            }
        }

        setViewControllers([firstViewController],
                direction: .forward,
                animated: true,
                completion: nil)

    }

    var selected = false

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard completed else {
            return
        }
        let page = vCs.firstIndex(of: self.viewControllers!.first!)

        if !selected {
            tabBar.setSelectedItem(tabBar.items[page!], animated: true)
        }
        selected = false
        
        currentIndex = page!

    }

    var currentIndex = 0
    var lastPosition: CGFloat = 0

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.lastPosition = scrollView.contentOffset.x

        if currentIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndex == vCs.count - 1 && scrollView.contentOffset.x > scrollView.bounds.size.width {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }

    //From https://stackoverflow.com/a/25167681/3697225
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if currentIndex == 0 && scrollView.contentOffset.x <= scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        } else if currentIndex == vCs.count - 1 && scrollView.contentOffset.x >= scrollView.bounds.size.width {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }

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

}

extension CollectionsViewController: MDCTabBarDelegate {

    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        let firstViewController = vCs[tabBar.items.firstIndex(of: item)!]
        currentIndex = tabBar.items.firstIndex(of: item)!
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: false,
                           completion: nil)
        
    }
}

// MARK: - Actions
extension CollectionsViewController {
    @objc func closeButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
}
