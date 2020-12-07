//
//  ViewController.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 01/04/17.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import reddift
import SDWebImage
import UIKit

class ContentListingViewController: MediaViewController, UICollectionViewDelegate, WrappingFlowLayoutDelegate, UICollectionViewDataSource, SubmissionMoreDelegate, UIScrollViewDelegate, UINavigationControllerDelegate, AutoplayScrollViewDelegate {
    var currentPlayingIndex = [IndexPath]()
    
    var isScrollingDown = true
    
    var lastScrollDirectionWasDown = false
    
    var lastYUsed = CGFloat.zero
    
    var lastY = CGFloat.zero
    
    func getTableView() -> UICollectionView {
        return self.tableView
    }
    
    var autoplayHandler: AutoplayScrollViewHandler!
    func headerOffset() -> Int {
        return 0
    }
    
    func subscribe(link: Submission) {
        let sub = link.subreddit
        let alrController = UIAlertController.init(title: "Follow r/\(sub)", message: nil, preferredStyle: .alert)
        if AccountController.isLoggedIn {
            let somethingAction = UIAlertAction(title: "Subscribe", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) in
                Subscriptions.subscribe(sub, true, session: self.session!)
                self.subChanged = true
                BannerUtil.makeBanner(text: "Subscribed\nr/\(sub)", color: ColorUtil.accentColorForSub(sub: sub), seconds: 3, context: self, top: true)
            })
            alrController.addAction(somethingAction)
        }
        
        let somethingAction = UIAlertAction(title: "Casually subscribe", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) in
            Subscriptions.subscribe(sub, false, session: self.session!)
            self.subChanged = true
            BannerUtil.makeBanner(text: "Added\nr/\(sub) ", color: ColorUtil.accentColorForSub(sub: sub), seconds: 3, context: self, top: true)
        })
        alrController.addAction(somethingAction)
        
        alrController.addCancelButton()
        
        alrController.modalPresentationStyle = .fullScreen
        self.present(alrController, animated: true, completion: {})
    }
    
    func hide(index: Int) {
        baseData.content.remove(at: index)
        flowLayout.reset(modal: presentingViewController != nil, vc: self, isGallery: false)
        tableView.reloadData()
    }
    
    func applyFilters() {
        self.baseData.getData(reload: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        for index in tableView.indexPathsForVisibleItems {
            if let cell = tableView.cellForItem(at: index) as? LinkCellView {
                cell.endVideos()
                self.currentPlayingIndex = self.currentPlayingIndex.filter({ (included) -> Bool in
                    return included.row != index.row
                })
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight && SettingValues.reduceColor {
                        if #available(iOS 13, *) {
                return .darkContent
            } else {
                return .default
            }

        } else {
            return .lightContent
        }
    }
    
    @objc func showSortMenu(_ selector: UIButton?) {
        if baseData is ProfileContributionLoader {
            let actionSheetController = DragDownAlertMenu(title: "Profile sorting", subtitle: "", icon: nil, themeColor: ColorUtil.baseAccent, full: true)
            
            let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)
            
            for link in UserContentSortBy.cases {
                actionSheetController.addAction(title: link.description, icon: userSort == link ? selected : nil) {
                    self.showTimeMenuUser(s: link, selector: selector)
                }
            }
            
            actionSheetController.show(self)
        }
    }
    
    func showFilterMenu(_ cell: LinkCellView) {
        //Not implemented
    }
    public var inHeadView = UIView()
    
    var baseData: ContributionLoader
    var session: Session?
    var tableView: UICollectionView!
    var loaded = false
    
    init(dataSource: ContributionLoader) {
        baseData = dataSource
        super.init(nibName: nil, bundle: nil)
        autoplayHandler = AutoplayScrollViewHandler(delegate: self)
        baseData.delegate = self
        setBarColors(color: baseData.color)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func failed(error: Error) {
        print(error.localizedDescription)
        loaded = true
        loading = false
        DispatchQueue.main.async {
            self.emptyStateView.isHidden = false
            self.endAndResetRefresh()
        }
    }
    
    @objc func drefresh(_ sender: AnyObject) {
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.delegate = self
        
        if !loaded && !loading {
            self.tableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height)
            refreshControl.beginRefreshing()
        } else {
            self.tableView.reloadData()
        }
        if let interactiveGesture = self.navigationController?.interactivePopGestureRecognizer {
            self.tableView.panGestureRecognizer.require(toFail: interactiveGesture)
        }
        autoplayHandler.autoplayOnce(self.tableView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !loading && !loaded {
            refresh()
        }
        
        setupBaseBarColors()
    }
    
    var flowLayout: WrappingFlowLayout = WrappingFlowLayout.init()
    var emptyStateView = EmptyStateView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseBarColors()
        
        flowLayout.delegate = self
        self.tableView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        self.view = UIView.init(frame: CGRect.zero)
        self.view.addSubview(tableView)
        tableView.verticalAnchors /==/ view.verticalAnchors
        tableView.horizontalAnchors /==/ view.safeHorizontalAnchors
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        refreshControl = UIRefreshControl()
        refreshControl.tintColor = ColorUtil.theme.fontColor
        
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl)
        refreshControl.centerAnchors /==/ tableView.centerAnchors
        
        tableView.alwaysBounceVertical = true
        
        self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner")
        self.tableView.register(AutoplayBannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "autoplay")
        self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb")
        self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text")
        self.tableView.register(CommentCellView.classForCoder(), forCellWithReuseIdentifier: "comment")
        self.tableView.register(MessageCellView.classForCoder(), forCellWithReuseIdentifier: "message")
        self.tableView.register(ModlogCellView.classForCoder(), forCellWithReuseIdentifier: "modlog")
        self.tableView.register(FriendCellView.classForCoder(), forCellWithReuseIdentifier: "friend")
        tableView.backgroundColor = ColorUtil.theme.backgroundColor
        
        var top = 0
        
        top += ((self.baseData is FriendsContributionLoader || baseData is ProfileContributionLoader || baseData is InboxContributionLoader || baseData is CollectionsContributionLoader || baseData is ModQueueContributionLoader || baseData is ModMailContributionLoader) ? 45 : 0)
        
        self.tableView.contentInset = UIEdgeInsets.init(top: CGFloat(top), left: 0, bottom: 65, right: 0)
        
        self.view.addSubview(emptyStateView)
        if self is ReadLaterViewController {
            emptyStateView.setText(title: "No Saved Posts", message: "Go add posts to Read Later to see them here.")
        } else {
            emptyStateView.setText(title: "Nothing to see here!", message: "No content was found.")
        }
        emptyStateView.isHidden = true
        emptyStateView.edgeAnchors /==/ self.tableView.edgeAnchors
        self.view.bringSubviewToFront(emptyStateView)
        
        session = (UIApplication.shared.delegate as! AppDelegate).session
        
        flowLayout.reset(modal: presentingViewController != nil, vc: self, isGallery: false)
        tableView.reloadData()
    }
    
    var oldsize = CGFloat(0)
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.view.bounds.width != oldsize {
            oldsize = self.view.bounds.width
            flowLayout.reset(modal: presentingViewController != nil, vc: self, isGallery: false)
            tableView.reloadData()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        oldsize = self.view.bounds.width
        coordinator.animate(
            alongsideTransition: { [unowned self] _ in
                self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: false)
                self.view.setNeedsLayout()
            }, completion: nil
        )
    }
    
    var tC: UIViewController?
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return baseData.content.count
    }
    
    func collectionView(_ tableView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let thing = baseData.content[indexPath.row]
        var cell: UICollectionViewCell?
        if thing is Submission {
            let tableWidth = self.tableView.frame.size.width
            var c: LinkCellView?
            switch SingleSubredditViewController.cellType(foSubmission: thing as! Submission, false, cellWidth: (tableWidth == 0 ? UIScreen.main.bounds.size.width : tableWidth) ) {
            case .thumb:
                c = tableView.dequeueReusableCell(withReuseIdentifier: "thumb", for: indexPath) as! ThumbnailLinkCellView
            case .banner:
                c = tableView.dequeueReusableCell(withReuseIdentifier: "banner", for: indexPath) as! BannerLinkCellView
            case .autoplay:
                c = tableView.dequeueReusableCell(withReuseIdentifier: "autoplay", for: indexPath) as! AutoplayBannerLinkCellView
            default:
                if !SettingValues.hideImageSelftext && (thing as! Submission).imageHeight > 0 {
                    c = tableView.dequeueReusableCell(withReuseIdentifier: "banner", for: indexPath) as! BannerLinkCellView
                } else {
                    c = tableView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as! TextLinkCellView
                }
            }
            
            c?.preservesSuperviewLayoutMargins = false
            c?.del = self
            
            (c)!.configure(submission: thing as! Submission, parent: self, nav: self.navigationController, baseSub: "", np: false)
                        
            if self is ReadLaterViewController {
                c?.readLater.isHidden = false
            }
            
            cell = c
        } else if thing is CommentModel {
            let c = tableView.dequeueReusableCell(withReuseIdentifier: "comment", for: indexPath) as! CommentCellView
            c.setComment(comment: (thing as! CommentModel), parent: self, nav: self.navigationController, width: self.view.frame.size.width)
            cell = c
        } else if thing is FriendModel {
            let c = tableView.dequeueReusableCell(withReuseIdentifier: "friend", for: indexPath) as! FriendCellView
            c.setFriend(friend: (thing as! FriendModel), parent: self)
            cell = c
        } else if thing is MessageModel {
            let c = tableView.dequeueReusableCell(withReuseIdentifier: "message", for: indexPath) as! MessageCellView
            c.setMessage(message: (thing as! MessageModel), parent: self, nav: self.navigationController, width: self.view.frame.size.width)
            cell = c
        } else {
            //Is mod log item
            let c = tableView.dequeueReusableCell(withReuseIdentifier: "modlog", for: indexPath) as! ModlogCellView
            c.setLogItem(logItem: (thing as! RModlogItem), parent: self, nav: self.navigationController, width: self.view.frame.size.width)
            cell = c
        }
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is AutoplayBannerLinkCellView {
            (cell as! AutoplayBannerLinkCellView).doLoadVideo()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, width: CGFloat, indexPath: IndexPath) -> CGSize {
        let itemWidth = width
        
        if indexPath.row < baseData.content.count {
            let thing = baseData.content[indexPath.row]
            
            if thing is Submission {
                let submission = thing as! Submission
                return SingleSubredditViewController.sizeWith(submission, width, false, false)
            } else if thing is CommentModel {
                let comment = thing as! CommentModel
                if estimatedHeights[comment.id] == nil {
                    let titleText = CommentCellView.getTitle(comment)
                    
                    let height = TextDisplayStackView.estimateHeight(fontSize: 16, submission: false, width: itemWidth - 16, titleString: titleText, htmlString: comment.htmlBody)
                    
                    estimatedHeights[comment.id] = height + 20
                }
                return CGSize(width: itemWidth, height: estimatedHeights[comment.id]!)
            } else if thing is FriendModel {
                return CGSize(width: itemWidth, height: 70)
            } else if thing is MessageModel {
                let message = thing as! MessageModel
                if estimatedHeights[message.id] == nil {
                    let titleText = MessageCellView.getTitleText(message: message)
                    
                    let height = TextDisplayStackView.estimateHeight(fontSize: 16, submission: false, width: itemWidth - 16 - (message.subject.unescapeHTML.hasPrefix("re:") ? 30 : 0), titleString: titleText, htmlString: message.htmlBody)
                    
                    estimatedHeights[message.id] = height + 20
                }
                return CGSize(width: itemWidth, height: estimatedHeights[message.id]!)
            } else {
                let logItem = thing as! ModlogModel
                if estimatedHeights[logItem.id] == nil {
                    let titleText = ModlogCellView.getTitleText(item: logItem)
                    
                    let height = TextDisplayStackView.estimateHeight(fontSize: 16, submission: false, width: itemWidth - 16, titleString: titleText, htmlString: logItem.targetTitle)
                    
                    estimatedHeights[logItem.id] = height + 20
                }
                return CGSize(width: itemWidth, height: estimatedHeights[logItem.id]!)
            }
        }
        return CGSize(width: itemWidth, height: 90)
    }
    
    var estimatedHeights: [String: CGFloat] = [:]
    
    var showing = false
    
    func showLoader() {
        showing = true
       // TODO: - maybe add this later
    }
    
    var sort = LinkSortType.hot
    var userSort = UserContentSortBy.new
    var time = TimeFilterWithin.day
    
    func showMenu(sender: UIButton?) {
        let actionSheetController = DragDownAlertMenu(title: "Sorting", subtitle: "", icon: nil, themeColor: ColorUtil.baseAccent, full: true)
        
        let selected = UIImage(sfString: SFSymbol.checkmarkCircle, overrideString: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)
        
        for link in LinkSortType.cases {
            actionSheetController.addAction(title: link.description, icon: sort == link ? selected : nil) {
                self.showTimeMenu(s: link, selector: sender)
            }
        }
        
        actionSheetController.show(self)
    }
    
    func showTimeMenuUser(s: UserContentSortBy, selector: UIButton?) {
        if s == .hot || s == .new {
            userSort = s
            refresh()
            return
        } else {
            let actionSheetController = DragDownAlertMenu(title: "Select a time period", subtitle: "", icon: nil, themeColor: ColorUtil.baseAccent, full: true)
            
            for t in TimeFilterWithin.cases {
                actionSheetController.addAction(title: t.param, icon: nil) {
                    self.userSort = s
                    self.time = t
                    self.refresh()
                }
            }
            
            actionSheetController.show(self)
        }
    }
    
    func showTimeMenu(s: LinkSortType, selector: UIButton?) {
        if s == .hot || s == .new || s == .rising || s == .best {
            sort = s
            refresh()
            return
        } else {
            let actionSheetController = DragDownAlertMenu(title: "Select a time period", subtitle: "", icon: nil, themeColor: ColorUtil.baseAccent, full: true)
            
            for t in TimeFilterWithin.cases {
                actionSheetController.addAction(title: t.param, icon: nil) {
                    self.sort = s
                    self.time = t
                    self.refresh()
                }
            }
            
            actionSheetController.show(self)
        }
    }
    
    func doHeadView() {
        inHeadView.removeFromSuperview()
        var statusBarHeight = UIApplication.shared.statusBarUIView?.frame.size.height ?? 0
        if statusBarHeight == 0 {
            statusBarHeight = (self.navigationController?.navigationBar.frame.minY ?? 20)
        }

        inHeadView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: max(self.view.frame.size.width, self.view.frame.size.height), height: statusBarHeight))
        self.inHeadView.backgroundColor = ColorUtil.getColorForSub(sub: "", true)
        
        if !(navigationController is TapBehindModalViewController) {
            self.view.addSubview(inHeadView)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? AutoplayBannerLinkCellView {
            if cell.videoView != nil {
                cell.endVideos()
                self.currentPlayingIndex = self.currentPlayingIndex.filter({ (included) -> Bool in
                    return included.row != indexPath.row
                })
            }
        }
        if let cell = cell as? GalleryLinkCellView {
            if cell.videoView != nil {
                cell.endVideos()
                self.currentPlayingIndex = self.currentPlayingIndex.filter({ (included) -> Bool in
                    return included.row != indexPath.row
                })
            }
        }
    }
    
    var refreshControl: UIRefreshControl!
    
    func refresh() {
        loading = true
        emptyStateView.isHidden = true
        baseData.reset()
        refreshControl.beginRefreshing()
        flowLayout.reset(modal: presentingViewController != nil, vc: self, isGallery: false)
        flowLayout.invalidateLayout()
        tableView.reloadData()
        baseData.getData(reload: true)
    }
    
    func loadMore() {
        if loading || !loaded {
            return
        }
        if !showing {
            showLoader()
        }
        loading = true
        baseData.getData(reload: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        autoplayHandler.scrollViewDidScroll(scrollView)
    }

    func didScrollExtras(_ currentY: CGFloat) {
        if self.tableView.contentSize.height > 0 && (tableView.contentSize.height - (tableView.contentOffset.y + tableView.frame.size.height) < 300) {
            if self.loaded && !self.loading && self.baseData.canGetMore {
                self.loadMore()
            }
        }

    }
    
    func endAndResetRefresh() {
        self.refreshControl.endRefreshing()
        self.refreshControl.removeFromSuperview()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = ColorUtil.theme.fontColor
        
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(self.refreshControl)
    }
    
    var loading: Bool = false
    
    func doneLoading(before: Int, filter: Bool) {
        loading = false
        loaded = true
        DispatchQueue.main.async {
            if filter {
                self.baseData.content = PostFilter.filter(self.baseData.content, previous: [], baseSubreddit: (self.baseData is SearchContributionLoader ? (self.baseData as! SearchContributionLoader).sub : "NO_SUBREDDIT"))
            }
            // If there is no data after loading, show the empty state view.
            if self.baseData.content.count == 0 {
                self.emptyStateView.isHidden = false
            } else {
                self.emptyStateView.isHidden = true
            }
            
            if before == 0 || before > self.baseData.content.count {
                self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: false)
                self.tableView.reloadData()
                
                var top = CGFloat(0)
                if #available(iOS 11, *) {
                    top += 22
                }
                
                //New xcode is complaining about computation times...
                let headerOffset = CGFloat((self.baseData is FriendsContributionLoader || self.baseData is ProfileContributionLoader || self.baseData is InboxContributionLoader || self.baseData is CollectionsContributionLoader || self.baseData is ModQueueContributionLoader || self.baseData is ModMailContributionLoader) ? 45 : 0)
                let totalOffset = (-1 * (headerOffset + (self.navigationController?.navigationBar.frame.size.height ?? 64)))
                self.tableView.contentOffset = CGPoint.init(x: 0, y: -18 + totalOffset - top)
            } else {
                var paths = [IndexPath]()
                for i in before..<self.baseData.content.count {
                    paths.append(IndexPath.init(item: i, section: 0))
                }
                
                self.flowLayout.reset(modal: self.presentingViewController != nil, vc: self, isGallery: false)
                self.tableView.insertItems(at: paths)
            }
            self.endAndResetRefresh()
        }
        self.loading = false
    }
}

