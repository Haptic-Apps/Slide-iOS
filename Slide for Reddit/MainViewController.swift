//
//  MainViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/25/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import BadgeSwift
import MaterialComponents.MaterialTabs
import RealmSwift
import reddift
import StoreKit
import UIKit
import WatchConnectivity

class MainViewController: ColorMuxPagingViewController, UINavigationControllerDelegate, ReadLaterDelegate {
    
    func didUpdate() {
        let count = ReadLater.readLaterIDs.count
        if count > 0 {
            let readLater = UIButton.init(type: .custom)
            readLater.setImage(UIImage.init(named: "bin")?.navIcon(), for: UIControlState.normal)
            readLater.addTarget(self, action: #selector(self.showReadLater(_:)), for: UIControlEvents.touchUpInside)
            
            readLaterBadge?.removeFromSuperview()
            readLaterBadge = nil
            
            readLaterBadge = BadgeSwift()
            readLater.addSubview(readLaterBadge!)
            readLaterBadge!.centerXAnchor == readLater.centerXAnchor
            readLaterBadge!.centerYAnchor == readLater.centerYAnchor - 2
            
            readLaterBadge!.text = "\(count)"
            readLaterBadge!.insets = CGSize.zero
            readLaterBadge!.font = UIFont.systemFont(ofSize: 12)
            readLaterBadge!.textColor = SettingValues.reduceColor ? ColorUtil.fontColor : UIColor.white
            readLaterBadge!.badgeColor = .clear
            readLaterBadge!.shadowOpacityBadge = 0
            
            readLaterB = UIBarButtonItem.init(customView: readLater)
            
            if SettingValues.subredditBar {
                navigationItem.leftBarButtonItems = [accountB]
                navigationItem.rightBarButtonItems = [readLaterB]
            } else {
                navigationItem.leftBarButtonItems = []
                navigationItem.rightBarButtonItems = [accountB, readLaterB]
            }
        } else {
            if SettingValues.subredditBar {
                navigationItem.leftBarButtonItems = [accountB]
                navigationItem.rightBarButtonItems = []
            } else {
                navigationItem.leftBarButtonItems = []
                navigationItem.rightBarButtonItems = [accountB]
            }
            navigationItem.rightBarButtonItems = []
        }
    }
    
    var isReload = false
    var readLaterBadge: BadgeSwift?
    var vCs: [UIViewController] = []
    public static var current: String = ""
    public static var needsRestart = false
    public var toolbar: UIView?
    var more = UIButton()
    var menu = UIButton()
    var readLaterB = UIBarButtonItem()
    var sortB = UIBarButtonItem()
    var readLater = UIButton()
    var accountB = UIBarButtonItem()
    
    override func viewWillAppear(_ animated: Bool) {
        menuNav?.view.isHidden = false
        super.viewWillAppear(animated)
        self.viewWillAppearActions()
        self.navigationController?.setToolbarHidden(true, animated: false)
        ReadLater.delegate = self
        if Reachability().connectionStatus().description == ReachabilityStatus.Offline.description {
            MainViewController.isOffline = true
            let offlineVC = OfflineOverviewViewController(subs: finalSubs)
            VCPresenter.showVC(viewController: offlineVC, popupIfPossible: false, parentNavigationController: nil, parentViewController: self)
        }
        if MainViewController.needsRestart {
            MainViewController.needsRestart = false
            tabBar.removeFromSuperview()
            self.navigationItem.leftBarButtonItems = []
            self.navigationItem.rightBarButtonItems = []
            if SettingValues.subredditBar {
                setupTabBar(finalSubs)
                self.dataSource = self
            } else {
                self.navigationItem.titleView = nil
                self.dataSource = nil
            }
        }
        didUpdate()
    }
    
    public func viewWillAppearActions() {
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        self.splitViewController?.navigationController?.setNavigationBarHidden(true, animated: false)
        
        let shouldBeNight = ColorUtil.shouldBeNight()
        if SubredditReorderViewController.changed || (shouldBeNight && ColorUtil.theme != SettingValues.nightTheme) || (!shouldBeNight && ColorUtil.theme != ColorUtil.defaultTheme) {
            var subChanged = false
            if finalSubs.count != Subscriptions.subreddits.count {
                subChanged = true
            } else {
                for i in 0 ..< finalSubs.count {
                    if finalSubs[i] != Subscriptions.subreddits[i] {
                        subChanged = true
                        break
                    }
                }
            }
            
            if ColorUtil.doInit() || subChanged || SubredditReorderViewController.changed {
                restartVC()
                return
            }
        }
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = false
        
        navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
        
        self.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: getSubredditVC()?.sub ?? "", true)
        if menuNav?.tableView != nil {
            menuNav?.tableView.reloadData()
        }
        
        if SettingValues.reduceColor && ColorUtil.theme.isLight() {
            UIApplication.shared.statusBarStyle = .default
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }
    }
    
