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

class CommentViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource, UZTextViewCellDelegate, LinkCellViewDelegate {
    
    internal func pushedMoreButton(_ cell: CommentDepthCell) {
        
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
        
    }
    
    

    
    var submission: Link? = nil
    var session: Session? = nil
    var cDepth: NSMutableDictionary = NSMutableDictionary()
    var comments: [Thing] = []
    var hiddenPersons: [String] = []
    var hidden: [String] = []
    var contents: [CellContent] = []
    weak var tableView : UITableView!
    var headerCell : LinkCellView?
    var hasSubmission = true
    var paginator: Paginator? = Paginator()
    var refreshControl: UIRefreshControl!
    
    var dataArray : [Thing] = []
    
    var heightArray : [CellContent] = []
    
    func doArrays(){
        dataArray = comments.filter{ !hidden.contains($0.getId()) }
        heightArray = contents.filter{ !hidden.contains($0.id) }
    }
    
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
                try session?.getArticles(link, sort:.top, comments:nil, completion: { (result) -> Void in
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
                        
                        self.submission = tuple.0.children[0] as? Link
                        
                        self.refreshControl.endRefreshing()
                        var allIncoming: [(Thing, Int)] = []
                        for child in listing.children {
                            let incoming = self.extendKeepMore(in: child, current: startDepth)
                            allIncoming.append(contentsOf: incoming)
                            for i in incoming{
                                self.comments.append(i.0)
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
                            if(!self.hasSubmission){
                                self.headerCell = LinkCellView()
                                self.headerCell?.delegate = self
                                self.headerCell?.setLink(submission: self.submission!, parent: self, nav: self.navigationController)
                                self.headerCell?.showBody(width: self.tableView.frame.size.width)
                                self.tableView.tableHeaderView = UIView(frame: CGRect.init(x:0, y:0, width:self.tableView.frame.width, height:0.01))
                            }
                            self.doArrays()
                            self.lastSeen = History.getSeenTime(s: link)
                            self.tableView.reloadData()
                            History.setComments(s: link)
                            History.addSeen(s: link)
                        })
                    }
                })
            } catch { print(error) }
        }
    }
    
    var lastSeen: Double = NSDate().timeIntervalSince1970
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 400.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "Cell")
        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "MoreCell")
        
        tableView.separatorStyle = .none
        refreshControl.beginRefreshing()
        refresh(self)
        
        updateToolbar()
        
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
    
    
    
    init(submission: Link){
        self.submission = submission
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: submission.subreddit))
    }
    
    init(submission: String){
        self.submission = Link(id: submission)
        hasSubmission = false
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: submission))
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
        self.tableView.register(LinkCellView.classForCoder(), forCellReuseIdentifier: "cell")
        title = submission?.subreddit
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: nil, action: nil)
        if let navigationController = self.navigationController as? ScrollingNavigationController {
            print("Following scroll")
            navigationController.followScrollView(self.tableView, delay: 50.0)
        }
        
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
    
    func updateStringsSingle(_ newComments: [Thing]) -> [CellContent] {
        let width = self.view.frame.size.width
        return newComments.map { (thing: Thing) -> CellContent in
            if let comment = thing as? Comment {
                let html = comment.bodyHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
                do {
                    let attr = try NSMutableAttributedString(data: html.data(using: .unicode)!, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                    let font = UIFont(name: ".SFUIText-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
                    let attr2 = attr.reconstruct(with: font, color: UIColor.black, linkColor: UIColor.blue)
                    return CellContent.init(string:attr2, width:(width - 25), hasRelies:false, id: comment.getId())
                } catch {
                    return CellContent(string:NSAttributedString(string: ""), width:width - 25, hasRelies:false, id: thing.getId())
                }
            } else {
                let attr = NSMutableAttributedString(string: "more")
                let font = UIFont(name: ".SFUIText-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
                let attr2 = attr.reconstruct(with: font, color: UIColor.black, linkColor: UIColor.blue)
                return CellContent.init(string:attr2, width:(width - 25), hasRelies:false, id: thing.getId())
            }
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
    
    func updateToolbar() {
        var items: [UIBarButtonItem] = []
        let space = UIBarButtonItem(barButtonSystemItem:.flexibleSpace, target: nil, action: nil)
        if let link = self.submission {
            items.append(space)
            // voting status
            switch(link.likes) {
            case .up:
                items.append(UIBarButtonItem(image: UIImage(named: "thumbDown"), style:.plain, target: self, action: #selector(CommentViewController.downVote(_:))))
                items.append(space)
                items.append(UIBarButtonItem(image: UIImage(named: "thumbUpFill"), style:.plain, target: self, action: #selector(CommentViewController.cancelVote(_:))))
            case .down:
                items.append(UIBarButtonItem(image: UIImage(named: "thumbDownFill"), style:.plain, target: self, action: #selector(CommentViewController.cancelVote(_:))))
                items.append(space)
                items.append(UIBarButtonItem(image: UIImage(named: "thumbUp"), style:.plain, target: self, action: #selector(CommentViewController.upVote(_:))))
            case .none:
                items.append(UIBarButtonItem(image: UIImage(named: "thumbDown"), style:.plain, target: self, action: #selector(CommentViewController.downVote(_:))))
                items.append(space)
                items.append(UIBarButtonItem(image: UIImage(named: "thumbUp"), style:.plain, target: self, action: #selector(CommentViewController.upVote(_:))))
            }
            items.append(space)
            
            items.append(space)
            
            // hide
            if link.hidden {
                items.append(UIBarButtonItem(image: UIImage(named: "eyeFill"), style:.plain, target: self, action: #selector(CommentViewController.doUnhide(_:))))
            } else {
                items.append(UIBarButtonItem(image: UIImage(named: "eye"), style:.plain, target: self, action: #selector(CommentViewController.doHide(_:))))
            }
            items.append(space)
            
            // comment button
            items.append(UIBarButtonItem(image: UIImage(named: "comment"), style:.plain, target: nil, action: nil))
            items.append(space)
        }
        self.toolbarItems = items
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count - hidden.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let datasetPosition = (indexPath as NSIndexPath).row;
        return heightArray[datasetPosition].textHeight
    }
    
    func unhideAll(comment: Comment, i : Int){
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
    
    func hideAll(comment: Comment, i: Int){
        let counter = hideNumber(n: comment, iB: i) - 1
        doArrays()
        tableView.beginUpdates()
        
        var indexPaths : [IndexPath] = []
        for row in i...counter{
            indexPaths.append(IndexPath(row: row, section: 0))
        }
        tableView.deleteRows(at: indexPaths, with: .middle)
        tableView.endUpdates()
        
        //notify inserted at i
    }
    
    func parentHidden(comment: Thing)->Bool{
        var n: String = ""
        if(comment is Comment){
            n = (comment as! Comment).parentId
        } else {
            n = (comment as! More).parentId
        }
        return hiddenPersons.contains(n) || hidden.contains(n)
    }
    
    func walkTree(n: Thing) -> [Thing] {
        var toReturn: [Thing] = []
        if n is Comment {
            for obj in (n as! Comment).replies.children {
                toReturn.append(obj)
            }
        }
        return toReturn
    }
    
    func walkTreeFully(n: Thing) -> [Thing] {
        var toReturn: [Thing] = []
        toReturn.append(n)
        if n is Comment {
            for obj in (n as! Comment).replies.children {
                toReturn.append(contentsOf: walkTreeFully(n: obj))
            }
        }
        return toReturn
    }
    
    func vote(comment: Thing,  dir: VoteDirection) {
        
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
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let cell = tableView.cellForRow(at: indexPath) as! CommentDepthCell
        let color = ColorUtil.getColorForSub(sub: (submission?.subreddit)!)
        let upimg = UIImage.init(named: "upvote")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
        let upvote = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: UIColor.init(hexString: "#FF9800"), image: upimg, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
            tableView.setEditing(false, animated: true)
            self.vote(comment: cell.content!, dir: .up)
            cell.refresh(comment: cell.content! as! Comment, submissionAuthor: (self.submission?.author)!)
        }
        
        let downimg = UIImage.init(named: "downvote")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
        let downvote = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: UIColor.init(hexString: "#2196F3"), image: downimg, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
            tableView.setEditing(false, animated: true)
            self.vote(comment: cell.content!, dir: .down)
            cell.refresh(comment: cell.content! as! Comment, submissionAuthor: self.link.author)
        }
        
        let rep = UIImage.init(named: "reply")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
        let reply = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: color, image: rep, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
            tableView.setEditing(false, animated: true)
        }
        
        let mor = UIImage.init(named: "ic_more_vert_white")?.imageResize(sizeChange: CGSize.init(width: 25, height: 25))
        let more = BGTableViewRowActionWithImage.rowAction(with: .normal, title: "    ", backgroundColor: color, image: mor, forCellHeight: UInt(cell.contentView.frame.size.height)) { (action, indexPath) in
            tableView.setEditing(false, animated: true)
            cell.more()
        }
        
        
        return [more!, reply!, downvote!, upvote!]
    }
    
    
    func unhideNumber(n: Thing, iB: Int) -> Int{
        var i = iB
        let children = walkTree(n: n);
        for ignored in children {
            let parentHidden = self.parentHidden(comment: ignored)
            if(parentHidden){
                continue
            }
            
            let name = ignored.getId()
            
            if(hidden.contains(name) || hiddenPersons.contains(name)){
                hidden.remove(at: hidden.index(of: name)!)
                i += 1
            }
            i += unhideNumber(n: ignored, iB: 0)
        }
        return i
    }
    
    func hideNumber(n: Thing, iB : Int) -> Int{
        var i = iB
        
        let children = walkTree(n: n);
        
        for ignored in children {
            if(n.getId() != ignored.getId()){
                
                let fullname = ignored.getId()
                
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
                let thing = dataArray[datasetPosition]
                if(thing is Comment){
                    let text = heightArray[datasetPosition]
                    cell.textView.attributedString = text.attributedString
                    cell.textView.frame.size.height = text.textHeight
                    var count = 0
                    if(hiddenPersons.contains(thing.getId())){
                        count = getChildNumber(n: thing as! Comment)
                    }
                    cell.setComment(comment: thing as! Comment, depth: cDepth[thing.getId()] as! Int, parent: self, hiddenCount: count, date: lastSeen, author: submission?.author)
                } else {
                    cell.setMore(more: (thing as! More), depth: cDepth[thing.getId()] as! Int)
                }
                cell.content = thing
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
            return cell
        }
    }
    
    
    
    func getChildNumber(n: Comment) -> Int{
        let children = walkTreeFully(n: n);
        return children.count - 1
    }
    
    func pushedSingleTap(_ cell: CommentDepthCell){
        if let comment = cell.content as? Comment {
            let row = tableView.indexPath(for: cell)?.row
            
            if(hiddenPersons.contains((comment.getId()))) {
                hiddenPersons.remove(at: hiddenPersons.index(of: comment.getId())!)
                unhideAll(comment: comment, i: row!)
                cell.expand()
                //todo hide child number
            } else {
                let childNumber = getChildNumber(n: comment);
                if (childNumber > 0) {
                    hideAll(comment: comment, i: row! + 1);
                    if (!hiddenPersons.contains(comment.getId())) {
                        hiddenPersons.append(comment.getId());
                    }
                    if (childNumber > 0) {
                        cell.collapse(childNumber: childNumber)
                    }
                }
            }
        } else {
            let datasetPosition = tableView.indexPath(for: cell)!.row
            
            if let more = dataArray[datasetPosition] as? More, let link = self.submission {
                do {
                    try session?.getMoreChildren(more.children, link:link, sort:.new, id: more.id, completion: { (result) -> Void in
                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(let list):
                            print(list)
                            
                            DispatchQueue.main.async(execute: { () -> Void in
                                let startDepth = 1
                                
                                var queue: [Thing] = []
                                for child in list {
                                    let incoming = self.extendKeepMore(in: child, current: startDepth)
                                    for i in incoming{
                                        queue.append(i.0)
                                        self.cDepth[i.0.getId()] = i.1
                                    }
                                }
                                
                                
                                print("Queue size is \(queue.count)")
                                self.comments.remove(at: datasetPosition)
                                self.contents.remove(at: datasetPosition)
                                
                                self.comments.insert(contentsOf: queue, at: datasetPosition)
                                self.contents.insert(contentsOf: self.updateStringsSingle(queue), at: datasetPosition)
                                self.doArrays()
                                self.tableView.reloadData()
                            })
                            
                        }
                    })
                } catch { print(error) }
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
