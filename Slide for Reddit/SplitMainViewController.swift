//
//  SplitMainViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/19/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
//

import Alamofire
import Anchorage
import AudioToolbox
import BadgeSwift
import SDWebImage
import SwiftyJSON
import MaterialComponents.MaterialTabs
import RealmSwift
import reddift
import SDCAlertView
import StoreKit
import UIKit
import WatchConnectivity
import WidgetKit

class SplitMainViewController: MainViewController {
    
    /*
    Corresponds to USR_DOMAIN in info.plist, which derives its value
    from USR_DOMAIN in the pbxproj build settings. Default is `ccrama.me`.
    */
    func USR_DOMAIN() -> String {
       return Bundle.main.object(forInfoDictionaryKey: "USR_DOMAIN") as! String
    }

    static var isFirst = true

    override func handleToolbars() {
    }
    
    override func redoSubs() {
        setupTabBar(finalSubs)
    }
    
    @objc override func showDrawer(_ sender: AnyObject) {
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarUIView?.backgroundColor = .clear
    }

    override func colorChanged(_ color: UIColor) {
        tabBar?.tintColor = ColorUtil.accentColorForSub(sub: MainViewController.current)
        inHeadView.backgroundColor = SettingValues.reduceColor ? ColorUtil.theme.foregroundColor : color
        if SettingValues.fullyHideNavbar {
            inHeadView.backgroundColor = .clear
        }
    }
    override func doProfileIcon() {
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
        account.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        account.addTarget(self, action: #selector(self.openDrawer(_:)), for: .touchUpInside)
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
    
    override func doButtons() {
        if menu.superview != nil && !MainViewController.needsReTheme {
            return
        }
        
        splitViewController?.navigationItem.hidesBackButton = true
        if #available(iOS 14.0, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                splitViewController?.showsSecondaryOnlyButton = false
                splitViewController?.navigationItem.hidesBackButton = true
                splitViewController?.navigationItem.backBarButtonItem = UIBarButtonItem()
            }
        }
        navigationController?.navigationItem.hidesBackButton = true
        
        sortButton = ExpandedHitButton(type: .custom)
        sortButton.setImage(UIImage(sfString: SFSymbol.arrowUpArrowDownCircle, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        sortButton.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControl.Event.touchUpInside)
        sortButton.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        
        if viewControllers != nil && viewControllers!.count > 0 {
            if let currentVC = viewControllers?[0] as? SingleSubredditViewController {
                currentVC.doSortImage(sortButton)
            }
        }
        sortB = UIBarButtonItem.init(customView: sortButton)

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
        account.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        account.sizeAnchors == CGSize.square(size: 30)
        account.addTarget(self, action: #selector(self.openDrawer(_:)), for: .touchUpInside)
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
        
        self.parent?.navigationController?.navigationBar.shadowImage = UIImage()
        self.parent?.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        for view in toolbar?.subviews ?? [UIView]() {
            view.removeFromSuperview()
        }
        if MainViewController.isOffline {
            toolbarItems = [settingsB, accountB, flexButton, offlineB]
        }
        didUpdate()
    }
    
    @objc func openDrawer(_ sender: AnyObject) {
        if self.navigationController?.viewControllers[0] is NavigationHomeViewController {
            self.navigationController?.popViewController(animated: true)
        } else if #available(iOS 14, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                self.splitViewController?.show(UISplitViewController.Column.primary)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.splitViewController?.preferredDisplayMode = .primaryOverlay
            }
        }
    }

