//
//  OfflineViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 05/23/2018.
//  Copyright © 2018 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import MaterialComponents.MaterialSnackbar
import MaterialComponents.MaterialBottomSheet
import SideMenu

class OfflineViewController: ColorMuxPagingViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UISplitViewControllerDelegate {
    public static var vCs: [UIViewController] = []
    public static var subs: [String] = []
    public static var current: String = ""

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true

        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        if (tabBar != nil) {
            tabBar.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        }
        navigationController?.navigationBar.isTranslucent = false

        navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
        navigationController?.setToolbarHidden(false, animated: false)
        UIApplication.shared.statusBarView?.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)

        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    func goToSubredditSafe(subreddit: String) {
        if (OfflineViewController.subs.contains(subreddit)) {
            let index = OfflineViewController.subs.index(of: subreddit)
            let firstViewController = OfflineViewController.vCs[index!]

            setViewControllers([firstViewController],
                    direction: .forward,
                    animated: true,
                    completion: nil)
            self.doCurrentPage(index!)
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: subreddit)
            tabBar.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
        }}

    func goToSubreddit(index: Int) {
        let firstViewController = MainViewController.vCs[index]

        setViewControllers([firstViewController],
                direction: .forward,
                animated: false,
                completion: nil)
        self.doCurrentPage(index)
    }

    var tabBar = MDCTabBar()

    func setupTabBar() {
        tabBar = MDCTabBar.init(frame: CGRect.init(x: 0, y: UIApplication.shared.statusBarView?.frame.size.height ?? 20, width: self.view.frame.size.width, height: 84))
        tabBar.backgroundColor = ColorUtil.getColorForSub(sub: MainViewController.current)
        tabBar.itemAppearance = .titles

        tabBar.selectedItemTintColor = UIColor.white
        tabBar.unselectedItemTintColor = UIColor.white.withAlphaComponent(0.45)
        tabBar.items = OfflineViewController.subs.enumerated().map { index, source in
            return UITabBarItem(title: source, image: nil, tag: index)
        }
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        tabBar.selectionIndicatorTemplate = IndicatorTemplate()
        tabBar.delegate = self
        tabBar.selectedItem = tabBar.items[0]
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: "NONE")
        tabBar.sizeToFit()

        self.view.addSubview(tabBar)
    }

    func didChooseSub(_ gesture: UITapGestureRecognizer) {
        print("Chose")
        let sub = gesture.view!.tag
        goToSubreddit(index: sub)
    }

    func generateSubs() -> (Int, [UIView]) {
        var subs: [UIView] = []
        var i = 0
        var count = 0
        for sub in OfflineViewController.subs {
            let label = UILabel()
            label.text = "          \(sub)"
            label.textColor = ColorUtil.fontColor
            label.adjustsFontSizeToFitWidth = true
            label.font = UIFont.boldSystemFont(ofSize: 14)

            var sideView = UIView()
            sideView = UIView(frame: CGRect(x: 10, y: 15, width: 15, height: 15))
            sideView.backgroundColor = ColorUtil.getColorForSub(sub: sub)
            sideView.translatesAutoresizingMaskIntoConstraints = false
            label.addSubview(sideView)
            sideView.layer.cornerRadius = 7.5
            sideView.clipsToBounds = true
            label.sizeToFit()
            label.frame = CGRect.init(x: i, y: -5, width: Int(label.frame.size.width), height: 50)
            i += Int(label.frame.size.width)
            label.tag = count
            count += 1
            label.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer.init(target: self, action: #selector(didChooseSub(_:)))
            label.addGestureRecognizer(tap)

            subs.append(label)

        }
        return (i, subs)
    }

    var currentTitle = "Offline content"

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else {
            return
        }
        let page = OfflineViewController.vCs.index(of: self.viewControllers!.first!)
        doCurrentPage(page!)
    }

    func doCurrentPage(_ page: Int) {
        self.currentPage = page
        let vc = OfflineViewController.vCs[page] as! SingleSubredditViewControllerOffline
        vc.viewWillAppear(true)
        OfflineViewController.current = vc.sub
        self.tintColor = ColorUtil.getColorForSub(sub: OfflineViewController.current)
        self.menuNav?.setSubreddit(subreddit: OfflineViewController.current)
        self.currentTitle = OfflineViewController.current

        if (!(vc).loaded) {
            (vc).load(reset: true)
        }

        tabBar.backgroundColor = ColorUtil.getColorForSub(sub: MainViewController.current)
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: MainViewController.current)
        if (!selected) {
            let page = OfflineViewController.vCs.index(of: self.viewControllers!.first!)
            if (!tabBar.items.isEmpty) {
                tabBar.setSelectedItem(tabBar.items[page!], animated: true)
            }
        } else {
            selected = false
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        color2 = ColorUtil.getColorForSub(sub: (pendingViewControllers[0] as! SingleSubredditViewControllerOffline).sub)
        color1 = ColorUtil.getColorForSub(sub: (OfflineViewController.vCs[currentPage] as! SingleSubredditViewControllerOffline).sub)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = OfflineViewController.vCs.index(of: viewController) else {
            return nil
        }

        let previousIndex = viewControllerIndex - 1

        guard previousIndex >= 0 else {
            return nil
        }

        guard OfflineViewController.vCs.count > previousIndex else {
            return nil
        }

        return OfflineViewController.vCs[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = OfflineViewController.vCs.index(of: viewController) else {
            return nil
        }

        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = OfflineViewController.vCs.count

        guard orderedViewControllersCount != nextIndex else {
            return nil
        }

        guard orderedViewControllersCount > nextIndex else {
            return nil
        }

        return OfflineViewController.vCs[nextIndex]
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed))]
    }

    @objc func spacePressed() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            let vc = (MainViewController.vCs[self.currentPage] as! SingleSubredditViewControllerOffline)
            vc.tableView.contentOffset.y = vc.tableView.contentOffset.y + 350
        }, completion: nil)
    }

    func restartVC() {
        var saved = currentPage

            self.dataSource = self
        self.delegate = self

            setupTabBar()

        view.backgroundColor = ColorUtil.backgroundColor

        OfflineViewController.vCs = []
        for subname in Subscriptions.subreddits {
            OfflineViewController.vCs.append(SingleSubredditViewControllerOffline(subName: subname, parent: self))
        }

        let firstViewController = MainViewController.vCs[0]

        setViewControllers([firstViewController],
                direction: .forward,
                animated: true,
                completion: nil)

        self.doCurrentPage(saved)

        if let nav = self.menuNav {
            if (nav.tableView != nil) {
                nav.tableView.reloadData()
            }
        }
        menuNav?.dismiss(animated: true)
    }

    override func viewDidLoad() {

        self.navToMux = self.navigationController!.navigationBar
        self.color1 = ColorUtil.backgroundColor
        self.color2 = ColorUtil.backgroundColor

        if (OfflineViewController.vCs.count == 0) {
            for subname in OfflineViewController.subs {
                OfflineViewController.vCs.append(SingleSubredditViewControllerOffline(subName: subname, parent: self))
            }
        }

        self.restartVC()


        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)

        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        self.automaticallyAdjustsScrollViewInsets = false
    }

    func colorChanged() {
        if (tabar != nil) {
            tabBar.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarView?.backgroundColor = .clear

        if (navigationController?.isNavigationBarHidden ?? false) {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }

    var currentPage = 0

    var selected = false
}

class IndicatorTemplateBottom: NSObject, MDCTabBarIndicatorTemplate {
    func indicatorAttributes(
            for context: MDCTabBarIndicatorContext
    ) -> MDCTabBarIndicatorAttributes {
        let bounds = context.bounds;
        let attributes = MDCTabBarIndicatorAttributes()
        let underlineFrame = CGRect.init(x: bounds.minX,
                y: bounds.height - 3,
                width: bounds.width,
                height: 3.0);
        attributes.path = UIBezierPath.init(roundedRect: underlineFrame, byRoundingCorners: UIRectCorner.init(arrayLiteral: UIRectCorner.topLeft, UIRectCorner.topRight), cornerRadii: CGSize.init(width: 8, height: 8))
        return attributes;
    }
}

extension OfflineViewController: MDCTabBarDelegate {

    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        selected = true
        let firstViewController = OfflineViewController.vCs[tabBar.items.index(of: item)!]

        setViewControllers([firstViewController],
                direction: .forward,
                animated: false,
                completion: nil)

        self.doCurrentPage(tabBar.items.index(of: item)!)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        tabBar.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)

    }
}