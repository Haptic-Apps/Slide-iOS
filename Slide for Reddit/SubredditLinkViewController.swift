//
//  SubredditLinkViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/22/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import ChameleonFramework
import XLPagerTabStrip
import AMScrollingNavbar
import SideMenu
import KCFloatingActionButton

class SubredditLinkViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource, IndicatorInfoProvider, ScrollingNavigationControllerDelegate, LinkCellViewDelegate, ColorPickerDelegate, KCFloatingActionButtonDelegate {
    
    var parentController: SubredditsViewController?
    var accentChosen: UIColor?
    func valueChanged(_ value: CGFloat, accent: Bool) {
        if(accent){
            accentChosen = UIColor.init(cgColor: GMPalette.allAccentCGColor()[Int(value * CGFloat(GMPalette.allAccentCGColor().count))])
        } else {
            self.navigationController?.navigationBar.barTintColor = UIColor.init(cgColor: GMPalette.allCGColor()[Int(value * CGFloat(GMPalette.allCGColor().count))])
            if(parentController != nil){
                parentController?.colorChanged()
            }
        }
    }
    
    func reply(_ cell: LinkCellView){
        
    }
    
    func save(_ cell: LinkCellView) {
        do {
            try session?.setSave(!ActionStates.isSaved(s: cell.link!), name: (cell.link?.name)!, completion: { (result) in
                
            })
            ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {
            
        }
    }
    
    func upvote(_ cell: LinkCellView) {
        do{
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.name)!, completion: { (result) in
                
            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {
            
        }
    }
    
    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.name)!, completion: { (result) in
                
            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {
            
        }
    }
    
    func more(_ cell: LinkCellView){
        let link = cell.link!
        let actionSheetController: UIAlertController = UIAlertController(title: link.title, message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "/u/\(link.author)", style: .default) { action -> Void in
            self.show(ProfileViewController.init(name: link.author), sender: self)
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "/r/\(link.subreddit)", style: .default) { action -> Void in
            self.show(SubredditLinkViewController.init(subName: link.subreddit, single: true), sender: self)
        }
        actionSheetController.addAction(cancelActionButton)
        
        if(AccountController.isLoggedIn){
            
            cancelActionButton = UIAlertAction(title: "Save", style: .default) { action -> Void in
                self.save(cell)
            }
            actionSheetController.addAction(cancelActionButton)
        }
        
        cancelActionButton = UIAlertAction(title: "Report", style: .default) { action -> Void in
            //todo report
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Hide", style: .default) { action -> Void in
            //todo hide
        }
        actionSheetController.addAction(cancelActionButton)
        
        var open = OpenInChromeController.init()
        if(open.isChromeInstalled()){
            cancelActionButton = UIAlertAction(title: "Open in Chrome", style: .default) { action -> Void in
                open.openInChrome(link.url!, callbackURL: nil, createNewTab: true)
            }
            actionSheetController.addAction(cancelActionButton)
        }

        cancelActionButton = UIAlertAction(title: "Open in Safari", style: .default) { action -> Void in
            UIApplication.shared.open(link.url!, options: [:], completionHandler: nil)
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Share content", style: .default) { action -> Void in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [link.url!], applicationActivities: nil);
            let currentViewController:UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Share comments", style: .default) { action -> Void in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [URL.init(string: "https://reddit.com" + link.permalink)!], applicationActivities: nil);
            let currentViewController:UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Fiter this content", style: .default) { action -> Void in
            self.showFilterMenu(link)
        }
        actionSheetController.addAction(cancelActionButton)
        
        
        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    func showFilterMenu(_ link: Link){
        let actionSheetController: UIAlertController = UIAlertController(title: "What would you like to filter?", message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Posts by /u/\(link.author)", style: .default) { action -> Void in
            PostFilter.profiles.append(link.author as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil)
            self.tableView.reloadData()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Posts from /r/\(link.subreddit)", style: .default) { action -> Void in
            PostFilter.subreddits.append(link.subreddit as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil)
            self.tableView.reloadData()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Posts linking to \(link.domain)", style: .default) { action -> Void in
            PostFilter.domains.append(link.domain as NSString)
            PostFilter.saveAndUpdate()
            self.links = PostFilter.filter(self.links, previous: nil)
            self.tableView.reloadData()
        }
        actionSheetController.addAction(cancelActionButton)
        
        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    
    var links: [Link] = []
    var paginator = Paginator()
    var sub : String
    var session: Session? = nil
    weak var tableView : UITableView!
    var itemInfo : IndicatorInfo
    var single: Bool = false
    var subreddit: Subreddit?
    
    /* override func previewActionItems() -> [UIPreviewActionItem] {
     let regularAction = UIPreviewAction(title: "Regular", style: .Default) { (action: UIPreviewAction, vc: UIViewController) -> Void in
     
     }
     
     let destructiveAction = UIPreviewAction(title: "Destructive", style: .Destructive) { (action: UIPreviewAction, vc: UIViewController) -> Void in
     
     }
     
     let actionGroup = UIPreviewActionGroup(title: "Group...", style: .Default, actions: [regularAction, destructiveAction])
     
     return [regularAction, destructiveAction, actionGroup]
     }*/
    init(subName: String, parent: SubredditsViewController){
        sub = subName;
        self.parentController = parent
        itemInfo = IndicatorInfo(title: sub)
        super.init(nibName:nil, bundle:nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: subName))
    }
    
    init(subName: String, single: Bool){
        sub = subName
        self.single = true
        itemInfo = IndicatorInfo(title: sub)
        super.init(nibName:nil, bundle:nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: subName))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scrollingNavigationController(_ controller: ScrollingNavigationController, didChangeState state: NavigationBarState) {
        switch state {
        case .collapsed:
            hide(true)
            break
        case .expanded:
           show(true)
            break
        case .scrolling:
            break
        }
    }
    
    func show(_ animated: Bool = true) {
        if(fab != nil){
        if animated == true {
            fab!.isHidden = false
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.fab!.alpha = 1
            })
        } else {
            fab!.isHidden = false
        }
        }
    }
    
