//
//  CommentViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/30/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox.AudioServices
import MaterialComponents.MDCActivityIndicator
import RealmSwift
import reddift
import RLBAlertsPickers
import SloppySwiper
import TTTAttributedLabel
import UIKit
import XLActionController

class CommentViewController: MediaTableViewController, TTTAttributedCellDelegate, LinkCellViewDelegate, UISearchBarDelegate, UINavigationControllerDelegate, TTTAttributedLabelDelegate, SubmissionMoreDelegate, ReplyDelegate {
    
    func hide(index: Int) {
        if index >= 0 {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    var menuCell: CommentDepthCell?
    var menuId: String?
    public var inHeadView = UIView()
    
    var commentDepthColors = [UIColor]()
    var pan: UIPanGestureRecognizer!

    var panGesture: UIPanGestureRecognizer!
    var translatingCell: CommentDepthCell?
    var didDisappearCompletely = false

    func isMenuShown() -> Bool {
        return menuCell != nil
    }

    func getMenuShown() -> String? {
        return menuId
    }

    func showFilterMenu(_ cell: LinkCellView) {
        //Not implemented
    }
    
    func applyFilters() {
        if PostFilter.filter([submission!], previous: nil, baseSubreddit: "all").isEmpty {
            self.navigationController?.popViewController(animated: true)
        }
    }

    init(submission: RSubmission, single: Bool) {
        self.submission = submission
        self.single = single
        self.text = [:]
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: submission.subreddit))
    }