    override func viewDidLoad() {
        SplitMainViewController.isFirst = true
        
        self.navToMux = self.navigationController?.navigationBar
        self.color1 = ColorUtil.theme.foregroundColor
        self.color2 = ColorUtil.theme.foregroundColor
        
        self.restartVC()
        self.navigationController?.modalPresentationStyle = .currentContext

        doButtons()
        
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        inHeadView.removeFromSuperview()
        inHeadView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: max(self.view.frame.size.width, self.view.frame.size.height), height: (UIApplication.shared.statusBarUIView?.frame.size.height ?? 20)))
        self.inHeadView.backgroundColor = SettingValues.fullyHideNavbar ? .clear : ColorUtil.getColorForSub(sub: self.currentTitle, true)
        
        if SettingValues.subredditBar {
            self.view.addSubview(inHeadView)
        }
        
        self.parent?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        for view in view.subviews {
            if view is UIScrollView {
                let scrollView = view as! UIScrollView
                scrollView.delegate = self
                
                if SettingValues.submissionGestureMode != .FULL {
                    scrollView.panGestureRecognizer.minimumNumberOfTouches = 1
                } else {
                    scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
                }
                
                if let pop = self.parent?.navigationController?.interactivePopGestureRecognizer {
                    scrollView.panGestureRecognizer.require(toFail: pop)
                }
            }
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountRefreshRequested), name: .accountRefreshRequested, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotificationPosted), name: .onAccountChangedToGuest, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotificationPosted), name: .onAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onThemeChanged), name: .onThemeChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(doReAppear), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
        
    @objc func onThemeChanged() {
        SingleSubredditViewController.cellVersion += 1
        MainViewController.needsReTheme = true
        navigationController?.toolbar.barTintColor = ColorUtil.theme.backgroundColor
        navigationController?.toolbar.tintColor = ColorUtil.theme.fontColor
        self.parent?.navigationController?.toolbar.barTintColor = ColorUtil.theme.foregroundColor
        self.parent?.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: getSubredditVC()?.sub ?? "", true)
        doRetheme()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        drawerButton.frame = CGRect(x: 8, y: size.height - 48, width: 40, height: 40)
        inHeadView.removeFromSuperview()
        
        doButtons()
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.getSubredditVC()?.showUI(false)
        }
    }

    override func doCurrentPage(_ page: Int) {
        guard page < finalSubs.count else { return }
        currentIndex = page

        let vc = self.viewControllers![0] as! SingleSubredditViewController
        if currentIndex == 0 && SettingValues.subredditBar && SettingValues.submissionGestureMode != .FULL {
            vc.setupSwipeGesture()
        } else if UIDevice.current.userInterfaceIdiom == .pad && !SettingValues.subredditBar && SettingValues.submissionGestureMode != .FULL {
            vc.setupSwipeGesture()
        }
        MainViewController.current = vc.sub
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: "Viewing \(vc.sub)")
        self.currentTitle = MainViewController.current
        self.parent?.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: vc.sub, true)
        self.inHeadView.backgroundColor = SettingValues.fullyHideNavbar ? .clear : ColorUtil.getColorForSub(sub: vc.sub, true)
        
        if !(vc).dataSource.loaded || !SettingValues.subredditBar {
            if vc.dataSource.loaded {
                vc.indicator?.isHidden = false
                vc.indicator?.startAnimating()
                vc.loadBubbles()
                vc.refresh(false)
            } else {
                vc.loadBubbles()
                DispatchQueue.main.async {
                    vc.dataSource.getData(reload: true)
                }
            }
        }
        
        UIView.animate(withDuration: 0.4, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            self.doToolbarOffset()
        }, completion: { [weak self] (_)in
            self?.dontMatch = false
        })

        doLeftItem()
        self.parent?.navigationController?.navigationBar.shadowImage = UIImage()
        self.parent?.navigationController?.navigationBar.layoutIfNeeded()
        
        tabBar?.tintColor = ColorUtil.accentColorForSub(sub: vc.sub)
    }

    override func doRetheme() {
        for controller in viewControllers ?? [] {
            if let sub = controller as? SingleSubredditViewController {
                sub.reTheme()
            }
        }
        tabBar?.removeFromSuperview()
        if SettingValues.subredditBar {
            setupTabBar(finalSubs)
        }
        setupBaseBarColors()
        toolbar?.backgroundColor = ColorUtil.theme.foregroundColor.add(overlay: ColorUtil.theme.isLight ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))
        self.doButtons()
        MainViewController.needsReTheme = false
    }
    
    var isReappear = false
    override func viewWillAppearActions(override: Bool = false) {
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        //self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.setNeedsStatusBarAppearanceUpdate()
        self.inHeadView.backgroundColor = SettingValues.fullyHideNavbar ? .clear : ColorUtil.getColorForSub(sub: self.currentTitle, true)
        
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
                    
        if subChanged || SubredditReorderViewController.changed {
            finalSubs = []
            finalSubs.append(contentsOf: Subscriptions.pinned)
            finalSubs.append(contentsOf: Subscriptions.subreddits.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending }).filter({ return !Subscriptions.pinned.contains($0) }))
            redoSubs()
        }
    
        self.parent?.navigationController?.navigationBar.shadowImage = UIImage()
        self.parent?.navigationController?.navigationBar.isTranslucent = false
        self.parent?.navigationController?.toolbar.barTintColor = ColorUtil.theme.foregroundColor
        self.parent?.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: getSubredditVC()?.sub ?? "", true)
        
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewWillAppearActions()
        self.handleToolbars()
        
        ReadLater.delegate = self
        if Reachability().connectionStatus().description == ReachabilityStatus.Offline.description {
            MainViewController.isOffline = true
            let offlineVC = OfflineOverviewViewController(subs: finalSubs)
            VCPresenter.showVC(viewController: offlineVC, popupIfPossible: false, parentNavigationController: nil, parentViewController: self)
        }
        
        if MainViewController.needsRestart {
            MainViewController.needsRestart = false
            tabBar?.removeFromSuperview()
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

    override func hardReset(soft: Bool = false) {
        if soft && false { //in case we need to not destroy the stack, disable for now
        } else {
            if #available(iOS 14, *) {
                (UIApplication.shared.delegate as! AppDelegate).resetStackNew()
            } else {
                (UIApplication.shared.delegate as! AppDelegate).resetStack()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AccountController.isLoggedIn && !MainViewController.first {
            checkForMail()
        }
        doReAppear()
    }
    
    @objc func doReAppear() {
        if !isReappear {
            isReappear = true
        } else {
            self.doToolbarOffset()
        }
    }

    override func addAccount(register: Bool) {
        doLogin(token: nil, register: register)
    }
    
    override func doAddAccount(register: Bool) {
        guard UIApplication.shared.keyWindow != nil else {
            fatalError("Window must exist when resetting the stack!")
        }

        let main: MainViewController!
        if #available(iOS 14, *) {
            main = (UIApplication.shared.delegate as! AppDelegate).resetStackNew()
        } else {
            main = (UIApplication.shared.delegate as! AppDelegate).resetStack()
        }
        (UIApplication.shared.delegate as! AppDelegate).login = main
        AccountController.addAccount(context: main, register: register)
    }

    override func addAccount(token: OAuth2Token, register: Bool) {
        doLogin(token: token, register: register)
    }
    
    override func goToSubreddit(subreddit: String, override: Bool = false) {
        if finalSubs.firstIndex(of: subreddit) == currentIndex {
            (self.viewControllers?[0] as? SingleSubredditViewController)?.refresh()
            return
        }
        //Temporary fix for 13
        UIView.animate(withDuration: 0.3, animations: {
            if SettingValues.appMode == .MULTI_COLUMN {
                self.splitViewController?.preferredDisplayMode = .primaryHidden
            }
        }, completion: nil)
        
        if self.finalSubs.contains(subreddit) && !override {
            let index = self.finalSubs.firstIndex(of: subreddit)
            if index == nil {
                VCPresenter.openRedditLink("/r/" + subreddit.replacingOccurrences(of: " ", with: ""), self.navigationController, self)
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
                self.color1 = ColorUtil.theme.foregroundColor
                self.color2 = ColorUtil.theme.foregroundColor
            }
            
            DispatchQueue.main.async {
                self.doCurrentPage(index!)
            }
            self.dontMatch = true

            self.setViewControllers([firstViewController],
                                    direction: index! > self.currentPage ? .forward : .reverse,
                                    animated: false,
                                    completion: { (_) in
                                     })
        } else {
            VCPresenter.openRedditLink("/r/" + subreddit.replacingOccurrences(of: " ", with: ""), self.navigationController, self)
        }
    }
    
    override func goToUser(profile: String) {
        VCPresenter.openRedditLink("/u/" + profile.replacingOccurrences(of: " ", with: ""), self.navigationController, self)
    }

    override func makeMenuNav() {
    }
    
    @objc override func restartVC() {
        let saved = getSubredditVC()
        let savedPage = saved?.sub ?? ""
        
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
        finalSubs.append(contentsOf: Subscriptions.subreddits.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending }).filter({ return !Subscriptions.pinned.containsIgnoringCase($0) }))

        MainViewController.isOffline = false
        var subs = [UIMutableApplicationShortcutItem]()
        for subname in finalSubs {
            if subs.count < 2 && !subname.contains("/") {
                subs.append(UIMutableApplicationShortcutItem.init(type: "me.ccrama.redditslide.subreddit", localizedTitle: subname, localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(templateImageName: "subs"), userInfo: [ "sub": "\(subname)" as NSSecureCoding ]))
            }
        }
        let faveSubs = Array(finalSubs[0..<4])
        let suite = UserDefaults(suiteName: "group.\(USR_DOMAIN()).redditslide.prefs")
        suite?.setValue(faveSubs, forKey: "favorites")
        suite?.synchronize()

        DispatchQueue.global().async {
            for raw in self.finalSubs {
                let item = raw.lowercased()
                if item.contains("m/") {
                    let image = SubredditCellView.defaultIconMulti
                    let data = image?.withPadding(10)?.withBackground(color: ColorUtil.baseColor).pngData() ?? Data()
                    suite?.setValue(data, forKey: "raw" + item)
                } else if item == "all" {
                    let image = SubredditCellView.allIcon
                    let data = image?.withPadding(10)?.withBackground(color: GMColor.blue500Color()).pngData() ?? Data()
                    suite?.setValue(data, forKey: "raw" + item)
                } else if item == "frontpage" {
                    let image = SubredditCellView.frontpageIcon
                    let data = image?.withPadding(10)?.withBackground(color: GMColor.green500Color()).pngData() ?? Data()
                    suite?.setValue(data, forKey: "raw" + item)
                } else if item == "popular" {
                    let image = SubredditCellView.popularIcon
                    let data = image?.withPadding(10)?.withBackground(color: GMColor.purple500Color()).pngData() ?? Data()
                    suite?.setValue(data, forKey: "raw" + item)
                } else if let icon = Subscriptions.icon(for: item) {
                    suite?.setValue(icon.unescapeHTML, forKey: item)
                }
            }
            
            let image = SubredditCellView.defaultIcon
            let data = image?.withPadding(10)?.withBackground(color: ColorUtil.baseColor).pngData() ?? Data()
            suite?.setValue(data, forKey: "raw")
            suite?.synchronize()
            
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        subs.append(UIMutableApplicationShortcutItem.init(type: "me.ccrama.redditslide.subreddit", localizedTitle: "Open link", localizedSubtitle: "Open current clipboard url", icon: UIApplicationShortcutIcon.init(templateImageName: "nav"), userInfo: [ "clipboard": "true" as NSSecureCoding ]))
        subs.reverse()
        UIApplication.shared.shortcutItems = subs
                
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
        
        tabBar?.removeFromSuperview()
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

}

