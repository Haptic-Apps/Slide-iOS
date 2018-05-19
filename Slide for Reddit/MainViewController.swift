//
//  MainViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/25/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import MaterialComponents.MaterialSnackbar
import MaterialComponents.MaterialBottomSheet
import SideMenu

class MainViewController: ColorMuxPagingViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UISplitViewControllerDelegate {
    var isReload = false
    public static var vCs: [UIViewController] = []
    public static var current: String = ""

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true


        if (AccountController.isLoggedIn) {
            checkForMail()
        }
        if (SubredditReorderViewController.changed) {
            restartVC()
        }

        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        if(tabBar != nil){
            tabBar.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        }
        navigationController?.navigationBar.isTranslucent = false

        navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
        navigationController?.setToolbarHidden(false, animated: false)

        if(SettingValues.viewType){
            navigationController?.setNavigationBarHidden(true, animated: true)
        }

        menuNav?.header.doColors()
        if (menuNav?.tableView != nil) {
            menuNav?.tableView.reloadData()
        }
    }

    func checkForMail() {
        let lastMail = UserDefaults.standard.integer(forKey: "mail")
        let session = (UIApplication.shared.delegate as! AppDelegate).session

        do {
            try session?.getProfile({ (result) in
                switch (result) {
                case .failure(let error):
                    print(error)
                case .success(let profile):
                    let unread = profile.inboxCount
                    let diff = unread - lastMail
                    DispatchQueue.main.async {
                        self.menuNav?.setmail(mailcount: unread)

                        if (diff > 0) {
                            let action = MDCSnackbarMessageAction()
                            let actionHandler = { () in
                                let inbox = InboxViewController.init()
                                self.show(inbox, sender: self)
                            }
                            action.handler = actionHandler
                            action.title = "VIEW"
                            let mes = MDCSnackbarMessage.init(text: "\(diff) new message\(diff > 1 ? "s" : "")!")
                            mes.action = action
                            MDCSnackbarManager.show(mes)
                            UserDefaults.standard.set(unread, forKey: "mail")
                            UserDefaults.standard.synchronize()
                        }
                    }
                    break

                }
            })
        } catch {

        }
    }

    func splitViewController(_ svc: UISplitViewController, shouldHide vc: UIViewController, in orientation: UIInterfaceOrientation) -> Bool {
        return false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.splitViewController?.delegate = self
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        if (SettingValues.multiColumn) {
            self.splitViewController?.maximumPrimaryColumnWidth = 10000
            self.splitViewController?.preferredPrimaryColumnWidthFraction = 1

        }


    }


    func addAccount() {
        menuNav?.dismiss(animated: true)
        doLogin(token: nil)
    }

    func addAccount(token: OAuth2Token) {
        menuNav?.dismiss(animated: true)
        doLogin(token: token)
    }

    func goToSubreddit(subreddit: String) {
        if (Subscriptions.subreddits.contains(subreddit)) {
            let index = Subscriptions.subreddits.index(of: subreddit)
            let firstViewController = MainViewController.vCs[index!]


            setViewControllers([firstViewController],
                    direction: .forward,
                    animated: true,
                    completion: nil)
            self.doCurrentPage(index!)
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: subreddit)
            if(tabBar != nil){
                tabBar.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
            }
        } else {
            show(RedditLink.getViewControllerForURL(urlS: URL.init(string: "/r/" + subreddit)!), sender: self)
        }
        menuNav?.dismiss(animated: true)
    }

    func goToSubreddit(index: Int) {
        let firstViewController = MainViewController.vCs[index]

        setViewControllers([firstViewController],
                direction: .forward,
                animated: false,
                completion: nil)
        self.doCurrentPage(index)
    }

    var alertController: UIAlertController?
    var tempToken: OAuth2Token?

    func setToken(token: OAuth2Token) {
        print("Setting token")
        alertController?.dismiss(animated: false, completion: nil)
        // Do any additional setup after loading the view.
        alertController = UIAlertController(title: nil, message: "Syncing subscriptions...\n\n", preferredStyle: .alert)

        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        UserDefaults.standard.setValue(true, forKey: "done" + token.name)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()

        alertController?.view.addSubview(spinnerIndicator)
        self.present(alertController!, animated: true, completion: nil)
        UserDefaults.standard.set(token.name, forKey: "name")
        UserDefaults.standard.synchronize()
        tempToken = token

        AccountController.switchAccount(name: token.name)
        (UIApplication.shared.delegate as! AppDelegate).syncColors(subredditController: self)
    }

    func complete(subs: [String]) {
        Subscriptions.set(name: (tempToken?.name)!, subs: subs, completion: {
            self.alertController?.dismiss(animated: true, completion: nil)
            self.restartVC()
        })
    }

    func restartVC() {

        print("Restarting VC")
        var saved = currentPage

        if (SettingValues.viewType) {
            self.dataSource = self
        } else {
            self.dataSource = nil
        }
        self.delegate = self
        if (subs != nil) {
            subs!.removeFromSuperview()
            subs = nil
        }
        if (SettingValues.viewType) {
            setupTabBar()
        }

        CachedTitle.titles.removeAll()
        view.backgroundColor = ColorUtil.backgroundColor
        splitViewController?.view.backgroundColor = ColorUtil.foregroundColor
        SubredditReorderViewController.changed = false

        MainViewController.vCs = []
        for subname in Subscriptions.subreddits {
            MainViewController.vCs.append(SingleSubredditViewController(subName: subname, parent: self))
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

    var tabBar = MDCTabBar()
    var subs: UIView?

    func setupTabBar() {
        tabBar = MDCTabBar.init(frame: CGRect.init(x: 0, y: 20, width: self.view.frame.size.width, height: 84))
        tabBar.backgroundColor = ColorUtil.getColorForSub(sub: MainViewController.current)
        tabBar.itemAppearance = .titles

        tabBar.selectedItemTintColor = ColorUtil.fontColor
        tabBar.unselectedItemTintColor = ColorUtil.fontColor.withAlphaComponent(0.45)
        tabBar.items = Subscriptions.subreddits.enumerated().map { index, source in
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
        for sub in Subscriptions.subreddits {
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

    func doLogin(token: OAuth2Token?) {
        (UIApplication.shared.delegate as! AppDelegate).login = self
        if (token == nil) {
            AccountController.addAccount()
        } else {
            setToken(token: token!)
        }
    }

    var tintColor: UIColor = UIColor.white
    var menuNav: NavigationSidebarViewController?
    var bottomSheet: MDCBottomSheetController?
    var currentTitle = "Slide"

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        menuNav?.dismiss(animated: true)
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else {
            return
        }
        let page = MainViewController.vCs.index(of: self.viewControllers!.first!)
        doCurrentPage(page!)
    }


    func doCurrentPage(_ page: Int) {
        self.currentPage = page
        let vc = MainViewController.vCs[page] as! SingleSubredditViewController
        vc.viewWillAppear(true)
        MainViewController.current = vc.sub
        self.tintColor = ColorUtil.getColorForSub(sub: MainViewController.current)
        self.menuNav?.setSubreddit(subreddit: MainViewController.current)
        self.currentTitle = MainViewController.current

        if (!(vc).loaded) {
            (vc).load(reset: true)
        }


        let label = UILabel()
        label.text = "   \(self.currentTitle)"
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFont(ofSize: 20)

        label.sizeToFit()
        let leftItem = UIBarButtonItem(customView: label)

        self.navigationItem.leftBarButtonItems = [ leftItem]

        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()

        tabBar.backgroundColor = ColorUtil.getColorForSub(sub: MainViewController.current)
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: MainViewController.current)
        if (!selected) {
            let page = MainViewController.vCs.index(of: self.viewControllers!.first!)
            if (!tabBar.items.isEmpty) {
                tabBar.setSelectedItem(tabBar.items[page!], animated: true)
            }
        } else {
            selected = false
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        color2 = ColorUtil.getColorForSub(sub: (pendingViewControllers[0] as! SingleSubredditViewController).sub)
        color1 = ColorUtil.getColorForSub(sub: (MainViewController.vCs[currentPage] as! SingleSubredditViewController).sub)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = MainViewController.vCs.index(of: viewController) else {
            return nil
        }

        let previousIndex = viewControllerIndex - 1

        guard previousIndex >= 0 else {
            return nil
        }

        guard MainViewController.vCs.count > previousIndex else {
            return nil
        }

        return MainViewController.vCs[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = MainViewController.vCs.index(of: viewController) else {
            return nil
        }

        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = MainViewController.vCs.count

        guard orderedViewControllersCount != nextIndex else {
            return nil
        }

        guard orderedViewControllersCount > nextIndex else {
            return nil
        }

        return MainViewController.vCs[nextIndex]
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed))]
    }

    @objc func spacePressed() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            let vc = (MainViewController.vCs[self.currentPage] as! SingleSubredditViewController)
            vc.tableView.contentOffset.y = vc.tableView.contentOffset.y + 350
        }, completion: nil)
    }


    override func viewDidLoad() {

        self.navToMux = self.navigationController!.navigationBar
        self.color1 = ColorUtil.backgroundColor
        self.color2 = ColorUtil.backgroundColor

        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        if (SettingValues.multiColumn) {
            self.splitViewController?.maximumPrimaryColumnWidth = 10000
            self.splitViewController?.preferredPrimaryColumnWidthFraction = 1
        }

        if (UIScreen.main.traitCollection.userInterfaceIdiom == .pad && UIApplication.shared.statusBarOrientation != .portrait && (self.navigationController)?.splitViewController != nil && !SettingValues.multiColumn) {
            self.splitViewController?.showDetailViewController(PlaceholderViewController(), sender: nil)
        }

        if (MainViewController.vCs.count == 0) {
            for subname in Subscriptions.subreddits {
                MainViewController.vCs.append(SingleSubredditViewController(subName: subname, parent: self))
            }
        }

        self.restartVC()

        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white")?.navIcon(), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let sortB = UIBarButtonItem.init(customView: sort)

        let shadowbox = UIButton.init(type: .custom)
        shadowbox.setImage(UIImage.init(named: "shadowbox")?.navIcon(), for: UIControlState.normal)
        shadowbox.addTarget(self, action: #selector(self.shadowbox), for: UIControlEvents.touchUpInside)
        shadowbox.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let sB = UIBarButtonItem.init(customView: shadowbox)

        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "moreh")?.toolbarIcon(), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let moreB = UIBarButtonItem.init(customView: more)

        let menu = UIButton.init(type: .custom)
        menu.setImage(UIImage.init(named: "menu")?.toolbarIcon(), for: UIControlState.normal)
        menu.addTarget(self, action: #selector(self.showDrawer(_:)), for: UIControlEvents.touchUpInside)
        menu.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let menuB = UIBarButtonItem.init(customView: menu)

        let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)

        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        toolbarItems = [menuB, flexButton, moreB]
        navigationItem.rightBarButtonItem = sortB

        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        self.automaticallyAdjustsScrollViewInsets = false

        if(menuNav == nil){
            menuNav = NavigationSidebarViewController()
            menuNav?.setViewController(controller: self)
            self.menuNav?.setSubreddit(subreddit: MainViewController.current)
            bottomSheet = MDCBottomSheetController(contentViewController: menuNav!)

        }


        checkForUpdate()

        if (UIScreen.main.traitCollection.userInterfaceIdiom == .pad) {
            self.edgesForExtendedLayout = UIRectEdge.all
            self.extendedLayoutIncludesOpaqueBars = true


            if (AccountController.isLoggedIn) {
                checkForMail()
            }
            if (SubredditReorderViewController.changed) {
                restartVC()
            }

            self.navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: self.currentTitle)
            if(tabBar != nil){
                tabBar.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)
            }

            navigationController?.navigationBar.isTranslucent = false

            menuNav?.header.doColors()
            if (menuNav?.tableView != nil) {
                menuNav?.tableView.reloadData()
            }
        }
    }

    func resetColors() {
        // self.navigationController?.navigationBar.barTintColor = self.tintColor
        //todo self.buttonBarView.backgroundColor = self.tintColor
    }

    func checkForUpdate() {
        if(!SettingValues.doneVersion()) {
            print("Getting posts for version \(Bundle.main.releaseVersionNumber!)")
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            do {
                try session?.getList(Paginator.init(), subreddit: Subreddit.init(subreddit: "slide_ios"), sort: LinkSortType.hot, timeFilterWithin: TimeFilterWithin.hour, completion: { (result) in
                    switch result {
                    case .failure:
                        //Ignore this
                        break;
                    case .success(let listing):
                        print("Got")
                        let submissions = listing.children.flatMap({ $0 as? Link })
                        let first = submissions[1]
                        let second = submissions[2]
                        var storedTitle = ""
                        var storedLink = ""

                        if (first.stickied && first.title.contains(Bundle.main.releaseVersionNumber!)) {
                            storedTitle = first.title
                            storedLink = first.permalink
                        } else if (second.stickied && second.title.contains(Bundle.main.releaseVersionNumber!)) {
                            storedTitle = second.title
                            storedLink = second.permalink
                        }

                        if(!storedTitle.isEmpty && !storedLink.isEmpty){
                            DispatchQueue.main.async {
                                print("Showing")
                                SettingValues.showVersionDialog(storedTitle, storedLink, parentVC: self)
                            }
                        }

                        break
                    }
                })
            } catch {
            }
        }
    }

    func colorChanged() {
        menuNav?.header.doColors()

        if(tabBar != nil){
            tabBar.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        }

        if (menuNav?.tableView != nil) {
            menuNav?.tableView.reloadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarView?.backgroundColor = .clear

        if (navigationController?.isNavigationBarHidden ?? false) {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }

    func showSortMenu(_ sender: UIButton?) {
        (MainViewController.vCs[currentPage] as? SingleSubredditViewController)?.showMenu(sender)
    }

    var currentPage = 0

    func showDrawer(_ sender: AnyObject) {
        menuNav!.setColors(MainViewController.current)
        present(bottomSheet!, animated: true, completion: nil)
    }

    func shadowbox() {
        (MainViewController.vCs[currentPage] as? SingleSubredditViewController)?.shadowboxMode()
    }



    func showMenu(_ sender: AnyObject) {
        (MainViewController.vCs[currentPage] as? SingleSubredditViewController)?.showMore(sender, parentVC: self)
    }

    func showThemeMenu() {
        let actionSheetController: UIAlertController = UIAlertController(title: "Select a base theme", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        for theme in ColorUtil.Theme.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: theme.rawValue, style: .default) { action -> Void in
                UserDefaults.standard.set(theme.rawValue, forKey: "theme")
                UserDefaults.standard.synchronize()
                ColorUtil.doInit()
                self.restartVC()
            }
            actionSheetController.addAction(saveActionButton)
        }

        //todo make this work on ipad, also maybe merge with current code in SettingsTheme?
        self.present(actionSheetController, animated: true, completion: nil)
    }

    var selected = false
}

class IndicatorTemplate: NSObject, MDCTabBarIndicatorTemplate {
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

extension MainViewController: MDCTabBarDelegate {

    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        selected = true
        let firstViewController = MainViewController.vCs[tabBar.items.index(of: item)!]

        setViewControllers([firstViewController],
                direction: .forward,
                animated: false,
                completion: nil)

        self.doCurrentPage(tabBar.items.index(of: item)!)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        tabBar.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)

    }
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    var releaseVersionNumberPretty: String {
        return "v\(releaseVersionNumber ?? "1.0.0")"
    }
}
