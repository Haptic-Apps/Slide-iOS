//
//  CommentViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/30/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import AudioToolbox.AudioServices
import BGTableViewRowActionWithImage
import AMScrollingNavbar
import UZTextView
import RealmSwift

class CommentViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource, UZTextViewCellDelegate, LinkCellViewDelegate, UISearchBarDelegate {
    
    internal func pushedMoreButton(_ cell: CommentDepthCell) {
        
    }
    func save(_ cell: LinkCellView) {
        do {
            let state = !ActionStates.isSaved(s: cell.link!)
            try session?.setSave(state, name: (cell.link?.name)!, completion: { (result) in
                DispatchQueue.main.async{
                    self.view.makeToast(state ? "Saved" : "Unsaved", duration: 3, position: .top)
                }
            })
            ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {
            
        }
    }
    func saveComment(_ comment: RComment) {
        do {
            let state = !ActionStates.isSaved(s: comment)
            try session?.setSave(state, name: comment.name, completion: { (result) in
                DispatchQueue.main.async{
                    self.view.makeToast(state ? "Saved" : "Unsaved", duration: 3, position: .bottom)
                }
            })
            ActionStates.setSaved(s: comment, saved: !ActionStates.isSaved(s: comment))
        } catch {
            
        }
    }
    
    var searchBar = UISearchBar()
    
    func reply(_ cell: LinkCellView) {
        print("Replying")
        
        let c = LinkCellView()
        c.delegate = self
        c.setLink(submission: self.submission!, parent: self, nav: self.navigationController)
        c.showBody(width: self.view.frame.size.width)
        c.frame = (tableView.tableHeaderView?.frame)!
        c.layoutIfNeeded()
        
        let reply  = ReplyViewController.init(thing: self.submission!, sub: (self.submission?.subreddit)!, view: c.contentView) { (comment) in
            DispatchQueue.main.async(execute: { () -> Void in
                let startDepth = 0
                
                let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!)]
                self.cDepth[comment!.getId()] = startDepth
                
                self.dataArray.insert(contentsOf: queue, at: 0)
                self.comments.insert(contentsOf: queue, at: 0)
                self.heightArray.insert(contentsOf: self.updateStringsSingle(queue), at: 0)
                self.contents.insert(contentsOf: self.updateStringsSingle(queue), at: 0)
                self.doArrays()
                self.tableView.reloadData()
            })
        }
        