    init(submission: RSubmission) {
        self.submission = submission
        self.text = [:]
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: submission.subreddit))
    }

    init(submission: String, subreddit: String?, np: Bool = false) {
        self.submission = RSubmission()
        self.np = np
        self.submission!.name = submission
        self.submission!.id = submission.startsWith("t3") ? submission : ("t3_" + submission)

        hasSubmission = false
        if subreddit != nil {
            self.subreddit = subreddit!
            self.submission!.subreddit = subreddit!
        }
        self.text = [:]
        super.init(nibName: nil, bundle: nil)
        if subreddit != nil {
            self.title = subreddit!
            setBarColors(color: ColorUtil.getColorForSub(sub: subreddit!))
        }
    }

    init(submission: String, comment: String, context: Int, subreddit: String, np: Bool = false) {
        self.submission = RSubmission()
        self.submission!.name = submission
        self.submission!.subreddit = subreddit
        hasSubmission = false
        self.context = comment
        self.np = np
        self.text = [:]
        self.contextNumber = context
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: subreddit))
    }

    var parents: [String: String] = [:]
    var approved: [String] = []
    var removed: [String] = []
    var offline = false
    var np = false
    var modLink = ""
    var swiper: SloppySwiper?

    var authorColor: UIColor = ColorUtil.fontColor

    func replySent(comment: Comment?, cell: CommentDepthCell?) {
        if comment != nil && cell != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                let startDepth = self.cDepth[cell!.comment!.getIdentifier()]! + 1

                let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!, depth: startDepth)]
                self.cDepth[comment!.getId()] = startDepth

                var realPosition = 0
                for c in self.comments {
                    let id = c
                    if id == cell!.comment!.getIdentifier() {
                        break
                    }
                    realPosition += 1
                }

                var insertIndex = 0
                for c in self.dataArray {
                    let id = c
                    if id == cell!.comment!.getIdentifier() {
                        break
                    }
                    insertIndex += 1
                }

                var ids: [String] = []
                for item in queue {
                    let id = item.getIdentifier()
                    ids.append(id)
                    self.content[id] = item
                }

                self.dataArray.insert(contentsOf: ids, at: insertIndex + 1)
                self.comments.insert(contentsOf: ids, at: realPosition + 1)
                self.updateStringsSingle(queue)
                self.doArrays()
                self.isReply = false
                self.tableView.reloadData()

            })
        } else if comment != nil && cell == nil {
            DispatchQueue.main.async(execute: { () -> Void in
                let startDepth = 0

                let queue: [Object] = [RealmDataWrapper.commentToRComment(comment: comment!, depth: startDepth)]
                self.cDepth[comment!.getId()] = startDepth

                let realPosition = 0
                self.menuId = nil

                var ids: [String] = []
                for item in queue {
                    let id = item.getIdentifier()
                    ids.append(id)
                    self.content[id] = item
                }

                self.dataArray.insert(contentsOf: ids, at: 0)
                self.comments.insert(contentsOf: ids, at: realPosition == 0 ? 0 : realPosition + 1)
                self.updateStringsSingle(queue)
                self.doArrays()
                self.isReply = false
                self.tableView.reloadData()
            })
        }
    }

    func openComments(id: String, subreddit: String?) {
        //don't do anything
    }

    func editSent(cr: Comment?, cell: CommentDepthCell) {
        if cr != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                var realPosition = 0

                var comment = cell.comment!
                for c in self.comments {
                    let id = c
                    if id == comment.getIdentifier() {
                        break
                    }
                    realPosition += 1
                }

                var insertIndex = 0
                for c in self.dataArray {
                    let id = c
                    if id == comment.getIdentifier() {
                        break
                    }
                    insertIndex += 1
                }

                comment = RealmDataWrapper.commentToRComment(comment: cr!, depth: 0)
                self.dataArray.remove(at: insertIndex)
                self.dataArray.insert(comment.getIdentifier(), at: insertIndex)
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

    func discard() {

    }

    func updateHeight(textView: UITextView) {
        UIView.setAnimationsEnabled(false)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }

    internal func pushedMoreButton(_ cell: CommentDepthCell) {

    }

    func save(_ cell: LinkCellView) {
        do {
            let state = !ActionStates.isSaved(s: cell.link!)
            print(cell.link!.id)
            try session?.setSave(state, name: (cell.link?.id)!, completion: { (result) in
                if result.error != nil {
                    print(result.error!)
                }
                DispatchQueue.main.async {
                    BannerUtil.makeBanner(text: state ? "Saved" : "Unsaved", color: ColorUtil.accentColorForSub(sub: self.subreddit), seconds: 1, context: self)
                }
            })
            ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {
        }
    }

    func doHeadView(_ size: CGSize) {
        inHeadView.removeFromSuperview()
        inHeadView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: max(self.view.frame.size.width, self.view.frame.size.height), height: (UIApplication.shared.statusBarView?.frame.size.height ?? 20)))
        if submission != nil {
            self.inHeadView.backgroundColor = !SettingValues.reduceColor ? ColorUtil.getColorForSub(sub: submission!.subreddit) : ColorUtil.foregroundColor
        }
        
        let landscape = size.width > size.height || (self.navigationController is TapBehindModalViewController && self.navigationController!.modalPresentationStyle == .pageSheet)
        if navigationController?.viewControllers.first != self && !landscape {
            self.navigationController?.view.addSubview(inHeadView)
        }
    }

    func saveComment(_ comment: RComment) {
        do {
            let state = !ActionStates.isSaved(s: comment)
            try session?.setSave(state, name: comment.id, completion: { (_) in
                DispatchQueue.main.async {
                    BannerUtil.makeBanner(text: state ? "Saved" : "Unsaved", color: ColorUtil.accentColorForSub(sub: self.sub), seconds: 1, context: self)
                }
            })
            ActionStates.setSaved(s: comment, saved: !ActionStates.isSaved(s: comment))
        } catch {

        }
    }

    var searchBar = UISearchBar()

    func reloadHeights() {
        //UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
       // }
    }
    
    func prepareReply() {
        tableView.beginUpdates()
        tableView.endUpdates()
        /*var index = 0
        for comment in self.comments {
            if (comment.contains(getMenuShown()!)) {
                    let indexPath = IndexPath.init(row: index, section: 0)
                    self.tableView.scrollToRow(at: indexPath,
                                               at: UITableViewScrollPosition.none, animated: true)
                break
            } else {
                index += 1
            }
        }*/
    }

    func hide(_ cell: LinkCellView) {

    }

    func reply(_ cell: LinkCellView) {
        if !offline {
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(submission: cell.link!, sub: cell.link!.subreddit, delegate: self)), parentVC: self)
        }
    }

    func upvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func deleteSelf(_ cell: LinkCellView) {
        if !offline {
            do {
                try session?.deleteCommentOrLink(cell.link!.getId(), completion: { (_) in
                    DispatchQueue.main.async {
                        if (self.navigationController?.modalPresentationStyle ?? .formSheet) == .formSheet {
                            self.navigationController?.dismiss(animated: true)
                        } else {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                })
            } catch {

            }
        }
    }
    
    var oldPosition: CGPoint = CGPoint.zero
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if scrollView.contentOffset.y > oldPosition.y {
            oldPosition = scrollView.contentOffset
            return true
        } else {
            tableView.setContentOffset(oldPosition, animated: true)
            oldPosition = CGPoint.zero
        }
        return false
    }
    
    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func more(_ cell: LinkCellView) {
        if !offline {
            PostActions.showMoreMenu(cell: cell, parent: self, nav: self.navigationController!, mutableList: false, delegate: self, index: tableView.indexPath(for: cell)?.row ?? 0)
        }
    }

    func readLater(_ cell: LinkCellView) {
        guard let link = cell.link else {
            fatalError("Cell must have a link!")
        }

        ReadLater.toggleReadLater(link: link)
        cell.refresh()
    }

    var submission: RSubmission?
    var session: Session?
    var cDepth: Dictionary = [String: Int]()
    var comments: [String] = []
    var hiddenPersons = Set<String>()
    var hidden: Set<String> = Set<String>()
    var headerCell: LinkCellView!
    var hasSubmission = true
    var paginator: Paginator? = Paginator()
    var context: String = ""
    var contextNumber: Int = 3

    var dataArray: [String] = []
    var filteredData: [String] = []
    var content: Dictionary = [String: Object]()

    func doArrays() {
        dataArray = comments.filter({ (s) -> Bool in
            !hidden.contains(s)
        })
    }

    var sort: CommentSort = SettingValues.defaultCommentSorting

    func getSelf() -> CommentViewController {
        return self
    }

    var reset = false
    var indicatorSet = false
    
    func loadOffline() {
        self.loaded = true
        DispatchQueue.main.async {
            self.offline = true
            do {
                
                let realm = try Realm()
                if let listing = realm.objects(RSubmission.self).filter({ (item) -> Bool in
                    return item.id == self.submission!.id
                }).first {
                    self.comments = []
                    self.hiddenPersons = []
                    var temp: [Object] = []
                    self.hidden = []
                    self.text = [:]
                    var currentIndex = 0
                    self.parents = [:]
                    var currentOP = ""
                    for child in listing.comments {
                        if child.depth == 1 {
                            currentOP = child.author
                        }
                        self.parents[child.getIdentifier()] = currentOP
                        currentIndex += 1
                        
                        temp.append(child)
                        self.content[child.getIdentifier()] = child
                        self.comments.append(child.getIdentifier())
                        self.cDepth[child.getIdentifier()] = child.depth
                    }
                    if !self.comments.isEmpty {
                        self.updateStringsSingle(temp)
                        self.doArrays()
                        self.lastSeen = (self.context.isEmpty ? History.getSeenTime(s: self.link) : Double(0))
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.refreshControl?.endRefreshing()
                        self.indicator.stopAnimating()
                        
                        if !self.comments.isEmpty {
                            var time = timeval(tv_sec: 0, tv_usec: 0)
                            gettimeofday(&time, nil)
                            
                            self.tableView.reloadData(with: .fade)
                        }
                        if self.comments.isEmpty {
                            BannerUtil.makeBanner(text: "No cached comments found!\nYou can set up auto-cache in Settings > Auto Cache", color: ColorUtil.accentColorForSub(sub: self.subreddit), seconds: 5, context: self)
                        } else {
                            BannerUtil.makeBanner(text: "Showing cached comments", color: ColorUtil.accentColorForSub(sub: self.subreddit), seconds: 5, context: self)
                        }
                        
                    })
                }
            } catch {
                BannerUtil.makeBanner(text: "No cached comments found!\nYou can set up auto-cache in Settings > Auto Cache", color: ColorUtil.accentColorForSub(sub: self.subreddit), seconds: 5, context: self)
            }
        }

    }

    func refresh(_ sender: AnyObject) {
        session = (UIApplication.shared.delegate as! AppDelegate).session
        approved.removeAll()
        removed.removeAll()
        content.removeAll()
        text.removeAll()
        dataArray.removeAll()
        cDepth.removeAll()
        comments.removeAll()
        hidden.removeAll()
        tableView.reloadData()
        if let link = self.submission {
            sub = link.subreddit
            
            self.setupTitleView(link.subreddit)

            reset = false
            do {
                var name = link.name
                if name.contains("t3_") {
                    name = name.replacingOccurrences(of: "t3_", with: "")
                }
                if offline {
                    self.loadOffline()
                } else {
                    try session?.getArticles(name, sort: sort, comments: (context.isEmpty ? nil : [context]), context: 3, completion: { (result) -> Void in
                        switch result {
                        case .failure(let error):
                            print(error)
                            self.loadOffline()
                        case .success(let tuple):
                            let startDepth = 1
                            let listing = tuple.1
                            self.comments = []
                            self.hiddenPersons = []
                            self.hidden = []
                            self.text = [:]
                            self.content = [:]
                            self.loaded = true
                            
                            if self.submission == nil || self.submission!.id.isEmpty() {
                                self.submission = RealmDataWrapper.linkToRSubmission(submission: tuple.0.children[0] as! Link)
                            } else {
                                self.submission = RealmDataWrapper.updateSubmission(self.submission!, tuple.0.children[0] as! Link)
                            }
                            
                            var allIncoming: [(Thing, Int)] = []
                            self.submission!.comments.removeAll()
                            self.parents = [:]
                            
                            for child in listing.children {
                                let incoming = self.extendKeepMore(in: child, current: startDepth)
                                allIncoming.append(contentsOf: incoming)
                                var currentIndex = 0
                                var currentOP = ""
                                
                                for i in incoming {
                                    let item = RealmDataWrapper.commentToRealm(comment: i.0, depth: i.1)
                                    self.content[item.getIdentifier()] = item
                                    self.comments.append(item.getIdentifier())
                                    if item is RComment {
                                        self.submission!.comments.append(item as! RComment)
                                    }
                                    if i.1 == 1 && item is RComment {
                                        currentOP = (item as! RComment).author
                                    }
                                    self.parents[item.getIdentifier()] = currentOP
                                    currentIndex += 1
                                    
                                    self.cDepth[item.getIdentifier()] = i.1
                                }
                            }
                            
                            var time = timeval(tv_sec: 0, tv_usec: 0)
                            gettimeofday(&time, nil)
                            self.paginator = listing.paginator
                            
                            if !self.comments.isEmpty {
                                do {
                                    let realm = try! Realm()
                                    //todo insert
                                    realm.beginWrite()
                                    for comment in self.comments {
                                        realm.create(type(of: self.content[comment]!), value: self.content[comment]!, update: true)
                                        if self.content[comment]! is RComment {
                                            self.submission!.comments.append(self.content[comment] as! RComment)
                                        }
                                    }
                                    realm.create(type(of: self.submission!), value: self.submission!, update: true)
                                    try realm.commitWrite()
                                } catch {
                                    
                                }
                            }
                            
                            if !allIncoming.isEmpty {
                                self.updateStrings(allIncoming)
                            }
                            
                            self.doArrays()
                            self.lastSeen = (self.context.isEmpty ? History.getSeenTime(s: self.submission!) : Double(0))
                            History.setComments(s: link)
                            History.addSeen(s: link)
                            DispatchQueue.main.async(execute: { () -> Void in
                                if !self.hasSubmission {
                                    self.headerCell = FullLinkCellView()
                                    self.headerCell?.del = self
                                    self.headerCell?.parentViewController = self
                                    self.hasDone = true
                                    self.headerCell?.aspectWidth = self.tableView.bounds.size.width
                                    self.headerCell?.configure(submission: self.submission!, parent: self, nav: self.navigationController, baseSub: self.submission!.subreddit, parentWidth: self.view.frame.size.width)
                                    self.headerCell?.showBody(width: self.view.frame.size.width - 24)
                                    self.tableView.tableHeaderView = UIView(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.width, height: 0.01))
                                    if let tableHeaderView = self.headerCell {
                                        var frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: tableHeaderView.estimateHeight(true))
                                        // Add safe area insets to left and right if available
                                        if #available(iOS 11.0, *) {
                                            frame = frame.insetBy(dx: max(self.view.safeAreaInsets.left, self.view.safeAreaInsets.right), dy: 0)
                                        }
                                        if self.tableView.tableHeaderView == nil || !frame.equalTo(tableHeaderView.frame) {
                                            tableHeaderView.frame = frame
                                            tableHeaderView.layoutIfNeeded()
                                            let view = UIView(frame: tableHeaderView.frame)
                                            view.addSubview(tableHeaderView)
                                            self.tableView.tableHeaderView = view
                                        }
                                    }
                                    
                                    self.setupTitleView(self.submission!.subreddit)
                                    
                                    self.navigationItem.backBarButtonItem?.title = ""
                                    self.setBarColors(color: ColorUtil.getColorForSub(sub: self.submission!.subreddit))
                                } else {
                                    
                                    self.headerCell?.refreshLink(self.submission!)
                                    self.headerCell?.aspectWidth = self.tableView.bounds.size.width
                                    self.headerCell?.showBody(width: self.view.frame.size.width - 24)
                                    
                                    var frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.headerCell!.estimateHeight(true, true))
                                    // Add safe area insets to left and right if available
                                    if #available(iOS 11.0, *) {
                                        frame = frame.insetBy(dx: max(self.view.safeAreaInsets.left, self.view.safeAreaInsets.right), dy: 0)
                                    }
                                    
                                    self.headerCell!.contentView.frame = frame
                                    self.headerCell!.contentView.layoutIfNeeded()
                                    let view = UIView(frame: self.headerCell!.contentView.frame)
                                    view.addSubview(self.headerCell!.contentView)
                                    self.tableView.tableHeaderView = view
                                }
                                self.refreshControl?.endRefreshing()
                                self.indicator.stopAnimating()
                                self.indicator.isHidden = true
                                self.doBanner(self.submission!)
                                
                                var index = 0
                                var loaded = false
                                
                                if SettingValues.hideAutomod && self.context.isEmpty() && self.submission!.author != AccountController.currentName && !self.comments.isEmpty {
                                    if let comment = self.content[self.comments[0]] as? RComment {
                                        if comment.author == "AutoModerator" {
                                            var toRemove = [String]()
                                            toRemove.append(comment.getIdentifier())
                                            self.modLink = comment.permalink
                                            self.hidden.insert(comment.getIdentifier())
                                            
                                            for next in self.walkTreeFlat(n: comment.getIdentifier()) {
                                                toRemove.append(next)
                                                self.hidden.insert(next)
                                            }
                                            self.dataArray = self.dataArray.filter({ (comment) -> Bool in
                                                return !toRemove.contains(comment)
                                            })
                                            self.modB.customView?.alpha = 1
                                        }
                                    }
                                }
                                if !self.context.isEmpty() {
                                    for comment in self.comments {
                                        if comment.contains(self.context) {
                                            self.menuId = comment
                                            self.tableView.reloadData()
                                            loaded = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                self.goToCell(i: index)
                                            }
                                            break
                                        } else {
                                            index += 1
                                        }
                                    }
                                    if !loaded {
                                        self.tableView.reloadData()
                                    }
                                } else if SettingValues.collapseDefault {
                                    self.tableView.reloadData()
                                    self.collapseAll()
                                } else {
                                    self.tableView.reloadData()
                                }
                            })
                        }
                    })
                }
            } catch {
                print(error)
        }

        }
    }

    var loaded = false

    var lastSeen: Double = NSDate().timeIntervalSince1970
    var savedTitleView: UIView?
    var savedHeaderView: UIView?

    override var navigationItem: UINavigationItem {
        if parent != nil && parent! is PagingCommentViewController {
            return parent!.navigationItem
        } else {
            return super.navigationItem
        }
    }
    
    func setupTitleView(_ sub: String) {
        let titleView = UILabel()
        titleView.text = sub
        titleView.textColor = SettingValues.reduceColor ? ColorUtil.fontColor : .white
        titleView.font = UIFont.boldSystemFont(ofSize: 17)
        let width = titleView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
        titleView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: 500))
        titleView.accessibilityTraits = UIAccessibilityTraitHeader | UIAccessibilityTraitLink
        titleView.accessibilityHint = "Opens the sub red it r \(sub)"
        titleView.accessibilityLabel = "Sub red it: r \(sub)"
        self.navigationItem.titleView = titleView
        
        titleView.addTapGestureRecognizer(action: {
            VCPresenter.openRedditLink("/r/\(sub)", self.navigationController, self)
        })
        
        if SettingValues.reduceColor {
            var sideView = UIView()
            sideView = UIView(frame: CGRect(x: -20, y: 15, width: 15, height: 15))
            sideView.backgroundColor = ColorUtil.getColorForSub(sub: sub)
            sideView.translatesAutoresizingMaskIntoConstraints = false
            titleView.addSubview(sideView)
            sideView.layer.cornerRadius = 7.5
            sideView.clipsToBounds = true
        }
    }

    var popup: UILabel!
    
    func doBanner(_ link: RSubmission) {
        if popup != nil {
            popup.removeFromSuperview()
        }
        var text = ""
        if np {
            text = "This is a no participation link.\nPlease don't vote or comment"
        }
        if link.archived {
            text = "This is an archived post.\nYou won't be able to vote or comment"
        } else if link.locked {
            text = "This is a locked post.\nYou won't be able to comment"
        }

        if !text.isEmpty && self.navigationController != nil {
            var top = CGFloat(64)
            var bottom = CGFloat(45)
            if #available(iOS 11.0, *) {
                top = 0
                bottom = 0
            }
            bottom += 64
            normalInsets = UIEdgeInsets.init(top: top, left: 0, bottom: bottom, right: 0)

            var width = UIScreen.main.bounds.width - 24
            if width > 375 {
                width = 375
            }
            popup = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: width, height: 48))
            popup.backgroundColor = ColorUtil.accentColorForSub(sub: link.subreddit)
            popup.textAlignment = .center
            popup.isUserInteractionEnabled = true

            let textParts = text.components(separatedBy: "\n")

            let finalText: NSMutableAttributedString!
            if textParts.count > 1 {
                let firstPart = NSMutableAttributedString.init(string: textParts[0], attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
                let secondPart = NSMutableAttributedString.init(string: "\n" + textParts[1], attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.systemFont(ofSize: 12)])
                firstPart.append(secondPart)
                finalText = firstPart
            } else {
                finalText = NSMutableAttributedString.init(string: text, attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
            }
            popup.attributedText = finalText

            popup.numberOfLines = 0

            popup.elevate(elevation: 2)
            popup.layer.cornerRadius = 5
            popup.clipsToBounds = true
            popup.transform = CGAffineTransform.init(scaleX: 0.001, y: 0.001)
            
            if let view = self.navigationController?.view {
                view.addSubview(popup)
                let bottomHeight: CGFloat
                if #available(iOS 11.0, *) {
                    bottomHeight = self.additionalSafeAreaInsets.bottom
                } else {
                    bottomHeight = 0
                }
                popup.bottomAnchor == self.navigationController!.view.safeBottomAnchor - 8 - 48 - bottomHeight
                popup.widthAnchor == width
                popup.heightAnchor == 48
                popup.centerXAnchor == self.navigationController!.view.centerXAnchor
                self.navigationController!.view.bringSubview(toFront: popup)
                
                UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                    self.popup.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
                }, completion: nil)
            }
        } else {
            var top = CGFloat(64)
            let bottom = CGFloat(45)
            if #available(iOS 11.0, *) {
                top = 0
            }
            normalInsets = UIEdgeInsets.init(top: top, left: 0, bottom: bottom, right: 0)
        }
        self.tableView.contentInset = normalInsets
    }
    
    var savedBack: UIBarButtonItem?

    func showSearchBar() {
        searchBar.alpha = 0
        savedHeaderView = tableView.tableHeaderView
        tableView.tableHeaderView = UIView()
        savedTitleView = navigationItem.titleView
        navigationItem.titleView = searchBar
        savedBack = navigationItem.leftBarButtonItem
        navigationItem.setRightBarButtonItems(nil, animated: true)
        navigationItem.setLeftBarButtonItems(nil, animated: true)
        self.navigationItem.setHidesBackButton(true, animated: false)
        UIView.animate(withDuration: 0.5, animations: {
            self.searchBar.alpha = 1
        }, completion: { _ in
            if ColorUtil.theme != .LIGHT {
                self.searchBar.keyboardAppearance = .dark
            }
            self.searchBar.becomeFirstResponder()
        })
    }

    var moreB = UIBarButtonItem()
    var modB = UIBarButtonItem()

    func hideSearchBar() {
        navigationController?.setNavigationBarHidden(false, animated: true)
        tableView.tableHeaderView = savedHeaderView!

        let sort = UIButton.init(type: .custom)
        sort.setImage(UIImage.init(named: "ic_sort_white")?.navIcon(), for: UIControlState.normal)
        sort.addTarget(self, action: #selector(self.sort(_:)), for: UIControlEvents.touchUpInside)
        sort.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let sortB = UIBarButtonItem.init(customView: sort)

        let search = UIButton.init(type: .custom)
        search.setImage(UIImage.init(named: "search")?.navIcon(), for: UIControlState.normal)
        search.addTarget(self, action: #selector(self.search(_:)), for: UIControlEvents.touchUpInside)
        search.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let searchB = UIBarButtonItem.init(customView: search)

        navigationItem.rightBarButtonItems = [sortB, searchB]
        navigationItem.leftBarButtonItem = savedBack

        navigationItem.titleView = savedTitleView
        
        isSearching = false
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSearchBar()
    }

    func sort(_ selector: UIButton?) {
        if !offline {
            let actionSheetController: UIAlertController = UIAlertController(title: "Default comment sorting", message: "", preferredStyle: .actionSheet)

            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)
            let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)

            for c in CommentSort.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: c.description, style: .default) { _ -> Void in
                    self.sort = c
                    self.reset = true
                    self.refresh(self)
                }
                if sort == c {
                    saveActionButton.setValue(selected, forKey: "image")
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

    var indicator: MDCActivityIndicator = MDCActivityIndicator()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.tableView.allowsSelection = false
        self.tableView.layer.speed = 1.5
        
        tableView.backgroundColor = ColorUtil.backgroundColor
        refreshControl = UIRefreshControl()
        self.tableView.contentOffset = CGPoint.init(x: 0, y: -self.refreshControl!.frame.size.height)
        refreshControl?.tintColor = ColorUtil.fontColor
        refreshControl?.attributedTitle = NSAttributedString(string: "")
        refreshControl?.addTarget(self, action: #selector(CommentViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        var top = CGFloat(64)
        let bottom = CGFloat(45)
        if #available(iOS 11.0, *) {
            top = 0
        }
        tableView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        if #available(iOS 10.0, *) {
        } else {
            tableView.addSubview(refreshControl!)
        }

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: nil, action: nil)

        searchBar.delegate = self
        searchBar.searchBarStyle = UISearchBarStyle.minimal
        searchBar.textColor = .white
        searchBar.showsCancelButton = true
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.white

        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension

        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "Cell")
        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "MoreCell")

        tableView.separatorStyle = .none
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillShow(_:)),
                name: NSNotification.Name.UIKeyboardWillShow,
                object: nil
        )
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillHide(_:)),
                name: NSNotification.Name.UIKeyboardWillHide,
                object: nil)

        headerCell = FullLinkCellView()
        headerCell!.del = self
        headerCell!.parentViewController = self
        headerCell!.aspectWidth = self.tableView.bounds.size.width

        headerCell!.configure(submission: submission!, parent: self, nav: self.navigationController, baseSub: submission!.subreddit, parentWidth: self.navigationController?.view.bounds.size.width ?? self.tableView.frame.size.width)
        headerCell!.showBody(width: self.view.frame.size.width - 24)

        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panCell))
        panGesture.direction = .horizontal
        panGesture.delegate = self
        
