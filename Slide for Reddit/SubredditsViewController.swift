
//
//  SubredditsViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/25/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import MaterialComponents
import MaterialComponents.MaterialSnackbar
import SideMenu

class SubredditsViewController:  ColorMuxPagingViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate , UISplitViewControllerDelegate {
    var isReload = false
    public static var vCs : [UIViewController] = []
    public static var current: String = ""
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        
        
        if(AccountController.isLoggedIn){
            checkForMail()
        }
        if(SubredditReorderViewController.changed){
            restartVC()
        }

        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        navigationController?.navigationBar.isTranslucent = false

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
        if(SettingValues.multiColumn){
        self.splitViewController?.maximumPrimaryColumnWidth = 10000
        self.splitViewController?.preferredPrimaryColumnWidthFraction = 1
            
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
            let firstViewController = SubredditsViewController.vCs[index!]
            
            
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
            self.doCurrentPage(index!)

            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: self.currentTitle)
        } else {
            show(RedditLink.getViewControllerForURL(urlS: URL.init(string: "/r/" + subreddit)!), sender: self)
        }
         menuLeftNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    func goToSubreddit(index: Int){
            let firstViewController = SubredditsViewController.vCs[index]
            
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: false,
                               completion: nil)
            self.doCurrentPage(index)
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
        
        print("Restarting VC")

        if(SettingValues.viewType){
             self.dataSource = self
        } else {
            self.dataSource = nil
        }
        self.delegate = self
        if(subs != nil){
            subs!.removeFromSuperview()
            subs = nil
        }
        if(SettingValues.viewType){
            setupTabBar()
        }

        CachedTitle.titles.removeAll()
        view.backgroundColor = ColorUtil.backgroundColor
        splitViewController?.view.backgroundColor = ColorUtil.foregroundColor
        SubredditReorderViewController.changed = false
        
        SubredditsViewController.vCs = []
        for subname in Subscriptions.subreddits {
            SubredditsViewController.vCs.append( SubredditLinkViewController(subName: subname, parent: self))
        }

        let firstViewController = SubredditsViewController.vCs[0]

        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: true,
                           completion: nil)

        self.doCurrentPage(0)
        
        if let nav = self.menuNav {
            if(nav.tableView != nil){
                nav.tableView.reloadData()
            }
        }
         menuLeftNavigationController?.dismiss(animated: true, completion: {})

    }
    
    var tabBar = MDCTabBar()
    var subs: UIView?
    func setupTabBar(){
        tabBar = MDCTabBar.init(frame: CGRect.init(x: 0, y: self.view.frame.size.height - 45, width: self.view.frame.size.width, height: 45))
        tabBar.backgroundColor = ColorUtil.foregroundColor
        tabBar.itemAppearance = .titles

        tabBar.selectedItemTintColor = ColorUtil.fontColor
        tabBar.unselectedItemTintColor = ColorUtil.fontColor.withAlphaComponent(0.45)
        // 2
        tabBar.items = Subscriptions.subreddits.enumerated().map { index, source in
            return UITabBarItem(title: source, image: nil, tag: index)
        }
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        tabBar.selectionIndicatorTemplate = IndicatorTemplate()
        tabBar.delegate = self
        // 3
        tabBar.selectedItem = tabBar.items[0]
        // 4
        //tabBar.delegate = self
        tabBar.tintColor = ColorUtil.accentColorForSub(sub: "NONE")
        // 5
        tabBar.sizeToFit()
        
        self.view.addSubview(tabBar)
    }
    
    func didChooseSub(_ gesture: UITapGestureRecognizer){
        print("Chose")
        
        let sub = gesture.view!.tag
        goToSubreddit(index: sub)
        

    }
    
    func generateSubs() -> (Int, [UIView]) {
        var subs : [UIView] = []
        var i = 0
        var count = 0
        for sub in Subscriptions.subreddits {
            let label = UILabel()
                label.text =  "          \(sub)"
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
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        let page = SubredditsViewController.vCs.index(of: self.viewControllers!.first!)
        doCurrentPage(page!)
    }
    
    
    func doCurrentPage(_ page: Int){
        self.currentPage = page
        let vc = SubredditsViewController.vCs[page] as! SubredditLinkViewController
        vc.viewWillAppear(true)
        SubredditsViewController.current = vc.sub
        self.tintColor = ColorUtil.getColorForSub(sub: SubredditsViewController.current)
        self.menuNav?.setSubreddit(subreddit: SubredditsViewController.current)
        self.currentTitle = SubredditsViewController.current
        
        //self.colorChanged()
        SideMenuManager.default.menuAddScreenEdgePanGesturesToPresent(toView: vc.view)
        for rec in (vc.view.gestureRecognizers)! {
            if(rec is UIScreenEdgePanGestureRecognizer){
                for view in view.subviews
                {
                    if let scrollView = view as? UIScrollView
                    {
                        scrollView.panGestureRecognizer.require(toFail: rec);
                    }
                }
            }
        }
        if(!(vc ).loaded){
            (vc ).load(reset:true)
        }
        
        let menu = UIButton.init(type: .custom)
        menu.setImage(UIImage.init(named:"menu")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
        menu.addTarget(self, action: #selector(self.showDrawer(_:)), for: UIControlEvents.touchUpInside)
        menu.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let menuB = UIBarButtonItem.init(customView: menu)
        
        let label = UILabel()
        label.text =  "   \(self.currentTitle)"
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFont(ofSize: 20)
        
        label.sizeToFit()
        let leftItem = UIBarButtonItem(customView: label)
        
        self.navigationItem.leftBarButtonItems = [menuB, leftItem]

        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()

        tabBar.tintColor = ColorUtil.accentColorForSub(sub: SubredditsViewController.current)
        if(!selected){
            let page = SubredditsViewController.vCs.index(of: self.viewControllers!.first!)
            if(!tabBar.items.isEmpty ) {

                tabBar.setSelectedItem(tabBar.items[page!], animated: true)
            }
        } else {
            selected = false
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        color2 = ColorUtil.getColorForSub(sub: (pendingViewControllers[0] as! SubredditLinkViewController).sub)
        color1 = ColorUtil.getColorForSub(sub: (SubredditsViewController.vCs[currentPage] as! SubredditLinkViewController).sub)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = SubredditsViewController.vCs.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard SubredditsViewController.vCs.count > previousIndex else {
            return nil
        }

        return SubredditsViewController.vCs[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = SubredditsViewController.vCs.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = SubredditsViewController.vCs.count
        
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }

        return SubredditsViewController.vCs[nextIndex]
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [ UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed)) ]
    }
    
    @objc func spacePressed() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            let vc = (SubredditsViewController.vCs[self.currentPage] as! SubredditLinkViewController)
            vc.tableView.contentOffset.y = vc.tableView.contentOffset.y + 350
        }, completion: nil)
    }

    
    override func viewDidLoad() {

        self.navToMux = self.navigationController!.navigationBar
        self.color1 = ColorUtil.backgroundColor
        self.color2 = ColorUtil.backgroundColor

        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.allVisible
        if(SettingValues.multiColumn){
            self.splitViewController?.maximumPrimaryColumnWidth = 10000
            self.splitViewController?.preferredPrimaryColumnWidthFraction = 1
        }
        
        if(UIScreen.main.traitCollection.userInterfaceIdiom == .pad && UIApplication.shared.statusBarOrientation != .portrait){
            self.splitViewController?.showDetailViewController(PlaceholderViewController(), sender: nil)
        }
        
        if(SubredditsViewController.vCs.count == 0){
            for subname in Subscriptions.subreddits {
                SubredditsViewController.vCs.append( SubredditLinkViewController(subName: subname, parent: self))
            }
        }
        
        self.restartVC()
        
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.showSortMenu(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let sortB = UIBarButtonItem.init(customView: sort)
        
        let shadowbox = UIButton.init(type: .custom)
        shadowbox.setImage(UIImage.init(named: "shadowbox")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), for: UIControlState.normal)
        shadowbox.addTarget(self, action: #selector(self.shadowbox), for: UIControlEvents.touchUpInside)
        shadowbox.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let sB = UIBarButtonItem.init(customView: shadowbox)

        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let moreB = UIBarButtonItem.init(customView: more)
        
        navigationItem.rightBarButtonItems = [ moreB, sortB, sB]
        
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
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
        SideMenuManager.menuWidth = 300
        SideMenuManager.menuFadeStatusBar = false
        
        // Enable gestures. The left and/or right menus must be set up above for these to work.
        // Note that these continue to work on the Navigation Controller independent of the view controller it displays!
        SideMenuManager.menuAddScreenEdgePanGesturesToPresent(toView: self.view)

        if(UIScreen.main.traitCollection.userInterfaceIdiom == .pad){
            self.edgesForExtendedLayout = UIRectEdge.all
            self.extendedLayoutIncludesOpaqueBars = true


            if(AccountController.isLoggedIn){
                checkForMail()
            }
            if(SubredditReorderViewController.changed){
                restartVC()
            }

            self.navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: self.currentTitle)
            navigationController?.navigationBar.isTranslucent = false

            menuNav?.header.doColors()
            if(menuNav?.tableView != nil){
                menuNav?.tableView.reloadData()
            }
        }
    }
    
    func resetColors(){
       // self.navigationController?.navigationBar.barTintColor = self.tintColor
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
        (SubredditsViewController.vCs[currentPage] as? SubredditLinkViewController)?.showMenu(sender)
    }
    
    var currentPage = 0
    
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
        (SubredditsViewController.vCs[currentPage] as? SubredditLinkViewController)?.shadowboxMode()
    }
    

    func showMenu(_ sender: AnyObject){
        (SubredditsViewController.vCs[currentPage] as? SubredditLinkViewController)?.showMore(sender, parentVC: self)
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
                                         y:  -0,
                                         width: bounds.width,
                                         height: 2.0);
        attributes.path = UIBezierPath.init(rect: underlineFrame)
        return attributes;
    }
}
extension SubredditsViewController: MDCTabBarDelegate {
    
    func tabBar(_ tabBar: MDCTabBar, didSelect item: UITabBarItem) {
        selected = true
        let firstViewController = SubredditsViewController.vCs[tabBar.items.index(of: item)! ]
        
        setViewControllers([firstViewController],
                           direction: .forward,
                           animated: false,
                           completion: nil)
        self.doCurrentPage(tabBar.items.index(of: item)!)
        navigationController?.navigationBar.barTintColor = ColorUtil.getColorForSub(sub: self.currentTitle)

    }
}

