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
import RealmSwift

class MainViewController: ColorMuxPagingViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UISplitViewControllerDelegate {
    var isReload = false
    public static var vCs: [UIViewController] = []
    public static var current: String = ""
    public static var needsRestart = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        
        if(MainViewController.needsRestart){
            MainViewController.needsRestart = false
            hardReset()
            return
        }

        if (SubredditReorderViewController.changed || ColorUtil.shouldBeNight()) {
            var subChanged = false
            if(finalSubs.count != Subscriptions.subreddits.count){
                subChanged = true
            } else {
                for i in 0...finalSubs.count - 1 {
                    if(finalSubs[i] != Subscriptions.subreddits[i]){
                        subChanged = true
                        break
                    }
                }
            }
            if (ColorUtil.doInit() || subChanged){
                restartVC()
            }
        }

        self.navigationController?.navigationBar.shadowImage = UIImage()
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
        
        if(!UserDefaults.standard.bool(forKey: "firstOpen")){
            var vc = SettingsWelcome(parent: self)
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true, completion: nil)
        }
        
        if(!UserDefaults.standard.bool(forKey: "beta")){
            let alert = UIAlertController.init(title: "Welcome to Slide Beta testing!", message: "\nBy clicking agree, you signify your understanding that you are testing Beta software that may contain bugs or incomplete features.\n\nBy using this Beta, you agree to report bugs and feature requests to either GitHub or the slide_ios subreddit. Please do not send reports through the TestFlight feedback system.", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "Open GitHub", style: .default, handler: { (action) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(URL.init(string: "https://github.com/ccrama/Slide-iOS")!, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(URL.init(string: "https://github.com/ccrama/Slide-iOS")!)
                }
            }))
            
            alert.addAction(UIAlertAction.init(title: "Visit the subreddit", style: .default, handler: { (action) in
                VCPresenter.openRedditLink("/r/slide_ios", self.navigationController, self)
            }))
            
            alert.addAction(UIAlertAction.init(title: "Agree", style: .destructive, handler: { (action) in
                UserDefaults.standard.set(true, forKey: "beta")
                UserDefaults.standard.synchronize()
            }))
            
            self.present(alert, animated: true)
        }
    }

    func hardReset(){
        navigationController?.popViewController(animated: false)
        navigationController?.pushViewController(MainViewController.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil), animated: false)
    }
    
    func checkForMail() {
        DispatchQueue.main.async {
            let lastMail = UserDefaults.standard.integer(forKey: "mail")
            let session = (UIApplication.shared.delegate as! AppDelegate).session
            
            do {
                try session?.getProfile({ (result) in
                    switch (result) {
                    case .failure(let error):
                        print(error)
                    case .success(let profile):
                        SettingValues.nsfwEnabled = profile.over18
                        let unread = profile.inboxCount
                        let diff = unread - lastMail
                        if(profile.isMod && AccountController.modSubs.isEmpty){
                            self.menuNav?.setMod(profile.hasModMail)
                            print("Getting mod subs")
                            AccountController.doModOf()
                        }
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
    }

    func splitViewController(_ svc: UISplitViewController, shouldHide vc: UIViewController, in orientation: UIInterfaceOrientation) -> Bool {
        return false
    }
    
    public static var first = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.splitViewController?.delegate = self
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        if (SettingValues.multiColumn) {
            self.splitViewController?.maximumPrimaryColumnWidth = 10000
            self.splitViewController?.preferredPrimaryColumnWidthFraction = 1

        }
        if (AccountController.isLoggedIn && !MainViewController.first) {
            checkForMail()
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
        SingleSubredditViewController.ignoreFab = true
        menuNav?.dismiss(animated: true) {
            if (Subscriptions.subreddits.contains(subreddit)) {
                let index = Subscriptions.subreddits.index(of: subreddit)
                let firstViewController = MainViewController.vCs[index!]
                
                self.setViewControllers([firstViewController],
                                        direction: index! > self.currentPage ? .forward : .reverse,
                                        animated: SettingValues.viewType ? true : false,
                                   completion: nil)

                self.doCurrentPage(index!)
                self.navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: subreddit)
                self.inHeadView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
                self.tabBar.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
            } else {
                //todo better sanitation
                VCPresenter.openRedditLink("/r/" + subreddit.replacingOccurrences(of: " ", with: ""), self.navigationController, self)
            }
        }
    }

    func goToSubreddit(index: Int) {
        SingleSubredditViewController.ignoreFab = true
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
        var finalSubs = subs
        if(!subs.contains("slide_ios")){
            self.alertController?.dismiss(animated: true, completion: {
                let alert = UIAlertController.init(title: "Subscribe to r/slide_ios?", message: "Would you like to subscribe to the Slide for Reddit iOS community and receive news and updates first?", preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "Maybe later", style: .cancel, handler: {(action) in
                    self.finalizeSetup(subs)
                }))
                alert.addAction(UIAlertAction.init(title: "Sure!", style: .default, handler: {(action) in
                    finalSubs.insert("slide_ios", at: 2)
                    self.finalizeSetup(finalSubs)
                    do {
                        try (UIApplication.shared.delegate as! AppDelegate).session!.setSubscribeSubreddit(Subreddit.init(subreddit: "slide_ios"), subscribe: true, completion: { (result) in
                            
                        })
                    } catch {
                        
                    }
                }))
                self.present(alert, animated: true, completion: nil)
            })
        } else {
            self.alertController?.dismiss(animated: true, completion: {
                self.finalizeSetup(subs)
            })
        }
    }
    
    func finalizeSetup(_ subs: [String]){
        Subscriptions.set(name: (tempToken?.name)!, subs: subs, completion: {
            self.menuNav = nil
            self.restartVC()
        })
    }
    
    var finalSubs = [String]()

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

        CachedTitle.titles.removeAll()
        view.backgroundColor = ColorUtil.backgroundColor
        splitViewController?.view.backgroundColor = ColorUtil.foregroundColor
        SubredditReorderViewController.changed = false

        MainViewController.vCs = []
        finalSubs = []
        LinkCellView.cachedInternet = nil
        if(Reachability().connectionStatus().description == ReachabilityStatus.Offline.description){
            MainViewController.isOffline = true
            let baseSubs = Subscriptions.subreddits
            do {
            let realm = try Realm()
            for subname in baseSubs {
                var hasLinks = false
                if let listing = realm.objects(RListing.self).filter({ (item) -> Bool in
                    return item.subreddit == subname
                }).first {
                    hasLinks = !listing.links.isEmpty
                }
                if(hasLinks){
                    finalSubs.append(subname)
                }
            }
            } catch {
                
            }
            for subname in finalSubs {
                MainViewController.vCs.append(SingleSubredditViewController(subName: subname, parent: self))
            }

        } else {
            finalSubs = Subscriptions.subreddits
            MainViewController.isOffline = false
            var subs = [UIMutableApplicationShortcutItem]()
            for subname in finalSubs {
                MainViewController.vCs.append(SingleSubredditViewController(subName: subname, parent: self))
                if(subs.count < 3 && !subname.contains("/")){
                    subs.append(UIMutableApplicationShortcutItem.init(type: "me.ccrama.redditslide.subreddit", localizedTitle: subname, localizedSubtitle: nil, icon: UIApplicationShortcutIcon.init(templateImageName: "subs"), userInfo: [ "sub": "\(subname)" ]))
                }
                
                subs.reverse()
            }
            UIApplication.shared.shortcutItems = subs
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

        doButtons()
        
        tabBar.removeFromSuperview()
        if (SettingValues.viewType) {
            setupTabBar(finalSubs)
        }
    }

    var tabBar = MDCTabBar()
    var subs: UIView?

    func setupTabBar(_ subs : [String]) {
        tabBar = MDCTabBar.init(frame: CGRect.init(x: 0, y: -4 + (UIApplication.shared.statusBarView?.frame.size.height ?? 20), width: self.view.frame.size.width, height: 76))
        tabBar.backgroundColor = ColorUtil.getColorForSub(sub: MainViewController.current)
        tabBar.itemAppearance = .titles

        tabBar.selectedItemTintColor = UIColor.white
        tabBar.unselectedItemTintColor = UIColor.white.withAlphaComponent(0.45)
        tabBar.items = subs.enumerated().map { index, source in
            return UITabBarItem(title: source, image: nil, tag: index)
        }
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        tabBar.selectionIndicatorTemplate = IndicatorTemplate()
        tabBar.delegate = self
        tabBar.selectedItem = tabBar.items[0]
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: "NONE")
        tabBar.sizeToFit()
        tabBar.frame.size.height = 48
        
        self.view.addSubview(tabBar)
    }
    
    func didChooseSub(_ gesture: UITapGestureRecognizer) {
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
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: vc.sub)
        self.inHeadView.backgroundColor = ColorUtil.getColorForSub(sub: vc.sub)

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

    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willRotate(to: toInterfaceOrientation, duration: duration)
        var isPhone = UIScreen.main.traitCollection.userInterfaceIdiom != .pad
        if(toInterfaceOrientation.isLandscape && isPhone){
            tabBar.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.size.width, height: 84)
            tabBar.sizeToFit()
        } else if(isPhone){
            tabBar.frame = CGRect.init(x: 0, y: UIApplication.shared.statusBarView?.frame.size.height ?? 20, width: self.view.frame.size.width, height: 84)
            tabBar.sizeToFit()
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

    var inHeadView = UIView()

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
        
        self.restartVC()

        doButtons()

        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        self.automaticallyAdjustsScrollViewInsets = false

        if(menuNav == nil){
            menuNav = NavigationSidebarViewController()
            menuNav?.setViewController(controller: self)
            self.menuNav?.setSubreddit(subreddit: MainViewController.current)
            bottomSheet = MDCBottomSheetController(contentViewController: menuNav!)
        }

        inHeadView.removeFromSuperview()
        inHeadView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: max(self.view.frame.size.width, self.view.frame.size.height), height: (UIApplication.shared.statusBarView?.frame.size.height ?? 20)))
        self.inHeadView.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        
        if(SettingValues.viewType){
            self.view.addSubview(inHeadView)
        }
        
        checkForUpdate()

        if (UIScreen.main.traitCollection.userInterfaceIdiom == .pad) {
            self.edgesForExtendedLayout = UIRectEdge.all
            self.extendedLayoutIncludesOpaqueBars = true

            self.navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = false

            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: self.currentTitle)
            tabBar.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)
            self.inHeadView.backgroundColor = ColorUtil.getColorForSub(sub: self.currentTitle)


            menuNav?.header.doColors()
            if (menuNav?.tableView != nil) {
                menuNav?.tableView.reloadData()
            }
            if(SettingValues.viewType){
                navigationController?.setNavigationBarHidden(true, animated: false)
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        let today =  formatter.string(from: Date())
    
        if(SettingValues.autoCache) {
            if (UserDefaults.standard.string(forKey: "DAY_LAUNCH") != today) {
                AutoCache.init(baseController: self)
                UserDefaults.standard.setValue(today, forKey: "DAY_LAUNCH")
            }
        }
    }
    
    public static var isOffline = false

    func doButtons(){
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white")?.navIcon(), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let sortB = UIBarButtonItem.init(customView: sort)

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

        let settings = UIButton.init(type: .custom)
        settings.setImage(UIImage.init(named: "settings")?.toolbarIcon(), for: UIControlState.normal)
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
        if(!MainViewController.isOffline){
            toolbarItems = [menuB, flexButton, moreB]
        } else {
            toolbarItems = [settingsB, flexButton, offlineB]
        }
        navigationItem.rightBarButtonItem = sortB
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

    func colorChanged(_ color: UIColor) {
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: MainViewController.current)
        tabBar.backgroundColor = color
        inHeadView.backgroundColor = color
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarView?.backgroundColor = .clear

        if (navigationController?.isNavigationBarHidden ?? false) {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }

    func showSortMenu(_ sender: UIButton?) {
        (MainViewController.vCs[currentPage] as? SingleSubredditViewController)?.showSortMenu(sender)
    }

    var currentPage = 0

    func showDrawer(_ sender: AnyObject) {
        if(menuNav == nil){
            menuNav = NavigationSidebarViewController()
            menuNav?.setViewController(controller: self)
            self.menuNav?.setSubreddit(subreddit: MainViewController.current)
            bottomSheet = MDCBottomSheetController(contentViewController: menuNav!)
        }
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