//        pan = UIPanGestureRecognizer(target: self, action: #selector(self.handlePop(_:)))
//        pan.direction = .horizontal
        
        self.tableView.addGestureRecognizer(panGesture)
        if navigationController != nil {
            panGesture.require(toFail: navigationController!.interactivePopGestureRecognizer!)
        }
    }

//    func handlePop(_ panGesture: UIPanGestureRecognizer) {
//
//        let percent = max(panGesture.translation(in: view).x, 0) / view.frame.width
//
//        switch panGesture.state {
//
//        case .began:
//            navigationController?.delegate = self
//            navigationController?.popViewController(animated: true)
//
//        case .changed:
//            UIPercentDrivenInteractiveTransition.update(percent)
//
//        case .ended:
//            let velocity = panGesture.velocity(in: view).x
//
//            // Continue if drag more than 50% of screen width or velocity is higher than 1000
//            if percent > 0.5 || velocity > 1000 {
//                UIPercentDrivenInteractiveTransition.finish(<#T##UIPercentDrivenInteractiveTransition#>)
//            } else {
//                UIPercentDrivenInteractiveTransition.cancelInteractiveTransition()
//            }
//
//        case .cancelled, .failed:
//            UIPercentDrivenInteractiveTransition.cancelInteractiveTransition()
//            
//        default:
//            break
//        }
//    }

    var keyboardHeight = CGFloat(0)

    func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            if keyboardHeight == 0 {
                keyboardHeight = keyboardRectangle.height
            }
