//
//  MainViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/25/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import BadgeSwift
import MaterialComponents.MaterialTabs
import RealmSwift
import reddift
import SDCAlertView
import StoreKit
import UIKit
import WatchConnectivity

class MainViewController: ColorMuxPagingViewController, UINavigationControllerDelegate, ReadLaterDelegate {

    override var prefersStatusBarHidden: Bool {
        return SettingValues.fullyHideNavbar
    }
    
    func didUpdate() {
        let count = ReadLater.readLaterIDs.count
        if count > 0 {
            let readLater = UIButton.init(type: .custom)
            readLater.setImage(UIImage(named: "bin")?.navIcon(), for: UIControl.State.normal)
            readLater.addTarget(self, action: #selector(self.showReadLater(_:)), for: UIControl.Event.touchUpInside)
            
            readLaterBadge?.removeFromSuperview()
            readLaterBadge = nil
            
            readLaterBadge = BadgeSwift()
            readLater.addSubview(readLaterBadge!)
            readLaterBadge!.centerXAnchor == readLater.centerXAnchor
            readLaterBadge!.centerYAnchor == readLater.centerYAnchor - 2
            
            readLaterBadge!.text = "\(count)"
            readLaterBadge!.insets = CGSize.zero
            readLaterBadge!.font = UIFont.boldSystemFont(ofSize: 10)
            readLaterBadge!.textColor = SettingValues.reduceColor ? ColorUtil.theme.navIconColor : UIColor.white
            readLaterBadge!.badgeColor = .clear
            readLaterBadge!.shadowOpacityBadge = 0
            readLater.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)

            readLaterB = UIBarButtonItem.init(customView: readLater)
            
            if SettingValues.subredditBar {
                navigationItem.leftBarButtonItem = accountB
                navigationItem.rightBarButtonItems = [sortB, readLaterB]
            } else {
                navigationItem.rightBarButtonItems = [sortB, readLaterB]
                doLeftItem()
            }
        } else {
            if SettingValues.subredditBar {
                navigationItem.leftBarButtonItems = [accountB]
                navigationItem.rightBarButtonItems = [sortB]
            } else {
                navigationItem.rightBarButtonItems = [sortB]
                doLeftItem()
            }
        }
    }
    
    var isReload = false
    var readLaterBadge: BadgeSwift?
    public static var current: String = ""
    public static var needsRestart = false
    public static var needsReTheme = false
    public var toolbar: UIView?
    var more = UIButton()
    var menu = UIButton()
    var readLaterB = UIBarButtonItem()
    var sortB = UIBarButtonItem().then {
        $0.accessibilityLabel = "Change Post Sorting Order"
    }
    var readLater = UIButton().then {
        $0.accessibilityLabel = "Open Read Later List"
    }
    var accountB = UIBarButtonItem()

    lazy var currentAccountTransitioningDelegate = CurrentAccountPresentationManager()
    
