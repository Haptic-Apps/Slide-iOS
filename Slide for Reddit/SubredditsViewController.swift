//
//  SubredditsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/25/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import SideMenu
import AMScrollingNavbar
import reddift

class SubredditsViewController:  ButtonBarPagerTabStripViewController {
    var isReload = false
    
    init(){
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
            self.buttonBarView.backgroundColor = self.navigationController?.navigationBar.barTintColor
            moveToViewController(at: index!)
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
        self.reloadPagerTabStripView()
        self.menuNav?.tableView.reloadData()
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
    override func viewDidLoad() {
        menuLeftNavigationController = UISideMenuNavigationController()
        menuLeftNavigationController?.leftSide = true
        menuNav = NavigationSidebarViewController()
        menuNav?.setViewController(controller: self)
        menuLeftNavigationController?.addChildViewController(menuNav!)
        // UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration of it here like setting its viewControllers.
        SideMenuManager.menuLeftNavigationController = menuLeftNavigationController
        menuLeftNavigationController?.navigationBar.isHidden = true
        
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
        SideMenuManager.menuAddPanGestureToPresent(toView: self.navigationController!.navigationBar)
        SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.navigationController!.view)
        
        settings.style.buttonBarItemFont = UIFont.systemFont(ofSize: 14)
        settings.style.selectedBarHeight = 3.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = .black
        settings.style.buttonBarItemsShouldFillAvailiableWidth = true
        
        
        settings.style.buttonBarLeftContentInset = 20
        settings.style.buttonBarRightContentInset = 20
        settings.style.buttonBarItemBackgroundColor = .clear
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.alpha = 0.5
            newCell?.label.alpha = 1
            newCell?.label.textColor = .white
            oldCell?.label.textColor = .white
            self.navigationController?.navigationBar.barStyle = .black;
            if((newCell?.label.text) != nil){
                self.tintColor = ColorUtil.getColorForSub(sub: (newCell?.label.text)!)
                self.navigationController?.navigationBar.barTintColor = self.tintColor
                self.colorChanged()
                self.menuNav?.setSubreddit(subreddit: (newCell?.label.text)!)
                self.buttonBarView.selectedBar.backgroundColor = ColorUtil.accentColorForSub(sub: (newCell?.label.text)!)
            }
        }
        view.backgroundColor = ColorUtil.backgroundColor
        // set up style before super view did load is executed
        // -
        
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        
        
        self.title = "Slide"
        
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let sortB = UIBarButtonItem.init(customView: sort)
        
        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
        let moreB = UIBarButtonItem.init(customView: more)
        
        navigationItem.rightBarButtonItems = [ moreB, sortB]
        
        let menu = UIButton.init(type: .custom)
        menu.setImage(UIImage.init(named: "menu"), for: UIControlState.normal)
        menu.addTarget(self, action: #selector(self.showDrawer(_:)), for: UIControlEvents.touchUpInside)
        menu.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let menuB = UIBarButtonItem.init(customView: menu)
        navigationItem.leftBarButtonItem = menuB
        
    }
    func resetColors(){
        self.navigationController?.navigationBar.barTintColor = self.tintColor
        self.buttonBarView.backgroundColor = self.tintColor
    }
    
    func colorChanged(){
        self.buttonBarView.backgroundColor = self.navigationController?.navigationBar.barTintColor
    }
    
    func showSortMenu(_ sender: AnyObject){
        (viewControllers[currentIndex] as? SubredditLinkViewController)?.showMenu(sender)
    }
    
    func showDrawer(_ sender: AnyObject){
        present(SideMenuManager.menuLeftNavigationController!, animated: true, completion: nil)
    }
    
    func showMenu(_ sender: AnyObject){
        let actionSheetController: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Search", style: .default) { action -> Void in
            print("Search")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Refresh", style: .default) { action -> Void in
            (self.viewControllers[self.currentIndex] as? SubredditLinkViewController)?.refresh()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Subreddit Theme", style: .default) { action -> Void in
            (self.viewControllers[self.currentIndex] as? SubredditLinkViewController)?.pickTheme(parent: self)
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Base Theme", style: .default) { action -> Void in
            self.showThemeMenu()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Filter", style: .default) { action -> Void in
            print("Filter")
        }
        actionSheetController.addAction(cancelActionButton)
        
        
        self.present(actionSheetController, animated: true, completion: nil)
        
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
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        var controllers : [UIViewController] = []
        for subname in Subscriptions.subreddits {
            controllers.append(SubredditLinkViewController(subName: subname))
        }
        return Array(controllers)
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: Subscriptions.subreddits[pagerTabStripController.currentIndex])
    }
}
