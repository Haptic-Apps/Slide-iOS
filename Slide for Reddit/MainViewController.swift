//
//  MainViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 7/19/20.
//  Copyright © 2020 Haptic Apps. All rights reserved.
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

    //MARK: - Variables
    
    var isReload = false
    var readLaterBadge: BadgeSwift?
    public static var current: String = ""
    public static var needsRestart = false
    public static var needsReTheme = false
    public var toolbar: UIView?
    var tabBar = MDCTabBar()
    var subs: UIView?
    var selected = false

    var finalSubs = [String]()

    var checkedClipboardOnce = false

    var more = UIButton()
    var menu = UIButton()
    var readLaterB = UIBarButtonItem()
    var sortB = UIBarButtonItem().then {
        $0.accessibilityLabel = "Change Post Sorting Order"
    }
    var sortButton: UIButton = UIButton()
    var inHeadView = UIView()

    var readLater = UIButton().then {
        $0.accessibilityLabel = "Open Read Later List"
    }
    var accountB = UIBarButtonItem()
    public static var first = true

    lazy var currentAccountTransitioningDelegate = CurrentAccountPresentationManager()

    override var prefersStatusBarHidden: Bool {
        return SettingValues.fullyHideNavbar
    }
    
    var statusbarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.size.height
    }
    
    var currentPage: Int {
        if let vc = viewControllers?[0] as? SingleSubredditViewController {
            return finalSubs.firstIndex(of: vc.sub) ?? 0
        } else {
            return 0
        }
    }
    
    public static var isOffline = false
    var menuB = UIBarButtonItem()
    var drawerButton = UIImageView()

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

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    var alertController: UIAlertController?
    var tempToken: OAuth2Token?

    var menuNav: NavigationSidebarViewController?

    var currentTitle = "Slide"

    //MARK: - Shared functions
    
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
    
    //from https://github.com/CleverTap/ios-request-review/blob/master/Example/RatingExample/ViewController.swift
    func requestReviewIfAppropriate() {
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

    @objc func onAccountRefreshRequested(_ notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            self?.checkForMail()
        }
    }
    
    func checkForMail() {
        DispatchQueue.main.async {
            //TODO reenable this
            if !self.checkedClipboardOnce && false {
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
    
    func doLogin(token: OAuth2Token?, register: Bool) {
        (UIApplication.shared.delegate as! AppDelegate).login = self
        if token == nil {
            AccountController.addAccount(context: self, register: register)
        } else {
            setToken(token: token!)
        }
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

    @objc public func onAccountChangedNotificationPosted() {
        DispatchQueue.main.async { [weak self] in
            self?.doProfileIcon()
        }
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
    func shadowbox() {
        getSubredditVC()?.shadowboxMode()
    }
    
    @objc func showMenu(_ sender: AnyObject) {
        getSubredditVC()?.showMore(sender, parentVC: self)
    }
    //MARK: - Overrides
    func handleToolbars() {
    }
    
    func redoSubs() {
    }
    
    func doRetheme() {
    }
    
    public func viewWillAppearActions(override: Bool = false) {
    }

    override func viewWillAppear(_ animated: Bool) {
    }

    
    func hardReset() {
    }

    override func viewDidAppear(_ animated: Bool) {
    }

    func addAccount(register: Bool) {
    }
    
    func doAddAccount(register: Bool) {
    }

    func addAccount(token: OAuth2Token, register: Bool) {
    }
    
    func goToSubreddit(subreddit: String) {
    }
    
    func goToUser(profile: String) {
    }

    func makeMenuNav() {
    }
    
    @objc func restartVC() {
    }
    
    func doCurrentPage(_ page: Int) {
    }
    
    func doButtons() {
    }
    
    func colorChanged(_ color: UIColor) {
    }
    
    @objc func showDrawer(_ sender: AnyObject) {
    }

    //MARK: - Other stuff
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

//TODO break this out
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
        self.doAddAccount(register: false)
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
