//
//  InboxViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 1/23/17.
//  Copyright © 2017 Haptic Apps. All rights reserved.
//

import MaterialComponents.MaterialTabs
import reddift
import UIKit

class InboxViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIToolbarDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    var content: [MessageWhere] = []
    var isReload = false
    var session: Session?

    var vCs: [UIViewController] = []

    public init() {
        self.session = (UIApplication.shared.delegate as! AppDelegate).session
        self.content = InboxViewController.doDefault()

        for place in content {
            vCs.append(ContentListingViewController.init(dataSource: InboxContributionLoader(whereContent: place)))
        }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func doDefault() -> [MessageWhere] {
        return [MessageWhere.inbox, MessageWhere.messages, MessageWhere.unread]
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Inbox"
        UIApplication.shared.applicationIconBadgeNumber = 0
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: "")
        let edit = UIButton.init(type: .custom)
        edit.setImage(UIImage.init(named: "edit")?.navIcon(), for: UIControlState.normal)
        edit.addTarget(self, action: #selector(self.new(_:)), for: UIControlEvents.touchUpInside)
        edit.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let editB = UIBarButtonItem.init(customView: edit)

        let read = UIButton.init(type: .custom)
        read.setImage(UIImage.init(named: "seen")?.navIcon(), for: UIControlState.normal)
        read.addTarget(self, action: #selector(self.read(_:)), for: UIControlEvents.touchUpInside)
        read.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let readB = UIBarButtonItem.init(customView: read)

        navigationItem.rightBarButtonItems = [editB, readB]

    }

    func new(_ sender: AnyObject) {
        VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(completion: {(_) in
            DispatchQueue.main.async(execute: { () -> Void in
                BannerUtil.makeBanner(text: "Message sent!", seconds: 3, context: self)
            })
        })), parentVC: self)
    }

    private func prepareOverlayVC(overlayVC: UIViewController) {
        overlayVC.transitioningDelegate = overlayTransitioningDelegate
        overlayVC.modalPresentationStyle = .custom
    }

    let overlayTransitioningDelegate = OverlayTransitioningDelegate()

    func read(_ sender: AnyObject) {
        do {
            try session?.markAllMessagesAsRead(completion: { (result) in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "All messages marked as read", seconds: 5, context: self)
                    }
                default:
                    break
                }
            })
        }
        catch {

        }
    }

    var time: Double = 0

    func close() {
        self.navigationController?.popViewController(animated: true)
    }

    var tabBar = MDCTabBar()

    override func viewDidLoad() {
        super.viewDidLoad()

        var items: [String] = []
        for i in content {
            items.append(i.description)
        }

        tabBar = MDCTabBar.init(frame: CGRect.init(x: 0, y: -8, width: self.view.frame.size.width, height: 45))
        tabBar.backgroundColor = ColorUtil.getColorForSub(sub: "")
        tabBar.itemAppearance = .titles
        // 2
        tabBar.items = content.enumerated().map { index, source in
            return UITabBarItem(title: source.description, image: nil, tag: index)
        }
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]

        // 3
        tabBar.selectedItem = tabBar.items[0]
        // 4
        tabBar.delegate = self
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: "NONE")
        // 5
        tabBar.sizeToFit()

        self.view.addSubview(tabBar)

        time = History.getInboxSeen()
        History.inboxSeen()
        view.backgroundColor = ColorUtil.backgroundColor
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
            print("Not nil")
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
        let page = vCs.index(of: self.viewControllers!.first!)

        if !selected {
            tabBar.setSelectedItem(tabBar.items[page! ], animated: true)
        }
        else {
            selected = false
        }
        currentIndex = page!

    }

    var currentIndex = 0
    var lastPosition: CGFloat = 0

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.lastPosition = scrollView.contentOffset.x

        if (currentIndex == vCs.count - 1) && (lastPosition > scrollView.frame.width) {
            scrollView.contentOffset.x = scrollView.frame.width
            return

        }
        else if currentIndex == 0 && lastPosition < scrollView.frame.width {
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

extension InboxViewController: MDCTabBarDelegate {

    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        selected = true
        let firstViewController = vCs[tabBar.items.index(of: item)!]

        setViewControllers([firstViewController],
                direction: .forward,
                animated: false,
                completion: nil)

    }

}