extension SplitMainViewController: NavigationHomeDelegate {
    func navigation(_ homeViewController: NavigationHomeViewController, didRequestAction: SettingValues.NavigationHeaderActions) {
        switch didRequestAction {
        case .HOME:
            navigation(homeViewController, didRequestSubreddit: "frontpage")
        case .POPULAR:
            navigation(homeViewController, didRequestSubreddit: "popular")
        case .RANDOM:
            random(homeViewController)
        case .SAVED:
            accountHeaderView(homeViewController, didRequestProfilePageAtIndex: 4)
        case .UPVOTED:
            accountHeaderView(homeViewController, didRequestProfilePageAtIndex: 3)
        case .HISTORY:
            navigation(homeViewController, didRequestHistory: ())
        case .AUTO_CACHE:
            navigation(homeViewController, didRequestCacheNow: ())
        case .YOUR_PROFILE:
            accountHeaderView(homeViewController, didRequestProfilePageAtIndex: 0)
        case .COLLECTIONS:
            navigation(homeViewController, didRequestCollections: ())
        case .CREATE_MULTI:
            navigation(homeViewController, didRequestNewMulti: ())
        case .TRENDING:
            ()
            //TODO trending page
        }
    }
    
    func doPresent(callback: @escaping () -> Void) {
        
    }
    
