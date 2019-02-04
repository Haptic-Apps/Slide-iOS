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
import SloppySwiper
import UIKit
import XLActionController

class ContentListingViewController: MediaViewController, UICollectionViewDelegate, WrappingFlowLayoutDelegate, UICollectionViewDataSource, SubmissionMoreDelegate, UIScrollViewDelegate, UINavigationControllerDelegate {
    var swiper: SloppySwiper?

    func hide(index: Int) {
        baseData.content.remove(at: index)
        flowLayout.reset()
        tableView.reloadData()
    }
    
    func applyFilters() {
        self.baseData.getData(reload: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if ColorUtil.theme.isLight() && SettingValues.reduceColor {
            return .default
        } else {
            return .lightContent
        }
    }

    @objc func showSortMenu(_ selector: UIButton?) {
        if baseData is ProfileContributionLoader {
            let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)
            
            let selected = UIImage.init(named: "selected")!.getCopy(withSize: .square(size: 20), withColor: .blue)
            
            for link in UserContentSortBy.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { _ -> Void in
                    self.showTimeMenuUser(s: link, selector: selector)
                }
                if userSort == link {
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !loading && !loaded {
            refresh()
        }
        
        if self.navigationController != nil && !((self.baseData is FriendsContributionLoader || baseData is ProfileContributionLoader || baseData is InboxContributionLoader || baseData is ModQueueContributionLoader || baseData is ModMailContributionLoader)) {
            if !(self.navigationController?.delegate is SloppySwiper) {
                swiper = SloppySwiper.init(navigationController: self.navigationController!)
                self.navigationController!.delegate = swiper!
            }
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
        tableView.verticalAnchors == view.verticalAnchors
        tableView.horizontalAnchors == view.safeHorizontalAnchors

        self.tableView.delegate = self
        self.tableView.dataSource = self

        refreshControl = UIRefreshControl()
        refreshControl.tintColor = ColorUtil.fontColor

        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControl.Event.valueChanged)
        tableView.addSubview(refreshControl)
        refreshControl.centerAnchors == tableView.centerAnchors

        tableView.alwaysBounceVertical = true

        self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner")
        self.tableView.register(AutoplayBannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "autoplay")
        self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb")
        self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text")
        self.tableView.register(CommentCellView.classForCoder(), forCellWithReuseIdentifier: "comment")
        self.tableView.register(MessageCellView.classForCoder(), forCellWithReuseIdentifier: "message")
        self.tableView.register(FriendCellView.classForCoder(), forCellWithReuseIdentifier: "friend")
        tableView.backgroundColor = ColorUtil.backgroundColor

        var top = 0
        
        top += ((self.baseData is FriendsContributionLoader || baseData is ProfileContributionLoader || baseData is InboxContributionLoader || baseData is ModQueueContributionLoader || baseData is ModMailContributionLoader) ? 45 : 0)
        
        self.tableView.contentInset = UIEdgeInsets.init(top: CGFloat(top), left: 0, bottom: 65, right: 0)

        self.view.addSubview(emptyStateView)
        if self is ReadLaterViewController {
            emptyStateView.setText(title: "No Saved Posts", message: "Go add posts to Read Later to see them here.")
        } else {
            emptyStateView.setText(title: "Nothing to see here!", message: "No content was found.")
        }
        emptyStateView.isHidden = true
        emptyStateView.edgeAnchors == self.tableView.edgeAnchors
        self.view.bringSubviewToFront(emptyStateView)

        session = (UIApplication.shared.delegate as! AppDelegate).session

        flowLayout.reset()
        tableView.reloadData()
    }
    
    var oldsize = CGFloat(0)

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if self.view.bounds.width != oldsize {
            oldsize = self.view.bounds.width
            flowLayout.reset()
            tableView.reloadData()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        oldsize = self.view.bounds.width
        coordinator.animate(
            alongsideTransition: { [unowned self] _ in
                self.flowLayout.reset()
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
        if thing is RSubmission {
            
            var c: LinkCellView?
            switch SingleSubredditViewController.cellType(forSubmission: thing as! RSubmission, false) {
            case .thumb:
                c = tableView.dequeueReusableCell(withReuseIdentifier: "thumb", for: indexPath) as! ThumbnailLinkCellView
            case .banner:
                c = tableView.dequeueReusableCell(withReuseIdentifier: "banner", for: indexPath) as! BannerLinkCellView
            case .autoplay:
                c = tableView.dequeueReusableCell(withReuseIdentifier: "autoplay", for: indexPath) as! AutoplayBannerLinkCellView
            default:
                c = tableView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as! TextLinkCellView
            }

            c?.preservesSuperviewLayoutMargins = false
            c?.del = self
            
            (c)!.configure(submission: thing as! RSubmission, parent: self, nav: self.navigationController, baseSub: "")

            c?.layer.shouldRasterize = true
            c?.layer.rasterizationScale = UIScreen.main.scale
            
            if self is ReadLaterViewController {
                c?.readLater.isHidden = false
            }

            cell = c
        } else if thing is RComment {
            let c = tableView.dequeueReusableCell(withReuseIdentifier: "comment", for: indexPath) as! CommentCellView
            c.setComment(comment: (thing as! RComment), parent: self, nav: self.navigationController, width: self.view.frame.size.width)
            c.layer.shouldRasterize = true
            c.layer.rasterizationScale = UIScreen.main.scale
            cell = c
        } else if thing is RFriend {
            let c = tableView.dequeueReusableCell(withReuseIdentifier: "friend", for: indexPath) as! FriendCellView
            c.setFriend(friend: (thing as! RFriend), parent: self)
            c.layer.shouldRasterize = true
            c.layer.rasterizationScale = UIScreen.main.scale
            cell = c
        } else {
            let c = tableView.dequeueReusableCell(withReuseIdentifier: "message", for: indexPath) as! MessageCellView
            c.setMessage(message: (thing as! RMessage), parent: self, nav: self.navigationController, width: self.view.frame.size.width)
            c.layer.shouldRasterize = true
            c.layer.rasterizationScale = UIScreen.main.scale
            cell = c
        }
        
        return cell!
    }

    func collectionView(_ collectionView: UICollectionView, width: CGFloat, indexPath: IndexPath) -> CGSize {
        let itemWidth = width

        if indexPath.row < baseData.content.count {
            let thing = baseData.content[indexPath.row]

            if thing is RSubmission {
                let submission = thing as! RSubmission
                return SingleSubredditViewController.sizeWith(submission, width, false)
            } else if thing is RComment {
                let comment = thing as! RComment
                if estimatedHeights[comment.id] == nil {
                    let attrs = [convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 12, submission: false)] as [String: Any]
                    let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: comment.created, numericDates: true))  •  ")

                    let boldString = NSMutableAttributedString(string: "\(comment.score)pts", attributes: convertToOptionalNSAttributedStringKeyDictionary(attrs))
                    let subString = NSMutableAttributedString(string: "r/\(comment.subreddit)")
                    let color = ColorUtil.getColorForSub(sub: comment.subreddit)
                    if color != ColorUtil.baseColor {
                        subString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange.init(location: 0, length: subString.length))
                    }

                    let infoString = NSMutableAttributedString.init(string: "", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: false)]))
                    infoString.append(boldString)
                    infoString.append(endString)
                    infoString.append(subString)

                    let titleString = NSMutableAttributedString.init(string: comment.submissionTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 18, submission: false)]))
                    titleString.append(NSAttributedString.init(string: "\n", attributes: nil))
                    titleString.append(infoString)
                    
                    let height = TextStackEstimator.init(fontSize: 16, submission: false, color: .white, width: itemWidth - 16)
                    height.setTextWithTitleHTML(titleString, htmlString: comment.htmlText)
                    
                    estimatedHeights[comment.id] = height.estimatedHeight + 20
                }
                return CGSize(width: itemWidth, height: estimatedHeights[comment.id]!)
            } else if thing is RFriend {
                return CGSize(width: itemWidth, height: 70)
            } else {
                let message = thing as! RMessage
                if estimatedHeights[message.id] == nil {
                    var title: NSMutableAttributedString = NSMutableAttributedString()
                    if message.wasComment {
                        title = NSMutableAttributedString.init(string: message.linkTitle, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 18, submission: true)]))
                    } else {
                        title = NSMutableAttributedString.init(string: message.subject, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.boldFontOfSize(size: 18, submission: true)]))
                    }

                    let endString = NSMutableAttributedString(string: "\(DateFormatter().timeSince(from: message.created, numericDates: true))  •  from \(message.author)")

                    let subString = NSMutableAttributedString(string: "r/\(message.subreddit)")
                    let color = ColorUtil.getColorForSub(sub: message.subreddit)
                    if color != ColorUtil.baseColor {
                        subString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange.init(location: 0, length: subString.length))
                    }

                    let infoString = NSMutableAttributedString.init(string: "", attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): FontGenerator.fontOfSize(size: 12, submission: true)]))
                    infoString.append(endString)
                    if !message.subreddit.isEmpty {
                        infoString.append(NSAttributedString.init(string: "  •  "))
                        infoString.append(subString)
                    }

                    let html = message.htmlBody
                    var content: NSMutableAttributedString?
                    if !html.isEmpty() {
                        do {
                            let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary([convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType): convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.html)]), documentAttributes: nil)
                            let font = FontGenerator.fontOfSize(size: 16, submission: false)
                            let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: .white)
                            content = LinkParser.parse(attr2, .white)
                        } catch {
                        }
                    }
                    
                    let framesetterT = CTFramesetterCreateWithAttributedString(title)
                    let textSizeT = CTFramesetterSuggestFrameSizeWithConstraints(framesetterT, CFRange(), nil, CGSize.init(width: itemWidth - 16 - (message.subject.hasPrefix("re:") ? 30 : 0), height: CGFloat.greatestFiniteMagnitude), nil)
                    let framesetterI = CTFramesetterCreateWithAttributedString(infoString)
                    let textSizeI = CTFramesetterSuggestFrameSizeWithConstraints(framesetterI, CFRange(), nil, CGSize.init(width: itemWidth - 16 - (message.subject.hasPrefix("re:") ? 30 : 0), height: CGFloat.greatestFiniteMagnitude), nil)
                    if content != nil {
                        let framesetterB = CTFramesetterCreateWithAttributedString(content!)
                        let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: itemWidth - 16 - (message.subject.hasPrefix("re:") ? 30 : 0), height: CGFloat.greatestFiniteMagnitude), nil)

                        estimatedHeights[message.id] = CGFloat(36 + textSizeT.height + textSizeI.height + textSizeB.height)
                    } else {
                        estimatedHeights[message.id] = CGFloat(36 + textSizeT.height + textSizeI.height)
                    }
                }
                return CGSize(width: itemWidth, height: estimatedHeights[message.id]!)
            }
        }
        return CGSize(width: itemWidth, height: 90)
    }

    var estimatedHeights: [String: CGFloat] = [:]

    var showing = false

    func showLoader() {
        showing = true
        //todo maybe add this later
    }

    var sort = LinkSortType.hot
    var userSort = UserContentSortBy.new
    var time = TimeFilterWithin.day

    func showMenu(sender: UIButton?) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { _ -> Void in
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

    func showTimeMenuUser(s: UserContentSortBy, selector: UIButton?) {
        if s == .hot || s == .new {
            userSort = s
            refresh()
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Time Period", message: "", preferredStyle: .actionSheet)
            
            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)
            
            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default) { _ -> Void in
                    self.userSort = s
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

    func showTimeMenu(s: LinkSortType, selector: UIButton?) {
        if s == .hot || s == .new || s == .rising || s == .best {
            sort = s
            refresh()
            return
        } else {
            let actionSheetController: UIAlertController = UIAlertController(title: "Sorting", message: "", preferredStyle: .actionSheet)

            let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { _ -> Void in
                print("Cancel")
            }
            actionSheetController.addAction(cancelActionButton)

            for t in TimeFilterWithin.cases {
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default) { _ -> Void in
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
    
    func doHeadView() {
        inHeadView.removeFromSuperview()
        inHeadView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: max(self.view.frame.size.width, self.view.frame.size.height), height: (UIApplication.shared.statusBarView?.frame.size.height ?? 20)))
        self.inHeadView.backgroundColor = ColorUtil.getColorForSub(sub: "", true)
        
        if !(navigationController is TapBehindModalViewController) {
            self.view.addSubview(inHeadView)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is LinkCellView && (cell as! LinkCellView).videoView != nil {
            (cell as! LinkCellView).videoView!.player?.pause()
            (cell as! LinkCellView).videoView!.player?.currentItem?.asset.cancelLoading()
            (cell as! LinkCellView).videoView!.player?.currentItem?.cancelPendingSeeks()
            (cell as! LinkCellView).videoView!.player = nil
            (cell as! LinkCellView).updater?.invalidate()
            (cell as! LinkCellView).avPlayerItem = nil
        }
    }

    var refreshControl: UIRefreshControl!

    func refresh() {
        loading = true
        emptyStateView.isHidden = true
        baseData.reset()
        refreshControl.beginRefreshing()
        flowLayout.reset()
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
        if scrollView.contentSize.height > 0 && (scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.frame.size.height) < 300) {
            if loaded && !loading && baseData.canGetMore {
                self.loadMore()
            }
        }
    }
    
    func endAndResetRefresh() {
        self.refreshControl.endRefreshing()
        self.refreshControl.removeFromSuperview()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = ColorUtil.fontColor
        
        self.refreshControl.attributedTitle = NSAttributedString(string: "")
        self.refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControl.Event.valueChanged)
        self.tableView.addSubview(self.refreshControl)
    }

    var loading: Bool = false

    func doneLoading(before: Int) {
        loading = false
        loaded = true
        DispatchQueue.main.async {
            self.baseData.content = PostFilter.filter(self.baseData.content, previous: [], baseSubreddit: (self.baseData is SearchContributionLoader ? (self.baseData as! SearchContributionLoader).sub : "all"))
            // If there is no data after loading, show the empty state view.
            if self.baseData.content.count == 0 {
                self.emptyStateView.isHidden = false
            }

            if before == 0 || before > self.baseData.content.count {
                self.flowLayout.reset()
                self.tableView.reloadData()
                
                var top = CGFloat(0)
                if #available(iOS 11, *) {
                    top += 22
                }
                
                self.tableView.contentOffset = CGPoint.init(x: 0, y: -18 + (-1 * (((self.baseData is FriendsContributionLoader || self.baseData is ProfileContributionLoader || self.baseData is InboxContributionLoader || self.baseData is ModQueueContributionLoader || self.baseData is ModMailContributionLoader) ? 45 : 0) + (self.navigationController?.navigationBar.frame.size.height ?? 64))) - top)
            } else {
                var paths = [IndexPath]()
                for i in before..<self.baseData.content.count {
                    paths.append(IndexPath.init(item: i, section: 0))
                }

                self.flowLayout.reset()
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
        PostActions.showMoreMenu(cell: cell, parent: self, nav: self.navigationController!, mutableList: false, delegate: self, index: tableView.indexPath(for: cell)?.row ?? 0)
    }

    func upvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.getId())!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.getId())!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func save(_ cell: LinkCellView) {
        do {
            try session?.setSave(!ActionStates.isSaved(s: cell.link!), name: (cell.link?.getId())!, completion: { (_) in

            })
            ActionStates.setSaved(s: cell.link!, saved: !ActionStates.isSaved(s: cell.link!))
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

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
            fatalError("Cell must have a link!")
        }

        if self is ReadLaterViewController {
            ReadLater.removeReadLater(id: cell.link!.getId())
            let savedIndex = tableView.indexPath(for: cell)?.row ?? 0
            self.baseData.content.remove(at: savedIndex)
            if self.baseData.content.count == 0 {
                self.tableView.reloadData()
            } else {
                self.tableView.deleteItems(at: [IndexPath.init(row: savedIndex, section: 0)])
            }
            BannerUtil.makeBanner(text: "Removed from Read Later\nTap to undo", color: GMColor.red500Color(), seconds: 3, context: self, top: false) {
                ReadLater.addReadLater(id: cell.link!.getId(), subreddit: cell.link!.subreddit)
                self.baseData.content.insert(cell.link!, at: savedIndex)
                if ReadLater.readLaterIDs.count == 1 {
                    self.tableView.reloadData()
                } else {
                    self.tableView.insertItems(at: [IndexPath.init(row: savedIndex, section: 0)])
                }
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
        titleLabel.centerAnchors == centerAnchors

        setText(title: "Title Placeholder", message: "Message Placeholder")
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(title: String, message: String?) {
        let finalText: NSMutableAttributedString!
        if let message = message {
            let firstPart = NSMutableAttributedString.init(string: title, attributes: convertToOptionalNSAttributedStringKeyDictionary([
                convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor.withAlphaComponent(0.8),
                convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.boldSystemFont(ofSize: 16),
                ]))
            let secondPart = NSMutableAttributedString.init(string: "\n" + message, attributes: convertToOptionalNSAttributedStringKeyDictionary([
                convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): ColorUtil.fontColor.withAlphaComponent(0.5),
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
