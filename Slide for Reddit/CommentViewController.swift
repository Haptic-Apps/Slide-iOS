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
import TTTAttributedLabel
import RealmSwift
import MaterialComponents.MaterialSnackbar
import MaterialComponents.MDCActivityIndicator

class CommentViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource, UZTextViewCellDelegate, LinkCellViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, TTTAttributedLabelDelegate, ReplyDelegate {
    
    func replySent(comment: Comment?) {
        if(comment != nil){
            let cell = tableView.cellForRow(at: IndexPath.init(row: menuIndex - 1, section: 0)) as! CommentDepthCell
        DispatchQueue.main.async(execute: { () -> Void in
            let startDepth = self.cDepth[cell.comment!.getIdentifier()] as! Int + 1
            
            let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!, depth: startDepth)]
            self.cDepth[comment!.getId()] = startDepth
            
            
            var realPosition = 0
            for c in self.comments{
                let id = c
                if(id == cell.comment!.getIdentifier()){
                    break
                }
                realPosition += 1
            }
            self.hideCommentMenu(cell)
            
            var ids : [String] = []
            for item in queue {
                let id = item.getIdentifier()
                ids.append(id)
                self.content[id] = item
            }
            self.dataArray.insert(contentsOf: ids, at: self.menuIndex)
            self.comments.insert(contentsOf: ids, at: realPosition + 1)
            self.updateStringsSingle(queue)
            self.doArrays()
            self.isReply = false
            self.tableView.reloadData()
            self.tableView.endEditing(true)
        })
        }
    }
    
    func openComments(id: String) {
        //don't do anything
    }
    
    func editSent(cr: Comment?){
        if(cr != nil){
            DispatchQueue.main.async(execute: { () -> Void in
                var realPosition = 0
                var comment = (self.tableView.cellForRow(at: IndexPath.init(row: self.menuIndex - 1, section: 0)) as! CommentDepthCell).content as! RComment
                for c in self.comments{
                    let id = c
                    if(id == comment.getIdentifier()){
                        break
                    }
                    realPosition += 1
                }
                comment = RealmDataWrapper.commentToRComment(comment: cr!, depth: 0)
                self.dataArray.remove(at: self.menuIndex - 1)
                self.dataArray.insert(comment.getIdentifier(), at: self.menuIndex - 1)
                self.comments.remove(at: realPosition)
                self.comments.insert(comment.getIdentifier(), at: realPosition)
                self.content[comment.getIdentifier()] = comment
                self.updateStringsSingle([comment])
                self.doArrays()
                self.tableView.reloadData()
                self.discard()
            })

        }
    }
    
    func updateHeight(textView: UITextView) {
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    func discard() {
        self.tableView.endEditing(true)
        tableView.beginUpdates()
        replyShown = false
        tableView.reloadRows(at: [IndexPath.init(row: menuIndex, section: 0)], with: .automatic)
        tableView.endUpdates()
    }
    
    internal func pushedMoreButton(_ cell: CommentDepthCell) {
        
    }
    func save(_ cell: LinkCellView) {
        do {
            let state = !ActionStates.isSaved(s: cell.link!)
            print(cell.link!.id)
            try session?.setSave(state, name: (cell.link?.id)!, completion: { (result) in
                if(result.error != nil){
                    print(result.error!)
                }
                DispatchQueue.main.async{
                    let message = MDCSnackbarMessage()
                    message.text = state ? "Saved" : "Unsaved"
                    message.duration = 3
                    MDCSnackbarManager.show(message)
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
            try session?.setSave(state, name: comment.id, completion: { (result) in
                DispatchQueue.main.async{
                    let message = MDCSnackbarMessage()
                    message.text = state ? "Saved" : "Unsaved"
                    message.duration = 3
                    MDCSnackbarManager.show(message)
                }
            })
            ActionStates.setSaved(s: comment, saved: !ActionStates.isSaved(s: comment))
        } catch {
            
        }
    }
    
    var searchBar = UISearchBar()
    var menu : CommentMenuCell?
    var reply: ReplyCellView?
    var menuShown = false
    var menuIndex = 0
    var replyShown = false
    var menuId = ""
    
    func hide(_ cell: LinkCellView){
        
    }
    func reply(_ cell: LinkCellView) {
        print("Replying")
        
        let c = LinkCellView()
        c.del = self
        c.aspectWidth = self.tableView.bounds.size.width
        c.setLink(submission: self.submission!, parent: self, nav: self.navigationController, baseSub: self.submission!.subreddit)
        c.showBody(width: self.view.frame.size.width)
        c.frame = (tableView.tableHeaderView?.frame)!
        c.layoutIfNeeded()
        
        let reply  = ReplyViewController.init(thing: self.submission!, sub: (self.submission?.subreddit)!, view: c.contentView) { (comment) in
            DispatchQueue.main.async(execute: { () -> Void in
                let startDepth = 0
                
                let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!, depth: 0)]
                self.cDepth[comment!.getId()] = startDepth
                
                var ids : [String] = []
                for item in queue {
                    let id = (item is RComment) ? (item as! RComment).getIdentifier() : (item as! RMore).getIdentifier()
                    ids.append(id)
                    self.content[id] = item
                }

                self.dataArray.insert(contentsOf: ids, at: 0)
                self.comments.insert(contentsOf: ids, at: 0)
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
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name:  (cell.link?.id)!, completion: { (result) in
                
            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {
            
        }
    }
    
    
    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.id)!, completion: { (result) in
                
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
        
        let open = OpenInChromeController.init()
        if(open.isChromeInstalled()){
            cancelActionButton = UIAlertAction(title: "Open in Chrome", style: .default) { action -> Void in
                open.openInChrome(link.url!, callbackURL: nil, createNewTab: true)
            }
            actionSheetController.addAction(cancelActionButton)
        }
        
        cancelActionButton = UIAlertAction(title: "Open in Safari", style: .default) { action -> Void in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(link.url!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(link.url!)
            }
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
        
        actionSheetController.modalPresentationStyle = .popover
        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = cell.contentView
            presenter.sourceRect = cell.contentView.bounds
        }
        

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
                let name = (thing is RComment) ? (thing as! RComment).id : (thing as! RSubmission).id
                try self.session?.report(name, reason: (textField?.text!)!, otherReason: "", completion: { (result) in
                    DispatchQueue.main.async{
                        let message = MDCSnackbarMessage()
                        message.text = "Report sent"
                        MDCSnackbarManager.show(message)
                    }
                })
            } catch {
                DispatchQueue.main.async{
                    let message = MDCSnackbarMessage()
                    message.text = "Error sending report. Try again later"
                    MDCSnackbarManager.show(message)
                }
            }
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        alert.modalPresentationStyle = .popover
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = self.headerCell!.contentView
            presenter.sourceRect = self.headerCell!.contentView.bounds
        }

        self.present(alert, animated: true, completion: nil)
    }
    
    var submission: RSubmission? = nil
    var session: Session? = nil
    var cDepth: NSMutableDictionary = NSMutableDictionary()
    var comments: [String] = []
    var hiddenPersons = Set<String>()
    var hidden: Set<String> = Set<String>()
    weak var tableView : UITableView!
    var headerCell : LinkCellView?
    var hasSubmission = true
    var paginator: Paginator? = Paginator()
    var refreshControl: UIRefreshControl!
    var context: String = ""
    var contextNumber: Int = 3
    
    var dataArray: [String] = []
    var filteredData: [String] = []
    var content: [String: Object] = [:]
    
    func doArrays(){
        dataArray = comments.filter({ (s) -> Bool in
            !hidden.contains(s)
        })
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
    
    func getSelf() -> CommentViewController {
        return self;
    }
    
    func refresh(_ sender:AnyObject) {
        session = (UIApplication.shared.delegate as! AppDelegate).session
        if let link = self.submission {
            sub = link.subreddit
            self.navigationItem.title = link.subreddit
            if(Subscriptions.isSubscriber(link.subreddit)){
                doSubbed()
            }

            do {
                try session?.getArticles(link.name, sort:sort, comments:(context.isEmpty ? nil : [context]), context: 3, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error)
                        print("Getting realm data")
                        DispatchQueue.main.async {

                            self.loaded = true
                        do {
                            let realm = try Realm()
                            if let listing =  realm.objects(RSubmission.self).filter({ (item) -> Bool in
                                return item.id == self.submission!.id
                            }).first{
                                
                                self.comments = []
                                self.hiddenPersons = []
                                var temp : [Object] = []
                                self.hidden = []
                                self.text = [:]
                                self.refreshControl.endRefreshing()
                                self.indicator?.stopAnimating()

                                    for child in listing.comments {
                                        temp.append(child)
                                        self.content[child.getIdentifier()] = child
                                        self.comments.append(child.getIdentifier())
                                        self.cDepth[child.getIdentifier()] = child.depth
                                    }
                                if(!self.comments.isEmpty){
                                    self.updateStringsSingle(temp)
                                    var time = timeval(tv_sec: 0, tv_usec: 0)
                                    gettimeofday(&time, nil)
                                    
                                    self.doArrays()
                                    self.lastSeen = (self.context.isEmpty ? History.getSeenTime(s: link) :  Double(0))
                                    
                                        self.tableView.beginUpdates()
                                        let range = NSMakeRange(0, self.tableView.numberOfRows(inSection: 0))
                                        let sections = NSIndexSet(indexesIn: range)
                                        self.tableView.reloadSections(sections as IndexSet, with: .automatic)
                                        self.tableView.endUpdates()
                                }
                            }
                        } catch {
                            
                        }
                            
                            self.refreshControl.endRefreshing()
                            self.indicator?.stopAnimating()
                            
                            if(self.comments.isEmpty){
                                let message = MDCSnackbarMessage()
                                message.text = "No cached comments found"
                                MDCSnackbarManager.show(message)
                            } else {
                                let message = MDCSnackbarMessage()
                                message.text = "Showing cached comments"
                                MDCSnackbarManager.show(message)
                            }
                        }
                        break
                    case .success(let tuple):
                        let startDepth = 1
                        let listing = tuple.1
                        self.comments = []
                        self.hiddenPersons = []
                        self.hidden = []
                        self.text = [:]
                        self.content = [:]
                        self.loaded = true
                        self.submission = RealmDataWrapper.linkToRSubmission(submission: tuple.0.children[0] as! Link)
                        
                        DispatchQueue.global().async(execute: { () -> Void in
                            var allIncoming: [(Thing, Int)] = []
                            self.submission!.comments.removeAll()
                            for child in listing.children {
                                let incoming = self.extendKeepMore(in: child, current: startDepth)
                                allIncoming.append(contentsOf: incoming)
                                for i in incoming{
                                    let item = RealmDataWrapper.commentToRealm(comment: i.0, depth: i.1)
                                    self.content[item.getIdentifier()] = item
                                    self.comments.append(item.getIdentifier())
                                    if(item is RComment){
                                        self.submission!.comments.append(item as! RComment)
                                    }
                                    self.cDepth[i.0.getId()] = i.1
                                }
                            }
                            
                            var time = timeval(tv_sec: 0, tv_usec: 0)
                            gettimeofday(&time, nil)
                            if(!allIncoming.isEmpty){
                                self.updateStrings(allIncoming)
                            }
                            self.paginator = listing.paginator
                            
                            if(!self.comments.isEmpty){
                            do {
                                let realm = try! Realm()
                                //todo insert
                                realm.beginWrite()
                                for comment in self.comments {
                                    realm.create(type(of: self.content[comment]!), value: self.content[comment]!, update: true)
                                    if(self.content[comment]! is RComment){
                                    self.submission!.comments.append(self.content[comment] as! RComment)
                                    }
                                }
                                self.submission!.comments.removeAll()
                                realm.create(type(of: self.submission!), value: self.submission!, update: true)
                                try realm.commitWrite()
                            } catch {
                                
                            }
                            }
                            self.doArrays()
                            self.lastSeen = (self.context.isEmpty ? History.getSeenTime(s: self.submission!) :  Double(0))
                            DispatchQueue.main.async(execute: { () -> Void in
                                History.setComments(s: link)
                                History.addSeen(s: link)
                                if(!self.hasSubmission){
                                    self.headerCell = LinkCellView()
                                    self.headerCell?.del = self
                                    self.headerCell?.parentViewController = self
                                    self.hasDone = true
                                    self.headerCell?.aspectWidth = self.tableView.bounds.size.width
                                    self.headerCell?.setLink(submission: self.submission!, parent: self, nav: self.navigationController, baseSub: self.submission!.subreddit)
                                    self.headerCell?.showBody(width: self.view.frame.size.width)
                                    self.tableView.tableHeaderView = UIView(frame: CGRect.init(x:0, y:0, width:self.tableView.frame.width, height:0.01))
                                    if let tableHeaderView = self.headerCell {
                                        var frame = CGRect.zero
                                        frame.size.width = self.tableView.bounds.size.width
                                        frame.size.height = tableHeaderView.estimateHeight(true)
                                        if self.tableView.tableHeaderView == nil || !frame.equalTo(tableHeaderView.frame) {
                                            tableHeaderView.frame = frame
                                            tableHeaderView.layoutIfNeeded()
                                            let view = UIView(frame: tableHeaderView.frame)
                                            view.addSubview(tableHeaderView)
                                            self.tableView.tableHeaderView = view
                                        }
                                    }
                                    self.navigationItem.title = self.submission!.subreddit
                                    self.navigationItem.backBarButtonItem?.title = ""
                                    self.setBarColors(color: ColorUtil.getColorForSub(sub: self.navigationItem.title!))
                                } else {
                                    self.headerCell?.refreshLink(self.submission!)
                                    self.headerCell?.showBody(width: self.view.frame.size.width)
                                }
                                self.refreshControl.endRefreshing()
                                self.indicator?.stopAnimating()
                                self.tableView.reloadData(with: .fade)
                                if(SettingValues.collapseDefault && self.context.isEmpty()){
                                    self.collapseAll()
                                }
                                
                                var index = 0
                                if(!self.context.isEmpty()){
                                    for comment in self.comments {
                                        if(comment.contains(self.context)){
                                            self.goToCell(i: index)
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                                self.showCommentMenu(self.tableView.cellForRow(at: IndexPath.init(row: index, section: 0)) as! CommentDepthCell)
                                            }
                                            break
                                        } else {
                                            index += 1
                                        }
                                    }
                                }
                            })


                        })
                    }
                })
            } catch { print(error) }
        }
    }
    
    var loaded = false
    
    var lastSeen: Double = NSDate().timeIntervalSince1970
    var savedTitleView: UIView?
    var savedHeaderView: UIView?
    
    override var navigationItem: UINavigationItem {
        if(parent != nil && parent! is PagingCommentViewController){
            return parent!.navigationItem
        } else {
            return super.navigationItem
        }
    }
    
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
        navigationController?.setNavigationBarHidden(true, animated: true)
        isSearching = false
        tableView.tableHeaderView = savedHeaderView!
        let more = UIButton.init(type: .custom)
        more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
        more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
        more.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let moreB = UIBarButtonItem.init(customView: more)
        
        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.sort(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let sortB = UIBarButtonItem.init(customView: sort)
        
        let search = UIButton.init(type: .custom)
        search.setImage(UIImage.init(named: "search")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        search.addTarget(self, action: #selector(self.search(_:)), for: UIControlEvents.touchUpInside)
        search.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
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
        
        actionSheetController.modalPresentationStyle = .formSheet
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    var indicator: MDCActivityIndicator? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsetsMake(56, 0, 45, 0)
        self.tableView.register(CommentMenuCell.classForCoder(), forCellReuseIdentifier: "menu")
        self.tableView.register(ReplyCellView.classForCoder(), forCellReuseIdentifier: "dreply")
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: nil, action: nil)

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
        self.menu = self.tableView.dequeueReusableCell(withIdentifier: "menu") as? CommentMenuCell
        self.reply = self.tableView.dequeueReusableCell(withIdentifier: "dreply") as? ReplyCellView
        
        if(single){
        refresh(self)
        }
       
    }
    
    var single = true
    var hasDone = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if(hasSubmission && self.view.frame.size.width != 0 && !hasDone){
            headerCell = LinkCellView()
            headerCell?.del = self
            self.headerCell?.parentViewController = self
            hasDone = true
            headerCell?.aspectWidth = self.tableView.bounds.size.width
            headerCell?.setLink(submission: submission!, parent: self, nav: self.navigationController, baseSub: submission!.subreddit)
            headerCell?.showBody(width: self.view.frame.size.width)
            self.tableView.tableHeaderView = UIView(frame: CGRect.init(x:0, y:0, width:self.tableView.frame.width, height:0.01))
            if let tableHeaderView = self.headerCell {
                var frame = CGRect.zero
                frame.size.width = self.tableView.bounds.size.width
                frame.size.height = tableHeaderView.estimateHeight(true)
                if self.tableView.tableHeaderView == nil || !frame.equalTo(tableHeaderView.frame) {
                    tableHeaderView.frame = frame
                    tableHeaderView.layoutIfNeeded()
                    let view = UIView(frame: tableHeaderView.frame)
                    view.addSubview(tableHeaderView)
                    self.tableView.tableHeaderView = view
                }
            }

        }
        if(indicator == nil){
            if(hasSubmission){
                indicator = MDCActivityIndicator.init(frame: CGRect.init(x: CGFloat(0), y: CGFloat(0), width: CGFloat(80), height: CGFloat(80)))
                indicator?.strokeWidth = 5
                indicator?.radius = 20
                indicator?.indicatorMode = .indeterminate
                indicator?.cycleColors = [ColorUtil.getColorForSub(sub: submission?.subreddit ?? ""), ColorUtil.accentColorForSub(sub: submission?.subreddit ?? "")]
                let center = CGPoint.init(x: self.tableView.center.x, y: CGFloat(tableView.bounds.height - 200))
                indicator?.center = center
                self.tableView.addSubview(indicator!)
                indicator?.startAnimating()
                
            } else {
                indicator = MDCActivityIndicator.init(frame: CGRect.init(x: CGFloat(0), y: CGFloat(0), width: CGFloat(80), height: CGFloat(80)))
                indicator?.strokeWidth = 5
                indicator?.radius = 20
                indicator?.indicatorMode = .indeterminate
                indicator?.cycleColors = [ColorUtil.getColorForSub(sub: submission?.subreddit ?? ""), ColorUtil.accentColorForSub(sub: submission?.subreddit ?? "")]
                let center = CGPoint.init(x: self.tableView.center.x, y: self.tableView.center.y)
                indicator?.center = center
                self.tableView.addSubview(indicator!)
                indicator?.startAnimating()
                
            }
        }

    }
    
    init(submission: RSubmission, single: Bool){
        self.submission = submission
        self.single = single
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: submission.subreddit))
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
        self.submission!.subreddit = subreddit
        hasSubmission = false
        self.context = comment
        print("Context is \(context)")
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
        (navigationController)?.setNavigationBarHidden(false, animated: false)
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true

        if(navigationController != nil){
        self.updateToolbar()
        }
        navigationItem.title = submission?.subreddit
        self.navigationItem.backBarButtonItem?.title = ""

        if(submission != nil){
            self.setBarColors(color: ColorUtil.getColorForSub(sub: self.navigationItem.title!))
        }
        
        if(navigationController != nil){
            let more = UIButton.init(type: .custom)
            more.setImage(UIImage.init(named: "ic_more_vert_white"), for: UIControlState.normal)
            more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
            more.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let moreB = UIBarButtonItem.init(customView: more)
            
            let sort = UIButton.init(type: .custom)
            sort.setImage(UIImage.init(named: "ic_sort_white"), for: UIControlState.normal)
            sort.addTarget(self, action: #selector(self.sort(_:)), for: UIControlEvents.touchUpInside)
            sort.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let sortB = UIBarButtonItem.init(customView: sort)
            
            let search = UIButton.init(type: .custom)
            search.setImage(UIImage.init(named: "search")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
            search.addTarget(self, action: #selector(self.search(_:)), for: UIControlEvents.touchUpInside)
            search.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let searchB = UIBarButtonItem.init(customView: search)
            
            navigationItem.rightBarButtonItems = [moreB, sortB, searchB]
            navigationItem.rightBarButtonItem?.imageInsets = UIEdgeInsetsMake(0, 0, 0, -20)
            doSubbed()
            

        }

    }

    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if(UIScreen.main.traitCollection.userInterfaceIdiom == .pad && Int(round(self.view.bounds.width / CGFloat(320))) > 1 && false){
            self.navigationController!.view.backgroundColor = .clear
        }
    }
    

    var duringAnimation = false
    var interactionController : UIPercentDrivenInteractiveTransition?

    
    
    func doSubbed(){
        let close = UIButton.init(type: .custom)
        close.setImage(UIImage.init(named: "close")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        close.addTarget(self, action: #selector(self.close(_:)), for: UIControlEvents.touchUpInside)
        close.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let closeB = UIBarButtonItem.init(customView: close)
        

        if(!Subscriptions.isSubscriber((submission?.subreddit)!)){

        let sub = UIButton.init(type: .custom)
            sub.setImage(UIImage.init(named: "addcircle")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25)), for: UIControlState.normal)
        sub.addTarget(self, action: #selector(self.subscribeSingle(_:)), for: UIControlEvents.touchUpInside)
        sub.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let subB = UIBarButtonItem.init(customView: sub)
            navigationItem.leftBarButtonItems = [closeB, subB]

        } else {
            navigationItem.leftBarButtonItems = [closeB]
        }
    }
    
    func close(_ sender: AnyObject){
        if(self.navigationController?.viewControllers.count == 1){
            self.navigationController?.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
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
            Sidebar.init(parent: self, subname: self.submission!.subreddit).displaySidebar()
        }
        actionSheetController.addAction(cancelActionButton)
        
        cancelActionButton = UIAlertAction(title: "Collapse child comments", style: .default) { action -> Void in
            self.collapseAll()
        }
        actionSheetController.addAction(cancelActionButton)
        
        self.present(actionSheetController, animated: true, completion: nil)
        
        
    }
    
       
    var sub: String = ""
    
    func subscribeSingle(_ selector: AnyObject){
        if(subChanged && !Subscriptions.isSubscriber(sub) || Subscriptions.isSubscriber(sub)){
            //was not subscriber, changed, and unsubscribing again
            Subscriptions.unsubscribe(sub, session: session!)
            subChanged = false
            let message = MDCSnackbarMessage()
            message.text = "Unsubscribed"
            MDCSnackbarManager.show(message)
            doSubbed()
        } else {
            let alrController = UIAlertController.init(title: "Subscribe to \(sub)", message: nil, preferredStyle: .actionSheet)
            if(AccountController.isLoggedIn){
                let somethingAction = UIAlertAction(title: "Add to sub list and subscribe", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                    Subscriptions.subscribe(self.sub, true, session: self.session!)
                    self.subChanged = true
                    let message = MDCSnackbarMessage()
                    message.text = "Subscribed"
                    MDCSnackbarManager.show(message)
                    self.doSubbed()
                })
                alrController.addAction(somethingAction)
            }
            
            let somethingAction = UIAlertAction(title: "Add to sub list", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in
                Subscriptions.subscribe(self.sub, false, session: self.session!)
                self.subChanged = true
                let message = MDCSnackbarMessage()
                message.text = "Added"
                MDCSnackbarManager.show(message)
                self.doSubbed()
            })
            alrController.addAction(somethingAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {(alert: UIAlertAction!) in print("cancel")})
            
            alrController.addAction(cancelAction)
            
            self.present(alrController, animated: true, completion:{})
            
        }
        
    }

    var subInfo: Subreddit?
    
    
    func search(_ sender: AnyObject){
        if(!dataArray.isEmpty){
        showSearchBar()
        }
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
    
    public func extendForMore(parentId: String, comments: [Thing], current depth: Int) -> ([(Thing, Int)]) {
        var buf: [(Thing, Int)] = []
        
        for thing in comments {
            let pId = thing is Comment ? (thing as! Comment).parentId : (thing as! More).parentId
            if(pId == parentId){
                if let comment = thing as? Comment {
                    var relativeDepth = 0
                    for parent in buf {
                        if(comment.parentId == parentId){
                            relativeDepth = parent.1 - depth
                            break
                        }
                    }
                    buf.append((comment, depth + relativeDepth))
                    buf.append(contentsOf: extendForMore(parentId: comment.getId(), comments: comments, current:depth + relativeDepth + 1))
                } else if let more = thing as? More {
                    var relativeDepth = 0
                    for parent in buf {
                        let parentId = parent.0 is Comment ? (parent.0 as! Comment).parentId : (parent.0 as! More).parentId
                        if(more.parentId == parentId){
                            relativeDepth = parent.1 - depth
                            break
                        }
                    }
                    buf.append((more, depth + relativeDepth))
                }
            }
        }
        return buf
    }
    
    func updateStrings(_ newComments: [(Thing, Int)]) {
        let color = ColorUtil.accentColorForSub(sub: ((newComments[0].0 as! Comment).subreddit))
        for thing in newComments {
            if let comment = thing.0 as? Comment {
                let html = comment.bodyHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
                do {
                    let attr = try NSMutableAttributedString(data: html.data(using: .unicode)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                    let font = FontGenerator.fontOfSize(size: 16, submission: false)
                    let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: color)
                    self.text[comment.getId()] = LinkParser.parse(attr2)
                } catch {
                    self.text[comment.getId()] = NSAttributedString(string: "")
                }
            } else {
                let attr = NSMutableAttributedString(string: "more")
                let font = FontGenerator.fontOfSize(size: 16, submission: false)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: color)
                self.text[(thing.0 as! More).getId()] = LinkParser.parse(attr2)
            }
        }
    }
    
    var text: [String:NSAttributedString] = [:]
    
    func updateStringsSingle(_ newComments: [Object]) {
        let color = ColorUtil.accentColorForSub(sub: ((newComments[0] as! RComment).subreddit))
        for thing in newComments {
            if let comment = thing as? RComment {
                let html = comment.htmlText
                do {
                    let attr = try NSMutableAttributedString(data: html.data(using: .unicode)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                    let font = FontGenerator.fontOfSize(size: 16, submission: false)
                    let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: color)
                    self.text[comment.getIdentifier()] = LinkParser.parse(attr2)
                } catch {
                    self.text[comment.getIdentifier()] = NSAttributedString(string: "")
                }
            } else {
                let attr = NSMutableAttributedString(string: "more")
                let font = FontGenerator.fontOfSize(size: 16, submission: false)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: color)
                self.text[(thing as! RMore).getIdentifier()] = LinkParser.parse(attr2)
            }

        }
    }
    
    func updateStringSearch(_ thing: Thing) -> CellContent {
        let width = self.view.frame.size.width
        let color = ColorUtil.accentColorForSub(sub: (thing as! RComment).subreddit)
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
                
                let font = FontGenerator.fontOfSize(size: 16, submission: false)
                let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: color)
                
                return CellContent.init(string:LinkParser.parse(attr2), width:(width - 25), hasRelies:false, id: comment.getId())
            } catch {
                return CellContent(string:NSAttributedString(string: ""), width:width - 25, hasRelies:false, id: thing.getId())
            }
        } else {
            let attr = NSMutableAttributedString(string: "more")
            let font = FontGenerator.fontOfSize(size: 16, submission: false)
            let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: color)
            return CellContent.init(string:LinkParser.parse(attr2), width:(width - 25), hasRelies:false, id: thing.getId())
        }
    }
    
    func vote(_ direction: VoteDirection) {
        if let link = self.submission {
            do {
                try session?.setVote(direction, name: link.id, completion: { (result) -> Void in
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
        var topCell = (tableView.indexPathsForVisibleRows?[0].row)!
        let contents = content[dataArray[topCell]]
        while((contents is RMore || (contents as! RComment).depth > 1) && dataArray.count > topCell){
            topCell += 1
        }
        for i in (topCell + 1)...dataArray.count - 1 {
            if(contents  is RComment && matches(comment: contents as! RComment, sort: currentSort)) {
                goToCell(i: i)
                break
            }
        }
    }
    
    func getCount(sort: CommentNavType) -> Int {
        var count = 0
        for comment in dataArray {
            let contents = content[comment]
            if(contents is RComment && matches(comment: contents as! RComment, sort: sort)){
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
        var topCell = (tableView.indexPathsForVisibleRows?[0].row)!
        while((content[dataArray[topCell]] is RMore || (content[dataArray[topCell]] as! RComment).depth > 1 ) && dataArray.count > topCell){
            topCell -= 1
        }
        for i in stride(from: (topCell - 1) , to: 0, by: -1) {
            if(content[dataArray[i]]  is RComment && matches(comment: content[dataArray[i]] as! RComment, sort: currentSort)) {
                goToCell(i: i)
                break
            }
        }
    }
    
    func matches(comment: RComment, sort: CommentNavType) ->Bool{
        switch sort {
        case .PARENTS:
            if( cDepth[comment.getIdentifier()] as! Int == 1) {
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
        if(!SettingValues.disableNavigationBar){
        if(navigationController?.isToolbarHidden)!{
            navigationController?.setToolbarHidden(false, animated: false)
        }
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
        self.navigationController?.toolbarItems = items
        navigationController?.toolbar.barTintColor = UIColor.black.withAlphaComponent(0.4)
        navigationController?.toolbar.tintColor = UIColor.white
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (menuShown ? 1 : 0) + (isSearching ?  self.filteredData.count : self.comments.count - self.hidden.count)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
     var isCurrentlyChanging = false
    func unhideAll(comment: String, i : Int){
        if(!isCurrentlyChanging){
            isCurrentlyChanging = true
        DispatchQueue.global(qos: .background).async {
            let counter = self.unhideNumber(n: comment, iB: i)
            self.doArrays()
            DispatchQueue.main.async {
                self.tableView.beginUpdates()

                var indexPaths : [IndexPath] = []
                for row in (i+1)...counter{
                    indexPaths.append(IndexPath(row: row, section: 0))
                }
                self.tableView.insertRows(at: indexPaths, with: .middle)
                self.tableView.endUpdates()
                self.isCurrentlyChanging = false
            }
            }
        }
    }
    
    func collapseAll(){
        if(dataArray.count > 0){
        for i in 0...dataArray.count - 1 {
            if(content[dataArray[i]]  is RComment && matches(comment: content[dataArray[i]] as! RComment, sort: .PARENTS)) {
                let _ = hideNumber(n: dataArray[i], iB: i)
                let t = content[dataArray[i]]
                let id = (t is RComment) ? (t as! RComment).getIdentifier() : (t as! RMore).getIdentifier()
                if (!hiddenPersons.contains(id)) {
                    hiddenPersons.insert(id);
                }
            }
        }
        doArrays()
            tableView.reloadData()
        }
    }
    
    
    func hideAll(comment: String, i: Int){
        if(!isCurrentlyChanging){
            isCurrentlyChanging = true
        DispatchQueue.global(qos: .background).async {
            let counter = self.hideNumber(n: comment, iB: i) - 1
            self.doArrays()
            DispatchQueue.main.async {
                self.tableView.beginUpdates()
                
                var indexPaths : [IndexPath] = []
                for row in i...counter {
                    indexPaths.append(IndexPath(row: row, section: 0))
                }
                self.tableView.deleteRows(at: indexPaths, with: .middle)
                self.tableView.endUpdates()
                self.isCurrentlyChanging = false
            }
        }
        }
        
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
    
    func walkTree(n: String) -> [String] {
        var toReturn: [String] = []
        if content[n] is RComment {
            let bounds = comments.index(where: { ($0 == n )})! + 1
            let parentDepth = (cDepth[n] as! Int)
            for obj in stride(from: bounds, to: comments.count, by: 1) {
                if((cDepth[comments[obj]] as! Int) > parentDepth){
                    toReturn.append(comments[obj])
                } else {
                    return toReturn
                }
            }
        }
        return toReturn
    }
    
    func walkTreeFully(n: String) -> [String] {
        var toReturn: [String] = []
        toReturn.append(n)
        if content[n] is RComment {
            let bounds = comments.index(where: { $0 == n})! + 1
            let parentDepth = (cDepth[n] as! Int)
            for obj in stride(from: bounds, to: comments.count, by: 1) {
                let currentDepth = cDepth[comments[obj]] as! Int
                if(currentDepth > parentDepth){
                    if(currentDepth == parentDepth + 1){
                        toReturn.append(contentsOf: walkTreeFully(n: comments[obj]))
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
            try session?.setVote(direction, name: comment.id, completion: { (result) -> Void in
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
                try self.session?.deleteCommentOrLink(comment.getIdentifier(), completion: { (result) in
                    DispatchQueue.main.async {
                        var realPosition = 0
                        for c in self.comments{
                            let id = c
                            if(id == comment.getIdentifier()){
                                break
                            }
                            realPosition += 1
                        }
                        self.text[comment.getIdentifier()] = NSAttributedString(string: "[deleted]")
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
                let id = comment.getIdentifier()
                for c in self.comments{
                    if(id == c){
                        break
                    }
                    realPosition += 1
                }
                let comment = RealmDataWrapper.commentToRComment(comment: cr!, depth: 0)
                self.dataArray.remove(at: index)
                self.dataArray.insert(comment.getIdentifier(), at: index)
                self.comments.remove(at: realPosition)
                self.comments.insert(comment.getIdentifier(), at: realPosition)
                self.content[comment.getIdentifier()] = comment
                self.updateStringsSingle([comment])
                self.doArrays()
                self.tableView.reloadData()
            })
        }
        
        let navEditorViewController: UINavigationController = UINavigationController(rootViewController: reply)
        self.prepareOverlayVC(overlayVC: navEditorViewController)
        self.present(navEditorViewController, animated: true, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAtDeprecated indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        var toReturn: [BGTableViewRowActionWithImage] = []
        let cell = tableView.cellForRow(at: indexPath) as! CommentDepthCell
        let color = ColorUtil.getColorForSub(sub: (submission?.subreddit)!)
        if(cell.content! is RComment){
            let author = (cell.content as! RComment).author
            let upimg = UIImage.init(named: "upvote")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
            if(!(submission?.archived)! && AccountController.isLoggedIn && author != "[deleted]" && author != "[removed]"){
                let upvote = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: UIColor.init(hexString: "#FF9800"), image: upimg, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
                    tableView.setEditing(false, animated: true)
                    self.vote(comment: cell.content! as! RComment, dir: .up)
                    cell.refresh(comment: cell.content! as! RComment, submissionAuthor: (self.submission?.author)!, text: cell.cellContent!)
                }
                toReturn.append(upvote!)
                
                let downimg = UIImage.init(named: "downvote")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
                let downvote = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: UIColor.init(hexString: "#2196F3"), image: downimg, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
                    tableView.setEditing(false, animated: true)
                    self.vote(comment: cell.content as! RComment, dir: .down)
                    cell.refresh(comment: cell.content as! RComment, submissionAuthor: (self.submission?.author)!, text: cell.cellContent!)
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
                        c.title.attributedText = cell.title.attributedText
                        let id = self.dataArray[indexPath!.row]
                        c.setComment(comment: self.content[self.dataArray[indexPath!.row]] as! RComment, depth: self.cDepth[id] as! Int, parent: self, hiddenCount: 0, date: self.lastSeen, author: self.submission?.author, text: cell.cellContent!)
                        
                        let reply  = ReplyViewController.init(thing: cell.content!, sub: (self.submission?.subreddit)!, view: c.contentView) { (comment) in
                            DispatchQueue.main.async(execute: { () -> Void in
                                let startDepth = self.cDepth[cell.comment!.getIdentifier()] as! Int + 1
                                
                                let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!, depth: startDepth)]
                                self.cDepth[comment!.getId()] = startDepth
                                
                                
                                var realPosition = 0
                                
                                var ids : [String] = []
                                for item in queue {
                                    let id = item.getIdentifier()
                                    ids.append(id)
                                    self.content[id] = item
                                }

                                for c in self.comments{
                                    if(c == cell.comment!.getIdentifier()){
                                        break
                                    }
                                    realPosition += 1
                                }
                                
                                self.dataArray.insert(contentsOf: ids, at: (indexPath?.row)! + 1)
                                self.comments.insert(contentsOf: ids, at: realPosition + 1)
                                self.updateStringsSingle(queue)
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
                self.moreComment(cell)
            }
            toReturn.append(more!)
        }
        return toReturn
    }
    
    func moreComment(_ cell: CommentDepthCell){
        cell.more(self)
    }
    
    func editComment(){
        menuShown = false
        tableView.beginUpdates()
        let cell = tableView.cellForRow(at: IndexPath.init(row: menuIndex - 1, section: 0)) as! CommentDepthCell
        tableView.deleteRows(at: [IndexPath.init(row: menuIndex, section: 0)], with: .middle)
        tableView.endUpdates()
        
        menuShown = true
        replyShown = true
        reply!.setContent(thing: cell.content!, sub: (cell.content as! RComment).subreddit, editing: true, delegate: self, parent: self)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath.init(row: menuIndex, section: 0)], with: .middle)
        tableView.endUpdates()
    }
    
    func deleteComment(cell: CommentDepthCell){
        self.doDelete(comment: cell.content as! RComment, index: (menuIndex - 1))
    }
    
    func doReply(){
        menuShown = false
        tableView.beginUpdates()
        let cell = tableView.cellForRow(at: IndexPath.init(row: menuIndex - 1, section: 0)) as! CommentDepthCell
        tableView.deleteRows(at: [IndexPath.init(row: menuIndex, section: 0)], with: .middle)
        tableView.endUpdates()

        menuShown = true
        replyShown = true
        reply!.setContent(thing: cell.content!, sub: (cell.content as! RComment).subreddit, editing: false, delegate: self, parent: self)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath.init(row: menuIndex, section: 0)], with: .middle)
        tableView.endUpdates()
    }

    func showCommentMenu(_ cell: CommentDepthCell) {
        if(cell.content! is RMore){
            return
        }
        cell.doHighlight()
        if(menuShown){
            menuShown = false
            tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath.init(row: menuIndex, section: 0)], with: .middle)
            tableView.endUpdates()
 
        }
        tableView.contentInset = UIEdgeInsetsMake(56, 0, self.tableView.frame.size.height * (2/3), 0)
        menuShown = true
        replyShown = false
        menu!.setComment(comment: cell.content as! RComment, cell: cell, parent: self)
        tableView.beginUpdates()
        var index = 0
        menuId = (cell.content as! RComment).getIdentifier()
        for comment in dataArray {
            if(content[comment] is RComment){
                if(((content[comment] as! RComment).getIdentifier() == menuId)){
                    break
                }
            }
            index += 1
        }
        menuIndex = index + 1
        tableView.insertRows(at: [IndexPath.init(row: menuIndex, section: 0)], with: .middle)
        tableView.endUpdates()
    }
    func hideCommentMenu(_ cell: CommentDepthCell) {
        menuShown = false
        replyShown = false
        cell.doUnHighlight()
        tableView.beginUpdates()
        tableView.deleteRows(at: [IndexPath.init(row: menuIndex, section: 0)], with: .middle)
        tableView.endUpdates()
        tableView.contentInset = UIEdgeInsetsMake(56, 0, 45, 0)
    }

    func unhideNumber(n: String, iB: Int) -> Int{
        var i = iB
        let children = walkTree(n: n);
        var toHide : [String] = []
        for name in children {
            
            if(hidden.contains(name)){
                i += 1
            }
            toHide.append(name)

            if(!hiddenPersons.contains(n)) {
                i += unhideNumber(n: name, iB: 0)
            }
        }
        for s in hidden {
            if(toHide.contains(s)){
                hidden.remove(s)
            }
        }
        return i
    }
    
    func hideNumber(n: String, iB : Int) -> Int{
        var i = iB
        
        let children = walkTree(n: n);
        
        for name in children {
            
                if(!hidden.contains(name)){
                    i += 1
                    hidden.insert(name)
                }
            i += hideNumber(n: name, iB: 0)
        }
        return i
    }
    
    var lastYUsed =  CGFloat(0)
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let currentY = scrollView.contentOffset.y;
        let headerHeight = CGFloat(70);
        
        if(currentY > lastYUsed && currentY > 0 ) {
            hideUI(inHeader: (currentY > headerHeight) )
        } else if((currentY < 70 || currentY < lastYUsed + 20)){
            showUI()
        }
        lastYUsed = currentY
    }
    
    func hideUI(inHeader: Bool){
        (navigationController)?.setNavigationBarHidden(true, animated: true)
    }
    
    func showUI(){
        (navigationController)?.setNavigationBarHidden(false, animated: true)
    }
    

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = nil
        if(menuShown && indexPath.row > 0 && dataArray[indexPath.row - 1]  == menuId){
            if(replyShown){
                return reply!
            }
            return menu!
        }
        
            var datasetPosition = (indexPath as NSIndexPath).row;
        
        if(menuShown){
            if(datasetPosition >= menuIndex){
                datasetPosition -= 1
            }
        }
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
            if let cell = cell as? CommentDepthCell {
                cell.delegate = self
                let thing = isSearching ? filteredData[datasetPosition] : dataArray[datasetPosition]
                if(content[thing] is RComment){
                    var count = 0
                    if(hiddenPersons.contains(thing)){
                        count = getChildNumber(n: content[thing]!.getIdentifier())
                    }
                    var t = text[thing]!
                    if(isSearching){
                        t = highlight(t)
                    }
                    cell.setComment(comment: content[thing] as! RComment, depth: cDepth[thing] as! Int, parent: self, hiddenCount: count, date: lastSeen, author: submission?.author, text: t)
                    if(thing == menuId && menuShown){
                        cell.doHighlight()
                    }
                } else {
                    cell.setMore(more: (content[thing] as! RMore), depth: cDepth[thing] as! Int)
                }
                cell.content = content[thing]
            }
            return cell
    }
    
    
    
    func getChildNumber(n: String) -> Int{
        let children = walkTreeFully(n: n);
        return children.count - 1
    }
    
    func highlight(_ cc: NSAttributedString) -> NSAttributedString {
        let base = NSMutableAttributedString.init(attributedString: cc)
        let r = base.mutableString.range(of: "\(searchBar.text!)", options: .caseInsensitive, range: NSMakeRange(0, base.string.length))
        if r.length > 0 {
            base.addAttribute(NSForegroundColorAttributeName, value: ColorUtil.getColorForSub(sub: ""), range: r)
        }
        return base.attributedSubstring(from: NSRange.init(location: 0, length: base.length))
    }
    
    var isSearching  = false
    
    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String)
    {
        filteredData = []
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
        for p in dataArray {
            let s = content[p]
            if(s is RComment){
                if ((s as! RComment).htmlText.localizedCaseInsensitiveContains(searchString!)) {
                    filteredData.append(p)
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
                context = (cell.content as! RComment).getIdentifier()
                var index = 0
                if(!self.context.isEmpty()){
                    for c in self.dataArray {
                        let comment = content[c]
                        if(comment is RComment && (comment as! RComment).getIdentifier().contains(self.context)){
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
                    let id = comment.getIdentifier()
                    let childNumber = getChildNumber(n: comment.getIdentifier());
                    if(hiddenPersons.contains((id)) && childNumber > 0) {
                        hiddenPersons.remove(at: hiddenPersons.index(of: id)!)
                        unhideAll(comment: comment.getId(), i: row!)
                        cell.expand()
                        //todo hide child number
                    } else {
                        if (childNumber > 0) {
                            hideAll(comment: comment.getIdentifier(), i: row! + 1);
                            if (!hiddenPersons.contains(id)) {
                                hiddenPersons.insert(id);
                            }
                            if (childNumber > 0) {
                                cell.collapse(childNumber: childNumber)
                            }
                        }
                    }
                } else {
                    let datasetPosition = tableView.indexPath(for: cell)!.row
                    if let more = content[dataArray[datasetPosition]] as? RMore, let link = self.submission {
                        if(more.children.isEmpty){
                            let url = URL.init(string: "https://www.reddit.com" + submission!.permalink +  more.parentId.substring(3, length: more.parentId.length - 3))
                            print(url!.absoluteString)
                            show(RedditLink.getViewControllerForURL(urlS: url!), sender: self)
                        } else {
                            do {
                                var strings: [String] = []
                                for c in more.children {
                                    strings.append(c.value)
                                }
                                cell.animateMore()
                                try session?.getMoreChildren(strings, name: link.id, sort:.new, id: more.id, completion: { (result) -> Void in
                                    switch result {
                                    case .failure(let error):
                                        print(error)
                                    case .success(let list):
                                        
                                        DispatchQueue.main.async(execute: { () -> Void in
                                            let startDepth = self.cDepth[more.getIdentifier()] as! Int

                                            var queue: [Object] = []
                                            for i in self.extendForMore(parentId: more.parentId, comments: list, current: startDepth) {
                                                queue.append(i.0 is Comment ? RealmDataWrapper.commentToRComment(comment: i.0 as! Comment, depth: i.1) : RealmDataWrapper.moreToRMore(more: i.0 as! More))
                                                self.cDepth[i.0.getId()] = i.1
                                                self.updateStrings([i])
                                            }
                                            
                                            var realPosition = 0
                                            for comment in self.comments{
                                                if(comment == more.getIdentifier()){
                                                    break
                                                }
                                                realPosition += 1
                                            }
                                            
                                            self.comments.remove(at: realPosition)
                                            self.dataArray.remove(at: datasetPosition)
                                            
                                            var ids : [String] = []
                                            for item in queue {
                                                let id = item.getIdentifier()
                                                ids.append(id)
                                                self.content[id] = item
                                            }
                                            
                                            if(queue.count != 0){
                                                self.tableView.beginUpdates()
                                                self.tableView.deleteRows(at: [IndexPath.init(row: datasetPosition, section: 0)], with: .fade)
                                                self.dataArray.insert(contentsOf: ids, at: datasetPosition)
                                                self.comments.insert(contentsOf: ids, at: realPosition)
                                                self.doArrays()
                                                var paths: [IndexPath] = []
                                                for i in stride(from: datasetPosition, to: datasetPosition + queue.count, by: 1){
                                                    paths.append(IndexPath.init(row: i, section: 0))
                                                }
                                                self.tableView.insertRows(at: paths, with: .left)
                                                self.tableView.endUpdates()
                                                
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

extension UITableView {
    func reloadData(with animation: UITableViewRowAnimation) {
        reloadSections(IndexSet(integersIn: 0..<numberOfSections), with: animation)
    }
}
extension Object {
    func getIdentifier() -> String {
        if(self is RComment) {
            return (self as! RComment).getId()
        } else if (self is RMore) {
            return (self as! RMore).getId()
        } else if( self is RSubmission){
            return (self as! RSubmission).getId()
        } else{
            return (self as! RMessage).getId()
        }
    }
}