    override func viewWillAppear(_ animated: Bool) {
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
        } else if MainViewController.needsReTheme {
            doRetheme()
        }
        didUpdate()
    }
    
    func redoSubs() {
        menuNav?.subsSource.reload()
        setupTabBar(finalSubs)
    }
    
    func doRetheme() {
        (viewControllers?[0] as? SingleSubredditViewController)?.reTheme()
        tabBar.removeFromSuperview()
        if SettingValues.subredditBar {
            setupTabBar(finalSubs)
        }
        setupBaseBarColors()
        menuNav?.setColors("")
        toolbar?.backgroundColor = ColorUtil.theme.foregroundColor.add(overlay: ColorUtil.theme.isLight ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))
        self.doButtons()
        MainViewController.needsReTheme = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if let themeChanged = previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) {
                if themeChanged {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        self.viewWillAppearActions(override: true)
                    }
                }
            }
        }
    }

    public func viewWillAppearActions(override: Bool = false) {
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        self.splitViewController?.navigationController?.setNavigationBarHidden(true, animated: false)
        self.setNeedsStatusBarAppearanceUpdate()
        self.inHeadView.backgroundColor = SettingValues.fullyHideNavbar ? .clear : ColorUtil.getColorForSub(sub: self.currentTitle, true)
        
        let shouldBeNight = ColorUtil.shouldBeNight()
        if SubredditReorderViewController.changed || (shouldBeNight && ColorUtil.theme.title != SettingValues.nightTheme) || (!shouldBeNight && ColorUtil.theme.title != UserDefaults.standard.string(forKey: "theme") ?? "light") {
            var subChanged = false
            if finalSubs.count != Subscriptions.subreddits.count {
                subChanged = true
            } else {
                for i in 0 ..< Subscriptions.pinned.count {
                    if finalSubs[i] != Subscriptions.pinned[i] {
                        subChanged = true
                        break
                    }
                }
            }
            
            if ColorUtil.doInit() {
                SingleSubredditViewController.cellVersion += 1
                MainViewController.needsReTheme = true
                if override {
                    doRetheme()
                }
            }
            
            if subChanged || SubredditReorderViewController.changed {
                finalSubs = []
                finalSubs.append(contentsOf: Subscriptions.pinned)
                finalSubs.append(contentsOf: Subscriptions.subreddits.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending }).filter({ return !Subscriptions.pinned.contains($0) }))
                redoSubs()
            }
        }
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = false
        
        navigationController?.toolbar.barTintColor = ColorUtil.theme.backgroundColor
        
        self.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: getSubredditVC()?.sub ?? "", true)
        if menuNav?.tableView != nil {
            menuNav?.tableView.reloadData()
        }
        
        setNeedsStatusBarAppearanceUpdate()
    }

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
    
    //    override func preferredScreenEdgesDeferringSystemGestures() -> UIRectEdge {
    //        return .bottom
    //    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
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

    @objc func onAccountRefreshRequested(_ notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            self?.checkForMail()
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
            
            if !AccountController.isLoggedIn {
                return
            }
            
            let lastMail = UserDefaults.standard.integer(forKey: "mail")
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            
            do {
                try session?.getProfile({ (result) in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let profile):
                        AccountController.current = profile
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
                                "Count": unread,
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
        if !MainViewController.first {
            menuNav?.animateIn()
        }
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
            if self.finalSubs.contains(subreddit) {
                let index = self.finalSubs.firstIndex(of: subreddit)
                if index == nil {
                    return
                }

                let firstViewController = SingleSubredditViewController(subName: self.finalSubs[index!], parent: self)
                
                //Siri Shortcuts integration
                if #available(iOS 12.0, *) {
                    let activity = SingleSubredditViewController.openSubredditActivity(subreddit: self.finalSubs[index!])
                    firstViewController.userActivity = activity
                    activity.becomeCurrent()
                }
                
                if SettingValues.subredditBar && !SettingValues.reduceColor {
                    self.color1 = ColorUtil.baseColor
                    self.color2 = ColorUtil.getColorForSub(sub: (firstViewController ).sub)
                } else {
                    self.color1 = ColorUtil.theme.backgroundColor
                    self.color2 = ColorUtil.theme.backgroundColor
                }
                
                weak var weakPageVc = self
                self.setViewControllers([firstViewController],
                                        direction: index! > self.currentPage ? .forward : .reverse,
                                        animated: SettingValues.subredditBar ? true : false,
                                        completion: { (_) in
                                             guard let pageVc = weakPageVc else {
                                                 return
                                             }

                                             DispatchQueue.main.async {
                                                 pageVc.doCurrentPage(index!)
                                             }
                                         })
            } else {
               // TODO: - better sanitation
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
        let firstViewController = SingleSubredditViewController(subName: finalSubs[index], parent: self)
        
        weak var weakPageVc = self

        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: false,
                           completion: { (_) in
                                guard let pageVc = weakPageVc else {
                                    return
                                }

                                DispatchQueue.main.async {
                                    pageVc.doCurrentPage(index)
                                }
                            })
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
            alertController = UIAlertController(title: "Syncing subscriptions...\n\n\n", message: nil, preferredStyle: .alert)
            
            let spinnerIndicator = UIActivityIndicatorView(style: .whiteLarge)
            UserDefaults.standard.setValue(true, forKey: "done" + token.name)
            spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
            spinnerIndicator.color = ColorUtil.theme.fontColor
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
            self.menuNav?.removeFromParent()
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
            menuNav?.removeFromParent()
            menuNav = nil
        }
        menuNav = NavigationSidebarViewController(controller: self)

        toolbar = UITouchCapturingView()
        toolbar!.layer.cornerRadius = 15

        menuNav?.topView = toolbar
        menuNav?.view.addSubview(toolbar!)
        menuNav?.muxColor = ColorUtil.theme.foregroundColor.add(overlay: ColorUtil.theme.isLight ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))

        toolbar!.backgroundColor = ColorUtil.theme.foregroundColor.add(overlay: ColorUtil.theme.isLight ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))
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
        
        self.addChild(menuNav!)
        self.view.addSubview(menuNav!.view)
        menuNav!.didMove(toParent: self)
        
        // 3- Adjust bottomSheet frame and initial position.
        let height = view.frame.height
        let width = view.frame.width
        var nextOffset = CGFloat(0)
        if self.splitViewController != nil && UIDevice.current.orientation == .portrait {
            nextOffset = 64
        }
        
        menuNav!.view.frame = CGRect(x: 0, y: self.view.frame.maxY - CGFloat(menuNav!.bottomOffset) - nextOffset, width: width, height: min(height - menuNav!.minTopOffset, height * 0.9))
    }
    
    @objc func restartVC() {
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
        
        if self.subs != nil {
            self.subs!.removeFromSuperview()
            self.subs = nil
        }
        
        CachedTitle.titles.removeAll()
        view.backgroundColor = ColorUtil.theme.backgroundColor
        splitViewController?.view.backgroundColor = ColorUtil.theme.foregroundColor
        SubredditReorderViewController.changed = false
        
        finalSubs = []
        LinkCellView.cachedInternet = nil
        
        finalSubs.append(contentsOf: Subscriptions.pinned)
        finalSubs.append(contentsOf: Subscriptions.subreddits.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending }).filter({ return !Subscriptions.pinned.contains($0) }))

        MainViewController.isOffline = false
        var subs = [UIMutableApplicationShortcutItem]()
        for subname in finalSubs {
            if subs.count < 2 && !subname.contains("/") {
                subs.append(UIMutableApplicationShortcutItem.init(type: "me.ccrama.redditslide.subreddit", localizedTitle: subname, localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(templateImageName: "subs"), userInfo: [ "sub": "\(subname)" as NSSecureCoding ]))
            }
        }
        
        subs.append(UIMutableApplicationShortcutItem.init(type: "me.ccrama.redditslide.subreddit", localizedTitle: "Open link", localizedSubtitle: "Open current clipboard url", icon: UIApplicationShortcutIcon.init(templateImageName: "nav"), userInfo: [ "clipboard": "true" as NSSecureCoding ]))
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
        
        let firstViewController = SingleSubredditViewController(subName: finalSubs[newIndex], parent: self)
        
        weak var weakPageVc = self
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: true,
                           completion: { (_) in
                                guard let pageVc = weakPageVc else {
                                    return
                                }

                                DispatchQueue.main.async {
                                    pageVc.doCurrentPage(newIndex)
                                }
                            })
        
        self.makeMenuNav()
        
        doButtons()
        
        tabBar.removeFromSuperview()
        self.navigationItem.leftBarButtonItems = []
        self.navigationItem.rightBarButtonItems = []
        self.delegate = self
        if SettingValues.subredditBar {
            setupTabBar(finalSubs)
            self.dataSource = self
        } else {
            self.navigationItem.titleView = nil
            self.dataSource = nil
        }
    }
    
    var tabBar = MDCTabBar()
    var subs: UIView?
    
    func setupTabBar(_ subs: [String]) {
        if !SettingValues.subredditBar {
            return
        }
        tabBar.removeFromSuperview()
        tabBar = MDCTabBar.init(frame: CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 48))
        tabBar.itemAppearance = .titles
        
        tabBar.selectedItemTintColor = SettingValues.reduceColor ? ColorUtil.theme.fontColor : UIColor.white
        tabBar.unselectedItemTintColor = SettingValues.reduceColor ? ColorUtil.theme.fontColor.withAlphaComponent(0.45) : UIColor.white.withAlphaComponent(0.45)
        
        tabBar.selectedItemTitleFont = UIFont.boldSystemFont(ofSize: 14)
        tabBar.unselectedItemTitleFont = UIFont.boldSystemFont(ofSize: 14)
        
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
        
        menuNav?.view.frame.size.width = splitViewController == nil ? view.frame.width : splitViewController!.primaryColumnWidth
    }
    
    func doLeftItem() {
        let label = UILabel()
        label.text = "   \(SettingValues.reduceColor ? "    " : "")\(SettingValues.subredditBar ? "" : self.currentTitle)"
        label.textColor = SettingValues.reduceColor ? ColorUtil.theme.fontColor : .white
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
            self.navigationItem.leftBarButtonItems = SettingValues.subredditBar ? [leftItem] : [accountB, leftItem]
        }
    }
    
    func doCurrentPage(_ page: Int) {
        guard page < finalSubs.count else { return }
        let vc = self.viewControllers![0] as! SingleSubredditViewController
        MainViewController.current = vc.sub
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: "Viewing \(vc.sub)")
        self.menuNav?.setSubreddit(subreddit: MainViewController.current)
        self.currentTitle = MainViewController.current
        menuNav!.setColors(MainViewController.current)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: vc.sub, true)
        self.inHeadView.backgroundColor = SettingValues.fullyHideNavbar ? .clear : ColorUtil.getColorForSub(sub: vc.sub, true)
        
        if !(vc).loaded || !SettingValues.subredditBar {
            if vc.loaded {
                vc.indicator?.isHidden = false
                vc.indicator?.startAnimating()
                vc.loadBubbles()
                vc.refresh(false)
            } else {
                vc.loadBubbles()
                (vc).load(reset: true)
            }
        }
        
        doLeftItem()
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        // Clear the menuNav's searchBar to refresh the menuNav
        self.menuNav?.searchBar.text = nil
        self.menuNav?.searchBar.endEditing(true)
        
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: vc.sub)
        if !selected {
            let page = finalSubs.firstIndex(of: (self.viewControllers!.first as! SingleSubredditViewController).sub)
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
            if UIDevice.current.userInterfaceIdiom == .pad && UIApplication.shared.applicationState == .active {
                self.menuNav?.didSlideOver()
            }
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed)),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(spacePressed)),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(spacePressedUp)),
            UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(search), discoverabilityTitle: "Search"),
            UIKeyCommand(input: "h", modifierFlags: .command, action: #selector(hideReadPosts), discoverabilityTitle: "Hide read posts"),
            UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(refresh), discoverabilityTitle: "Reload"),
        ]
    }
    
    @objc func spacePressed() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            if let vc = self.getSubredditVC() {
                vc.tableView.contentOffset.y = min(vc.tableView.contentOffset.y + 350, vc.tableView.contentSize.height - vc.tableView.frame.size.height)
            }
        }, completion: nil)
    }

    @objc func spacePressedUp() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            if let vc = self.getSubredditVC() {
                vc.tableView.contentOffset.y = max(vc.tableView.contentOffset.y - 350, -64)
            }
        }, completion: nil)
    }

    @objc func search() {
        if let vc = self.getSubredditVC() {
            vc.search()
        }
    }

    @objc func hideReadPosts() {
        if let vc = self.getSubredditVC() {
            vc.hideReadPosts()
        }
    }

    @objc func refresh() {
        if let vc = self.getSubredditVC() {
            vc.refresh()
        }
    }

    var inHeadView = UIView()
    
    @objc public func onAccountChangedNotificationPosted() {
        DispatchQueue.main.async { [weak self] in
            self?.doProfileIcon()
        }
    }

    override func viewDidLoad() {
        self.navToMux = self.navigationController!.navigationBar
        self.color1 = ColorUtil.theme.backgroundColor
        self.color2 = ColorUtil.theme.backgroundColor
        
        self.splitViewController?.preferredDisplayMode = UISplitViewController.DisplayMode.allVisible
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
        inHeadView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: max(self.view.frame.size.width, self.view.frame.size.height), height: (UIApplication.shared.statusBarUIView?.frame.size.height ?? 20)))
        self.inHeadView.backgroundColor = SettingValues.fullyHideNavbar ? .clear : ColorUtil.getColorForSub(sub: self.currentTitle, true)
        
        if SettingValues.subredditBar {
            self.view.addSubview(inHeadView)
        }
        
        checkForUpdate()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        let today = formatter.string(from: Date())
        
        if SettingValues.autoCache {
            if UserDefaults.standard.string(forKey: "DAY_LAUNCH") != today {
                _ = AutoCache.init(baseController: self, subs: Subscriptions.offline)
                UserDefaults.standard.setValue(today, forKey: "DAY_LAUNCH")
            }
        }
        requestReviewIfAppropriate()
        
        //        drawerButton = UIImageView.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        //        drawerButton.backgroundColor = ColorUtil.theme.foregroundColor
        //        drawerButton.clipsToBounds = true
        //        drawerButton.contentMode = .center
        //        drawerButton.layer.cornerRadius = 20
        //        drawerButton.image = UIImage(named: "menu")?.getCopy(withSize: CGSize.square(size: 25), withColor: ColorUtil.theme.fontColor)
        //        self.view.addSubview(drawerButton)
        //        drawerButton.translatesAutoresizingMaskIntoConstraints = false
        //        drawerButton.addTapGestureRecognizer {
        //            self.showDrawer(self.drawerButton)
        //        }
        
        toolbar?.addTapGestureRecognizer(action: {
            self.showDrawer(self.drawerButton)
        })

        NotificationCenter.default.addObserver(self, selector: #selector(onAccountRefreshRequested), name: .accountRefreshRequested, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotificationPosted), name: .onAccountChangedToGuest, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotificationPosted), name: .onAccountChanged, object: nil)

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(showDrawer(_:)))
        swipe.direction = .up
        
        //        drawerButton.addGestureRecognizer(swipe)
        //        drawerButton.isHidden = true
        //
        //        drawerButton.bottomAnchor == self.view.safeBottomAnchor - 8
        //        drawerButton.leadingAnchor == self.view.safeLeadingAnchor + 8
        //        drawerButton.heightAnchor == 40
        //        drawerButton.widthAnchor == 40
        
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .right
        for view in view.subviews {
            for rec in view.gestureRecognizers ?? [] {
                rec.require(toFail: edgePan)
            }
        }
        for rec in self.view.gestureRecognizers ?? [] {
            rec.require(toFail: edgePan)
        }

        self.view.addGestureRecognizer(edgePan)
    }
    
    @objc func screenEdgeSwiped() {
        switch SettingValues.sideGesture {
        case .SUBS:
            menuNav?.expand()
        case .INBOX:
            self.showCurrentAccountMenu(nil)
        case .POST:
            if let vc = self.viewControllers?[0] as? SingleSubredditViewController {
                vc.newPost(self)
            }
        case .SIDEBAR:
            if let vc = self.viewControllers?[0] as? SingleSubredditViewController {
                vc.doDisplaySidebar()
            }
        case .NONE:
            return
        }
    }
    
    public static var isOffline = false
    var menuB = UIBarButtonItem()
    var drawerButton = UIImageView()
    
    func doProfileIcon() {
        let account = ExpandedHitButton(type: .custom)
        let accountImage = UIImage(sfString: SFSymbol.personCropCircle, overrideString: "profile")?.navIcon()
        if let image = AccountController.current?.image, let imageUrl = URL(string: image) {
            account.sd_setImage(with: imageUrl, for: UIControl.State.normal, placeholderImage: accountImage, options: [.allowInvalidSSLCertificates], context: nil)
        } else {
            account.setImage(accountImage, for: UIControl.State.normal)
        }
        account.layer.cornerRadius = 5
        account.clipsToBounds = true
        account.contentMode = .scaleAspectFill
        account.addTarget(self, action: #selector(self.showCurrentAccountMenu(_:)), for: UIControl.Event.touchUpInside)
        account.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        account.sizeAnchors == CGSize.square(size: 30)
        accountB = UIBarButtonItem(customView: account)
        accountB.accessibilityIdentifier = "Account button"
        accountB.accessibilityLabel = "Account"
        accountB.accessibilityHint = "Open account page"
        if #available(iOS 13, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            self.accountB.customView?.addInteraction(interaction)
        }
        didUpdate()
    }
    
    func doButtons() {
        if menu.superview != nil && !MainViewController.needsReTheme {
            return
        }
        let sort = ExpandedHitButton(type: .custom)
        sort.setImage(UIImage(sfString: SFSymbol.arrowUpArrowDownCircle, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControl.Event.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        sortB = UIBarButtonItem.init(customView: sort)

        let account = ExpandedHitButton(type: .custom)
        let accountImage = UIImage(sfString: SFSymbol.personCropCircle, overrideString: "profile")?.navIcon()
        if let image = AccountController.current?.image, let imageUrl = URL(string: image) {
            print("Loading \(image)")
            account.sd_setImage(with: imageUrl, for: UIControl.State.normal, placeholderImage: accountImage, options: [.allowInvalidSSLCertificates], context: nil)
        } else {
            account.setImage(accountImage, for: UIControl.State.normal)
        }
        account.layer.cornerRadius = 5
        account.clipsToBounds = true
        account.contentMode = .scaleAspectFill
        account.addTarget(self, action: #selector(self.showCurrentAccountMenu(_:)), for: UIControl.Event.touchUpInside)
        account.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        account.sizeAnchors == CGSize.square(size: 30)
        accountB = UIBarButtonItem(customView: account)
        accountB.accessibilityIdentifier = "Account button"
        accountB.accessibilityLabel = "Account"
        accountB.accessibilityHint = "Open account page"
        if #available(iOS 13, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            self.accountB.customView?.addInteraction(interaction)
        }

        let settings = ExpandedHitButton(type: .custom)
        settings.setImage(UIImage.init(sfString: SFSymbol.magnifyingglass, overrideString: "search")?.toolbarIcon(), for: UIControl.State.normal)
       // TODO: - this settings.addTarget(self, action: #selector(self.showDrawer(_:)), for: UIControlEvents.touchUpInside)
        settings.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let settingsB = UIBarButtonItem.init(customView: settings)
        
        let offline = ExpandedHitButton(type: .custom)
        offline.setImage(UIImage(sfString: SFSymbol.wifiSlash, overrideString: "offline")?.toolbarIcon(), for: UIControl.State.normal)
        offline.addTarget(self, action: #selector(self.restartVC), for: UIControl.Event.touchUpInside)
        offline.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let offlineB = UIBarButtonItem.init(customView: offline)
        
        let flexButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        for view in toolbar?.subviews ?? [UIView]() {
            view.removeFromSuperview()
        }
        if !MainViewController.isOffline {
            more = UIButton(type: .custom).then {
                $0.setImage(UIImage.init(sfString: SFSymbol.ellipsis, overrideString: "moreh")?.toolbarIcon(), for: UIControl.State.normal)
                $0.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControl.Event.touchUpInside)

                $0.accessibilityIdentifier = "Subreddit options button"
                $0.accessibilityLabel = "Options"
                $0.accessibilityHint = "Open subreddit options menu"
            }
            toolbar?.insertSubview(more, at: 0)
            more.sizeAnchors == .square(size: 56)
            
            menu = UIButton(type: .custom).then {
                $0.setImage(UIImage.init(sfString: SFSymbol.magnifyingglass, overrideString: "search")?.toolbarIcon(), for: UIControl.State.normal)
                $0.addTarget(self, action: #selector(self.showDrawer(_:)), for: UIControl.Event.touchUpInside)
                $0.accessibilityIdentifier = "Nav drawer button"
                $0.accessibilityLabel = "Navigate"
                $0.accessibilityHint = "Open navigation drawer"
            }
            toolbar?.insertSubview(menu, at: 0)
            menu.sizeAnchors == .square(size: 56)

            if let tool = toolbar {
                menu.leftAnchor == tool.leftAnchor
                menu.topAnchor == tool.topAnchor
                more.rightAnchor == tool.rightAnchor
                more.topAnchor == tool.topAnchor
            }
            
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
                        
                        let submissions = listing.children.compactMap({ $0 as? Link })
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
                                SettingValues.showVersionDialog(storedTitle, submissions[0], parentVC: self)
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
        inHeadView.backgroundColor = SettingValues.reduceColor ? ColorUtil.theme.backgroundColor : color
        if SettingValues.fullyHideNavbar {
            inHeadView.backgroundColor = .clear
        }
        menuNav?.setColors(finalSubs[currentPage])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarUIView?.backgroundColor = .clear
        
        menuNav?.view.isHidden = true
    }
    
    @objc func showSortMenu(_ sender: UIButton?) {
        getSubredditVC()?.showSortMenu(sender)
    }
    
    @objc func showReadLater(_ sender: UIButton?) {
        VCPresenter.showVC(viewController: ReadLaterViewController(subreddit: currentTitle), popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
    }

    @objc func showCurrentAccountMenu(_ sender: UIButton?) {
        let vc = CurrentAccountViewController()
        vc.delegate = self
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = currentAccountTransitioningDelegate
        present(vc, animated: true)
    }
    
    func getSubredditVC() -> SingleSubredditViewController? {
        return viewControllers?.count ?? 0 == 0 ? nil : viewControllers?[0] as? SingleSubredditViewController
    }
    
    var currentPage: Int {
        if let vc = viewControllers?[0] as? SingleSubredditViewController {
            return finalSubs.firstIndex(of: vc.sub) ?? 0
        } else {
            return 0
        }
    }
    
    @objc func showDrawer(_ sender: AnyObject) {
        if menuNav == nil {
            makeMenuNav()
        }
        menuNav!.setColors(MainViewController.current)
        menuNav!.expand()
    }
    
    func shadowbox() {
        getSubredditVC()?.shadowboxMode()
    }
    
    @objc func showMenu(_ sender: AnyObject) {
        getSubredditVC()?.showMore(sender, parentVC: self)
    }
    
    var selected = false
}

extension MainViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = finalSubs.firstIndex(of: (viewController as! SingleSubredditViewController).sub)
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
        
        guard finalSubs.count > previousIndex else {
            return nil
        }
        
        return SingleSubredditViewController(subName: finalSubs[previousIndex], parent: self)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = finalSubs.firstIndex(of: (viewController as! SingleSubredditViewController).sub) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = finalSubs.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        
        return SingleSubredditViewController(subName: finalSubs[nextIndex], parent: self)
    }
    
}

extension MainViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let page = finalSubs.firstIndex(of: (self.viewControllers!.first as! SingleSubredditViewController).sub)
        //        let page = tabBar.items.index(of: tabBar.selectedItem!)
        // TODO: - Crashes here
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
    
    func currentAccountViewController(_ controller: CurrentAccountViewController, goToMultireddit multireddit: String) {
        finalSubs = []
        finalSubs.append(contentsOf: Subscriptions.pinned)
        finalSubs.append(contentsOf: Subscriptions.subreddits.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending }).filter({ return !Subscriptions.pinned.contains($0) }))
        redoSubs()
        goToSubreddit(subreddit: multireddit)
    }
    
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestCacheNow: Void) {
        if Subscriptions.offline.isEmpty {
            let alert = AlertController.init(title: "Caption", message: "", preferredStyle: .alert)
            
            alert.setupTheme()
            alert.attributedTitle = NSAttributedString(string: "You have no subs set to Auto Cache", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
            
            alert.attributedMessage = TextDisplayStackView.createAttributedChunk(baseHTML: "You can set this up in Settings > Offline Caching", fontSize: 14, submission: false, accentColor: ColorUtil.baseAccent, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
            
            alert.addCloseButton()
            alert.addBlurView()
            present(alert, animated: true, completion: nil)
        } else {
            _ = AutoCache.init(baseController: self, subs: Subscriptions.offline)
        }
    }
    
    func currentAccountViewController(_ controller: CurrentAccountViewController, didRequestHistory: Void) {
        VCPresenter.showVC(viewController: HistoryViewController(), popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
    }

    func currentAccountViewController(_ controller: CurrentAccountViewController?, didRequestAccountChangeToName accountName: String) {

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
        let name: String
        if AccountController.current != nil {
            name = AccountController.current!.name
        } else {
            name = AccountController.currentName
        }
        AccountController.delete(name: name)
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
                                         y: bounds.height - (UIDevice.current.userInterfaceIdiom == .pad ? 9 : 7),
                                         width: bounds.width,
                                         height: UIDevice.current.userInterfaceIdiom == .pad ? 4 : 5)
        attributes.path = UIBezierPath.init(roundedRect: underlineFrame, byRoundingCorners: UIDevice.current.userInterfaceIdiom == .pad ? UIRectCorner.init(arrayLiteral: UIRectCorner.topLeft, UIRectCorner.topRight, UIRectCorner.bottomLeft, UIRectCorner.bottomRight) : UIRectCorner.init(arrayLiteral: UIRectCorner.topLeft, UIRectCorner.topRight), cornerRadii: UIDevice.current.userInterfaceIdiom == .pad ? CGSize.init(width: 2, height: 2) : CGSize.init(width: 8, height: 8))
        return attributes
    }
}

extension MainViewController: MDCTabBarDelegate {
    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        selected = true
        let firstViewController = SingleSubredditViewController(subName: finalSubs[tabBar.items.firstIndex(of: item)!], parent: self)

        weak var weakPageVc = self
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: false,
                           completion: { (_) in
                                guard let pageVc = weakPageVc else {
                                    return
                                }

                                DispatchQueue.main.async {
                                    pageVc.doCurrentPage(tabBar.items.firstIndex(of: item)!)
                                }
                            })

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

class ExpandedHitButton: UIButton {
    override func point( inside point: CGPoint, with event: UIEvent? ) -> Bool {
        let relativeFrame = self.bounds
        let hitTestEdgeInsets = UIEdgeInsets( top: -44, left: -44, bottom: -44, right: -44 )
        let hitFrame = relativeFrame.inset(by: hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
}

@available(iOS 13.0, *)
extension MainViewController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in

            return self.makeContextMenu()
        })

    }
    func makeContextMenu() -> UIMenu {

        // Create a UIAction for sharing
        var buttons = [UIAction]()
        for accountName in AccountController.names.unique().sorted() {
            if accountName == AccountController.currentName {
                buttons.append(UIAction(title: accountName, image: UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon(), handler: { (_) in
                }))
            } else {
                buttons.append(UIAction(title: accountName, image: nil, handler: { (_) in
                    self.currentAccountViewController(nil, didRequestAccountChangeToName: accountName)
                }))
            }
        }

        // Create and return a UIMenu with the share action
        return UIMenu(title: "Switch Accounts", children: buttons)
    }

}
