//
//  ViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 01/04/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import SDWebImage
import MaterialComponents.MaterialSnackbar
import XLActionController

class ContentListingViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource {
    var baseData: ContributionLoader
    var session: Session? = nil
    weak var tableView : UITableView!
    
    /* override func previewActionItems() -> [UIPreviewActionItem] {
     let regularAction = UIPreviewAction(title: "Regular", style: .Default) { (action: UIPreviewAction, vc: UIViewController) -> Void in
     
     }
     
     let destructiveAction = UIPreviewAction(title: "Destructive", style: .Destructive) { (action: UIPreviewAction, vc: UIViewController) -> Void in
     
     }
     
     let actionGroup = UIPreviewActionGroup(title: "Group...", style: .Default, actions: [regularAction, destructiveAction])
     
     return [regularAction, destructiveAction, actionGroup]
     }*/
    init(dataSource: ContributionLoader){
        baseData = dataSource
        super.init(nibName:nil, bundle:nil)
        baseData.delegate = self
        setBarColors(color: baseData.color)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    func failed(error: Error){
        print(error)
    }
    
    func drefresh(_ sender:AnyObject) {
        refresh()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 400.0
        tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.register(LinkTableViewCell.classForCoder(), forCellReuseIdentifier: "submission")
        self.tableView.register(CommentCellView.classForCoder(), forCellReuseIdentifier: "comment")
        self.tableView.register(MessageCellView.classForCoder(), forCellReuseIdentifier: "message")
        
        if(baseData is ProfileContributionLoader || baseData is InboxContributionLoader){
            self.tableView.contentInset = UIEdgeInsets.init(top: 45, left: 0, bottom: 0, right: 0)
        }
        session = (UIApplication.shared.delegate as! AppDelegate).session
        
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    var tC: UIViewController?
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return baseData.content.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thing = baseData.content[indexPath.row]
        var cell: UITableViewCell?
        if(thing is RSubmission){
           let c = tableView.dequeueReusableCell(withIdentifier: "submission", for: indexPath) as! LinkTableViewCell
            c.setLink(submission: (thing as! RSubmission), parent: self, nav: self.navigationController, baseSub: "all")
            c.del = self
            cell = c
        } else if thing is RComment {
            let c = tableView.dequeueReusableCell(withIdentifier: "comment", for: indexPath) as! CommentCellView
            c.setComment(comment: (thing as! RComment), parent: self, nav: self.navigationController, width: self.view.frame.size.width)
            cell = c
        } else {
            let c = tableView.dequeueReusableCell(withIdentifier: "message", for: indexPath) as! MessageCellView
            c.setMessage(message: (thing as! RMessage), parent: self, nav: self.navigationController, width: self.view.frame.size.width)
            cell = c
        }
        
        if indexPath.row == baseData.content.count - 1 && !loading && baseData.canGetMore {
            self.loadMore()
        }

        return cell!
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
    
    func showMenu(sender: UIButton?){
        let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)
        
        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default)
            { action -> Void in
                self.showTimeMenu(s: link, selector: sender)
            }
            actionSheetController.addAction(saveActionButton)
        }

        if let presenter = actionSheetController.popoverPresentationController {
            presenter.sourceView = sender!
            presenter.sourceRect = sender!.bounds
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
        
    }
    
    func showTimeMenu(s: LinkSortType, selector: UIButton?){
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

            if let presenter = actionSheetController.popoverPresentationController {
                presenter.sourceView = selector!
                presenter.sourceRect = selector!.bounds
            }
            
            self.present(actionSheetController, animated: true, completion: nil)
        }
    }
    
    var refreshControl: UIRefreshControl!
    
    func refresh(){
        tableView.reloadData()
        refreshControl.beginRefreshing()
        loading = true
        baseData.getData(reload: true)
    }
    
    func loadMore(){
        if(!showing){
            showLoader()
        }
        loading = true
        baseData.getData(reload: false)
    }
    
    
    var loading: Bool = false
    
    func doneLoading(){
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
        self.loading = false
        if(baseData.content.count == 0){
            let message = MDCSnackbarMessage()
            message.text = "No content found"
            MDCSnackbarManager.show(message)
        }
    }
}

extension ContentListingViewController : LinkTableViewCellDelegate {
    func more(_ cell: LinkTableViewCell) {
        let link = cell.link!

        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Post by /u/\(link.author)"


        alertController.addAction(Action(ActionData(title: "/u/\(link.author)'s profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in

            let prof = ProfileViewController.init(name: link.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)
        }))
        alertController.addAction(Action(ActionData(title: "/r/\(link.subreddit)", image: UIImage(named: "subs")!.menuIcon()), style: .default, handler: { action in

            let sub = SingleSubredditViewController.init(subName: link.subreddit, single: true)
            VCPresenter.showVC(viewController: sub, popupIfPossible: true, parentNavigationController: self.navigationController, parentViewController: self)

        }))

        alertController.addAction(Action(ActionData(title: "Share comment permalink", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { action in
            let activityViewController = UIActivityViewController(activityItems: [link.permalink], applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: {})
        }))
        if (AccountController.isLoggedIn) {
            alertController.addAction(Action(ActionData(title: "Save", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { action in
                self.save(cell)
            }))

        }



        let open = OpenInChromeController.init()
        if (open.isChromeInstalled()) {

            alertController.addAction(Action(ActionData(title: "Open in Chrome", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { action in
                open.openInChrome(link.url!, callbackURL: nil, createNewTab: true)
            }))
        }
        alertController.addAction(Action(ActionData(title: "Open in Safari", image: UIImage(named: "world")!.menuIcon()), style: .default, handler: { action in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(link.url!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(link.url!)
            }
        }))

        alertController.addAction(Action(ActionData(title: "Share content", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { action in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [link.url!], applicationActivities: nil);
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }))
        alertController.addAction(Action(ActionData(title: "Share comments", image: UIImage(named: "comments")!.menuIcon()), style: .default, handler: { action in
            let activityViewController: UIActivityViewController = UIActivityViewController(activityItems: [URL.init(string: "https://reddit.com" + link.permalink)!], applicationActivities: nil);
            let currentViewController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
            currentViewController.present(activityViewController, animated: true, completion: nil);
        }))


        alertController.addAction(Action(ActionData(title: "Cancel", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: nil))

        //todo make this work on ipad
        self.present(alertController, animated: true, completion: nil)
    }


    func upvote(_ cell: LinkTableViewCell) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.getId())!, completion: { (result) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func downvote(_ cell: LinkTableViewCell) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.getId())!, completion: { (result) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func save(_ cell: LinkTableViewCell) {
        do {
            try session?.setSave(!ActionStates.isSaved(s: cell.link!), name: (cell.link?.getId())!, completion: { (result) in

            })
            ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }
    func reply(_ cell: LinkTableViewCell) {

    }

    func hide(_ cell: LinkTableViewCell) {

    }

}