//todo content insets

        }
    }

    var normalInsets = UIEdgeInsets(top: 0, left: 0, bottom: 45, right: 0)

    func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset = normalInsets
    }

    var single = true
    var hasDone = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if hasSubmission && self.view.frame.size.width != 0 {

            guard let headerCell = headerCell else {
                return
            }

            var frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: headerCell.estimateHeight(true))
            // Add safe area insets to left and right if available
            if #available(iOS 11.0, *) {
                frame = frame.insetBy(dx: max(view.safeAreaInsets.left, view.safeAreaInsets.right), dy: 0)
            }

            if self.tableView.tableHeaderView == nil || !frame.equalTo(headerCell.contentView.frame) {
                headerCell.contentView.frame = frame
                headerCell.contentView.layoutIfNeeded()
                let view = UIView(frame: headerCell.contentView.frame)
                view.addSubview(headerCell.contentView)
                self.tableView.tableHeaderView = view
            }

        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    var subreddit = ""

    // MARK: - Table view data source

    var forceLoad = false
    var startedOnce = false
    
    func doStartupItems() {
        if !startedOnce {
            startedOnce = true
            (navigationController)?.setNavigationBarHidden(false, animated: false)
            self.edgesForExtendedLayout = UIRectEdge.all
            self.extendedLayoutIncludesOpaqueBars = true
            
            self.commentDepthColors = ColorUtil.getCommentDepthColors()
            
            self.setupTitleView(submission == nil ? subreddit : submission!.subreddit)
            
            self.navigationItem.backBarButtonItem?.title = ""
            
            if submission != nil {
                self.setBarColors(color: ColorUtil.getColorForSub(sub: submission == nil ? subreddit : submission!.subreddit))
            }
            
            self.authorColor = ColorUtil.getCommentNameColor(submission == nil ? subreddit : submission!.subreddit)
            
            navigationController?.setToolbarHidden(false, animated: true)
            self.isToolbarHidden = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isHiding = true
        
        if navigationController != nil {
            let sort = UIButton.init(type: .custom)
            sort.accessibilityLabel = "Change sort type"
            sort.setImage(UIImage.init(named: "ic_sort_white")?.navIcon(), for: UIControlState.normal)
            sort.addTarget(self, action: #selector(self.sort(_:)), for: UIControlEvents.touchUpInside)
            sort.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let sortB = UIBarButtonItem.init(customView: sort)
            
            let search = UIButton.init(type: .custom)
            search.accessibilityLabel = "Search"
            search.setImage(UIImage.init(named: "search")?.navIcon(), for: UIControlState.normal)
            search.addTarget(self, action: #selector(self.search(_:)), for: UIControlEvents.touchUpInside)
            search.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            let searchB = UIBarButtonItem.init(customView: search)
            
            navigationItem.rightBarButtonItems = [sortB, searchB]
            navigationItem.rightBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -20)
        }
        
        doStartupItems()

        if !loaded && (single || forceLoad) {
            refresh(self)
        }

        if headerCell.videoView != nil {
            headerCell.videoView?.player?.play()
        }
        
        if isSearching {
            isSearching = false
            tableView.reloadData()
        }
        
        if SettingValues.reduceColor && ColorUtil.theme.isLight() {
            UIApplication.shared.statusBarStyle = .default
        } else {
            UIApplication.shared.statusBarStyle = .lightContent
        }
        if navigationController != nil && (didDisappearCompletely || !loaded) {
            self.setupTitleView(submission == nil ? subreddit : submission!.subreddit)
            self.updateToolbar()
        }
        
        if popup != nil {
            var width = UIScreen.main.bounds.width - 24
            if width > 375 {
                width = 375
            }
            self.navigationController!.view.addSubview(popup)
            popup.transform = .identity
            popup.bottomAnchor == self.navigationController!.view.safeBottomAnchor - 8
            popup.widthAnchor == width
            popup.heightAnchor == 48
            popup.centerXAnchor == self.navigationController!.view.centerXAnchor
            self.navigationController!.view.bringSubview(toFront: popup)
            
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.popup.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
            }, completion: nil)
        }
        
        if !loaded {
            refreshControl?.beginRefreshing()
        }
        
        if !(parent is PagingCommentViewController) && self.navigationController != nil {
            if (SettingValues.commentGesturesMode == .SWIPE_ANYWHERE || SettingValues.commentGesturesMode == .GESTURES) && !(self.navigationController?.delegate is SloppySwiper) {
                swiper = SloppySwiper.init(navigationController: self.navigationController!)
                self.navigationController!.delegate = swiper!
            }
        }
        
        if let interactiveGesture = self.navigationController?.interactivePopGestureRecognizer {
            self.tableView.panGestureRecognizer.require(toFail: interactiveGesture)
        }
    }

    var originalPosition: CGPoint?
    var currentPositionTouched: CGPoint?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad && Int(round(self.view.bounds.width / CGFloat(320))) > 1 && false {
            self.navigationController!.view.backgroundColor = .clear
        }
        self.isHiding = false
        didDisappearCompletely = false
    }

    var duringAnimation = false

    func close(_ sender: AnyObject) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func showMod(_ sender: AnyObject) {
        if !modLink.isEmpty() {
            VCPresenter.openRedditLink(self.modLink, self.navigationController, self)
        }
    }
    
    func showMenu(_ sender: AnyObject) {
        if !offline {
            let link = submission!

            let alertController: BottomSheetActionController = BottomSheetActionController()
            alertController.headerData = "Comment actions"

            alertController.addAction(Action(ActionData(title: "Refresh", image: UIImage(named: "sync")!.menuIcon()), style: .default, handler: { _ in
                self.reset = true
                self.refresh(self)
            }))

            alertController.addAction(Action(ActionData(title: "r/\(link.subreddit)", image: UIImage(named: "subs")!.menuIcon()), style: .default, handler: { _ in
                VCPresenter.openRedditLink("www.reddit.com/r/\(link.subreddit)", self.navigationController, self)
            }))

            alertController.addAction(Action(ActionData(title: "Related submissions", image: UIImage(named: "size")!.menuIcon()), style: .default, handler: { _ in
                let related = RelatedViewController.init(thing: self.submission!)
                VCPresenter.showVC(viewController: related, popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
            }))

            alertController.addAction(Action(ActionData(title: "r/\(link.subreddit) sidebar", image: UIImage(named: "info")!.menuIcon()), style: .default, handler: { _ in
                Sidebar.init(parent: self, subname: self.submission!.subreddit).displaySidebar()
            }))

            alertController.addAction(Action(ActionData(title: "Collapse child comments", image: UIImage(named: "comments")!.menuIcon()), style: .default, handler: { _ in
                self.collapseAll()
            }))

            VCPresenter.presentAlert(alertController, parentVC: self)
        }
    }

    var sub: String = ""

    var subInfo: Subreddit?

    func search(_ sender: AnyObject) {
        if !dataArray.isEmpty {
            showSearchBar()
        }
    }

    public func extendKeepMore(in comment: Thing, current depth: Int) -> ([(Thing, Int)]) {
        var buf: [(Thing, Int)] = []

        if let comment = comment as? Comment {
            buf.append((comment, depth))
            for obj in comment.replies.children {
                buf.append(contentsOf: extendKeepMore(in: obj, current: depth + 1))
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
            if pId == parentId {
                if let comment = thing as? Comment {
                    var relativeDepth = 0
                    for parent in buf {
                        if comment.parentId == parentId {
                            relativeDepth = parent.1 - depth
                            break
                        }
                    }
                    buf.append((comment, depth + relativeDepth))
                    buf.append(contentsOf: extendForMore(parentId: comment.getId(), comments: comments, current: depth + relativeDepth + 1))
                } else if let more = thing as? More {
                    var relativeDepth = 0
                    for parent in buf {
                        let parentId = parent.0 is Comment ? (parent.0 as! Comment).parentId : (parent.0 as! More).parentId
                        if more.parentId == parentId {
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
        var color = UIColor.black
        var first = true
        for thing in newComments {
            if first && thing.0 is Comment {
                color = ColorUtil.accentColorForSub(sub: ((newComments[0].0 as! Comment).subreddit))
                first = false
            }
            if let comment = thing.0 as? Comment {
                let html = comment.bodyHtml.preprocessedHTMLStringBeforeNSAttributedStringParsing
                self.text[comment.getId()] = TextDisplayStackView.createAttributedChunk(baseHTML: html, fontSize: 16, submission: false, accentColor: color)
            } else {
                let attr = NSMutableAttributedString(string: "more")
                self.text[(thing.0 as! More).getId()] = LinkParser.parse(attr, color)
            }
        }
    }

    var text: [String: NSAttributedString]

    func updateStringsSingle(_ newComments: [Object]) {
        let color = ColorUtil.accentColorForSub(sub: ((newComments[0] as! RComment).subreddit))
        for thing in newComments {
            if let comment = thing as? RComment {
                let html = comment.htmlText
                self.text[comment.getIdentifier()] = TextDisplayStackView.createAttributedChunk(baseHTML: html, fontSize: 16, submission: false, accentColor: color)
            } else {
                let attr = NSMutableAttributedString(string: "more")
                self.text[(thing as! RMore).getIdentifier()] = LinkParser.parse(attr, color)
            }

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
            } catch {
                print(error)
            }
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

    func loadAll(_ sender: AnyObject) {
        context = ""
        reset = true
        refreshControl?.beginRefreshing()
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

    func getCount(sort: CommentNavType) -> Int {
        var count = 0
        for comment in dataArray {
            let contents = content[comment]
            if contents is RComment && matches(comment: contents as! RComment, sort: sort) {
                count += 1
            }
        }
        return count
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }

    func showNavTypes(_ sender: UIView) {
        if !loaded {
            return
        }
        let alertController = BottomSheetActionController()
        alertController.headerData = "Navigation Type"
        alertController.settings.cancelView.hideCollectionViewBehindCancelView = false

        let link = getCount(sort: .LINK)
        let parents = getCount(sort: .PARENTS)
        let op = getCount(sort: .OP)
        let gilded = getCount(sort: .GILDED)
        let you = getCount(sort: .YOU)

        alertController.addAction(Action(ActionData(title: "Parent comment (\(parents))"), style: .default, handler: { _ in
            self.currentSort = .PARENTS
        }))

        alertController.addAction(Action(ActionData(title: "OP (\(op))"), style: .default, handler: { _ in
            self.currentSort = .OP
        }))

        alertController.addAction(Action(ActionData(title: "Link (\(link))"), style: .default, handler: { _ in
            self.currentSort = .LINK
        }))

        alertController.addAction(Action(ActionData(title: "You (\(you))"), style: .default, handler: { _ in
            self.currentSort = .YOU
        }))

        alertController.addAction(Action(ActionData(title: "Gilded (\(gilded))"), style: .default, handler: { _ in
            self.currentSort = .GILDED
        }))

        self.present(alertController, animated: true, completion: nil)
    }

    func goToCell(i: Int) {
        let indexPath = IndexPath(row: i, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .none, animated: true)

    }
    
    var goingToCell = false
    
    func goToCellTop(i: Int) {
        let indexPath = IndexPath(row: i, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        goingToCell = true
    }

    func goUp(_ sender: AnyObject) {
        if !loaded {
            return
        }
        var topCell = 0
        if let top = tableView.indexPathsForVisibleRows {
            if top.count > 0 {
                topCell = top[0].row
            }
        }
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionWeak()
        }
        var contents = content[dataArray[topCell]]

        while (contents is RComment ?  !matches(comment: contents as! RComment, sort: currentSort) : true ) && dataArray.count > topCell && topCell - 1 >= 0 {
            topCell -= 1
            contents = content[dataArray[topCell]]
        }
        goToCellTop(i: topCell)
        lastMoved = topCell
    }

    var lastMoved = -1

    func goDown(_ sender: AnyObject) {
        if !loaded {
            return
        }
        var topCell = 0
        if let top = tableView.indexPathsForVisibleRows {
            if top.count > 0 {
                topCell = top[0].row
            }
        }
        if #available(iOS 10.0, *) {
            HapticUtility.hapticActionWeak()
        }
        if topCell <= 0 && lastMoved < 0 {
            goToCellTop(i: 0)
            lastMoved = 0
        } else {
            var contents = content[dataArray[topCell]]
            while (contents is RMore || (contents as! RComment).depth > 1) && dataArray.count > topCell {
                topCell += 1
                contents = content[dataArray[topCell]]
            }
            for i in (topCell + 1)...(dataArray.count - 1) {
                contents = content[dataArray[i]]
                if contents is RComment && matches(comment: contents as! RComment, sort: currentSort) && i > lastMoved {
                    goToCellTop(i: i)
                    lastMoved = i
                    break
                }
            }
        }
    }

    func matches(comment: RComment, sort: CommentNavType) -> Bool {
        switch sort {
        case .PARENTS:
            if cDepth[comment.getIdentifier()]! == 1 {
                return true
            } else {
                return false
            }
        case .GILDED:
            if comment.gilded {
                return true
            } else {
                return false
            }
        case .OP:
            if comment.author == submission?.author {
                return true
            } else {
                return false
            }
        case .LINK:
            if comment.htmlText.contains("<a") {
                return true
            } else {
                return false
            }
        case .YOU:
            if AccountController.isLoggedIn && comment.author == AccountController.currentName {
                return true
            } else {
                return false
            }
        }

    }

    func updateToolbar() {
        navigationController?.setToolbarHidden(false, animated: false)
        self.isToolbarHidden = false
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        var items: [UIBarButtonItem] = []
        if !context.isEmpty() {
            items.append(space)
            let loadFullThreadButton = UIBarButtonItem.init(title: "Load full thread", style: .plain, target: self, action: #selector(CommentViewController.loadAll(_:)))
            loadFullThreadButton.accessibilityLabel = "Load full thread"
            items.append(loadFullThreadButton)
            items.append(space)
        } else {
            let up = UIButton(type: .custom)
            up.accessibilityLabel = "Navigate up one comment thread"
            up.setImage(UIImage(named: "up")?.toolbarIcon(), for: UIControlState.normal)
            up.addTarget(self, action: #selector(CommentViewController.goUp(_:)), for: UIControlEvents.touchUpInside)
            up.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            let upB = UIBarButtonItem(customView: up)

            let nav = UIButton(type: .custom)
            nav.accessibilityLabel = "Change criteria for comment thread navigation"
            nav.setImage(UIImage(named: "nav")?.toolbarIcon(), for: UIControlState.normal)
            nav.addTarget(self, action: #selector(CommentViewController.showNavTypes(_:)), for: UIControlEvents.touchUpInside)
            nav.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            let navB = UIBarButtonItem(customView: nav)

            let down = UIButton(type: .custom)
            down.accessibilityLabel = "Navigate down one comment thread"
            down.setImage(UIImage(named: "down")?.toolbarIcon(), for: UIControlState.normal)
            down.addTarget(self, action: #selector(CommentViewController.goDown(_:)), for: UIControlEvents.touchUpInside)
            down.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            let downB = UIBarButtonItem(customView: down)

            let more = UIButton(type: .custom)
            more.accessibilityLabel = "Post options"
            more.setImage(UIImage(named: "moreh")?.toolbarIcon(), for: UIControlState.normal)
            more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControlEvents.touchUpInside)
            more.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            moreB = UIBarButtonItem(customView: more)
            
            let mod = UIButton(type: .custom)
            mod.accessibilityLabel = "Moderator options"
            mod.setImage(UIImage(named: "mod")?.toolbarIcon(), for: UIControlState.normal)
            mod.addTarget(self, action: #selector(self.showMod(_:)), for: UIControlEvents.touchUpInside)
            mod.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            modB = UIBarButtonItem(customView: mod)
            if modLink.isEmpty() && modB.customView != nil {
                modB.customView? = UIView(frame: modB.customView!.frame)
            }

            items.append(modB)
            items.append(space)
            items.append(upB)
            items.append(space)
            items.append(navB)
            items.append(space)
            items.append(downB)
            items.append(space)
            items.append(moreB)
        }
        self.navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = false

        if parent != nil && parent is PagingCommentViewController {
            parent?.toolbarItems = items
            parent?.navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
            parent?.navigationController?.toolbar.tintColor = ColorUtil.fontColor
        } else {
            toolbarItems = items
            navigationController?.toolbar.barTintColor = ColorUtil.backgroundColor
            navigationController?.toolbar.tintColor = ColorUtil.fontColor
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (isSearching ? self.filteredData.count : self.comments.count - self.hidden.count)
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if SettingValues.collapseFully {
            let datasetPosition = (indexPath as NSIndexPath).row
            if dataArray.isEmpty {
                return UITableViewAutomaticDimension
            }
            let thing = isSearching ? filteredData[datasetPosition] : dataArray[datasetPosition]
            if !hiddenPersons.contains(thing) && thing != self.menuId {
                if let height = oldHeights[thing] {
                    return height
                }
            }
        }
        return UITableViewAutomaticDimension
    }

    var tagText: String?

    func tagUser(name: String) {
        let alertController = UIAlertController(title: "Tag \(AccountController.formatUsernamePosessive(input: name, small: true)) profile", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        let confirmAction = UIAlertAction(title: "Set", style: .default) { (_) in
            if let text = self.tagText {
                ColorUtil.setTagForUser(name: name, tag: text)
                self.tableView.reloadData()
            } else {
                // user did not fill field
            }
        }

        if !ColorUtil.getTagForUser(name: name).isEmpty {
            let removeAction = UIAlertAction(title: "Remove tag", style: .default) { (_) in
                ColorUtil.removeTagForUser(name: name)
                self.tableView.reloadData()
            }
            alertController.addAction(removeAction)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        }

        let config: TextField.Config = { textField in
            textField.becomeFirstResponder()
            textField.textColor = .black
            textField.placeholder = "Tag"
            textField.left(image: UIImage.init(named: "flag"), color: .black)
            textField.leftViewPadding = 12
            textField.borderWidth = 1
            textField.cornerRadius = 8
            textField.borderColor = UIColor.lightGray.withAlphaComponent(0.5)
            textField.backgroundColor = .white
            textField.keyboardAppearance = .default
            textField.keyboardType = .default
            textField.returnKeyType = .done
            textField.text = ColorUtil.getTagForUser(name: name)
            textField.action { textField in
                self.tagText = textField.text
            }
        }

        alertController.addOneTextField(configuration: config)

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)

    }

    var isCurrentlyChanging = false
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        inHeadView.removeFromSuperview()
        headerCell.videoView?.player?.pause()
        self.didDisappearCompletely = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isHiding = true
        self.inHeadView.removeFromSuperview()
        if popup != nil {
            UIView.animate(withDuration: 0.15, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                self.popup.transform = CGAffineTransform.identity.scaledBy(x: 0.001, y: 0.001)
            }, completion: { (_) in
                self.popup.removeFromSuperview()
            })
        }
    }

    func collapseAll() {
        if dataArray.count > 0 {
            for i in 0...dataArray.count - 1 {
                if content[dataArray[i]] is RComment && matches(comment: content[dataArray[i]] as! RComment, sort: .PARENTS) {
                    _ = hideNumber(n: dataArray[i], iB: i)
                    let t = content[dataArray[i]]
                    let id = (t is RComment) ? (t as! RComment).getIdentifier() : (t as! RMore).getIdentifier()
                    if !hiddenPersons.contains(id) {
                        hiddenPersons.insert(id)
                    }
                }
            }
            doArrays()
            tableView.reloadData()
        }
    }

    func hideAll(comment: String, i: Int) {
        if !isCurrentlyChanging {
            isCurrentlyChanging = true
            DispatchQueue.global(qos: .background).async {
                let counter = self.hideNumber(n: comment, iB: i) - 1
                self.doArrays()
                DispatchQueue.main.async {
                    self.tableView.beginUpdates()

                    var indexPaths: [IndexPath] = []
                    for row in i...counter {
                        indexPaths.append(IndexPath(row: row, section: 0))
                    }
                    self.tableView.deleteRows(at: indexPaths, with: .fade)
                    self.tableView.endUpdates()
                    self.isCurrentlyChanging = false
                }
            }
        }
    }

    func unhideAll(comment: String, i: Int) {
        if !isCurrentlyChanging {
            isCurrentlyChanging = true
            DispatchQueue.global(qos: .background).async {
                let counter = self.unhideNumber(n: comment, iB: i)
                self.doArrays()
                DispatchQueue.main.async {
                    self.tableView.beginUpdates()

                    var indexPaths: [IndexPath] = []
                    for row in (i + 1)...counter {
                        indexPaths.append(IndexPath(row: row, section: 0))
                    }
                    self.tableView.insertRows(at: indexPaths, with: .fade)
                    self.tableView.endUpdates()
                    self.isCurrentlyChanging = false
                }
            }
        }
    }

    func parentHidden(comment: Object) -> Bool {
        var n: String = ""
        if comment is RComment {
            n = (comment as! RComment).parentId
        } else {
            n = (comment as! RMore).parentId
        }
        return hiddenPersons.contains(n) || hidden.contains(n)
    }

    func walkTree(n: String) -> [String] {
        var toReturn: [String] = []
        if content[n] is RComment {
            let bounds = comments.index(where: { ($0 == n) })! + 1
            let parentDepth = (cDepth[n] ?? 0)
            for obj in stride(from: bounds, to: comments.count, by: 1) {
                if (cDepth[comments[obj]] ?? 0) > parentDepth {
                    toReturn.append(comments[obj])
                } else {
                    return toReturn
                }
            }
        }
        return toReturn
    }

    func walkTreeFlat(n: String) -> [String] {
        var toReturn: [String] = []
        if content[n] is RComment {
            let bounds = comments.index(where: { ($0 == n) })! + 1
            let parentDepth = (cDepth[n] ?? 0)
            for obj in stride(from: bounds, to: comments.count, by: 1) {
                let depth = (cDepth[comments[obj]] ?? 0)
                if depth == 1 + parentDepth {
                    toReturn.append(comments[obj])
                } else if depth == parentDepth {
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
            let bounds = comments.index(where: { $0 == n })! + 1
            let parentDepth = (cDepth[n] ?? 0)
            for obj in stride(from: bounds, to: comments.count, by: 1) {
                let currentDepth = cDepth[comments[obj]] ?? 0
                if currentDepth > parentDepth {
                    if currentDepth == parentDepth + 1 {
                        toReturn.append(contentsOf: walkTreeFully(n: comments[obj]))
                    }
                } else {
                    return toReturn
                }
            }
        }
        return toReturn
    }

    func vote(comment: RComment, dir: VoteDirection) {

        var direction = dir
        switch ActionStates.getVoteDirection(s: comment) {
        case .up:
            if dir == .up {
                direction = .none
            }
        case .down:
            if dir == .down {
                direction = .none
            }
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
        } catch {
            print(error)
        }
        ActionStates.setVoteDirection(s: comment, direction: direction)
    }

    func moreComment(_ cell: CommentDepthCell) {
        cell.more(self)
    }

    func modMenu(_ cell: CommentDepthCell) {
        cell.mod(self)
    }

    func deleteComment(cell: CommentDepthCell) {
        let alert = UIAlertController.init(title: "Really delete this comment?", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "Yes", style: .destructive, handler: { (_) in
            do {
                try self.session?.deleteCommentOrLink(cell.comment!.getIdentifier(), completion: { (_) in
                    DispatchQueue.main.async {
                        var realPosition = 0
                        for c in self.comments {
                            let id = c
                            if id == cell.comment!.getIdentifier() {
                                break
                            }
                            realPosition += 1
                        }
                        self.text[cell.comment!.getIdentifier()] = NSAttributedString(string: "[deleted]")
                        self.doArrays()
                        self.tableView.reloadData()
                    }
                })
            } catch {

            }
        }))
        alert.addAction(UIAlertAction.init(title: "No", style: .cancel, handler: nil))
        VCPresenter.presentAlert(alert, parentVC: self)
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    @objc func spacePressed() {
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.tableView.contentOffset.y += 350
        }, completion: nil)
    }

    func unhideNumber(n: String, iB: Int) -> Int {
        var i = iB
        let children = walkTreeFlat(n: n)
        var toHide: [String] = []
        for name in children {
            if hidden.contains(name) {
                i += 1
            }
            toHide.append(name)

            if !hiddenPersons.contains(name) {
                i += unhideNumber(n: name, iB: 0)
            }
        }
        for s in hidden {
            if toHide.contains(s) {
                hidden.remove(s)
            }
        }
        return i
    }

    func hideNumber(n: String, iB: Int) -> Int {
        var i = iB

        let children = walkTreeFlat(n: n)

        for name in children {
            if !hidden.contains(name) {
                i += 1
                hidden.insert(name)
            }
            i += hideNumber(n: name, iB: 0)
        }
        return i
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(
            alongsideTransition: { [unowned self] _ in
                if let header = self.tableView.tableHeaderView {
                    var frame = header.frame
                    var leftInset: CGFloat = 0
                    var rightInset: CGFloat = 0

                    if #available(iOS 11.0, *) {
                        leftInset = self.tableView.safeAreaInsets.left
                        rightInset = self.tableView.safeAreaInsets.right
                        frame.origin.x = leftInset
                    } else {
                        // Fallback on earlier versions
                    }

                    self.headerCell!.aspectWidth = size.width - (leftInset + rightInset)

                    frame.size.width = size.width - (leftInset + rightInset)
                    frame.size.height = self.headerCell!.estimateHeight(true, true)

                    self.headerCell!.contentView.frame = frame
                    self.tableView.tableHeaderView!.frame = frame
                    self.tableView.reloadData(with: .none)
                    self.doHeadView(size)
                    self.view.setNeedsLayout()
                }
            }, completion: nil)
    }
    
    var lastYUsed = CGFloat(0)
    var isToolbarHidden = false
    var isHiding = false
    var lastY = CGFloat(0)
    var oldY = CGFloat(0)

override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //self.tableView.endEditing(true)
        let currentY = scrollView.contentOffset.y
        if !SettingValues.pinToolbar {
            if currentY > lastYUsed && currentY > 60 {
                if navigationController != nil && !isHiding && !goingToCell && !isToolbarHidden && !(scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
                    hideUI(inHeader: true)
                }
            } else if (currentY < lastYUsed + 20) && !isHiding && navigationController != nil && (isToolbarHidden) {
                showUI()
                goingToCell = false
            }
        }
        lastYUsed = currentY
        lastY = currentY
    }

    func hideUI(inHeader: Bool) {
        isHiding = true
        //self.tableView.endEditing(true)
        if inHeadView.superview == nil {
            doHeadView(self.view.frame.size)
        }
        (navigationController)?.setNavigationBarHidden(true, animated: true)
        
        if popup == nil {
            (self.navigationController)?.setToolbarHidden(true, animated: true)
        }
        
        self.isToolbarHidden = true
        isHiding = false
    }

    func showUI() {
        (navigationController)?.setNavigationBarHidden(false, animated: true)
        (navigationController)?.setToolbarHidden(false, animated: true)
        self.isToolbarHidden = false
    }

override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell! = nil

    let datasetPosition = (indexPath as NSIndexPath).row

    cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
    if content.isEmpty || text.isEmpty || cDepth.isEmpty || dataArray.isEmpty {
        self.refresh(self)
        return cell
    }
    let thing = isSearching ? filteredData[datasetPosition] : dataArray[datasetPosition]
    let parentOP = parents[thing]
        if let cell = cell as? CommentDepthCell {
            if content[thing] is RComment {
                var count = 0
                let hiddenP = hiddenPersons.contains(thing)
                if hiddenP {
                    count = getChildNumber(n: content[thing]!.getIdentifier())
                }
                var t = text[thing]!
                if isSearching {
                    t = highlight(t)
                }

                cell.setComment(comment: content[thing] as! RComment, depth: cDepth[thing]!, parent: self, hiddenCount: count, date: lastSeen, author: submission?.author, text: t, isCollapsed: hiddenP, parentOP: parentOP ?? "", depthColors: commentDepthColors, indexPath: indexPath)
            } else {
                cell.setMore(more: (content[thing] as! RMore), depth: cDepth[thing]!, depthColors: commentDepthColors, parent: self)
            }
            cell.content = content[thing]
        }
        return cell
    }

//    @available(iOS 11.0, *)
//    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        let cell = tableView.cellForRow(at: indexPath)
//        if cell is CommentDepthCell && (cell as! CommentDepthCell).comment != nil && (SettingValues.commentActionRightLeft != .NONE || SettingValues.commentActionRightRight != .NONE) {
//            HapticUtility.hapticActionWeak()
//            var actions = [UIContextualAction]()
//            if SettingValues.commentActionRightRight != .NONE {
//                let action = UIContextualAction.init(style: .normal, title: "", handler: { (action, _, b) in
//                    b(true)
//                    self.doAction(cell: cell as! CommentDepthCell, action: SettingValues.commentActionRightRight, indexPath: indexPath)
//                })
//                action.backgroundColor = SettingValues.commentActionRightRight.getColor()
//                action.image = UIImage.init(named: SettingValues.commentActionRightRight.getPhoto())?.navIcon()
//
//                actions.append(action)
//            }
//            if SettingValues.commentActionRightLeft != .NONE {
//                let action = UIContextualAction.init(style: .normal, title: "", handler: { (action, _, b) in
//                    b(true)
//                    self.doAction(cell: cell as! CommentDepthCell, action: SettingValues.commentActionRightLeft, indexPath: indexPath)
//                })
//                action.backgroundColor = SettingValues.commentActionRightLeft.getColor()
//                action.image = UIImage.init(named: SettingValues.commentActionRightLeft.getPhoto())?.navIcon()
//
//                actions.append(action)
//            }
//            let config = UISwipeActionsConfiguration.init(actions: actions)
//
//            return config
//
//        } else {
//            return UISwipeActionsConfiguration.init()
//        }
//    }
//
//    @available(iOS 11.0, *)
//    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        let cell = tableView.cellForRow(at: indexPath)
//        if cell is CommentDepthCell && (cell as! CommentDepthCell).comment != nil && SettingValues.commentGesturesEnabled && (SettingValues.commentActionLeftLeft != .NONE || SettingValues.commentActionLeftRight != .NONE) {
//            HapticUtility.hapticActionWeak()
//            var actions = [UIContextualAction]()
//            if SettingValues.commentActionLeftLeft != .NONE {
//                let action = UIContextualAction.init(style: .normal, title: "", handler: { (action, _, b) in
//                    b(true)
//                    self.doAction(cell: cell as! CommentDepthCell, action: SettingValues.commentActionLeftLeft, indexPath: indexPath)
//                })
//                action.backgroundColor = SettingValues.commentActionLeftLeft.getColor()
//                action.image = UIImage.init(named: SettingValues.commentActionLeftLeft.getPhoto())?.navIcon()
//
//                actions.append(action)
//            }
//            if SettingValues.commentActionLeftRight != .NONE {
//                let action = UIContextualAction.init(style: .normal, title: "", handler: { (action, _, b) in
//                    b(true)
//                    self.doAction(cell: cell as! CommentDepthCell, action: SettingValues.commentActionLeftRight, indexPath: indexPath)
//                })
//                action.backgroundColor = SettingValues.commentActionLeftRight.getColor()
//                action.image = UIImage.init(named: SettingValues.commentActionLeftRight.getPhoto())?.navIcon()
//
//                actions.append(action)
//            }
//            let config = UISwipeActionsConfiguration.init(actions: actions)
//
//            return config
//
//        } else {
//            return UISwipeActionsConfiguration.init()
//        }
//    }

    func doAction(cell: CommentDepthCell, action: SettingValues.CommentAction, indexPath: IndexPath) {
        switch action {
        case .UPVOTE:
            cell.upvote(cell)
        case .DOWNVOTE:
            cell.downvote(cell)
        case .SAVE:
            cell.save()
        case .MENU:
            cell.menu(cell)
        case .COLLAPSE:
            collapseParent(indexPath, baseCell: cell)
        case .REPLY:
            cell.reply(cell)
        case .EXIT:
            self.close(cell)
        case .NEXT:
            if parent is PagingCommentViewController {
                (parent as! PagingCommentViewController).next()
            }
        case .NONE:
            break
        }
    }

    func collapseParent(_ indexPath: IndexPath, baseCell: CommentDepthCell) {
        var topCell = indexPath.row
        var contents = content[dataArray[topCell]]
        var id = ""
        if (contents as! RComment).depth == 1 {
            //collapse self
            id = baseCell.comment!.getIdentifier()
        } else {
            while (contents is RMore || (contents as! RComment).depth > 1) && 0 <= topCell {
                topCell -= 1
                contents = content[dataArray[topCell]]
            }
            var skipTop = false
            let indexPath = IndexPath.init(row: topCell, section: 0)
            for index in tableView.indexPathsForVisibleRows ?? [] {
                if index.row == topCell {
                    skipTop = true
                    break
                }
            }
            
            if !skipTop {
                self.tableView.scrollToRow(at: indexPath,
                                           at: UITableViewScrollPosition.none, animated: false)
            }
            
            id = (contents as! RComment).getIdentifier()
        }
        let childNumber = getChildNumber(n: id)
        let indexPath = IndexPath.init(row: topCell, section: 0)
        if let c = tableView.cellForRow(at: indexPath) {
            let cell = c as! CommentDepthCell
            if childNumber == 0 {
                if !SettingValues.collapseFully {
                } else if cell.isCollapsed {
                } else {
                    oldHeights[cell.comment!.getIdentifier()] = cell.contentView.frame.size.height
                    if !hiddenPersons.contains(cell.comment!.getIdentifier()) {
                        hiddenPersons.insert(cell.comment!.getIdentifier())
                    }
                    self.tableView.beginUpdates()
                    oldHeights[cell.comment!.getIdentifier()] = cell.contentView.frame.size.height
                    cell.collapse(childNumber: 0)
                    self.tableView.endUpdates()
                }
            } else {
                oldHeights[cell.comment!.getIdentifier()] = cell.contentView.frame.size.height
                cell.collapse(childNumber: childNumber)
                if hiddenPersons.contains((id)) && childNumber > 0 {
                } else {
                    if childNumber > 0 {
                        hideAll(comment: id, i: topCell + 1)
                        if !hiddenPersons.contains(id) {
                            hiddenPersons.insert(id)
                        }
                    }
                }
            }
        }
    }
    
    var oldHeights = [String: CGFloat]()

    func getChildNumber(n: String) -> Int {
        let children = walkTreeFully(n: n)
        return children.count - 1
    }

    func highlight(_ cc: NSAttributedString) -> NSAttributedString {
        let base = NSMutableAttributedString.init(attributedString: cc)
        let r = base.mutableString.range(of: "\(searchBar.text!)", options: .caseInsensitive, range: NSRange(location: 0, length: base.string.length))
        if r.length > 0 {
            base.addAttribute(NSForegroundColorAttributeName, value: ColorUtil.accentColorForSub(sub: subreddit), range: r)
        }
        return base.attributedSubstring(from: NSRange.init(location: 0, length: base.length))
    }

    var isSearching = false

    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String) {
        filteredData = []
        if textSearched.length != 0 {
            isSearching = true
            searchTableList()
        } else {
            isSearching = false
        }
        tableView.reloadData()
    }

    func searchTableList() {
        let searchString = searchBar.text
        var count = 0
        for p in dataArray {
            let s = content[p]
            if s is RComment {
                if (s as! RComment).htmlText.localizedCaseInsensitiveContains(searchString!) {
                    filteredData.append(p)
                }
            }
            count += 1
        }
    }

    var isReply = false

    func pushedSingleTap(_ cell: CommentDepthCell) {
        if !isReply {
            if isSearching {
                hideSearchBar()
                context = (cell.content as! RComment).getIdentifier()
                var index = 0
                if !self.context.isEmpty() {
                    for c in self.dataArray {
                        let comment = content[c]
                        if comment is RComment && (comment as! RComment).getIdentifier().contains(self.context) {
                            self.menuId = comment!.getIdentifier()
                            self.tableView.reloadData()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.goToCell(i: index)
                            }
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
                    let childNumber = getChildNumber(n: comment.getIdentifier())
                    if childNumber == 0 {
                        if !SettingValues.collapseFully {
                            cell.showMenu(nil)
                        } else if cell.isCollapsed {
                            self.tableView.beginUpdates()
                            cell.expandSingle()
                            self.tableView.endUpdates()
                            if hiddenPersons.contains((id)) {
                                hiddenPersons.remove(at: hiddenPersons.index(of: id)!)
                            }
                        } else {
                            oldHeights[cell.comment!.getIdentifier()] = cell.contentView.frame.size.height
                            if !hiddenPersons.contains(id) {
                                hiddenPersons.insert(id)
                            }
                            
                            self.tableView.beginUpdates()
                            cell.collapse(childNumber: 0)
                            self.tableView.endUpdates()
                        }
                    } else {
                        if hiddenPersons.contains((id)) && childNumber > 0 {
                            hiddenPersons.remove(at: hiddenPersons.index(of: id)!)
                            unhideAll(comment: comment.getId(), i: row!)
                            cell.expand()
                            //todo hide child number
                        } else {
                            if childNumber > 0 {
                                hideAll(comment: comment.getIdentifier(), i: row! + 1)
                                if !hiddenPersons.contains(id) {
                                    hiddenPersons.insert(id)
                                }
                                if childNumber > 0 {
                                    oldHeights[cell.comment!.getIdentifier()] = cell.contentView.frame.size.height
                                    cell.collapse(childNumber: childNumber)
                                }
                            }
                        }
                    }
                } else {
                    let datasetPosition = tableView.indexPath(for: cell)?.row ?? -1
                    if datasetPosition == -1 {
                        return
                    }
                    if let more = content[dataArray[datasetPosition]] as? RMore, let link = self.submission {
                        if more.children.isEmpty {
                            VCPresenter.openRedditLink("https://www.reddit.com" + submission!.permalink + more.parentId.substring(3, length: more.parentId.length - 3), self.navigationController, self)
                        } else {
                            do {
                                var strings: [String] = []
                                for c in more.children {
                                    strings.append(c.value)
                                }
                                cell.animateMore()
                                try session?.getMoreChildren(strings, name: link.id, sort: .new, id: more.id, completion: { (result) -> Void in
                                    switch result {
                                    case .failure(let error):
                                        print(error)
                                    case .success(let list):
                                        DispatchQueue.main.async(execute: { () -> Void in
                                            let startDepth = self.cDepth[more.getIdentifier()] ?? 0

                                            var queue: [Object] = []
                                            for i in self.extendForMore(parentId: more.parentId, comments: list, current: startDepth) {
                                                let item = i.0 is Comment ? RealmDataWrapper.commentToRComment(comment: i.0 as! Comment, depth: i.1) : RealmDataWrapper.moreToRMore(more: i.0 as! More)
                                                queue.append(item)
                                                self.cDepth[item.getIdentifier()] = i.1
                                                self.updateStrings([i])
                                            }

                                            var realPosition = 0
                                            for comment in self.comments {
                                                if comment == more.getIdentifier() {
                                                    break
                                                }
                                                realPosition += 1
                                            }

                                            self.comments.remove(at: realPosition)
                                            self.dataArray.remove(at: datasetPosition)
                                            
                                            let currentParent = self.parents[more.getIdentifier()]

                                            var ids: [String] = []
                                            for item in queue {
                                                let id = item.getIdentifier()
                                                self.parents[id] = currentParent
                                                ids.append(id)
                                                self.content[id] = item
                                            }

                                            if queue.count != 0 {
                                                self.tableView.beginUpdates()
                                                self.tableView.deleteRows(at: [IndexPath.init(row: datasetPosition, section: 0)], with: .fade)
                                                self.dataArray.insert(contentsOf: ids, at: datasetPosition)
                                                self.comments.insert(contentsOf: ids, at: realPosition)
                                                self.doArrays()
                                                var paths: [IndexPath] = []
                                                for i in stride(from: datasetPosition, to: datasetPosition + queue.count, by: 1) {
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

                            } catch {
                                print(error)
                            }
                        }
                    }
                }
            }
        }
    }

    func mod(_ cell: LinkCellView) {
        PostActions.showModMenu(cell, parent: self)
    }
}

extension Thing {
    func getId() -> String {
        return Self.kind + "_" + id
    }
}

extension CommentViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == panGesture {
            if SettingValues.commentGesturesMode == .NONE || SettingValues.commentGesturesMode == .SWIPE_ANYWHERE {
                return false
            }
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.numberOfTouches == 2 {
            return true
        }
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Limit angle of pan gesture recognizer to avoid interfering with scrolling
        if gestureRecognizer == panGesture {
            if SettingValues.commentGesturesMode == .NONE || SettingValues.commentGesturesMode == .SWIPE_ANYWHERE {
                return false
            }
        }
        
        if let recognizer = gestureRecognizer as? UIPanGestureRecognizer, recognizer == panGesture {
            return recognizer.shouldRecognizeForAxis(.horizontal, withAngleToleranceInDegrees: 45)
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return SettingValues.commentActionRightLeft == .NONE && SettingValues.commentActionRightRight == .NONE && translatingCell == nil
    }
    
    func panCell(_ recognizer: UIPanGestureRecognizer) {
        
        if recognizer.view != nil {
            let velocity = recognizer.velocity(in: recognizer.view!).x
            if (velocity < 0 && (SettingValues.commentActionLeftLeft == .NONE && SettingValues.commentActionLeftRight == .NONE) && translatingCell == nil) || (velocity > 0 && (SettingValues.commentActionRightLeft == .NONE && SettingValues.commentActionRightRight == .NONE) && translatingCell == nil) {
                return
            }
        }

        if recognizer.state == .began || translatingCell == nil {
            let point = recognizer.location(in: self.tableView)
            let indexpath = self.tableView.indexPathForRow(at: point)
            if indexpath == nil {
                return
            }

            guard let cell = self.tableView.cellForRow(at: indexpath!) as? CommentDepthCell else { return }
            translatingCell = cell
        }
        
        translatingCell?.handlePan(recognizer)
        if recognizer.state == .ended {
            translatingCell = nil
        }
    }
}