    //    override func preferredScreenEdgesDeferringSystemGestures() -> UIRectEdge {
    //        return .bottom
    //    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    //from https://github.com/CleverTap/ios-request-review/blob/master/Example/RatingExample/ViewController.swift
    private func requestReviewIfAppropriate() {
        if #available(iOS 10.3, *) {
            let lastReviewedVersion = UserDefaults.standard.string(forKey: "lastReviewed")
            let timesOpened = UserDefaults.standard.integer(forKey: "appOpens")
            if lastReviewedVersion != nil && (getVersion() == lastReviewedVersion!) || timesOpened < 10 {
                UserDefaults.standard.set(timesOpened + 1, forKey: "appOpens")
                UserDefaults.standard.synchronize()
                return
            }
            SKStoreReviewController.requestReview()
            UserDefaults.standard.set(0, forKey: "appOpens")
            UserDefaults.standard.set(getVersion(), forKey: "lastReviewed")
            UserDefaults.standard.synchronize()
        } else {
            print("SKStoreReviewController not available")
        }
    }
    
    func getVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "\(version) build \(build)"
    }
    
    func hardReset() {
        PagingCommentViewController.savedComment = nil
        navigationController?.popViewController(animated: false)
        navigationController?.setViewControllers([MainViewController.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)], animated: false)
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Fixes bug with corrupt nav stack
        // https://stackoverflow.com/a/39457751/7138792
        navigationController.interactivePopGestureRecognizer?.isEnabled = navigationController.viewControllers.count > 1
        if navigationController.viewControllers.count == 1 {
            self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
    
    var checkedClipboardOnce = false
    func checkForMail() {
        DispatchQueue.main.async {
            if !self.checkedClipboardOnce {
                var clipUrl: URL?
                if let url = UIPasteboard.general.url {
                    if ContentType.getContentType(baseUrl: url) == .REDDIT {
                        clipUrl = url
                    }
                }
                if clipUrl == nil {
                    if let urlS = UIPasteboard.general.string {
                        if let url = URL.init(string: urlS) {
                            if ContentType.getContentType(baseUrl: url) == .REDDIT {
                                clipUrl = url
                            }
                        }
                    }
                }
                
                if clipUrl != nil {
                    self.checkedClipboardOnce = true
                    BannerUtil.makeBanner(text: "Open link from clipboard", color: GMColor.green500Color(), seconds: 5, context: self, top: true, callback: {
                        () in
                        VCPresenter.openRedditLink(clipUrl!.absoluteString, self.navigationController, self)
                    })
                }
            }
            
            let lastMail = UserDefaults.standard.integer(forKey: "mail")
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            
            do {
                try session?.getProfile({ (result) in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let profile):
                        SettingValues.nsfwEnabled = profile.over18
                        if let nsfw = UserDefaults.standard.object(forKey: SettingValues.pref_hideNSFWCollection + AccountController.currentName) {
                            SettingValues.hideNSFWCollection = nsfw as! Bool
                        } else {
                            SettingValues.hideNSFWCollection = UserDefaults.standard.bool(forKey: SettingValues.pref_hideNSFWCollection)
                        }
                        if let nsfw = UserDefaults.standard.object(forKey: SettingValues.pref_nsfwPreviews + AccountController.currentName) {
                            SettingValues.nsfwPreviews = nsfw as! Bool
                        } else {
                            SettingValues.nsfwPreviews = UserDefaults.standard.bool(forKey: SettingValues.pref_nsfwPreviews)
                        }
                        
                        let unread = profile.inboxCount
                        let diff = unread - lastMail
                        if profile.isMod && AccountController.modSubs.isEmpty {
                            print("Getting mod subs")
                            AccountController.doModOf()
                        }
                        DispatchQueue.main.async {
                            if diff > 0 {
                                BannerUtil.makeBanner(text: "\(diff) new message\(diff > 1 ? "s" : "")!", seconds: 5, context: self, top: true, callback: {
                                    () in
                                    let inbox = InboxViewController.init()
                                    VCPresenter.showVC(viewController: inbox, popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
                                })
                            }
                            UserDefaults.standard.set(unread, forKey: "mail")
                            NotificationCenter.default.post(name: .onAccountMailCountChanged, object: nil, userInfo: [
                                "Count": unread
                                ])
                            UserDefaults.standard.synchronize()
                        }
                    }
                })
            } catch {
                
            }
        }
    }
    
    func splitViewController(_ svc: UISplitViewController, shouldHide vc: UIViewController, in orientation: UIInterfaceOrientation) -> Bool {
        return false
    }
    
    public static var first = true
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AccountController.isLoggedIn && !MainViewController.first {
            checkForMail()
        }
        self.navigationController?.delegate = self
    }
    
    func addAccount(register: Bool) {
        menuNav?.dismiss(animated: true)
        doLogin(token: nil, register: register)
    }
    
    static func doAddAccount(register: Bool) {
        guard let window = UIApplication.shared.keyWindow else {
            fatalError("Window must exist when resetting the stack!")
        }

        let main = MainViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        let rootController: UIViewController
        if UIDevice.current.userInterfaceIdiom == .pad && SettingValues.appMode == .SPLIT {
            let split = UISplitViewController()
            rootController = split
            split.preferredDisplayMode = .allVisible
            
            (rootController as! UISplitViewController).viewControllers = [UINavigationController(rootViewController: main)]
        } else {
            rootController = UINavigationController(rootViewController: main)
        }
        
        window.setRootViewController(rootController, animated: false)

        (UIApplication.shared.delegate as! AppDelegate).login = main
        AccountController.addAccount(context: main, register: register)
    }

    func addAccount(token: OAuth2Token, register: Bool) {
        menuNav?.dismiss(animated: true)
        doLogin(token: token, register: register)
    }
    
    func goToSubreddit(subreddit: String) {
        menuNav?.dismiss(animated: true) {
            if Subscriptions.subreddits.contains(subreddit) {
                let index = Subscriptions.subreddits.index(of: subreddit)
                if index == nil {
                    return
                }
                let firstViewController = self.vCs[index!]
                
                if SettingValues.subredditBar && !SettingValues.reduceColor {
                    self.color1 = ColorUtil.baseColor
                    self.color2 = ColorUtil.getColorForSub(sub: (firstViewController as! SingleSubredditViewController).sub)
                } else {
                    self.color1 = ColorUtil.backgroundColor
                    self.color2 = ColorUtil.backgroundColor
                }
                
                self.setViewControllers([firstViewController],
                                        direction: index! > self.currentPage ? .forward : .reverse,
                                        animated: SettingValues.subredditBar ? true : false,
                                        completion: nil)
                self.doCurrentPage(index!)
            } else {
                //todo better sanitation
                VCPresenter.openRedditLink("/r/" + subreddit.replacingOccurrences(of: " ", with: ""), self.navigationController, self)
            }
        }
    }
    
    func goToUser(profile: String) {
        menuNav?.dismiss(animated: true) {
            VCPresenter.openRedditLink("/u/" + profile.replacingOccurrences(of: " ", with: ""), self.navigationController, self)
        }
    }
    
    func goToSubreddit(index: Int) {
        let firstViewController = vCs[index]
        
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
        
        if UserDefaults.standard.array(forKey: "subs" + token.name) != nil {
            UserDefaults.standard.set(token.name, forKey: "name")
            UserDefaults.standard.synchronize()
            tempToken = token
            AccountController.switchAccount(name: token.name)
            (UIApplication.shared.delegate as! AppDelegate).syncColors(subredditController: self)
        } else {
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
    }
    
    func complete(subs: [String]) {
        var finalSubs = subs
        if !subs.contains("slide_ios") {
            self.alertController?.dismiss(animated: true, completion: {
                let alert = UIAlertController.init(title: "Subscribe to r/slide_ios?", message: "Would you like to subscribe to the Slide for Reddit iOS community and receive news and updates first?", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "Maybe later", style: .cancel, handler: {(_) in
                    self.finalizeSetup(subs)
                }))
                alert.addAction(UIAlertAction.init(title: "Sure!", style: .default, handler: {(_) in
                    finalSubs.insert("slide_ios", at: 2)
                    self.finalizeSetup(finalSubs)
                    do {
                        try (UIApplication.shared.delegate as! AppDelegate).session!.setSubscribeSubreddit(Subreddit.init(subreddit: "slide_ios"), subscribe: true, completion: { (_) in
                            
                        })
                    } catch {
                        
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            })
        } else {
            if self.alertController != nil {
                self.alertController?.dismiss(animated: true, completion: {
                    self.finalizeSetup(subs)
                })
            } else {
                self.finalizeSetup(subs)
            }
        }
    }
    
    func finalizeSetup(_ subs: [String]) {
        Subscriptions.set(name: (tempToken?.name)!, subs: subs, completion: {
            self.menuNav?.view.removeFromSuperview()
            self.menuNav?.backgroundView.removeFromSuperview()
            self.menuNav?.removeFromParentViewController()
            self.menuNav = nil
            self.hardReset()
        })
    }
    
    var finalSubs = [String]()
    
    func makeMenuNav() {
        if menuNav != nil {
            more.removeFromSuperview()
            menu.removeFromSuperview()
            menuNav?.view.removeFromSuperview()
            menuNav?.backgroundView.removeFromSuperview()
            menuNav?.removeFromParentViewController()
            menuNav = nil
        }
        menuNav = NavigationSidebarViewController(controller: self)

        toolbar = UITouchCapturingView()
        toolbar!.layer.cornerRadius = 15

        menuNav?.topView = toolbar
        menuNav?.view.addSubview(toolbar!)
        menuNav?.muxColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.theme.isLight() ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))

        toolbar!.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.theme.isLight() ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))
        toolbar!.horizontalAnchors == menuNav!.view.horizontalAnchors
        toolbar!.topAnchor == menuNav!.view.topAnchor
        toolbar!.heightAnchor == 90

        //toolbar!.roundCorners([UIRectCorner.topLeft, UIRectCorner.topRight], radius: 15)
        self.menuNav?.setSubreddit(subreddit: MainViewController.current)
        //        menuNav?.modalPresentationStyle = .overCurrentContext
        
        //        bottomSheetTransitioningDelegate.direction = .bottom
        //        bottomSheetTransitioningDelegate.coverageRatio = 0.85
        //        bottomSheetTransitioningDelegate.draggingView = menuNav?.view
        //        bottomSheetTransitioningDelegate.scrollView = menuNav?.tableView
        //        bottomSheetTransitioningDelegate.menuViewController = menuNav
        //        menuNav?.transitioningDelegate = bottomSheetTransitioningDelegate
        
        //        slideInTransitioningDelegate.coverageRatio = 0.85
        //        slideInTransitioningDelegate.direction = .bottom
        //        menuNav?.transitioningDelegate = slideInTransitioningDelegate
        
        //        self.coverPartiallyDelegate = CoverPartiallyPresentationController(presentedViewController: menuNav!, presenting: self, coverDirection: .down)
        //        menuNav?.transitioningDelegate = coverPartiallyDelegate
        
        self.addChildViewController(menuNav!)
        self.view.addSubview(menuNav!.view)
        menuNav!.didMove(toParentViewController: self)
        
        // 3- Adjust bottomSheet frame and initial position.
        let height = view.frame.height
        let width = view.frame.width
        var nextOffset = CGFloat(0)
        if self.splitViewController != nil && UIDevice.current.orientation == .portrait {
            nextOffset = 64
        }

        menuNav!.view.frame = CGRect(x: 0, y: self.view.frame.maxY - CGFloat(menuNav!.bottomOffset) - nextOffset, width: width, height: min(height - menuNav!.minTopOffset, height * 0.9))
    }
    
    func restartVC() {
        if (splitViewController != nil && SettingValues.appMode != .SPLIT) || (splitViewController == nil && SettingValues.appMode == .SPLIT) {
            (UIApplication.shared.delegate as! AppDelegate).resetStack()
            //return
        }
        
        let saved = getSubredditVC()
        let savedPage = saved?.sub ?? ""
        
        self.makeMenuNav()
        self.doButtons()
        
        if SettingValues.subredditBar {
            self.dataSource = self
        } else {
            self.dataSource = nil
        }
        
        self.delegate = self
        if self.subs != nil {
            self.subs!.removeFromSuperview()
            self.subs = nil
        }
        
        CachedTitle.titles.removeAll()
        view.backgroundColor = ColorUtil.backgroundColor
        splitViewController?.view.backgroundColor = ColorUtil.foregroundColor
        SubredditReorderViewController.changed = false
        
        vCs = []
        finalSubs = []
        LinkCellView.cachedInternet = nil
        
        finalSubs = Subscriptions.subreddits
        MainViewController.isOffline = false
        var subs = [UIMutableApplicationShortcutItem]()
        for subname in finalSubs {
            if subname == savedPage {
                vCs.append(saved!)
                SingleSubredditViewController.firstPresented = false
                saved!.reloadNeedingColor()
                saved!.parentController = self
            } else {
                vCs.append(SingleSubredditViewController(subName: subname, parent: self))
            }
            if subs.count < 2 && !subname.contains("/") {
                subs.append(UIMutableApplicationShortcutItem.init(type: "me.ccrama.redditslide.subreddit", localizedTitle: subname, localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(templateImageName: "subs"), userInfo: [ "sub": "\(subname)" ]))
            }
        }
        
        subs.append(UIMutableApplicationShortcutItem.init(type: "me.ccrama.redditslide.subreddit", localizedTitle: "Open link", localizedSubtitle: "Open current clipboard url", icon: UIApplicationShortcutIcon.init(templateImageName: "nav"), userInfo: [ "clipboard": "true" ]))
        subs.reverse()
        UIApplication.shared.shortcutItems = subs
        
        if SettingValues.submissionGesturesEnabled {
            for view in view.subviews {
                if view is UIScrollView {
                    let scrollView = view as! UIScrollView
                    if scrollView.isPagingEnabled {
                        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
                    }
                    break
                }
            }
        }
        
        var newIndex = 0
        
        for sub in self.finalSubs {
            if sub == savedPage {
                newIndex = finalSubs.lastIndex(of: sub)!
            }
        }
        
        let firstViewController = vCs[newIndex]
        
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: true,
                           completion: nil)
        
        self.doCurrentPage(newIndex)
        
        self.makeMenuNav()
        
        doButtons()
        
        tabBar.removeFromSuperview()
        if SettingValues.subredditBar {
            setupTabBar(finalSubs)
        } else {
            self.navigationItem.titleView = nil
        }
    }
    
    var tabBar = MDCTabBar()
    var subs: UIView?
    
    func setupTabBar(_ subs: [String]) {
        tabBar = MDCTabBar.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 48))
        tabBar.itemAppearance = .titles
        
        tabBar.selectedItemTintColor = SettingValues.reduceColor ? ColorUtil.fontColor : UIColor.white
        tabBar.unselectedItemTintColor = SettingValues.reduceColor ? ColorUtil.fontColor.withAlphaComponent(0.45) : UIColor.white.withAlphaComponent(0.45)
        
        tabBar.items = subs.enumerated().map { index, source in
            return UITabBarItem(title: source, image: nil, tag: index)
        }
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        tabBar.selectionIndicatorTemplate = IndicatorTemplate()
        tabBar.delegate = self
        tabBar.inkColor = UIColor.clear
        tabBar.selectedItem = tabBar.items[0]
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: subs.isEmpty ? "NONE" : subs[0])
        tabBar.backgroundColor = .clear
        tabBar.sizeToFit()
        //self.viewToMux = self.tabBar
        
        self.navigationItem.titleView = tabBar
        
        for item in tabBar.items {
            if item.title == currentTitle {
                tabBar.setSelectedItem(item, animated: false)
            }
        }
    }
    
    func didChooseSub(_ gesture: UITapGestureRecognizer) {
        let sub = gesture.view!.tag
        goToSubreddit(index: sub)
    }
    
    var statusbarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height
    }
    
    func doLogin(token: OAuth2Token?, register: Bool) {
        (UIApplication.shared.delegate as! AppDelegate).login = self
        if token == nil {
            AccountController.addAccount(context: self, register: register)
        } else {
            setToken(token: token!)
        }
    }
    
    var menuNav: NavigationSidebarViewController?

    var currentTitle = "Slide"
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        menuNav?.dismiss(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        menuNav?.view.width = splitViewController == nil ? view.frame.width : splitViewController!.primaryColumnWidth
    }
    
    func doCurrentPage(_ page: Int) {
        guard page < vCs.count else { return }
        let vc = vCs[page] as! SingleSubredditViewController
        MainViewController.current = vc.sub
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, "Viewing \(vc.sub)")
        self.menuNav?.setSubreddit(subreddit: MainViewController.current)
        self.currentTitle = MainViewController.current
        menuNav!.setColors(MainViewController.current)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: vc.sub, true)
        self.inHeadView.backgroundColor = ColorUtil.getColorForSub(sub: vc.sub, true)
        
        if !(vc).loaded || !SettingValues.subredditBar {
            if vc.loaded {
                vc.indicator?.isHidden = false
                vc.indicator?.startAnimating()
                vc.refresh(false)
            } else {
                (vc).load(reset: true)
            }
        }
        
        let label = UILabel()
        label.text = "   \(SettingValues.reduceColor ? "    " : "")\(SettingValues.subredditBar ? "" : self.currentTitle)"
        label.textColor = SettingValues.reduceColor ? ColorUtil.fontColor : .white
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFont(ofSize: 20)
        
        if SettingValues.reduceColor {
            var sideView = UIView()
            sideView = UIView(frame: CGRect(x: 5, y: 5, width: 15, height: 15))
            sideView.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)
            sideView.translatesAutoresizingMaskIntoConstraints = false
            label.addSubview(sideView)
            sideView.layer.cornerRadius = 7.5
            sideView.clipsToBounds = true
        }
        
        label.sizeToFit()
        let leftItem = UIBarButtonItem(customView: label)
        
        if !SettingValues.subredditBar {
            self.navigationItem.leftBarButtonItems = [leftItem]
        }
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        // Clear the menuNav's searchBar to refresh the menuNav
        self.menuNav?.searchBar.text = nil
        
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: vc.sub)
        if !selected {
            let page = vCs.index(of: self.viewControllers!.first!)
            if !tabBar.items.isEmpty {
                tabBar.setSelectedItem(tabBar.items[page!], animated: true)
            }
        } else {
            selected = false
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        drawerButton.frame = CGRect(x: 8, y: size.height - 48, width: 40, height: 40)
        inHeadView.removeFromSuperview()
        
        doButtons()
        var wasntHidden = false
        if !(menuNav?.view.isHidden ?? true) {
            wasntHidden = true
            menuNav?.view.isHidden = true
        }
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if wasntHidden {
                self.menuNav?.view.isHidden = false
            }
            self.menuNav?.doRotate(false)
            self.getSubredditVC()?.showUI(false)
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed))]
    }
    
    @objc func spacePressed() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            if let vc = self.getSubredditVC() {
                vc.tableView.contentOffset.y += 350
            }
        }, completion: nil)
    }
    
    var inHeadView = UIView()
    
    override func viewDidLoad() {
        self.navToMux = self.navigationController!.navigationBar
        self.color1 = ColorUtil.backgroundColor
        self.color2 = ColorUtil.backgroundColor
        
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        self.splitViewController?.maximumPrimaryColumnWidth = 10000
        self.splitViewController?.preferredPrimaryColumnWidthFraction = 0.33
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad && self.splitViewController != nil {
            self.splitViewController?.showDetailViewController(PlaceholderViewController(), sender: nil)
        }
        
        self.restartVC()
        
        doButtons()
        
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        inHeadView.removeFromSuperview()
        inHeadView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: max(self.view.frame.size.width, self.view.frame.size.height), height: (UIApplication.shared.statusBarView?.frame.size.height ?? 20)))
        self.inHeadView.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle, true)
        
        if SettingValues.subredditBar {
            self.view.addSubview(inHeadView)
        }
        
        checkForUpdate()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        let today = formatter.string(from: Date())
        
        if SettingValues.autoCache {
            if UserDefaults.standard.string(forKey: "DAY_LAUNCH") != today {
                _ = AutoCache.init(baseController: self)
                UserDefaults.standard.setValue(today, forKey: "DAY_LAUNCH")
            }
        }
        requestReviewIfAppropriate()
        
        //        drawerButton = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        //        drawerButton.backgroundColor = ColorUtil.foregroundColor
        //        drawerButton.clipsToBounds = true
        //        drawerButton.contentMode = .center
        //        drawerButton.layer.cornerRadius = 20
        //        drawerButton.image = UIImage(named: "menu")?.getCopy(withSize: CGSize.square(size: 25), withColor: ColorUtil.fontColor)
        //        self.view.addSubview(drawerButton)
        //        drawerButton.translatesAutoresizingMaskIntoConstraints = false
        //        drawerButton.addTapGestureRecognizer {
        //            self.showDrawer(self.drawerButton)
        //        }
        
        toolbar?.addTapGestureRecognizer(action: {
            self.showDrawer(self.drawerButton)
        })
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(showDrawer(_:)))
        swipe.direction = .up
        
        //        drawerButton.addGestureRecognizer(swipe)
        //        drawerButton.isHidden = true
        //
        //        drawerButton.bottomAnchor == self.view.safeBottomAnchor - 8
        //        drawerButton.leadingAnchor == self.view.safeLeadingAnchor + 8
        //        drawerButton.heightAnchor == 40
        //        drawerButton.widthAnchor == 40
    }
    
    public static var isOffline = false
    var menuB = UIBarButtonItem()
    var drawerButton = UIImageView()
    
    func doButtons() {
        if menu.superview != nil {
            return
        }
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white")?.navIcon(), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        sortB = UIBarButtonItem.init(customView: sort)

        let account = UIButton(type: .custom)
        account.setImage(UIImage(named: "profile")?.navIcon(), for: UIControlState.normal)
        account.addTarget(self, action: #selector(self.showCurrentAccountMenu(_:)), for: UIControlEvents.touchUpInside)
        accountB = UIBarButtonItem(customView: account)
        accountB.accessibilityLabel = "Account"
        
        let settings = UIButton.init(type: .custom)
        settings.setImage(UIImage.init(named: "search")?.toolbarIcon(), for: UIControlState.normal)
        //todo this settings.addTarget(self, action: #selector(self.showDrawer(_:)), for: UIControlEvents.touchUpInside)
        settings.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let settingsB = UIBarButtonItem.init(customView: settings)
        
        let offline = UIButton.init(type: .custom)
        offline.setImage(UIImage.init(named: "offline")?.toolbarIcon(), for: UIControlState.normal)
        offline.addTarget(self, action: #selector(self.restartVC), for: UIControlEvents.touchUpInside)
        offline.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let offlineB = UIBarButtonItem.init(customView: offline)
        
        let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        if !MainViewController.isOffline {
            more = UIButton.init(type: .custom)
            more.accessibilityIdentifier = "more"
            more.setImage(UIImage.init(named: "moreh")?.toolbarIcon(), for: UIControlState.normal)
            more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
            more.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            
            menu = UIButton.init(type: .custom)
            menu.accessibilityIdentifier = "search"
            menu.setImage(UIImage.init(named: "search")?.toolbarIcon(), for: UIControlState.normal)
            menu.addTarget(self, action: #selector(self.showDrawer(_:)), for: UIControlEvents.touchUpInside)
            menu.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            toolbar?.addSubview(menu)
            toolbar?.addSubview(more)
            
            menu.heightAnchor == 56
            menu.widthAnchor == 56
            if let tool = toolbar {
                menu.leftAnchor == tool.leftAnchor
                menu.topAnchor == tool.topAnchor
                more.rightAnchor == tool.rightAnchor
                more.topAnchor == tool.topAnchor
            }
            
            more.heightAnchor == 56
            more.widthAnchor == 56
            
        } else {
            toolbarItems = [settingsB, accountB, flexButton, offlineB]
        }
        didUpdate()
    }
    
    func checkForUpdate() {
        if !SettingValues.doneVersion() {
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            do {
                try session?.getList(Paginator.init(), subreddit: Subreddit.init(subreddit: "slide_ios"), sort: LinkSortType.hot, timeFilterWithin: TimeFilterWithin.hour, completion: { (result) in
                    switch result {
                    case .failure:
                        //Ignore this
                        break
                    case .success(let listing):
                        
                        let submissions = listing.children.flatMap({ $0 as? Link })
                        if submissions.count < 2 {
                            return
                        }
                        
                        let first = submissions[0]
                        let second = submissions[1]
                        var storedTitle = ""
                        var storedLink = ""
                        
                        let g1 = first.title.capturedGroups(withRegex: "(\\d+(\\.\\d+)+)")
                        let g2 = second.title.capturedGroups(withRegex: "(\\d+(\\.\\d+)+)")
                        let lastUpdate = g1.isEmpty ? (g2.isEmpty ? "" : g2[0][0]) : g1[0][0]
                        
                        if first.stickied && first.title.contains(Bundle.main.releaseVersionNumber!) {
                            storedTitle = first.title
                            storedLink = first.permalink
                        } else if second.stickied && second.title.contains(Bundle.main.releaseVersionNumber!) {
                            storedTitle = second.title
                            storedLink = second.permalink
                        } else if Bundle.main.releaseVersionNumber!.contains(lastUpdate) || Bundle.main.releaseVersionNumber!.contains(lastUpdate) {
                            storedTitle = g1.isEmpty ? second.title : first.title
                            storedLink = g1.isEmpty ? second.permalink : first.permalink
                            
                            UserDefaults.standard.set(true, forKey: Bundle.main.releaseVersionNumber!)
                            UserDefaults.standard.synchronize()
                        }
                        
                        if !storedTitle.isEmpty && !storedLink.isEmpty {
                            DispatchQueue.main.async {
                                print("Showing")
                                SettingValues.showVersionDialog(storedTitle, storedLink, parentVC: self)
                            }
                        }
                    }
                })
            } catch {
            }
        }
    }
    
    func colorChanged(_ color: UIColor) {
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: MainViewController.current)
        inHeadView.backgroundColor = SettingValues.reduceColor ? ColorUtil.backgroundColor : color
        menuNav?.setColors(finalSubs[currentPage])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarView?.backgroundColor = .clear
        
        menuNav?.view.isHidden = true
    }
    
    func showSortMenu(_ sender: UIButton?) {
        getSubredditVC()?.showSortMenu(sender)
    }
    
    func showReadLater(_ sender: UIButton?) {
        VCPresenter.showVC(viewController: ReadLaterViewController(subreddit: currentTitle), popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
    }

    func showCurrentAccountMenu(_ sender: UIButton?) {
        let vc = CurrentAccountViewController()
        vc.delegate = self
        let navVC = UINavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .overCurrentContext
        navVC.modalTransitionStyle = .crossDissolve
        present(navVC, animated: true)
    }
    
    func getSubredditVC() -> SingleSubredditViewController? {
        if vCs.isEmpty {
            return nil
        }
        return (vCs[currentPage] as? SingleSubredditViewController)
    }
    
    var currentPage: Int {
        if let vc = viewControllers?[0] as? SingleSubredditViewController {
            return finalSubs.firstIndex(of: vc.sub) ?? 0
        } else {
            return 0
        }
    }
    
    func showDrawer(_ sender: AnyObject) {
        if menuNav == nil {
            makeMenuNav()
        }
        menuNav!.setColors(MainViewController.current)
        menuNav!.expand()
    }
    
    func shadowbox() {
        getSubredditVC()?.shadowboxMode()
    }
    
    func showMenu(_ sender: AnyObject) {
        getSubredditVC()?.showMore(sender, parentVC: self)
    }
    
    var selected = false
}

extension MainViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = vCs.index(of: viewController)
        if let vc = viewController as? SingleSubredditViewController {
            index = finalSubs.firstIndex(of: vc.sub)
        }
        guard let viewControllerIndex = index else {
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

extension MainViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let page = vCs.index(of: self.viewControllers!.first!)
        //        let page = tabBar.items.index(of: tabBar.selectedItem!)
        // TODO: Crashes here
        guard page != nil else {
            return
        }
        doCurrentPage(page!)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let pendingSub = (pendingViewControllers[0] as! SingleSubredditViewController).sub
        let prevSub = getSubredditVC()?.sub ?? ""
        color2 = ColorUtil.getColorForSub(sub: pendingSub, true)
        color1 = ColorUtil.getColorForSub(sub: prevSub, true)
    }
}

extension MainViewController: CurrentAccountViewControllerDelegate {
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestSettingsMenu: Void) {
        let settings = SettingsViewController()
        VCPresenter.showVC(viewController: settings, popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
    }

    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestAccountChangeToName accountName: String) {

        AccountController.switchAccount(name: accountName)
        if !UserDefaults.standard.bool(forKey: "done" + accountName) {
            do {
                try addAccount(token: OAuth2TokenRepository.token(of: accountName), register: false)
            } catch {
                addAccount(register: false)
            }
        } else {
            Subscriptions.sync(name: accountName, completion: { [weak self] in
                self?.hardReset()
            })
        }
    }

    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestGuestAccount: Void) {
        AccountController.switchAccount(name: "GUEST")
        Subscriptions.sync(name: "GUEST", completion: { [weak self] in
            self?.hardReset()
        })
    }

    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestLogOut: Void) {
        AccountController.delete(name: AccountController.currentName)
        AccountController.switchAccount(name: "GUEST")
        Subscriptions.sync(name: "GUEST", completion: { [weak self] in
            self?.hardReset()
        })
    }

    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestNewAccount: Void) {
        MainViewController.doAddAccount(register: false)
    }

}

class IndicatorTemplate: NSObject, MDCTabBarIndicatorTemplate {
    func indicatorAttributes(
        for context: MDCTabBarIndicatorContext
        ) -> MDCTabBarIndicatorAttributes {
        let bounds = context.bounds
        let attributes = MDCTabBarIndicatorAttributes()
        let underlineFrame = CGRect.init(x: bounds.minX,
                                         y: bounds.height - 7,
                                         width: bounds.width,
                                         height: 5)
        attributes.path = UIBezierPath.init(roundedRect: underlineFrame, byRoundingCorners: UIRectCorner.init(arrayLiteral: UIRectCorner.topLeft, UIRectCorner.topRight), cornerRadii: CGSize.init(width: 8, height: 8))
        return attributes
    }
}

extension MainViewController: MDCTabBarDelegate {
    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        selected = true
        let firstViewController = vCs[tabBar.items.index(of: item)!]
        
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: false,
                           completion: nil)
        
        self.doCurrentPage(tabBar.items.index(of: item)!)
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
