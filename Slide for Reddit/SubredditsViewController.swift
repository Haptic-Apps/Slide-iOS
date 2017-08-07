
//
//  SubredditsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/25/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import PagingMenuController
import reddift
import MaterialComponents.MaterialSnackbar
import SAHistoryNavigationViewController
import SideMenu

class SubredditsViewController:  PagingMenuController , UISplitViewControllerDelegate {
    var isReload = false
    public static var viewControllers : [UIViewController] = [UIViewController()]
    public static var current: String = ""
    struct PagingMenuOptionsSingle: PagingMenuControllerCustomizable {
        var componentType: ComponentType {
            return .pagingController(pagingControllers: viewControllers)
        }
        var isScrollEnabled: Bool {
            return false
        }
        var lazyLoadingPage: LazyLoadingPage {
            return LazyLoadingPage.one
        }
    }
    struct PagingMenuOptionsBar: PagingMenuControllerCustomizable {
        var componentType: ComponentType {
            return .all(menuOptions: MenuOptions(), pagingControllers:viewControllers)
        }
        var lazyLoadingPage: LazyLoadingPage {
            return LazyLoadingPage.three
        }
    }
    struct MenuItem: MenuItemViewCustomizable {
        var horizontalMargin = 00
        var displayMode: MenuItemDisplayMode
    }
   
    struct MenuOptions: MenuViewCustomizable {
        static var color = UIColor.blue
        
        var itemsOptions: [MenuItemViewCustomizable] {
            var menuitems: [MenuItemViewCustomizable] = []
            for controller in viewControllers {
                let m = MenuItem(horizontalMargin: 10, displayMode:( (controller as! SubredditLinkViewController).displayMode))
                menuitems.append(m)
            }
            return menuitems
        }
        
        static func setColor(c: UIColor){
            color = c
        }
        
        var isAutoSelectAtScrollEnd: Bool {
            return false
        }

        var displayMode: MenuDisplayMode {
            return MenuDisplayMode.standard(widthMode: .flexible, centerItem: true, scrollingMode: MenuScrollingMode.scrollEnabled)
        }
        
        var backgroundColor: UIColor {
            return ColorUtil.backgroundColor
        }
        var selectedBackgroundColor: UIColor {
            return ColorUtil.backgroundColor
        }
        var height: CGFloat {
            return 56
        }
        var marginTop: CGFloat {
            return 20
        }

        var animationDuration: TimeInterval {
            return 0.3
        }
        var deceleratingRate: CGFloat {
            return UIScrollViewDecelerationRateFast
        }
        var selectedItemCenter: Bool {
            return true
        }
        var focusMode: MenuFocusMode {
            return .none
        }
        var dummyItemViewsSet: Int {
            return 1
        }
        var menuPosition: MenuPosition {
            return .top
        }
    
        var dividerImage: UIImage? {
            return nil
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.title = currentTitle
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barTintColor = self.tintColor
        
        if(AccountController.isLoggedIn){
            checkForMail()
        }
        menuNav?.header.doColors()
        if(menuNav?.tableView != nil){
        menuNav?.tableView.reloadData()
        }
    }
    