    func doClose(needsHome: Bool, callback: @escaping () -> Void) {
        if needsHome {
            
        } else {
            doPresent(callback: callback)
        }
    }
    
    func navigation(_ homeViewController: NavigationHomeViewController, didRequestSubreddit: String) {
        if let nav = homeViewController.navigationController as? SwipeForwardNavigationController, nav.topViewController != self {
            nav.pushNextViewControllerFromRight() {
                if !self.finalSubs.contains(didRequestSubreddit) {
                    self.goToSubreddit(subreddit: didRequestSubreddit)
                    return
                }
            }
        }
        goToSubreddit(subreddit: didRequestSubreddit)
    }
    
    func navigation(_ homeViewController: NavigationHomeViewController, didRequestNewMulti: Void) {
        let alert = DragDownAlertMenu(title: "Create a new Multireddit", subtitle: "Name your  Multireddit", icon: nil)
        
        alert.addTextInput(title: "Create", icon: UIImage(sfString: SFSymbol.plusCircleFill, overrideString: "add")?.menuIcon(), enabled: true, action: {
            alert.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                var text = alert.getText() ?? ""
                text = text.replacingOccurrences(of: " ", with: "_")
                if text == "" {
                    let alert = AlertController(attributedTitle: nil, attributedMessage: nil, preferredStyle: .alert)
                    alert.setupTheme()
                    alert.attributedTitle = NSAttributedString(string: "Name cannot be empty!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
                    alert.addAction(AlertAction(title: "Ok", style: .normal, handler: { (_) in
                        self.navigation(homeViewController, didRequestNewMulti: ())
                    }))
                    return
                }
                do {
                    try (UIApplication.shared.delegate as! AppDelegate).session?.createMultireddit(text, descriptionMd: "", completion: { (result) in
                        switch result {
                        case .success(let multireddit):
                            if let parent = self.parent {
                                DispatchQueue.main.async {
                                    VCPresenter.presentModally(viewController: ManageMultireddit(multi: multireddit, reloadCallback: {
                                    }, dismissCallback: {
                                        Subscriptions.subscribe("/m/" + text, false, session: nil)
                                        self.navigation(homeViewController, goToMultireddit: "/m/" + text)
                                    }), parent, nil)
                                }
                            }
                        case .failure:
                            if let parent = self.parent {
                                DispatchQueue.main.async {
                                    BannerUtil.makeBanner(text: "Error creating Multireddit, try again later", color: GMColor.red500Color(), seconds: 3, context: parent)
                                }
                            }
                        }
                    })
                } catch {
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Error creating Multireddit, try again later", color: GMColor.red500Color(), seconds: 3, context: self.parent)
                    }
                }
            }
        }, inputPlaceholder: "Name...", inputValue: nil, inputIcon: UIImage(named: "wiki")!.menuIcon(), textRequired: true, exitOnAction: false)
        