extension ContentListingViewController: LinkCellViewDelegate {
    func openComments(id: String, subreddit: String?) {
        let comment = CommentViewController.init(submission: id, subreddit: subreddit)
        VCPresenter.showVC(viewController: comment, popupIfPossible: true, parentNavigationController: navigationController, parentViewController: self)
    }
    
    func deleteSelf(_ cell: LinkCellView) {
        //Dont implememt
    }
    
    func more(_ cell: LinkCellView) {
        PostActions.showMoreMenu(cell: cell, parent: self, nav: self.navigationController, mutableList: false, delegate: self, index: tableView.indexPath(for: cell)?.row ?? 0)
    }
    
    func upvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.id)!, completion: { (_) in
                
            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh()
            cell.refreshTitle(force: true)
        } catch {
            
        }
    }
    
    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.id)!, completion: { (_) in
                
            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!)
            cell.refresh()
            cell.refreshTitle(force: true)
        } catch {
            
        }
    }
    
    func save(_ cell: LinkCellView) {
        if baseData is CollectionsContributionLoader {
            var message = ""
            if let ctitle = (baseData as? CollectionsContributionLoader)?.collectionTitle {
                if Collections.getCollectionIDs(title: ctitle).count == 1 {
                    message = "Deleting the last post in \(ctitle) will delete the collection entirely"
                }
                let alert = UIAlertController(title: "Remove from this collection?", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Remove", style: UIAlertAction.Style.destructive, handler: { (_) in
                    Collections.removeFromCollection(link: cell.link!, title: ctitle)
                    self.baseData.content = self.baseData.content.filter { (object) -> Bool in
                        if let link = object as? Submission {
                            if link.id == cell.link!.id {
                                return false
                            }
                        }
                        return true
                    }
                    self.tableView.reloadData()
                }))
                alert.addCancelButton()
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            do {
                try session?.setSave(!ActionStates.isSaved(s: cell.link!), name: (cell.link?.id)!, completion: { (_) in
                    
                })
                ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
                History.addSeen(s: cell.link!)
                cell.refresh()
            } catch {
                
            }
        }
    }
    
    func reply(_ cell: LinkCellView) {
        
    }
    
    func hide(_ cell: LinkCellView) {
    }
    
    func mod(_ cell: LinkCellView) {
        PostActions.showModMenu(cell, parent: self)
    }
    
    func readLater(_ cell: LinkCellView) {
        guard cell.link != nil else {
            return
        }
        
        if self is ReadLaterViewController {
            ReadLater.removeReadLater(id: cell.link!.id)
            let savedIndex = tableView.indexPath(for: cell)?.row ?? 0
            self.baseData.content.remove(at: savedIndex)
            if self.baseData.content.count == 0 {
                self.tableView.reloadData()
            } else {
                self.tableView.deleteItems(at: [IndexPath.init(row: savedIndex, section: 0)])
            }
            BannerUtil.makeBanner(text: "Removed from Read Later\nTap to undo", color: GMColor.red500Color(), seconds: 3, context: self, top: false) {
                ReadLater.addReadLater(id: cell.link!.id, subreddit: cell.link!.subreddit)
                self.baseData.content.insert(cell.link!, at: savedIndex)
                if ReadLater.readLaterIDs.count == 1 {
                    self.tableView.reloadData()
                } else {
                    self.tableView.insertItems(at: [IndexPath.init(row: savedIndex, section: 0)])
                }
            }
        } else {
            ReadLater.toggleReadLater(link: cell.link!)
            if #available(iOS 10.0, *) {
                HapticUtility.hapticActionComplete()
            }
        }
        cell.refresh()
    }
    
}