    func checkForMail(){
        let lastMail = UserDefaults.standard.integer(forKey: "mail")
        let session = (UIApplication.shared.delegate as! AppDelegate).session

            do {
                try session?.getProfile({ (result) in
            switch(result){
            case .failure(let error):
                print(error)
            case .success(let profile):
                let unread = profile.inboxCount
                let diff = unread - lastMail
                DispatchQueue.main.async {
                    self.menuNav?.setmail(mailcount: unread)

                    if(diff > 0){
                        let action = MDCSnackbarMessageAction()
                        let actionHandler = {() in
                            let inbox = InboxViewController.init()
                            self.show(inbox, sender: self)
                        }
                        action.handler = actionHandler
                        action.title = "VIEW"
                        let mes = MDCSnackbarMessage.init(text: "\(diff) new message\(diff > 1 ? "s" : "")!")
                        mes?.action = action
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
        if(SettingValues.multiColumn){
        self.splitViewController?.maximumPrimaryColumnWidth = 10000
        self.splitViewController?.preferredPrimaryColumnWidthFraction = 1
            
        }
        if(SubredditReorderViewController.changed){
            SubredditReorderViewController.changed = false
            self.restartVC()
        }
    }
    
    var menuLeftNavigationController: UISideMenuNavigationController?
    
    func addAccount(){
        menuLeftNavigationController?.dismiss(animated: true, completion: nil)
        doLogin(token: nil)
    }
    
    func addAccount(token: OAuth2Token){
         menuLeftNavigationController?.dismiss(animated: true, completion: nil)
        doLogin(token: token)
    }
    
    func goToSubreddit(subreddit: String){
        if(Subscriptions.subreddits.contains(subreddit)){
            let index = Subscriptions.subreddits.index(of: subreddit)
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForUser(name: subreddit)
            move(toPage: index!)
        } else {
            show(RedditLink.getViewControllerForURL(urlS: URL.init(string: "/r/" + subreddit)!), sender: self)
        }
         menuLeftNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    var alertController: UIAlertController?
    var tempToken: OAuth2Token?
    
    func setToken(token: OAuth2Token){
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
        self.present(alertController!,animated: true, completion: nil)
        UserDefaults.standard.set(token.name, forKey: "name")
        UserDefaults.standard.synchronize()
        tempToken = token
        
        AccountController.switchAccount(name: token.name)
        (UIApplication.shared.delegate as! AppDelegate).syncColors(subredditController: self)
    }
    
    func complete(subs: [String]){
        Subscriptions.set(name: (tempToken?.name)!, subs: subs, completion: {
            self.alertController?.dismiss(animated: true, completion: nil)
            self.restartVC()
        })
    }
    
    func restartVC(){
        
        CachedTitle.titles.removeAll()
        
        SubredditReorderViewController.changed = true
    
        if(SettingValues.viewType){
            setup(PagingMenuOptionsBar() as PagingMenuControllerCustomizable)
        } else {
            setup(PagingMenuOptionsSingle() as PagingMenuControllerCustomizable)
        }
        
        SubredditsViewController.current = (SubredditsViewController.viewControllers[0] as! SubredditLinkViewController).sub
            self.tintColor = ColorUtil.getColorForSub(sub: SubredditsViewController.current)
            self.navigationController?.navigationBar.barTintColor = self.tintColor
            self.menuNav?.setSubreddit(subreddit: SubredditsViewController.current)
            if(!SettingValues.viewType){
                self.title = SubredditsViewController.current
                self.currentTitle = self.title!
            }
            
            MenuOptions.setColor(c: ColorUtil.accentColorForSub(sub: SubredditsViewController.current))
            self.colorChanged()
            
        
        if let nav = self.menuNav {
            if(nav.tableView != nil){
                nav.tableView.reloadData()
            }
        }
         menuLeftNavigationController?.dismiss(animated: true, completion: {})
        let _ = self.menuView?.withPadding(padding: UIEdgeInsetsMake(20, 0, 0, 0))

    }
    
    func doLogin(token: OAuth2Token?){
        (UIApplication.shared.delegate as! AppDelegate).login = self
        if(token == nil){
            AccountController.addAccount()
        } else {
            setToken(token: token!)
        }
    }
    
    var tintColor: UIColor = UIColor.white
    var menuNav: NavigationSidebarViewController?
    var currentTitle = "Slide"
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        menuLeftNavigationController?.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        (self.navigationController as? SAHistoryNavigationViewController)?.historyBackgroundColor = .black

        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        if(SettingValues.multiColumn){
            self.splitViewController?.maximumPrimaryColumnWidth = 10000
            self.splitViewController?.preferredPrimaryColumnWidthFraction = 1
            
        }

        if(SubredditsViewController.viewControllers.count == 1){
            for subname in Subscriptions.subreddits {
                SubredditsViewController.viewControllers.append( SubredditLinkViewController(subName: subname, parent: self))
            }
        }
        
        SubredditsViewController.viewControllers.remove(at: 0)
        
        if(SettingValues.viewType){
            setup(PagingMenuOptionsBar() as PagingMenuControllerCustomizable)
        } else {
            setup(PagingMenuOptionsSingle() as PagingMenuControllerCustomizable)
        }
        SubredditsViewController.current = (SubredditsViewController.viewControllers[0] as! SubredditLinkViewController).sub
            self.tintColor = ColorUtil.getColorForSub(sub: SubredditsViewController.current)
            self.navigationController?.navigationBar.barTintColor = self.tintColor
            self.menuNav?.setSubreddit(subreddit: SubredditsViewController.current)
            if(!SettingValues.viewType){
                self.title = SubredditsViewController.current
                self.currentTitle = self.title!
            }
            
            MenuOptions.setColor(c: ColorUtil.accentColorForSub(sub: SubredditsViewController.current))
            self.colorChanged()

        self.title = "Slide"
        
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let sortB = UIBarButtonItem.init(customView: sort)
        
        let shadowbox = UIButton.init(type: .custom)
        shadowbox.setImage(UIImage.init(named: "shadowbox")?.withColor(tintColor: ColorUtil.fontColor), for: UIControlState.normal)
        shadowbox.addTarget(self, action: #selector(self.shadowbox), for: UIControlEvents.touchUpInside)
        shadowbox.frame = CGRect.init(x: 0, y: 20, width: 30, height: 30)
        shadowbox.translatesAutoresizingMaskIntoConstraints = false
        let sB = UIBarButtonItem.init(customView: shadowbox)

        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: -30, y: 0, width: 30, height: 30)
        let moreB = UIBarButtonItem.init(customView: more)
        
        navigationItem.rightBarButtonItems = [ moreB, sortB, sB]
        
        view.backgroundColor = ColorUtil.backgroundColor
        // set up style before super view did load is executed
        // -
        onMove = { state in
            switch state {
            case let .didMoveController(menuController, _):
                self.navigationController?.navigationBar.barStyle = .black;
                SubredditsViewController.current = (menuController as! SubredditLinkViewController).sub
                    self.tintColor = ColorUtil.getColorForSub(sub: SubredditsViewController.current)
                    self.navigationController?.navigationBar.barTintColor = self.tintColor
                    self.menuNav?.setSubreddit(subreddit: SubredditsViewController.current)
                if(SettingValues.viewType){
                    self.title = SubredditsViewController.current
                }
                    if (menuController as! SubredditLinkViewController).links.count == 0  {
                        (menuController as! SubredditLinkViewController).load(reset: true)
                    }
                    
                    if(!SettingValues.viewType){
                        self.title = SubredditsViewController.current
                        self.currentTitle = self.title!
                    }
                    
                    MenuOptions.setColor(c: ColorUtil.accentColorForSub(sub: SubredditsViewController.current))
                    self.colorChanged()
                    SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: menuController.view)
                
            default: break
            }
        }

        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        let menu = UIButton.init(type: .custom)
        menu.setImage(UIImage.init(named: "menu"), for: UIControlState.normal)
        menu.addTarget(self, action: #selector(self.showDrawer(_:)), for: UIControlEvents.touchUpInside)
        menu.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let menuB = UIBarButtonItem.init(customView: menu)
        navigationItem.leftBarButtonItem = menuB
        
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        self.automaticallyAdjustsScrollViewInsets = false
        menuNav = NavigationSidebarViewController()
        menuNav?.setViewController(controller: self)
        self.menuNav?.setSubreddit(subreddit: SubredditsViewController.current)

        menuLeftNavigationController = UISideMenuNavigationController.init(rootViewController: menuNav!)

        menuLeftNavigationController?.leftSide = true
        // UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration
        // of it here like setting its viewControllers. If you're using storyboards, you'll want to do something like:
        // let menuLeftNavigationController = storyboard!.instantiateViewController(withIdentifier: "LeftMenuNavigationController") as! UISideMenuNavigationController
        SideMenuManager.menuLeftNavigationController = menuLeftNavigationController
        
        SideMenuManager.menuPresentMode = .menuSlideIn
        SideMenuManager.menuAnimationFadeStrength = 0.2
        SideMenuManager.menuParallaxStrength = 2
        SideMenuManager.menuFadeStatusBar = false
        
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the view controller it displays!
        SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.view)
    }
    
    func resetColors(){
        self.navigationController?.navigationBar.barTintColor = self.tintColor
       //todo self.buttonBarView.backgroundColor = self.tintColor
    }
    
    func colorChanged(){
        //todoself.buttonBarView.backgroundColor = self.navigationController?.navigationBar.barTintColor
        menuNav?.header.doColors()
        if(menuNav?.tableView != nil){
        menuNav?.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if(navigationController?.isNavigationBarHidden ?? false){
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    func showSortMenu(_ sender: AnyObject){
        (SubredditsViewController.viewControllers[currentPage] as? SubredditLinkViewController)?.showMenu(sender)
    }
    
    
    func showDrawer(_ sender: AnyObject){
       // let navEditorViewController: UINavigationController = UINavigationController(rootViewController: menuNav)
      //  self.prepareOverlayVC(overlayVC: navEditorViewController)
      //  self.present(navEditorViewController, animated: true, completion: nil)

        // create animator object with instance of modal view controller
        // we need to keep it in property with strong reference so it will not get release
        
        // set transition delegate of modal view controller to our object
        
        // if you modal cover all behind view controller, use UIModalPresentationFullScreen
        present(SideMenuManager.menuLeftNavigationController!, animated: true)
    }
    
    func shadowbox(){
        (SubredditsViewController.viewControllers[currentPage] as? SubredditLinkViewController)?.shadowboxMode()
    }
    

    func showMenu(_ sender: AnyObject){
        (SubredditsViewController.viewControllers[currentPage] as? SubredditLinkViewController)?.showMore(self, parentVC: self)
    }
    
    func showThemeMenu(){
        let actionSheetController: UIAlertController = UIAlertController(title: "Select a base theme", message: "", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        for theme in ColorUtil.Theme.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: theme.rawValue , style: .default)
            { action -> Void in
                UserDefaults.standard.set(theme.rawValue, forKey: "theme")
                UserDefaults.standard.synchronize()
                ColorUtil.doInit()
                self.restartVC()
            }
            actionSheetController.addAction(saveActionButton)
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
}