        let navEditorViewController: UINavigationController = UINavigationController(rootViewController: reply)
        self.prepareOverlayVC(overlayVC: navEditorViewController)
        self.present(navEditorViewController, animated: true, completion: nil)
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
            self.report(self.submission!)
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Hide", style: .default) { action -> Void in
            //todo hide
        }
        actionSheetController.addAction(cancelActionButton)
        let open = OpenInChromeController.init()
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
            //todo filter content
        }
        actionSheetController.addAction(cancelActionButton)
        
        
        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    func report(_ thing: Object){
        let alert = UIAlertController(title: "Report this content", message: "Enter a reason (not required)", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "Report", style: .destructive, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            do {
                let name = (thing is RComment) ? (thing as! RComment).name : (thing as! RSubmission).name
                try self.session?.report(name, reason: (textField?.text!)!, otherReason: "", completion: { (result) in
                    DispatchQueue.main.async{
                        self.view.makeToast("Report sent", duration: 3, position: .top)
                    }
                })
            } catch {
                DispatchQueue.main.async{
                    self.view.makeToast("Error sending report", duration: 3, position: .top)
                }
            }
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    var submission: RSubmission? = nil
    var session: Session? = nil
    var cDepth: NSMutableDictionary = NSMutableDictionary()
    var comments: [Object] = []
    var hiddenPersons: [String] = []
    var hidden: [String] = []
    var contents: [CellContent] = []
    weak var tableView : UITableView!
    var headerCell : LinkCellView?
    var hasSubmission = true
    var paginator: Paginator? = Paginator()
    var refreshControl: UIRefreshControl!
    var context: String = ""
    var contextNumber: Int = 0
    
    var dataArray : [Object] = []
    var heightArray : [CellContent] = []
    var filteredData : [Object] = []
    var filteredHeights : [CellContent] = []
    
    func doArrays(){
        dataArray = comments.filter{ !hidden.contains($0 is RComment ? ($0 as! RComment).getId() : ($0 as! RMore).getId()) }
        heightArray = contents.filter{ !hidden.contains($0.id) }
    }
    
    var sort: CommentSort = SettingValues.defaultCommentSorting
    
    override func loadView(){
        self.view = UITableView(frame: CGRect.zero, style: .plain)
        self.tableView = self.view as! UITableView
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsSelection = false
        
        tableView.backgroundColor = ColorUtil.backgroundColor
        refreshControl = UIRefreshControl()
        self.tableView.contentOffset = CGPoint.init(x: 0, y: -self.refreshControl.frame.size.height)
        refreshControl.tintColor = ColorUtil.fontColor
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(CommentViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
        
    }
    
    func refresh(_ sender:AnyObject) {
        session = (UIApplication.shared.delegate as! AppDelegate).session
        if let link = self.submission {
            do {
                print("Context number is \(contextNumber)")
                print("Name is \(link.name)")
                try session?.getArticles(link.name, sort:sort, comments:(context.isEmpty ? nil : [context]), context: contextNumber, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let tuple):
                        let startDepth = 1
                        let listing = tuple.1
                        self.comments = []
                        self.hiddenPersons = []
                        self.hidden = []
                        self.contents = []
                        
                        self.submission = RealmDataWrapper.linkToRSubmission(submission: tuple.0.children[0] as! Link)
                        
                        self.refreshControl.endRefreshing()
                        var allIncoming: [(Thing, Int)] = []
                        self.submission!.comments.removeAll()
                        for child in listing.children {
                            let incoming = self.extendKeepMore(in: child, current: startDepth)
                            allIncoming.append(contentsOf: incoming)
                            for i in incoming{
                                let item = RealmDataWrapper.commentToRealm(comment: i.0)
                                self.comments.append(item)
                                if(item is RComment){
                                self.submission!.comments.append(item as! RComment)
                                }
                                self.cDepth[i.0.getId()] = i.1
                            }
                        }
                        
                        var time = timeval(tv_sec: 0, tv_usec: 0)
                        gettimeofday(&time, nil)
                        if(!allIncoming.isEmpty){
                            self.contents += self.updateStrings(allIncoming)
                        }
                        self.paginator = listing.paginator
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            do {
                                let realm = try! Realm()
                                //todo insert
                                realm.beginWrite()
                                for comment in self.comments {
                                    realm.create(type(of: comment), value: comment, update: true)
                                }
                                realm.create(type(of: self.submission!), value: self.submission!, update: true)
                                try realm.commitWrite()
                            } catch {
                                
                            }
                            

                            if(!self.hasSubmission){
                                self.headerCell = LinkCellView()
                                self.headerCell?.delegate = self
                                self.hasDone = true
                                self.headerCell?.setLink(submission: self.submission!, parent: self, nav: self.navigationController)
                                self.headerCell?.showBody(width: self.view.frame.size.width)
                                self.tableView.tableHeaderView = UIView(frame: CGRect.init(x:0, y:0, width:self.tableView.frame.width, height:0.01))
                                if let tableHeaderView = self.headerCell {
                                    var frame = CGRect.zero
                                    frame.size.width = self.tableView.bounds.size.width
                                    frame.size.height = tableHeaderView.estimateHeight()
                                    if self.tableView.tableHeaderView == nil || !frame.equalTo(tableHeaderView.frame) {
                                        tableHeaderView.frame = frame
                                        tableHeaderView.layoutIfNeeded()
                                        let view = UIView(frame: tableHeaderView.frame)
                                        view.addSubview(tableHeaderView)
                                        self.tableView.tableHeaderView = view
                                    }
                                }
                                self.title = self.submission!.subreddit
                                self.setBarColors(color: ColorUtil.getColorForSub(sub: self.title!))
                            } else {
                                self.headerCell?.refreshLink(self.submission!)
                            }
                            self.doArrays()
                            self.lastSeen = History.getSeenTime(s: link)
                            self.tableView.reloadData()
                            History.setComments(s: link)
                            History.addSeen(s: link)
                            
                            var index = 0
                            if(!self.context.isEmpty()){
                                for comment in self.comments {
                                    if(comment is RComment && (comment as! RComment).getId().contains(self.context)){
                                        self.goToCell(i: index)
                                        break
                                    } else {
                                        index += 1
                                    }
                                }
                            }
                        })
                    }
                })
            } catch { print(error) }
        }
    }
    
    var lastSeen: Double = NSDate().timeIntervalSince1970
    var savedTitleView: UIView?
    var savedHeaderView: UIView?
    
    func showSearchBar() {
        searchBar.alpha = 0
        savedHeaderView = tableView.tableHeaderView
        tableView.tableHeaderView = UIView()
        savedTitleView = navigationItem.titleView
        navigationItem.titleView = searchBar
        navigationItem.setRightBarButtonItems(nil, animated: true)
        UIView.animate(withDuration: 0.5, animations: {
            self.searchBar.alpha = 1
        }, completion: { finished in
            self.searchBar.becomeFirstResponder()
        })
    }
    
    func hideSearchBar() {
        (navigationController as? ScrollingNavigationController)?.showNavbar(animated: true)
        isSearching = false
        tableView.tableHeaderView = savedHeaderView!
        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
        let moreB = UIBarButtonItem.init(customView: more)
        
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.sort(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 15, y: 0, width: 30, height: 30)
        let sortB = UIBarButtonItem.init(customView: sort)
        
        let search = UIButton.init(type: .custom)
        search.setImage(UIImage.init(named: "search")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        search.addTarget(self, action: #selector(self.search(_:)), for: UIControlEvents.touchUpInside)
        search.frame = CGRect.init(x: 15, y: 0, width: 30, height: 30)
        let searchB = UIBarButtonItem.init(customView: search)
        
        navigationItem.rightBarButtonItems = [moreB, sortB, searchB]
        
        navigationItem.titleView = savedTitleView
        
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSearchBar()
    }
    
    func sort(_ sender: AnyObject){
        let actionSheetController: UIAlertController = UIAlertController(title: "Default comment sorting", message: "", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        for c in CommentSort.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: c.description, style: .default)
            { action -> Void in
                self.sort = c
                self.refresh(self)
            }
            actionSheetController.addAction(saveActionButton)
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(LinkCellView.classForCoder(), forCellReuseIdentifier: "cell")
        self.tableView.register(LinkCellView.classForCoder(), forCellReuseIdentifier: "repcell")
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        if let navigationController = self.navigationController as? ScrollingNavigationController {
            print("Following scroll")
            navigationController.followScrollView(self.tableView, delay: 50.0)
        }
        
        searchBar.delegate = self
        searchBar.searchBarStyle = UISearchBarStyle.minimal
        searchBar.textColor = .white
        searchBar.showsCancelButton = true
        
        tableView.estimatedRowHeight = 400.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "Cell")
        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "Reply")
        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "MoreCell")
        
        tableView.separatorStyle = .none
        refreshControl.beginRefreshing()
        refresh(self)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    var hasDone = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if(hasSubmission && self.view.frame.size.width != 0 && !hasDone){
            headerCell = LinkCellView()
            headerCell?.delegate = self
            hasDone = true
            headerCell?.setLink(submission: submission!, parent: self, nav: self.navigationController)
            headerCell?.showBody(width: self.view.frame.size.width)
            self.tableView.tableHeaderView = UIView(frame: CGRect.init(x:0, y:0, width:self.tableView.frame.width, height:0.01))
            if let tableHeaderView = self.headerCell {
                var frame = CGRect.zero
                frame.size.width = self.tableView.bounds.size.width
                frame.size.height = tableHeaderView.estimateHeight()
                if self.tableView.tableHeaderView == nil || !frame.equalTo(tableHeaderView.frame) {
                    tableHeaderView.frame = frame
                    tableHeaderView.layoutIfNeeded()
                    let view = UIView(frame: tableHeaderView.frame)
                    view.addSubview(tableHeaderView)
                    self.tableView.tableHeaderView = view
                }
            }
            
        }
        
    }
    
    init(submission: RSubmission){
        self.submission = submission
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: submission.subreddit))
    }
    
    init(submission: String, subreddit: String?){
        self.submission = RSubmission()
        self.submission!.name = submission
        hasSubmission = false
        super.init(nibName: nil, bundle: nil)
        if(subreddit != nil){
            setBarColors(color: ColorUtil.getColorForSub(sub: subreddit!))
        }
    }
    
    init(submission: String, comment: String, context: Int, subreddit: String){
        self.submission = RSubmission()
        self.submission!.name = submission
        hasSubmission = false
        self.context = comment
        self.contextNumber = context
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = submission?.subreddit
        if(hasSubmission && !comments.isEmpty){
            self.setBarColors(color: ColorUtil.getColorForSub(sub: self.title!))
        }
        
        if(navigationController != nil){
            let more = UIButton.init(type: .custom)
            more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
            more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
            more.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            let moreB = UIBarButtonItem.init(customView: more)
            
            let sort = UIButton.init(type: .custom)
            sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
            sort.addTarget(self, action: #selector(self.sort(_:)), for: UIControlEvents.touchUpInside)
            sort.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            let sortB = UIBarButtonItem.init(customView: sort)
            
            let search = UIButton.init(type: .custom)
            search.setImage(UIImage.init(named: "search")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
            search.addTarget(self, action: #selector(self.search(_:)), for: UIControlEvents.touchUpInside)
            search.frame = CGRect.init(x: 0, y: 0, width: 30, height: 30)
            let searchB = UIBarButtonItem.init(customView: search)
            
            navigationItem.rightBarButtonItems = [moreB, sortB, searchB]
        }
        
        updateToolbar()
    }
    
    func showMenu(_ sender: AnyObject){
        let link = submission!
        let actionSheetController: UIAlertController = UIAlertController(title: link.title, message: "", preferredStyle: .actionSheet)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Refresh", style: .default) { action -> Void in
            self.refresh(self)
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Related submissions", style: .default) { action -> Void in
            let related = RelatedViewController.init(thing: self.submission!)
            self.show(related, sender: self)
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "View sub sidebar", style: .default) { action -> Void in
            self.displaySidebar()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Collapse child comments", style: .default) { action -> Void in
            self.collapseAll()
        }
        actionSheetController.addAction(cancelActionButton)
        
        self.present(actionSheetController, animated: true, completion: nil)
        
        
    }
    
    func doDisplaySidebar(_ sub: Subreddit){
        let alrController = UIAlertController(title: sub.displayName + "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", message: "\(sub.accountsActive) here now\n\(sub.subscribers) subscribers", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let margin:CGFloat = 8.0
        let rect = CGRect.init(x: margin, y: margin + 23, width: alrController.view.bounds.size.width - margin * 4.0, height: 300)
        let scrollView = UIScrollView(frame: rect)
        scrollView.backgroundColor = UIColor.clear
        var info: UZTextView = UZTextView()
        info = UZTextView(frame: CGRect(x: 0, y: 0, width: rect.size.width, height: CGFloat.greatestFiniteMagnitude))
        //todo info.delegate = self
        info.isUserInteractionEnabled = true
        info.backgroundColor = .clear
        
        if(!sub.description.isEmpty()){
            let html = sub.descriptionHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
            do {
                let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
                let attr2 = attr.reconstruct(with: font, color: UIColor.darkGray, linkColor: ColorUtil.accentColorForSub(sub: sub.displayName))
                let contentInfo = CellContent.init(string:attr2, width: rect.size.width)
                info.attributedString = contentInfo.attributedString
                info.frame.size.height = (contentInfo.textHeight)
                scrollView.contentSize = CGSize.init(width: rect.size.width, height: info.frame.size.height)
                scrollView.addSubview(info)
            } catch {
            }
            //todo parentController?.registerForPreviewing(with: self, sourceView: info)
        }
        
        alrController.view.addSubview(scrollView)
        
        let subscribed = sub.userIsSubscriber || subChanged && !sub.userIsSubscriber ? "Unsubscribe" : "Subscribe"
        var somethingAction = UIAlertAction(title: subscribed, style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in self.subscribe(sub)})
        alrController.addAction(somethingAction)
        
        somethingAction = UIAlertAction(title: "Submit a post", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in print("something")})
        alrController.addAction(somethingAction)
        
        somethingAction = UIAlertAction(title: "Subreddit moderators", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in print("something")})
        alrController.addAction(somethingAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
        
        alrController.addAction(cancelAction)
        
        self.present(alrController, animated: true, completion:{})
    }
    
    var subChanged = false
    func subscribe(_ sub: Subreddit){
        if(subChanged && !sub.userIsSubscriber || sub.userIsSubscriber){
            //was not subscriber, changed, and unsubscribing again
            Subscriptions.unsubscribe(sub.displayName, session: session!)
            subChanged = false
            self.view.makeToast("Unsubscribed", duration: 4, position: .bottom)
        } else {
            let alrController = UIAlertController.init(title: "Subscribe to \(sub.displayName)", message: nil, preferredStyle: .actionSheet)
            if(AccountController.isLoggedIn){
                let somethingAction = UIAlertAction(title: "Add to sub list and subscribe", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                    Subscriptions.subscribe(sub.displayName, true, session: self.session!)
                    self.subChanged = true
                    self.view.makeToast("Subscribed", duration: 4, position: .bottom)
                })
                alrController.addAction(somethingAction)
            }
            
            let somethingAction = UIAlertAction(title: "Add to sub list", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                Subscriptions.subscribe(sub.displayName, false, session: self.session!)
                self.subChanged = true
                self.view.makeToast("Added", duration: 4, position: .bottom)
            })
            alrController.addAction(somethingAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
            
            alrController.addAction(cancelAction)
            
            self.present(alrController, animated: true, completion:{})
            
        }
    }
    
    var subInfo: Subreddit?
    
    func displaySidebar(){
        do {
            try (UIApplication.shared.delegate as! AppDelegate).session?.about(submission!.subreddit, completion: { (result) in
                switch result {
                case .success(let r):
                    self.subInfo = r
                    DispatchQueue.main.async {
                        self.doDisplaySidebar(r)
                    }
                default:
                    DispatchQueue.main.async{
                        self.view.makeToast("Subreddit sidebar not found", duration: 5, position: .bottom)
                    }
                    break
                }
            })
        } catch {
        }
    }
    
    
    func search(_ sender: AnyObject){
        showSearchBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    public func extendKeepMore(in comment: Thing, current depth: Int) -> ([(Thing, Int)]) {
        var buf: [(Thing, Int)] = []
        
        if let comment = comment as? Comment {
            buf.append((comment, depth))
            for obj in comment.replies.children {
                buf.append(contentsOf: extendKeepMore(in: obj, current:depth + 1))
            }
        } else if let more = comment as? More {
            buf.append((more, depth))
        }
        return buf
    }
    
    
    func updateStrings(_ newComments: [(Thing, Int)]) -> [CellContent] {
        let width = self.view.frame.size.width
        let color = ColorUtil.accentColorForSub(sub: ((newComments[0].0 as! Comment).subreddit))
        return newComments.map { (thing: Thing, depth: Int) -> CellContent in
            if let comment = thing as? Comment {
                let html = comment.bodyHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
                do {
                    let attr = try NSMutableAttributedString(data: html.data(using: .unicode)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                    let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
                    let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: color)
                    return CellContent.init(string:attr2, width:(width - 25 - CGFloat(depth * 4)), hasRelies:false, id: comment.getId())
                } catch {
                    return CellContent(string:NSAttributedString(string: ""), width:width - 25, hasRelies:false, id: thing.getId())
                }
            } else {
                return CellContent(string:"more", width:width - 25, hasRelies:false, id: thing.getId())
            }
        }
    }
    
    func updateStringsSingle(_ newComments: [Object]) -> [CellContent] {
        let width = self.view.frame.size.width
        return newComments.map { (thing: Object) -> CellContent in
            if let comment = thing as? RComment {
                let html = comment.htmlText
                do {
                    let attr = try NSMutableAttributedString(data: html.data(using: .unicode)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                    let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
                    let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: UIColor.blue)
                    return CellContent.init(string:attr2, width:(width - 25) - CGFloat((cDepth[comment.getId()] as! Int) * 4), hasRelies:false, id: comment.getId())
                } catch {
                    return CellContent(string:NSAttributedString(string: ""), width:width - 25, hasRelies:false, id: comment.getId())
                }
            } else {
                let attr = NSMutableAttributedString(string: "more")
                let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: UIColor.blue)
                return CellContent.init(string:attr2, width:(width - 25), hasRelies:false, id: (thing as! RMore).getId())
            }
        }
    }
    
    func updateStringSearch(_ thing: Thing) -> CellContent {
        let width = self.view.frame.size.width
        if let comment = thing as? Comment {
            let html = comment.bodyHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
            do {
                let attr = try NSMutableAttributedString(data: html.data(using: .unicode)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                do {
                    let regex = try NSRegularExpression.init(pattern: ("\\b\(searchBar.text!)\\b"), options: .caseInsensitive)
                    
                    let substring = NSMutableAttributedString(string: searchBar.text!)
                    substring.addAttribute(NSForegroundColorAttributeName, value: ColorUtil.getColorForSub(sub: comment.subreddit), range: NSMakeRange(0, substring.string.length))
                    
                    regex.replaceMatches(in: attr.mutableString, options: NSRegularExpression.MatchingOptions.anchored, range: NSRange.init(location: 0, length: attr.length), withTemplate: substring.string)
                } catch {
                    print(error)
                }
                
                let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: UIColor.blue)
                
                return CellContent.init(string:attr2, width:(width - 25), hasRelies:false, id: comment.getId())
            } catch {
                return CellContent(string:NSAttributedString(string: ""), width:width - 25, hasRelies:false, id: thing.getId())
            }
        } else {
            let attr = NSMutableAttributedString(string: "more")
            let font = UIFont(name: ".SFUIText-Light", size: 16) ?? UIFont.systemFont(ofSize: 16)
            let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: UIColor.blue)
            return CellContent.init(string:attr2, width:(width - 25), hasRelies:false, id: thing.getId())
        }
    }
    
    func vote(_ direction: VoteDirection) {
        if let link = self.submission {
            do {
                try session?.setVote(direction, name: link.name, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let check):
                        print(check)
                    }
                })
            } catch { print(error) }
        }
    }
    
    
    func hide(_ hide: Bool) {
        if let link = self.submission {
            do {
                try session?.setHide(hide, name: link.name, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let check):
                        print(check)
                    }
                })
            } catch { print(error) }
        }
    }
    
    func downVote(_ sender: AnyObject?) {
        vote(.down)
    }
    
    func upVote(_ sender: AnyObject?) {
        vote(.up)
    }
    
    func cancelVote(_ sender: AnyObject?) {
        vote(.none)
    }
    
    func doHide(_ sender: AnyObject?) {
        hide(true)
    }
    
    func doUnhide(_ sender: AnyObject?) {
        hide(false)
    }
    
    func loadAll(_ sender: AnyObject){
        context = ""
        refreshControl.beginRefreshing()
        refresh(sender)
        updateToolbar()
    }
    
    var currentSort: CommentNavType = .PARENTS
    
    enum CommentNavType {
        case PARENTS
        case GILDED
        case OP
        case LINK
        case YOU
    }
    
    
    
    func goDown(_ sender: AnyObject){
        let topCell = (tableView.indexPathsForVisibleRows?[0].row)!
        for i in (topCell + 1)...dataArray.count - 1 {
            if(dataArray[i]  is RComment && matches(comment: dataArray[i] as! RComment, sort: currentSort)) {
                goToCell(i: i)
                break
            }
        }
    }
    
    func getCount(sort: CommentNavType) -> Int {
        var count = 0
        for comment in dataArray {
            if(comment is RComment && matches(comment: comment as! RComment, sort: sort)){
                count += 1
            }
        }
        return count
    }
    
    func showNavTypes(_ sender: AnyObject){
        let actionSheetController: UIAlertController = UIAlertController(title: "Navigation type", message: "", preferredStyle: .actionSheet)
        
        let link = getCount(sort: .LINK)
        let parents = getCount(sort: .PARENTS)
        let op = getCount(sort: .OP)
        let gilded = getCount(sort: .GILDED)
        let you = getCount(sort: .YOU)
        
        var cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Parent comment (\(parents))", style: .default) { action -> Void in
            self.currentSort = .PARENTS
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "OP (\(op))", style: .default) { action -> Void in
            self.currentSort = .OP
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Link (\(link))", style: .default) { action -> Void in
            self.currentSort = .LINK
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "You (\(you))", style: .default) { action -> Void in
            self.currentSort = .YOU
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Gilded (\(gilded))", style: .default) { action -> Void in
            self.currentSort = .GILDED
        }
        actionSheetController.addAction(cancelActionButton)
        
        
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func goToCell(i: Int){
        let indexPath = IndexPath.init(row: i, section: 0)
        self.tableView.scrollToRow(at: indexPath,
                                   at: UITableViewScrollPosition.top, animated: true)
        
    }
    
    func goUp(_ sender: AnyObject){
        let topCell = (tableView.indexPathsForVisibleRows?[0].row)!
        for i in stride(from: (topCell - 1) , to: -1, by: -1) {
            if(dataArray[i]  is RComment && matches(comment: dataArray[i] as! RComment, sort: currentSort)) {
                goToCell(i: i)
                break
            }
        }
    }
    
    func matches(comment: RComment, sort: CommentNavType) ->Bool{
        switch sort {
        case .PARENTS:
            if( cDepth[comment.getId()] as! Int == 1) {
                return true
            } else {
                return false
            }
        case .GILDED:
            if(comment.gilded > 0){
                return true
            } else {
                return false
            }
        case .OP:
            if(comment.author == submission?.author){
                return true
            } else {
                return false
            }
        case .LINK:
            if(comment.htmlText.contains("<a")){
                return true
            } else {
                return false
            }
        case .YOU:
            if(AccountController.isLoggedIn && comment.author == AccountController.currentName){
                return true
            } else {
                return false
            }
        }
        
    }
    
    func updateToolbar() {
        navigationController?.isToolbarHidden = false
        let space = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target: nil, action: nil)
        var items: [UIBarButtonItem] = []
        if(!context.isEmpty()){
            items.append(space)
            items.append(UIBarButtonItem.init(title: "Load full thread", style: .plain, target: self, action: #selector(CommentViewController.loadAll(_:))))
            items.append(space)
        } else {
            items.append(space)
            items.append(UIBarButtonItem(image: UIImage(named: "up")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(CommentViewController.goUp(_:))))
            items.append(space)
            items.append(UIBarButtonItem(image: UIImage(named: "nav")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(CommentViewController.showNavTypes(_:))))
            items.append(space)
            items.append(UIBarButtonItem(image: UIImage(named: "down")?.imageResize(sizeChange: CGSize.init(width: 30, height: 30)), style:.plain, target: self, action: #selector(CommentViewController.goDown(_:))))
            items.append(space)
        }
        self.toolbarItems = items
        navigationController?.toolbar.barTintColor = UIColor.black.withAlphaComponent(0.4)
        navigationController?.toolbar.tintColor = UIColor.white
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ?  self.filteredData.count : self.comments.count - self.hidden.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let datasetPosition = (indexPath as NSIndexPath).row;
        return isSearching ? filteredHeights[datasetPosition].textHeight : heightArray[datasetPosition].textHeight
    }
    
    func unhideAll(comment: Object, i : Int){
        let counter = unhideNumber(n: comment, iB: i)
        doArrays()
        //notify inserted to counter from i
        tableView.beginUpdates()
        
        var indexPaths : [IndexPath] = []
        for row in (i+1)...counter{
            indexPaths.append(IndexPath(row: row, section: 0))
        }
        tableView.insertRows(at: indexPaths, with: .middle)
        tableView.endUpdates()
    }
    
    func collapseAll(){
        for i in 0...dataArray.count - 1 {
            if(dataArray[i]  is RComment && matches(comment: dataArray[i] as! RComment, sort: .PARENTS)) {
                hideNumber(n: dataArray[i], iB: i)
                let t = dataArray[i]
                let id = (t is RComment) ? (t as! RComment).getId() : (t as! RMore).getId()
                if (!hiddenPersons.contains(id)) {
                    hiddenPersons.append(id);
                }
            }
        }
        doArrays()
        tableView.reloadData()
    }
    
    
    func hideAll(comment: Object, i: Int){
        let counter = hideNumber(n: comment, iB: i) - 1
        doArrays()
        tableView.beginUpdates()
        
        var indexPaths : [IndexPath] = []
        for row in i...counter {
            indexPaths.append(IndexPath(row: row, section: 0))
        }
        tableView.deleteRows(at: indexPaths, with: .middle)
        tableView.endUpdates()
        
        //notify inserted at i
    }
    
    func parentHidden(comment: Object)->Bool{
        var n: String = ""
        if(comment is RComment){
            n = (comment as! RComment).parentId
        } else {
            n = (comment as! RMore).parentId
        }
        return hiddenPersons.contains(n) || hidden.contains(n)
    }
    
    func walkTree(n: Object) -> [Object] {
        var toReturn: [Object] = []
        if n is RComment {
            let bounds = comments.index(where: { ($0 is RComment) && ($0 as! RComment).getId() == (n as! RComment).getId() })! + 1
            let parentDepth = (cDepth[(n as! RComment).getId()] as! Int)
            for obj in stride(from: bounds, to: comments.count, by: 1) {
                let current = comments[obj]
                let id = current is RComment ? (current as! RComment).getId() : (current as! RMore).getId()
                if((cDepth[id] as! Int) > parentDepth){
                    toReturn.append(current)
                } else {
                    return toReturn
                }
            }
        }
        return toReturn
    }
    
    func walkTreeFully(n: Object) -> [Object] {
        var toReturn: [Object] = []
        toReturn.append(n)
        if n is RComment {
            let bounds = comments.index(where: { ($0 is RComment) && ($0 as! RComment).getId() == (n as! RComment).getId() })! + 1
            let parentDepth = (cDepth[(n as! RComment).getId()] as! Int)
            for obj in stride(from: bounds, to: comments.count, by: 1) {
                let current = comments[obj]
                let id = current is RComment ? (current as! RComment).getId() : (current as! RMore).getId()
                let currentDepth = cDepth[id] as! Int
                if(currentDepth > parentDepth){
                    if(currentDepth == parentDepth + 1){
                        toReturn.append(contentsOf: walkTreeFully(n: current))
                    }
                } else {
                    return toReturn
                }
            }
        }
        return toReturn
    }
    
    func vote(comment: RComment,  dir: VoteDirection) {
        
        var direction = dir
        switch(ActionStates.getVoteDirection(s: comment)){
        case .up:
            if(dir == .up){
                direction = .none
            }
            break
        case .down:
            if(dir == .down){
                direction = .none
            }
            break
        default:
            break
        }
        do {
            try session?.setVote(direction, name: comment.name, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let check):
                    print(check)
                }
            })
        } catch { print(error) }
        ActionStates.setVoteDirection(s: comment, direction: direction)
    }
    
    func doDelete(comment: RComment, index: Int) {
        let alert = UIAlertController.init(title: "Really delete this comment?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .destructive, handler: { (action) in
            do{
                try self.session?.deleteCommentOrLink(comment.getId(), completion: { (result) in
                    DispatchQueue.main.async {
                        var realPosition = 0
                        for c in self.comments{
                            let id = c is RComment ? (c as! RComment).getId() : (c as! RMore).getId()
                            if(id == comment.getId()){
                                break
                            }
                            realPosition += 1
                        }
                        self.contents[realPosition].attributedString = NSAttributedString(string: "[deleted]")
                        self.doArrays()
                        self.tableView.reloadData()
                    }
                })
            } catch {
                
            }
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func edit(comment: RComment, index: Int) {
        let reply  = ReplyViewController.init(thing: comment, sub: (self.submission?.subreddit)!, editing: true) { (cr) in
            DispatchQueue.main.async(execute: { () -> Void in
                
                var realPosition = 0
                for c in self.comments{
                    let id = c is RComment ? (c as! RComment).getId() : (c as! RMore).getId()
                    if(id == comment.getId()){
                        break
                    }
                    realPosition += 1
                }
                let comment = RealmDataWrapper.commentToRComment(comment: cr!)
                self.dataArray.remove(at: index)
                self.dataArray.insert(comment, at: index)
                self.comments.remove(at: realPosition)
                self.comments.insert(comment, at: realPosition)
                self.heightArray.remove(at: index)
                self.heightArray.insert(contentsOf: self.updateStringsSingle([comment]), at: index)
                self.contents.remove(at: realPosition)
                self.contents.insert(contentsOf: self.updateStringsSingle([comment]), at: realPosition)
                self.doArrays()
                self.tableView.reloadData()
            })
        }
        
        let navEditorViewController: UINavigationController = UINavigationController(rootViewController: reply)
        self.prepareOverlayVC(overlayVC: navEditorViewController)
        self.present(navEditorViewController, animated: true, completion: nil)
    }
    
    
    let overlayTransitioningDelegate = OverlayTransitioningDelegate()
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        var toReturn: [BGTableViewRowActionWithImage] = []
        let cell = tableView.cellForRow(at: indexPath) as! CommentDepthCell
        let color = ColorUtil.getColorForSub(sub: (submission?.subreddit)!)
        if(cell.content! is RComment){
            let author = (cell.content as! RComment).author
            if(!(submission?.archived)! && AccountController.isLoggedIn && author != "[deleted]" && author != "[removed]"){
                let upimg = UIImage.init(named: "upvote")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
                let upvote = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: UIColor.init(hexString: "#FF9800"), image: upimg, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
                    tableView.setEditing(false, animated: true)
                    self.vote(comment: cell.content! as! RComment, dir: .up)
                    cell.refresh(comment: cell.content! as! RComment, submissionAuthor: (self.submission?.author)!)
                }
                toReturn.append(upvote!)
                
                let downimg = UIImage.init(named: "downvote")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
                let downvote = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: UIColor.init(hexString: "#2196F3"), image: downimg, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
                    tableView.setEditing(false, animated: true)
                    self.vote(comment: cell.content as! RComment, dir: .down)
                    cell.refresh(comment: cell.content as! RComment, submissionAuthor: (self.submission?.author)!)
                }
                toReturn.append(downvote!)
                
                if(author == AccountController.currentName){
                    let editimg = UIImage.init(named: "edit")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
                    let edit = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: color, image: editimg, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
                        tableView.setEditing(false, animated: true)
                        self.edit(comment: cell.content as! RComment, index: (indexPath?.row)!)
                    }
                    toReturn.append(edit!)
                    let deleteimg = UIImage.init(named: "delete")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
                    let delete = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: GMColor.red500Color(), image: deleteimg, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
                        tableView.setEditing(false, animated: true)
                        self.doDelete(comment: cell.content as! RComment, index: (indexPath?.row)!)
                    }
                    toReturn.append(delete!)
                }
                if(!(submission?.locked)!){
                    let rep = UIImage.init(named: "reply")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
                    let reply = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: color, image: rep, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
                        tableView.setEditing(false, animated: true)
                        
                        let c = tableView.dequeueReusableCell(withIdentifier: "Reply", for: indexPath!) as! CommentDepthCell
                        self.isReply = true
                        let text = self.isSearching ? self.filteredHeights[indexPath!.row] :  self.heightArray[indexPath!.row]
                        c.textView.attributedString = text.attributedString
                        c.textView.frame.size.height = text.textHeight
                        let gid = self.dataArray[indexPath!.row]
                        let id = gid is RComment ? (gid as! RComment).getId() : (gid as! RMore).getId()
                        c.setComment(comment: self.dataArray[indexPath!.row] as! RComment, depth: self.cDepth[id] as! Int, parent: self, hiddenCount: 0, date: self.lastSeen, author: self.submission?.author)
                        
                        let reply  = ReplyViewController.init(thing: cell.content!, sub: (self.submission?.subreddit)!, view: c.contentView) { (comment) in
                            DispatchQueue.main.async(execute: { () -> Void in
                                let startDepth = self.cDepth[cell.comment!.getId()] as! Int + 1
                                
                                let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!)]
                                self.cDepth[comment!.getId()] = startDepth
                                
                                
                                var realPosition = 0
                                for c in self.comments{
                                    let id = c is RComment ? (c as! RComment).getId() : (c as! RMore).getId()
                                    if(id == cell.comment!.getId()){
                                        break
                                    }
                                    realPosition += 1
                                }
                                
                                self.dataArray.insert(contentsOf: queue, at: (indexPath?.row)! + 1)
                                self.comments.insert(contentsOf: queue, at: realPosition + 1)
                                self.heightArray.insert(contentsOf: self.updateStringsSingle(queue), at: (indexPath?.row)! + 1)
                                self.contents.insert(contentsOf: self.updateStringsSingle(queue), at: realPosition + 1)
                                self.doArrays()
                                self.isReply = false
                                self.tableView.reloadData()
                            })
                        }
                        
                        let navEditorViewController: UINavigationController = UINavigationController(rootViewController: reply)
                        self.prepareOverlayVC(overlayVC: navEditorViewController)
                        self.present(navEditorViewController, animated: true, completion: nil)
                        
                    }
                    toReturn.append(reply!)
                    
                }
            }
            let mor = UIImage.init(named: "ic_more_vert_white")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
            let more = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: color, image: mor, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
                tableView.setEditing(false, animated: true)
                self.moreComment(cell.content as! RComment)
            }
            toReturn.append(more!)
        }
        return toReturn
    }
    
    func moreComment(_ comment: RComment){
        let alertController = UIAlertController(title: "Comment by /u/\(comment.author)", message: "", preferredStyle: .actionSheet)
        
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        
        alertController.addAction(cancelActionButton)
        
        let profile: UIAlertAction = UIAlertAction(title: "/u/\(comment.author)'s profile", style: .default) { action -> Void in
            self.show(ProfileViewController.init(name: comment.author), sender: self)
        }
        
        alertController.addAction(profile)
        if(AccountController.isLoggedIn){
            
            let save: UIAlertAction = UIAlertAction(title: "Save", style: .default) { action -> Void in
                self.saveComment(comment)
            }
            
            alertController.addAction(save)
        }
        
        let report: UIAlertAction = UIAlertAction(title: "Report", style: .default) { action -> Void in
            self.report(comment)
        }
        
        alertController.addAction(report)
        
        
        parent?.present(alertController, animated: true, completion: nil)
    }
    
    
    private func prepareOverlayVC(overlayVC: UIViewController) {
        overlayVC.transitioningDelegate = overlayTransitioningDelegate
        overlayVC.modalPresentationStyle = .custom
    }
    
    func unhideNumber(n: Object, iB: Int) -> Int{
        var i = iB
        let children = walkTree(n: n);
        for ignored in children {
            let parentHidden = self.parentHidden(comment: ignored)
            if(parentHidden){
                continue
            }
            
            let name = ignored is RComment ? (ignored as! RComment).getId() : (ignored as! RMore).getId()
            
            if(hidden.contains(name) || hiddenPersons.contains(name)){
                hidden.remove(at: hidden.index(of: name)!)
                i += 1
            }
            i += unhideNumber(n: ignored, iB: 0)
        }
        return i
    }
    
    func hideNumber(n: Object, iB : Int) -> Int{
        var i = iB
        
        let children = walkTree(n: n);
        let id = n is RComment ? (n as! RComment).getId() : (n as! RMore).getId()
        
        for ignored in children {
            let name = ignored is RComment ? (ignored as! RComment).getId() : (ignored as! RMore).getId()
            if(id != name){
                
                let fullname = name
                
                if(!hidden.contains(fullname)){
                    i += 1
                    hidden.append(fullname)
                }
            }
            i += hideNumber(n: ignored, iB: 0)
            
        }
        return i
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = nil
        
        
        if contents.indices ~= (indexPath as NSIndexPath).row {
            
            let datasetPosition = (indexPath as NSIndexPath).row;
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
            if let cell = cell as? CommentDepthCell {
                cell.delegate = self
                let thing = isSearching ? filteredData[datasetPosition] : dataArray[datasetPosition]
                if(thing is RComment){
                    let text = isSearching ? filteredHeights[datasetPosition] :  heightArray[datasetPosition]
                    cell.textView.attributedString = text.attributedString
                    cell.textView.frame.size.height = text.textHeight
                    var count = 0
                    if(hiddenPersons.contains((thing as! RComment).getId())){
                        count = getChildNumber(n: thing as! RComment)
                    }
                    cell.setComment(comment: thing as! RComment, depth: cDepth[(thing as! RComment).getId()] as! Int, parent: self, hiddenCount: count, date: lastSeen, author: submission?.author)
                } else {
                    cell.setMore(more: (thing as! RMore), depth: cDepth[(thing as! RMore).getId()] as! Int)
                }
                cell.content = thing
                if(((thing is RComment) ? (thing as! RComment).getId() : (thing as! RMore).getId()).contains(context) && !context.isEmpty()){
                    cell.setIsContext()
                }
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
            return cell
        }
    }
    
    
    
    func getChildNumber(n: RComment) -> Int{
        let children = walkTreeFully(n: n);
        return children.count - 1
    }
    
    func highlight(_ cc: CellContent) -> CellContent {
        let base = NSMutableAttributedString.init(attributedString: cc.attributedString)
        let r = base.mutableString.range(of: "\(searchBar.text!)", options: .caseInsensitive, range: NSMakeRange(0, base.string.length))
        if r.length > 0 {
            print("Range found")
            base.addAttribute(NSForegroundColorAttributeName, value: ColorUtil.getColorForSub(sub: ""), range: r)
        } else {
            print("Not found")
        }
        return CellContent.init(string: base.attributedSubstring(from: NSRange.init(location: 0, length: base.length)), width: cc.width, hasRelies: false, id: cc.id)
    }
    
    var isSearching  = false
    
    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String)
    {
        filteredData = []
        filteredHeights = []
        if(textSearched.length != 0) {
            isSearching = true
            searchTableList()
        }
        else {
            isSearching = false
        }
        tableView.reloadData()
    }
    
    func searchTableList(){
        let searchString = searchBar.text
        var count = 0
        for s in dataArray {
            if(s is RComment){
                if ((s as! RComment).htmlText.localizedCaseInsensitiveContains(searchString!)) {
                    filteredData.append(s)
                    filteredHeights.append(highlight(heightArray[count]))
                }
            }
            count += 1
        }
    }
    
    var isReply = false
    
    func pushedSingleTap(_ cell: CommentDepthCell){
        if(!isReply){
            if(isSearching){
                hideSearchBar()
                context = (cell.content as! RComment).getId()
                var index = 0
                if(!self.context.isEmpty()){
                    for comment in self.dataArray {
                        if((comment as! RComment).getId().contains(self.context)){
                            self.goToCell(i: index)
                            break
                        } else {
                            index += 1
                        }
                    }
                }
                
            } else {
                if let comment = cell.content as? RComment {
                    let row = tableView.indexPath(for: cell)?.row
                    let id = comment.getId()
                    if(hiddenPersons.contains((id))) {
                        hiddenPersons.remove(at: hiddenPersons.index(of: id)!)
                        unhideAll(comment: comment, i: row!)
                        cell.expand()
                        //todo hide child number
                    } else {
                        let childNumber = getChildNumber(n: comment );
                        if (childNumber > 0) {
                            hideAll(comment: comment, i: row! + 1);
                            if (!hiddenPersons.contains(id)) {
                                hiddenPersons.append(id);
                            }
                            if (childNumber > 0) {
                                cell.collapse(childNumber: childNumber)
                            }
                        }
                    }
                } else {
                    let datasetPosition = tableView.indexPath(for: cell)!.row
                    if let more = dataArray[datasetPosition] as? RMore, let link = self.submission {
                        do {
                            var strings: [String] = []
                            for c in more.children {
                                strings.append(c.value)
                            }
                            try session?.getMoreChildren(strings, name: link.name, sort:.new, id: more.id, completion: { (result) -> Void in
                                switch result {
                                case .failure(let error):
                                    print(error)
                                case .success(let list):
                                    
                                    DispatchQueue.main.async(execute: { () -> Void in
                                        let startDepth = self.cDepth[more.getId()] as! Int
                                        
                                        var queue: [Object] = []
                                        for child in list {
                                            let incoming = self.extendKeepMore(in: child, current: startDepth)
                                            for i in incoming{
                                                queue.append(i.0 is Comment ? RealmDataWrapper.commentToRComment(comment: i.0 as! Comment) : RealmDataWrapper.moreToRMore(more: i.0 as! More))
                                                self.cDepth[i.0.getId()] = i.1
                                            }
                                        }
                                        
                                        var realPosition = 0
                                        for comment in self.comments{
                                            let id = comment is RComment ? (comment as! RComment).getId() : (comment as! RMore).getId()
                                            if(id == more.getId()){
                                                break
                                            }
                                            realPosition += 1
                                        }
                                        
                                        
                                        self.comments.remove(at: realPosition)
                                        self.dataArray.remove(at: datasetPosition)
                                        self.contents.remove(at: realPosition)
                                        self.heightArray.remove(at: datasetPosition)
                                        
                                        if(queue.count != 0){
                                            
                                            self.dataArray.insert(contentsOf: queue, at: datasetPosition)
                                            self.comments.insert(contentsOf: queue, at: realPosition)
                                            self.heightArray.insert(contentsOf: self.updateStringsSingle(queue), at: datasetPosition)
                                            self.contents.insert(contentsOf: self.updateStringsSingle(queue), at: realPosition)
                                            self.doArrays()
                                            self.tableView.reloadData()
                                            
                                        } else {
                                            self.doArrays()
                                            self.tableView.reloadData()
                                        }
                                    })
                                    
                                }
                            })
                        } catch { print(error) }
                    }
                    
                }
            }
        }
    }
}

extension Thing {
    func getId() -> String{
        return Self.kind + "_" + id
    }
}

extension UIImage {
    
    func imageResize (sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
}


extension UISearchBar {
    
    var textColor:UIColor? {
        get {
            if let textField = self.value(forKey: "searchField") as? UITextField  {
                return textField.textColor
            } else {
                return nil
            }
        }
        
        set (newValue) {
            if let textField = self.value(forKey: "searchField") as? UITextField  {
                textField.textColor = newValue
            }
        }
    }
}