    func hide(_ animated: Bool = true) {
        if(fab != nil){
        if animated == true {
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.fab!.alpha = 0
            }, completion: { finished in
                self.fab!.isHidden = true
            })
        } else {
            fab!.isHidden = true
        }
        }
    }
    
    override func loadView(){
        
        self.view = UITableView(frame: CGRect.zero, style: .plain)
        self.tableView = self.view as! UITableView
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        tableView.backgroundColor = ColorUtil.backgroundColor
        tableView.separatorColor = ColorUtil.backgroundColor
        tableView.separatorInset = .zero
        
        refreshControl = UIRefreshControl()
        self.tableView.contentOffset = CGPoint.init(x: 0, y: -self.refreshControl.frame.size.height)
        refreshControl.tintColor = ColorUtil.fontColor
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
        
    }
    
    func drefresh(_ sender:AnyObject) {
        load(reset: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    var sideMenu: UISideMenuNavigationController?
    var menuNav: SubSidebarViewController?
    
    override func viewDidLoad() {
        self.tableView.register(LinkCellView.classForCoder(), forCellReuseIdentifier: "cell")
        session = (UIApplication.shared.delegate as! AppDelegate).session
        if self.links.count == 0 && !single {
            load(reset: true)
        }
        
        tableView.estimatedRowHeight = 400.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if(single){
            sideMenu = UISideMenuNavigationController()
            menuNav = SubSidebarViewController.init(parentController: self, sub: sub, completion: { (success, subreddit) in
                if(success || self.sub == ("all") || self.sub == ("frontpage") || self.sub.hasPrefix("/m/")){
                    if(self.sub != ("all") && self.sub != ("frontpage") && !self.sub.hasPrefix("/m/")){
                    if(SettingValues.saveHistory){
                        if(SettingValues.saveNSFWHistory && subreddit!.over18){
                            Subscriptions.addHistorySub(name: AccountController.currentName, sub: subreddit!.displayName)
                        } else if(!subreddit!.over18){
                            Subscriptions.addHistorySub(name: AccountController.currentName, sub: subreddit!.displayName)
                        }
                    }
                    }
                    
                    self.load(reset: true)
                } else {
                    let alert = UIAlertController.init(title: "Subreddit not found", message: "/r/\(self.sub) could not be found, is it spelled correctly?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "Ok", style: .default, handler: { (_) in
                        let presentingViewController: UIViewController! = self.presentingViewController
                        
                        self.dismiss(animated: false) {
                            // go back to MainMenuView as the eyes of the user
                            presentingViewController.dismiss(animated: false, completion: nil)
                        }
                        
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            })
            sideMenu?.addChildViewController(menuNav!)
            // UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration of it here like setting its viewControllers.
            SideMenuManager.menuRightNavigationController = sideMenu
            sideMenu?.navigationBar.isHidden = true
            
            // Enable gestures. The left and/or right menus must be set up above for these to work.
            // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
            
        } else {
            sideMenu = UISideMenuNavigationController()
            print("Sub is \(sub)")
            menuNav = SubSidebarViewController.init(parentController: self, sub: sub, completion: { (success) in })
            sideMenu?.addChildViewController(menuNav!)
            // UISideMenuNavigationController is a subclass of UINavigationController, so do any additional configuration of it here like setting its viewControllers.
            SideMenuManager.menuRightNavigationController = sideMenu
            sideMenu?.navigationBar.isHidden = true
            
            // Enable gestures. The left and/or right menus must be set up above for these to work.
            // Note that these continue to work on the Navigation Controller independent of the View Controller it displays!
            
        }
        
        if(SettingValues.hiddenFAB){
        fab = KCFloatingActionButton()
        fab!.buttonColor = ColorUtil.accentColorForSub(sub: sub)
        fab!.buttonImage = UIImage.init(named: "hide")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30))
        fab!.fabDelegate = self
            fab!.sticky = true
        self.view.addSubview(fab!)
        }
        super.viewDidLoad()
        
    }
    
    func emptyKCFABSelected(_ fab: KCFloatingActionButton) {
        tableView.beginUpdates()
        
        var indexPaths : [IndexPath] = []
        var newLinks : [Link] = []

        var count = 0
        for submission in links {
            if(History.getSeen(s: submission)){
                indexPaths.append(IndexPath(row: count, section: 0))
            } else {
                newLinks.append(submission)
            }
            count += 1
        }
        
        links = newLinks
        tableView.deleteRows(at: indexPaths, with: .middle)
        tableView.endUpdates()

        print("Empty")
    }
    
    var fab : KCFloatingActionButton?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func pickTheme(parent: SubredditsViewController?){
        parentController = parent
        let alertController = UIAlertController(title: "\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 120)
        let customView = ColorPicker(frame: rect)
        customView.delegate = self
        
        customView.backgroundColor = ColorUtil.backgroundColor
        alertController.view.addSubview(customView)
        
        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: {(alert: UIAlertAction!) in
            ColorUtil.setColorForSub(sub: self.sub, color: (self.navigationController?.navigationBar.barTintColor)!)
            self.tableView.reloadData()
        })
        
        let accentAction = UIAlertAction(title: "Accent color", style: .default, handler: {(alert: UIAlertAction!) in
            ColorUtil.setColorForSub(sub: self.sub, color: (self.navigationController?.navigationBar.barTintColor)!)
            self.pickAccent(parent: parent)
            self.tableView.reloadData()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in
            if(parent != nil){
                parent?.resetColors()
            }
        })
        
        alertController.addAction(accentAction)
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func pickAccent(parent: SubredditsViewController?){
        parentController = parent
        let alertController = UIAlertController(title: "\n\n\n\n\n\n", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 10.0
        let rect = CGRect(x: margin, y: margin, width: alertController.view.bounds.size.width - margin * 4.0, height: 120)
        let customView = ColorPicker(frame: rect)
        customView.setAccent(accent: true)
        customView.delegate = self
        
        customView.backgroundColor = ColorUtil.backgroundColor
        alertController.view.addSubview(customView)
        
        let somethingAction = UIAlertAction(title: "Save", style: .default, handler: {(alert: UIAlertAction!) in
            if self.accentChosen != nil {
                ColorUtil.setAccentColorForSub(sub: self.sub, color: self.accentChosen!)
            }
            self.tableView.reloadData()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction!) in
            if(parent != nil){
                parent?.resetColors()
            }
        })
        
        alertController.addAction(somethingAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isTranslucent = false
        (navigationController as? ScrollingNavigationController)?.showNavbar(animated: true)
        if let navigationController = self.navigationController as? ScrollingNavigationController {
            navigationController.followScrollView(self.tableView, delay: 50.0)
            navigationController.scrollingNavbarDelegate = self
        }
        if(single){
            if(navigationController != nil){
                self.title = sub
                let sort = UIButton.init(type: .custom)
                sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
                sort.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
                sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
                let sortB = UIBarButtonItem.init(customView: sort)
                
                let more = UIButton.init(type: .custom)
                more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
                more.addTarget(self, action: #selector(self.showMoreNone(_:)), for: UIControlEvents.touchUpInside)
                more.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
                let moreB = UIBarButtonItem.init(customView: more)
                
                navigationItem.rightBarButtonItems = [ moreB, sortB]
            } else if parentController != nil && parentController?.navigationController != nil{
                parentController?.navigationController?.title = sub
                let sort = UIButton.init(type: .custom)
                sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
                sort.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
                sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
                let sortB = UIBarButtonItem.init(customView: sort)
                
                let more = UIButton.init(type: .custom)
                more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
                more.addTarget(self, action: #selector(self.showMoreNone(_:)), for: UIControlEvents.touchUpInside)
                more.frame = CGRect.init(x: -15, y: 0, width: 30, height: 30)
                let moreB = UIBarButtonItem.init(customView: more)
                
                parentController?.navigationItem.rightBarButtonItems = [ moreB, sortB]
            }
        } else {
            paging = true
        }
        super.viewWillAppear(animated)
        /* todo this, too slow currently
        if(savedIndex != nil){
            tableView.reloadRows(at: [savedIndex!], with: .none)
        } else {
            tableView.reloadData()
        }*/
    }
    
    func showMoreNone(_ sender: AnyObject){
        showMore(sender, parentVC: nil)
    }
    
    func search(){
        let alert = UIAlertController(title: "Search", message: "", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "Search All", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            let search = SearchViewController.init(subreddit: "all", searchFor: (textField?.text!)!)
            self.parentController?.show(search, sender: self.parentController)
        }))
        
        if(sub != "all" && sub != "frontpage" && sub != "friends"){
            alert.addAction(UIAlertAction(title: "Search \(sub)", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                let search = SearchViewController.init(subreddit: self.sub, searchFor: (textField?.text!)!)
                self.parentController?.show(search, sender: self.parentController)
            }))
        }
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        parentController?.present(alert, animated: true, completion: nil)
        
    }
    
    func showMore(_ sender: AnyObject, parentVC: SubredditsViewController? = nil){
        let actionSheetController: UIAlertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Search", style: .default) { action -> Void in
            self.search()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Refresh", style: .default) { action -> Void in
            self.refresh()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Gallery mode", style: .default) { action -> Void in
            self.galleryMode()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Subreddit Theme", style: .default) { action -> Void in
            if(parentVC != nil){
                let p = (parentVC!)
                self.pickTheme(parent: p)
            } else {
                self.pickTheme(parent: nil)
            }

        }
        actionSheetController.addAction(cancelActionButton)
        
        if(!single){
        cancelActionButton = UIAlertAction(title: "Base Theme", style: .default) { action -> Void in
            if(parentVC != nil){
                (parentVC)!.showThemeMenu()
            }
        }
        actionSheetController.addAction(cancelActionButton)
        }
        
        cancelActionButton = UIAlertAction(title: "Filter", style: .default) { action -> Void in
            print("Filter")
        }
        actionSheetController.addAction(cancelActionButton)
        
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func galleryMode(){
        let controller = GalleryTableViewController()
        var gLinks:[Link] = []
        for l in links{
            if (((((l.baseJson["preview"] as? [String: Any])?["images"] as? [Any])?.first as? [String: Any])?["source"] as? [String: Any])?["url"] as? String) != nil {
                gLinks.append(l)
            }
        }
        controller.setLinks(links: gLinks)
        show(controller, sender: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return links.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! LinkCellView
        
        let link = self.links[(indexPath as NSIndexPath).row]
        cell.setLink(submission: link, parent: self, nav: self.navigationController)
        cell.delegate = self
        if indexPath.row == self.links.count - 1 && !loading {
            self.loadMore()
        }
        
        return cell
    }
    
    var loading = false
    
    func loadMore(){
        if(!showing){
            showLoader()
        }
        load(reset: false)
    }
    
    var showing = false
    func showLoader() {
        showing = true
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.frame = CGRect(x: 0, y: 0.0, width: 80.0, height: 80.0)
        spinner.center = CGPoint(x: tableView.frame.size.width  / 2,
                                 y: tableView.frame.size.height / 2);
        
        tableView.tableFooterView = spinner
        spinner.startAnimating()
        
    }
    
    var sort = SettingValues.defaultSorting
    var time = SettingValues.defaultTimePeriod
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
    
    func showMenu(_ selector: AnyObject){
        let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default)
            { action -> Void in
                self.showTimeMenu(s: link)
            }
            actionSheetController.addAction(saveActionButton)
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    func showTimeMenu(s: LinkSortType){
        if(s == .hot || s == .new){
            sort = s
            refresh()
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)
            
            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default)
                { action -> Void in
                    print("Sort is \(s) and time is \(t)")
                    self.sort = s
                    self.time = t
                    self.refresh()
                }
                actionSheetController.addAction(saveActionButton)
            }
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
    
    var refreshControl: UIRefreshControl!
    
    func refresh(){
        self.links = []
        tableView.reloadData()
        refreshControl.beginRefreshing()
        load(reset: true)
    }
    
    var savedIndex: IndexPath?
    
    func load(reset: Bool){
        if(!loading){
            do {
                loading = true
                refreshControl.beginRefreshing()
                if(reset){
                    paginator = Paginator()
                }
                if(sub.hasPrefix("/m/")){
                    try session?.getList(paginator, subreddit: Multireddit.init(name: sub.substring(3, length: sub.length - 3), user: AccountController.currentName) , sort: sort, timeFilterWithin: time, completion: { (result) in
                        switch result {
                        case .failure:
                            print(result.error!)
                        case .success(let listing):
                            if(reset){
                                self.links = []
                            }
                            let values = PostFilter.filter(listing.children.flatMap({$0 as? Link}), previous: self.links)
                            self.links += values
                            self.paginator = listing.paginator
                            DispatchQueue.main.async{
                                self.tableView.reloadData()
                                self.refreshControl.endRefreshing()
                                self.loading = false
                            }
                        }
                    })
                } else {
                    print("Sort is \(self.sort) and time is \(self.time)")

                    try session?.getList(paginator, subreddit: Subreddit.init(subreddit: sub) , sort: sort, timeFilterWithin: time, completion: { (result) in
                        switch result {
                        case .failure:
                            print(result.error!)
                        case .success(let listing):
                            if(reset){
                                self.links = []
                            }
                            let values = PostFilter.filter(listing.children.flatMap({$0 as? Link}), previous: self.links)
                            self.links += values
                            self.paginator = listing.paginator
                            DispatchQueue.main.async{
                                self.tableView.reloadData()
                                self.refreshControl.endRefreshing()
                                self.loading = false
                            }
                        }
                    })
                }
            } catch {
                print(error)
            }
            
        }
    }
    
    
}
extension UIViewController {
    func topMostViewController() -> UIViewController {
        // Handling Modal views
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topMostViewController()
        }
            // Handling UIViewController's added as subviews to some other views.
        else {
            for view in self.view.subviews
            {
                // Key property which most of us are unaware of / rarely use.
                if let subViewController = view.next {
                    if subViewController is UIViewController {
                        let viewController = subViewController as! UIViewController
                        return viewController.topMostViewController()
                    }
                }
            }
            return self
        }
    }
}

extension UITabBarController {
    override func topMostViewController() -> UIViewController {
        return self.selectedViewController!.topMostViewController()
    }
}

extension UINavigationController {
    override func topMostViewController() -> UIViewController {
        return self.visibleViewController!.topMostViewController()
    }
}
