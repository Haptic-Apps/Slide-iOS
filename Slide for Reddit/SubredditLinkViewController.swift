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


class SubredditLinkViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource, IndicatorInfoProvider, ScrollingNavigationControllerDelegate, LinkCellViewDelegate {
    
    func save(_ cell: LinkCellView) {
        do {
            try session?.setSave(!ActionStates.isSaved(s: cell.link!), name: (cell.link?.name)!, completion: { (result) in
                
            })
            History.addSeen(s: cell.link!)
            cell.refresh(submission:cell.link!)
        } catch {
            
        }
    }
    
    func upvote(_ cell: LinkCellView) {
        do{
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.name)!, completion: { (result) in
                
            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh(submission:cell.link!)
        } catch {
            
        }
    }
    
    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.name)!, completion: { (result) in
                
            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!)
            cell.refresh(submission:cell.link!)
        } catch {
            
        }
    }
    
    func more(_ cell: LinkCellView){
        
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
    init(subName: String){
        sub = subName;
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
            print("navbar collapsed")
        case .expanded:
            print("navbar expanded")
        case .scrolling:
            print("navbar is moving")
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
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(LinkCellView.classForCoder(), forCellReuseIdentifier: "cell")
        session = (UIApplication.shared.delegate as! AppDelegate).session
        if self.links.count == 0 {
            load(reset: true)
        }
        
        tableView.estimatedRowHeight = 400.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isTranslucent = false
        if let navigationController = self.navigationController as? ScrollingNavigationController {
            print("Following scroll")
            navigationController.followScrollView(self.tableView, delay: 50.0)
            navigationController.scrollingNavbarDelegate = self
        }
        if(single){
            self.title = sub
        }
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
    
    var sort = LinkSortType.hot
    var time = TimeFilterWithin.day
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return itemInfo
    }
    
    func showMenu(){
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
    
    func load(reset: Bool){
        if(!loading){
            do {
                loading = true
                refreshControl.beginRefreshing()
                if(reset){
                    paginator = Paginator()
                }
                try session?.getList(paginator, subreddit: Subreddit.init(subreddit: sub) , sort: sort, timeFilterWithin: time, completion: { (result) in
                    switch result {
                    case .failure:
                        print(result.error!)
                    case .success(let listing):
                        if(reset){
                            self.links = []
                        }
                        self.links += listing.children.flatMap({$0 as? Link})
                        self.paginator = listing.paginator
                        DispatchQueue.main.async{
                            self.tableView.reloadData()
                            self.refreshControl.endRefreshing()
                            self.loading = false
                        }
                    }
                })
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
