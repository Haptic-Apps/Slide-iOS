//
//  SubredditsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/25/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import PagingMenuController
import SideMenu
import AMScrollingNavbar
import reddift


class SubredditsViewController:  PagingMenuController {
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
    }
    struct PagingMenuOptionsBar: PagingMenuControllerCustomizable {
        var componentType: ComponentType {
            return .all(menuOptions: MenuOptions(), pagingControllers:viewControllers)
        }
    }
    struct MenuItem: MenuItemViewCustomizable {
        var horizontalMargin = 10
        var displayMode: MenuItemDisplayMode
    }
   
    struct MenuOptions: MenuViewCustomizable {
        static var color = UIColor.blue
        
        var itemsOptions: [MenuItemViewCustomizable] {
            var menuitems: [MenuItemViewCustomizable] = []
            for controller in viewControllers {
                menuitems.append(MenuItem(horizontalMargin: 10, displayMode:( (controller as! SubredditLinkViewController).displayMode)))
            }
            return menuitems
        }
        
        static func setColor(c: UIColor){
            color = c
        }

        var displayMode: MenuDisplayMode {
            return MenuDisplayMode.standard(widthMode: .flexible, centerItem: true, scrollingMode: MenuScrollingMode.scrollEnabled)
        }
        
        var backgroundColor: UIColor {
            return ColorUtil.getColorForSub(sub: current)
        }
        var selectedBackgroundColor: UIColor {
            return ColorUtil.getColorForSub(sub: current)
        }
        var height: CGFloat {
            return 30
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
            return .underline(height: 3, color: ColorUtil.accentColorForSub(sub: current), horizontalPadding: 0, verticalPadding: 0)
        }
        var dummyItemViewsSet: Int {
            return 3
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
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barTintColor = self.tintColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if(SubredditReorderViewController.changed){
            SubredditReorderViewController.changed = false
            self.restartVC()
        }
        
    }
    
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
           //todo  self.buttonBarView.backgroundColor = self.navigationController?.navigationBar.barTintColor
            move(toPage: index!)
        } else {
            show(RedditLink.getViewControllerForURL(urlS: URL.init(string: "/r/" + subreddit)!), sender: self)
            (navigationController as? ScrollingNavigationController)?.showNavbar(animated: true)
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
    
        if(SettingValues.viewType){
            setup(PagingMenuOptionsBar() as PagingMenuControllerCustomizable)
        } else {
            setup(PagingMenuOptionsSingle() as PagingMenuControllerCustomizable)
        }
        
        SubredditsViewController.current = (SubredditsViewController.viewControllers[0] as! SubredditLinkViewController).sub
        if(SubredditsViewController.current != nil){
            self.tintColor = ColorUtil.getColorForSub(sub: SubredditsViewController.current)
            self.navigationController?.navigationBar.barTintColor = self.tintColor
            self.menuNav?.setSubreddit(subreddit: SubredditsViewController.current)
            if(!SettingValues.viewType){
                self.title = SubredditsViewController.current
                self.currentTitle = self.title!
            }
            
            MenuOptions.setColor(c: ColorUtil.accentColorForSub(sub: SubredditsViewController.current))
            self.colorChanged()
            
        }
        
        if let nav = self.menuNav {
            if(nav.tableView != nil){
                nav.tableView.reloadData()
            }
        }
        menuLeftNavigationController?.dismiss(animated: true, completion: {
        })
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
    var menuLeftNavigationController: UISideMenuNavigationController?
    var menuNav: NavigationSidebarViewController?
    var currentTitle = "Slide"
    override func viewDidLoad() {
        self.title = currentTitle
        menuLeftNavigationController = UISideMenuNavigationController()
        menuLeftNavigationController?.leftSide = true
        menuNav = NavigationSidebarViewController()
        menuNav?.setViewController(controller: self)
        menuLeftNavigationController?.addChildViewController(menuNav!)
        // UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration of it here like setting its viewControllers.
        SideMenuManager.menuLeftNavigationController = menuLeftNavigationController
        SideMenuManager.menuPresentMode = .menuSlideIn
        menuLeftNavigationController?.navigationBar.isHidden = true
        
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
        SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.view, forMenu: UIRectEdge.left)
        SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view, forMenu: UIRectEdge.left)
        
        if(SubredditsViewController.viewControllers.count == 1){
            for subname in Subscriptions.subreddits {
                SubredditsViewController.viewControllers.append( SubredditLinkViewController(subName: subname, parent: self))
                print(subname)
            }
        }
        
        SubredditsViewController.viewControllers.remove(at: 0)
        
        if(SettingValues.viewType){
            setup(PagingMenuOptionsBar() as PagingMenuControllerCustomizable)
        } else {
            setup(PagingMenuOptionsSingle() as PagingMenuControllerCustomizable)
        }
        SubredditsViewController.current = (SubredditsViewController.viewControllers[0] as! SubredditLinkViewController).sub
        if(SubredditsViewController.current != nil){
            self.tintColor = ColorUtil.getColorForSub(sub: SubredditsViewController.current)
            self.navigationController?.navigationBar.barTintColor = self.tintColor
            self.menuNav?.setSubreddit(subreddit: SubredditsViewController.current)
            if(!SettingValues.viewType){
                self.title = SubredditsViewController.current
                self.currentTitle = self.title!
            }
            
            MenuOptions.setColor(c: ColorUtil.accentColorForSub(sub: SubredditsViewController.current))
            self.colorChanged()
            
        }

        self.title = "Slide"
        
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let sortB = UIBarButtonItem.init(customView: sort)
        
        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: -30, y: 0, width: 30, height: 30)
        let moreB = UIBarButtonItem.init(customView: more)
        
        navigationItem.rightBarButtonItems = [ moreB, sortB]
        
        view.backgroundColor = ColorUtil.backgroundColor
        // set up style before super view did load is executed
        // -
        onMove = { state in
            switch state {
            case let .willMoveController(menuController, previousMenuController):
                print(previousMenuController)
                print(menuController)
                self.navigationController?.navigationBar.barStyle = .black;
                SubredditsViewController.current = (menuController as! SubredditLinkViewController).sub
                if(SubredditsViewController.current != nil){
                    self.tintColor = ColorUtil.getColorForSub(sub: SubredditsViewController.current)
                    self.navigationController?.navigationBar.barTintColor = self.tintColor
                    self.menuNav?.setSubreddit(subreddit: SubredditsViewController.current)
                    if(!SettingValues.viewType){
                        self.title = SubredditsViewController.current
                        self.currentTitle = self.title!
                    }
                    
                    MenuOptions.setColor(c: ColorUtil.accentColorForSub(sub: SubredditsViewController.current))
                    self.colorChanged()
                    
                }
            case let .didMoveController(menuController, previousMenuController):
                print(previousMenuController)
                print(menuController)
               

            case let .willMoveItem(menuItemView, previousMenuItemView):
                print(previousMenuItemView)
                print(menuItemView)
            case let .didMoveItem(menuItemView, previousMenuItemView):
                print(previousMenuItemView)
                print(menuItemView)
            case .didScrollStart:
                print("Scroll start")
            case .didScrollEnd:
                print("Scroll end")
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
        
    }
    func resetColors(){
        self.navigationController?.navigationBar.barTintColor = self.tintColor
       //todo self.buttonBarView.backgroundColor = self.tintColor
    }
    
    func colorChanged(){
        //todoself.buttonBarView.backgroundColor = self.navigationController?.navigationBar.barTintColor
    }
    
    func showSortMenu(_ sender: AnyObject){
        (SubredditsViewController.viewControllers[currentPage] as? SubredditLinkViewController)?.showMenu(sender)
    }
    
    func showDrawer(_ sender: AnyObject){
        present(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)
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