class EmptyStateView: UIView {
    
    var titleLabel = UILabel().then {
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: .zero)
        
        addSubview(titleLabel)
        titleLabel.centerAnchors /==/ centerAnchors
        titleLabel.widthAnchor /==/ self.widthAnchor - 50
        
        setText(title: "Title Placeholder", message: "Message Placeholder")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setText(title: String, message: String?) {
        let finalText: NSMutableAttributedString!
        if let message = message {
            let firstPart = NSMutableAttributedString.init(string: title, attributes: convertToOptionalNSAttributedStringKeyDictionary([
                convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor.withAlphaComponent(0.8),
                convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 20),
            ]))
            let secondPart = NSMutableAttributedString.init(string: "\n\n" + message, attributes: convertToOptionalNSAttributedStringKeyDictionary([
                convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.theme.fontColor.withAlphaComponent(0.5),
                convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 14),
            ]))
            firstPart.append(secondPart)
            finalText = firstPart
        } else {
            finalText = NSMutableAttributedString.init(string: title, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.white, convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 14)]))
        }
        titleLabel.attributedText = finalText
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringDocumentReadingOptionKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.DocumentReadingOptionKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.DocumentReadingOptionKey(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringDocumentAttributeKey(_ input: NSAttributedString.DocumentAttributeKey) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringDocumentType(_ input: NSAttributedString.DocumentType) -> String {
    return input.rawValue
}