        if let parent = parent {
            alert.show(parent)
        }

    }
    
    func navigation(_ homeViewController: NavigationHomeViewController, didRequestSearch: String) {
        VCPresenter.showVC(viewController: SearchViewController(subreddit: self.currentTitle, searchFor: didRequestSearch), popupIfPossible: false, parentNavigationController: homeViewController.navigationController, parentViewController: homeViewController)
    }
    
    func navigation(_ homeViewController: NavigationHomeViewController, didRequestSwitchAccountMenu: Void) {
        let optionMenu = DragDownAlertMenu(title: "Accounts", subtitle: "Currently signed in as \(AccountController.isLoggedIn ? AccountController.currentName : "Guest")", icon: nil)

        for accountName in AccountController.names.unique().sorted() {
            if accountName != AccountController.currentName {
                optionMenu.addAction(title: accountName, icon: UIImage(sfString: SFSymbol.personFill, overrideString: "profile")!.menuIcon()) {
                    homeViewController.accountHeader?.setLoadingState(true)
                    self.navigation(homeViewController, didRequestAccountChangeToName: accountName)
                }
            } else {
               // TODO: - enabled
                optionMenu.addAction(title: "\(accountName) (current)", icon: UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.menuIcon().getCopy(withColor: GMColor.green500Color())) {
                }
            }
        }
        
        if AccountController.isLoggedIn {
            optionMenu.addAction(title: "Browse as Guest", icon: UIImage(sfString: SFSymbol.xmark, overrideString: "hide")!.menuIcon()) {
                homeViewController.accountHeader?.setEmptyState(true, animate: false)
                self.navigation(homeViewController, didRequestGuestAccount: ())
            }

            optionMenu.addAction(title: "Log out of u/\(AccountController.currentName)", icon: UIImage(sfString: SFSymbol.trashFill, overrideString: "delete")!.menuIcon().getCopy(withColor: GMColor.red500Color())) {
                homeViewController.accountHeader?.setEmptyState(true, animate: false)
                self.navigation(homeViewController, didRequestLogOut: ())
            }
        }
        
        optionMenu.addAction(title: "Add a new account", icon: UIImage(sfString: SFSymbol.plusCircleFill, overrideString: "add")!.menuIcon().getCopy(withColor: ColorUtil.baseColor)) {
            self.navigation(homeViewController, didRequestNewAccount: ())
        }
        
        homeViewController.present(optionMenu, animated: true, completion: nil)
    }
    
    func navigation(_ homeViewController: NavigationHomeViewController, didRequestModMenu: Void) {
        let vc = ModerationViewController()
        let navVC = SwipeForwardNavigationController(rootViewController: vc)
        navVC.navigationBar.isTranslucent = false
        homeViewController.present(navVC, animated: true)
    }

    func navigation(_ homeViewController: NavigationHomeViewController, didRequestInbox: Void) {
        let vc = InboxViewController()
        let navVC = SwipeForwardNavigationController(rootViewController: vc)
        navVC.navigationBar.isTranslucent = false
        homeViewController.present(navVC, animated: true)
    }
    
    func navigation(_ homeViewController: NavigationHomeViewController, didRequestUser: String) {
        VCPresenter.openRedditLink("/u/" + didRequestUser.replacingOccurrences(of: " ", with: ""), homeViewController.navigationController, homeViewController)
    }

    func random(_ vc: NavigationHomeViewController) {
        Alamofire.request("https://www.reddit.com/r/random/about.json", method: .get).responseString { response in
            do {
                guard let data = response.data else {
                    BannerUtil.makeBanner(text: "Random subreddit not found", color: GMColor.red500Color(), seconds: 2, context: self.parent, top: true, callback: nil)
                    return
                }
                let json = try JSON(data: data)
                if let sub = json["data"]["display_name"].string {
                    VCPresenter.openRedditLink("/r/\(sub)", vc.navigationController, vc)
                } else {
                    BannerUtil.makeBanner(text: "Random subreddit not found", color: GMColor.red500Color(), seconds: 2, context: self.parent, top: true, callback: nil)
                }
            } catch {
                BannerUtil.makeBanner(text: "Random subreddit not found", color: GMColor.red500Color(), seconds: 2, context: self.parent, top: true, callback: nil)
            }
        }
    }
    
    func navigation(_ homeViewController: NavigationHomeViewController, didRequestSettingsMenu: Void) {
        let settings = SettingsViewController()
        VCPresenter.showVC(viewController: settings, popupIfPossible: true, parentNavigationController: homeViewController.navigationController, parentViewController: homeViewController)
    }
    
    func navigation(_ homeViewController: NavigationHomeViewController, goToMultireddit multireddit: String) {
        finalSubs = []
        finalSubs.append(contentsOf: Subscriptions.pinned)
        finalSubs.append(contentsOf: Subscriptions.subreddits.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending }).filter({ return !Subscriptions.pinned.contains($0) }))
        redoSubs()
        goToSubreddit(subreddit: multireddit)
    }
    
    func navigation(_ homeViewController: NavigationHomeViewController, didRequestCacheNow: Void) {
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
    
    func navigation(_ homeViewController: NavigationHomeViewController, didRequestHistory: Void) {
        VCPresenter.showVC(viewController: HistoryViewController(), popupIfPossible: true, parentNavigationController: homeViewController.navigationController, parentViewController: homeViewController)
    }

    func navigation(_ homeViewController: NavigationHomeViewController, didRequestCollections: Void) {
        if Collections.collectionIDs.count == 0 {
            let alert = AlertController.init(title: "You haven't created a collection yet!", message: nil, preferredStyle: .alert)
            
            alert.setupTheme()
            alert.attributedTitle = NSAttributedString(string: "You haven't created a collection yet!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
            
            alert.attributedMessage = TextDisplayStackView.createAttributedChunk(baseHTML: "Create a new collection by long pressing on the 'save' icon of a post", fontSize: 16, submission: false, accentColor: ColorUtil.baseAccent, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
            
            alert.addCloseButton()
            alert.addBlurView()
            homeViewController.present(alert, animated: true, completion: nil)
        } else {
            let vc = CollectionsViewController()
            let navVC = SwipeForwardNavigationController(rootViewController: vc)
            navVC.navigationBar.isTranslucent = false
            homeViewController.present(navVC, animated: true)
        }
    }

    func navigation(_ homeViewController: NavigationHomeViewController?, didRequestAccountChangeToName accountName: String) {
        AccountController.switchAccount(name: accountName)
        if !UserDefaults.standard.bool(forKey: "done" + accountName) {
            do {
                try addAccount(token: OAuth2TokenRepository.token(of: accountName), register: false)
            } catch {
                addAccount(register: false)
            }
        } else {
            Subscriptions.sync(name: accountName, completion: { [weak self] in
                self?.hardReset(soft: true)
            })
        }
    }

    func navigation(_ homeViewController: NavigationHomeViewController, didRequestGuestAccount: Void) {
        AccountController.switchAccount(name: "GUEST")
        Subscriptions.sync(name: "GUEST", completion: { [weak self] in
            self?.hardReset(soft: true)
        })
    }

    func navigation(_ homeViewController: NavigationHomeViewController, didRequestLogOut: Void) {
        let name: String
        if AccountController.current != nil {
            name = AccountController.current!.name
        } else {
            name = AccountController.currentName
        }
        AccountController.delete(name: name)
        AccountController.switchAccount(name: "GUEST")
        Subscriptions.sync(name: "GUEST", completion: { [weak self] in
            self?.hardReset(soft: true)
        })
    }

    func navigation(_ homeViewController: NavigationHomeViewController, didRequestNewAccount: Void) {
        self.doAddAccount(register: false)
    }

    func displayMenu(_ homeViewController: NavigationHomeViewController, _ menu: DragDownAlertMenu) {
        homeViewController.present(menu, animated: true, completion: nil)
    }
    
    func accountHeaderView(_ homeViewController: NavigationHomeViewController, didRequestProfilePageAtIndex index: Int) {
        let vc = ProfileViewController(name: AccountController.currentName)
        vc.openTo = index
        let navVC = SwipeForwardNavigationController(rootViewController: vc)
        navVC.navigationBar.isTranslucent = false
        homeViewController.present(navVC, animated: true)
    }
}

extension MainViewController: PagingTitleDelegate {
    func didSelect(_ subreddit: String) {
        goToSubreddit(subreddit: subreddit)
    }
}

extension UIImage {
  func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        
    guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
    defer { UIGraphicsEndImageContext() }
        
    let rect = CGRect(origin: .zero, size: size)
    ctx.setFillColor(color.cgColor)
    ctx.fill(rect)
    ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
    ctx.draw(image, in: rect)
        
    return UIGraphicsGetImageFromCurrentImageContext() ?? self
  }
}
extension UIImage {
    func withPadding(_ padding: CGFloat) -> UIImage? {
        return withPadding(x: padding, y: padding)
    }

    func withPadding(x: CGFloat, y: CGFloat) -> UIImage? {
        let newWidth = size.width + 2 * x
        let newHeight = size.height + 2 * y
        let newSize = CGSize(width: newWidth, height: newHeight)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        let origin = CGPoint(x: (newWidth - size.width) / 2, y: (newHeight - size.height) / 2)
        draw(at: origin)
        let imageWithPadding = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithPadding
    }
}
