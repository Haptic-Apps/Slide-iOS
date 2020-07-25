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
import SwiftyJSON
import MaterialComponents.MaterialTabs
import RealmSwift
import reddift
import SDCAlertView
import StoreKit
import UIKit
import WatchConnectivity

class SplitMainViewController: MainViewController {
    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return true
    }

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
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: MainViewController.current)
        inHeadView.backgroundColor = SettingValues.reduceColor ? ColorUtil.theme.foregroundColor : color
        if SettingValues.fullyHideNavbar {
            inHeadView.backgroundColor = .clear
        }
    }

    override func doButtons() {
        if menu.superview != nil && !MainViewController.needsReTheme {
            return
        }
        sortButton = ExpandedHitButton(type: .custom)
        sortButton.setImage(UIImage(sfString: SFSymbol.arrowUpArrowDownCircle, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        sortButton.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControl.Event.touchUpInside)
        sortButton.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
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

    override func viewDidLoad() {
        self.navToMux = self.navigationController!.navigationBar
        self.color1 = ColorUtil.theme.foregroundColor
        self.color2 = ColorUtil.theme.foregroundColor
        
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
        
        self.parent?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        for view in view.subviews {
            if view is UIScrollView {
                let scrollView = view as! UIScrollView
                scrollView.delegate = self
                
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
        let vc = self.viewControllers![0] as! SingleSubredditViewController
        MainViewController.current = vc.sub
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: "Viewing \(vc.sub)")
        self.currentTitle = MainViewController.current
        self.parent?.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: vc.sub, true)
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
        self.parent?.navigationController?.navigationBar.shadowImage = UIImage()
        self.parent?.navigationController?.navigationBar.layoutIfNeeded()
        
        // Clear the menuNav's searchBar to refresh the menuNav
        //TODO make this affect the sidebar
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

    override func doRetheme() {
        (viewControllers?[0] as? SingleSubredditViewController)?.reTheme()
        tabBar.removeFromSuperview()
        if SettingValues.subredditBar {
            setupTabBar(finalSubs)
        }
        setupBaseBarColors()
        toolbar?.backgroundColor = ColorUtil.theme.foregroundColor.add(overlay: ColorUtil.theme.isLight ? UIColor.black.withAlphaComponent(0.05) : UIColor.white.withAlphaComponent(0.05))
        self.doButtons()
        MainViewController.needsReTheme = false
    }
    
    override func viewWillAppearActions(override: Bool = false) {
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        //self.navigationController?.setNavigationBarHidden(true, animated: false)
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
        
        self.parent?.navigationController?.navigationBar.shadowImage = UIImage()
        self.parent?.navigationController?.navigationBar.isTranslucent = false
        self.parent?.navigationController?.toolbar.barTintColor = ColorUtil.theme.foregroundColor
        self.parent?.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: getSubredditVC()?.sub ?? "", true)
        
        //TODO make the sidebar do this
        if menuNav?.tableView != nil {
            menuNav?.tableView.reloadData()
        }
        
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

    override func hardReset(soft: Bool = false) {
        if soft && false { //in case we need to not destroy the stack, disable for now
        } else {
            if #available(iOS 14.0, *) {
                _ = (UIApplication.shared.delegate as! AppDelegate).resetStackNew()
            } else {
                _ = (UIApplication.shared.delegate as! AppDelegate).resetStack()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AccountController.isLoggedIn && !MainViewController.first {
            checkForMail()
        }
    }

    override func addAccount(register: Bool) {
        doLogin(token: nil, register: register)
    }
    
    override func doAddAccount(register: Bool) {
        guard let window = UIApplication.shared.keyWindow else {
            fatalError("Window must exist when resetting the stack!")
        }

        if #available(iOS 14.0, *) {
            let main = (UIApplication.shared.delegate as! AppDelegate).resetStackNew()
            (UIApplication.shared.delegate as! AppDelegate).login = main
            AccountController.addAccount(context: main, register: register)
        } else {
            let main = (UIApplication.shared.delegate as! AppDelegate).resetStack()
            (UIApplication.shared.delegate as! AppDelegate).login = main
            AccountController.addAccount(context: main, register: register)
        }
    }

    override func addAccount(token: OAuth2Token, register: Bool) {
        doLogin(token: token, register: register)
    }
    
    override func goToSubreddit(subreddit: String, override: Bool = false) {
        if self.finalSubs.contains(subreddit) && !override {
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
                self.color1 = ColorUtil.theme.foregroundColor
                self.color2 = ColorUtil.theme.foregroundColor
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

}

extension SplitMainViewController: CurrentAccountHeaderViewDelegate {
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestAction: SettingValues.NavigationHeaderActions) {
        switch didRequestAction {
        case .HOME:
            goToSubreddit(subreddit: "frontpage")
        case .POPULAR:
            goToSubreddit(subreddit: "popular")
        case .RANDOM:
            random()
            //TODO new random functionality
        case .SAVED:
            view.accountHeaderView(view.shortcutsView, didRequestProfilePageAtIndex: 5)
        case .UPVOTED:
            view.accountHeaderView(view.shortcutsView, didRequestProfilePageAtIndex: 4)
        case .HISTORY:
            currentAccountViewController(view, didRequestHistory: ())
        case .AUTO_CACHE:
            currentAccountViewController(view, didRequestCacheNow: ())
        case .YOUR_PROFILE:
            view.accountHeaderView(view.shortcutsView, didRequestProfilePageAtIndex: 1)
        case .COLLECTIONS:
            currentAccountViewController(view, didRequestCollections: ())
        case .CREATE_MULTI:
            view.multiButtonPressed()
        case .TRENDING:
            ()
            //TODO trending page
        }
    }
    
    func random() {
        Alamofire.request("https://www.reddit.com/r/random/about.json", method: .get).responseString { response in
            do {
                guard let data = response.data else {
                    BannerUtil.makeBanner(text: "Random subreddit not found", color: GMColor.red500Color(), seconds: 2, context: self.parent, top: true, callback: nil)
                    return
                }
                let json = try JSON(data: data)
                if let sub = json["data"]["display_name"].string {
                    self.goToSubreddit(subreddit: sub, override: true)
                } else {
                    BannerUtil.makeBanner(text: "Random subreddit not found", color: GMColor.red500Color(), seconds: 2, context: self.parent, top: true, callback: nil)
                }
            } catch {
                BannerUtil.makeBanner(text: "Random subreddit not found", color: GMColor.red500Color(), seconds: 2, context: self.parent, top: true, callback: nil)
            }
        }
    }
    
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestSettingsMenu: Void) {
        let settings = SettingsViewController()
        VCPresenter.showVC(viewController: settings, popupIfPossible: true, parentNavigationController: view.parent?.navigationController, parentViewController: view.parent ?? self)
    }
    
    func currentAccountViewController(_ view: CurrentAccountHeaderView, goToMultireddit multireddit: String) {
        finalSubs = []
        finalSubs.append(contentsOf: Subscriptions.pinned)
        finalSubs.append(contentsOf: Subscriptions.subreddits.sorted(by: { $0.caseInsensitiveCompare($1) == .orderedAscending }).filter({ return !Subscriptions.pinned.contains($0) }))
        redoSubs()
        goToSubreddit(subreddit: multireddit)
    }
    
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestCacheNow: Void) {
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
    
    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestHistory: Void) {
        VCPresenter.showVC(viewController: HistoryViewController(), popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
    }

    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestCollections: Void) {
        if Collections.collectionIDs.count == 0 {
            let alert = AlertController.init(title: "You haven't created a collection yet!", message: nil, preferredStyle: .alert)
            
            alert.setupTheme()
            alert.attributedTitle = NSAttributedString(string: "You haven't created a collection yet!", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
            
            alert.attributedMessage = TextDisplayStackView.createAttributedChunk(baseHTML: "Create a new collection by long pressing on the 'save' icon of a post", fontSize: 16, submission: false, accentColor: ColorUtil.baseAccent, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
            
            alert.addCloseButton()
            alert.addBlurView()
            present(alert, animated: true, completion: nil)

        } else {
            let vc = CollectionsViewController()
            let navVC = SwipeForwardNavigationController(rootViewController: vc)
            navVC.navigationBar.isTranslucent = false
            present(navVC, animated: true)
        }
    }

    func currentAccountViewController(_ view: CurrentAccountHeaderView?, didRequestAccountChangeToName accountName: String) {
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

    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestGuestAccount: Void) {
        AccountController.switchAccount(name: "GUEST")
        Subscriptions.sync(name: "GUEST", completion: { [weak self] in
            self?.hardReset(soft: true)
        })
    }

    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestLogOut: Void) {
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

    func currentAccountViewController(_ view: CurrentAccountHeaderView, didRequestNewAccount: Void) {
        self.doAddAccount(register: false)
    }

}
