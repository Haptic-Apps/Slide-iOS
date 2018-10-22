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
import XLActionController

class ContentListingViewController: MediaViewController, UICollectionViewDelegate, WrappingFlowLayoutDelegate, UICollectionViewDataSource, SubmissionMoreDelegate, UIScrollViewDelegate {
    
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
        print(error)
        loaded = true
        loading = false
    }

    func drefresh(_ sender: AnyObject) {
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = []
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        if !loaded && !loading {
            defer {
                refreshControl.beginRefreshing()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !loading && !loaded {
            refresh()
        }
    }

    var flowLayout: WrappingFlowLayout = WrappingFlowLayout.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBaseBarColors()
        
        flowLayout.delegate = self
        self.tableView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        self.view = UIView.init(frame: CGRect.zero)
        self.view.addSubview(tableView)

        self.tableView.delegate = self
        self.tableView.dataSource = self

        refreshControl = UIRefreshControl()
        refreshControl.tintColor = ColorUtil.fontColor

        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
        tableView.alwaysBounceVertical = true

        self.tableView.setContentOffset(CGPoint(x: 0, y: -refreshControl.frame.size.height), animated: true)
        
        self.automaticallyAdjustsScrollViewInsets = false

        self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner")
        self.tableView.register(AutoplayBannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "autoplay")
        self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb")
        self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text")
        self.tableView.register(CommentCellView.classForCoder(), forCellWithReuseIdentifier: "comment")
        self.tableView.register(MessageCellView.classForCoder(), forCellWithReuseIdentifier: "message")
        self.tableView.register(NoContentCell.classForCoder(), forCellWithReuseIdentifier: "nocontent")
        self.tableView.register(FriendCellView.classForCoder(), forCellWithReuseIdentifier: "friend")
        tableView.backgroundColor = ColorUtil.backgroundColor

        var top = 0
        
        top += ((self.baseData is FriendsContributionLoader || baseData is ProfileContributionLoader || baseData is InboxContributionLoader || baseData is ModQueueContributionLoader || baseData is ModMailContributionLoader) ? 45 : 0)
        
        self.tableView.contentInset = UIEdgeInsets.init(top: CGFloat(top), left: 0, bottom: 65, right: 0)
        
        session = (UIApplication.shared.delegate as! AppDelegate).session
    }
    
    var oldsize = CGFloat(0)

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.frame = self.view.bounds
        if self.view.bounds.width != oldsize {
            oldsize = self.view.bounds.width
            flowLayout.reset()
            tableView.reloadData()
        }
    }

    var tC: UIViewController?

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return baseData.content.count == 0 && loaded && !loading ? 1 : baseData.content.count
    }

    func collectionView(_ tableView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if baseData.content.count == 0 {
            let cell = tableView.dequeueReusableCell(withReuseIdentifier: "nocontent", for: indexPath) as! NoContentCell
            cell.doText(controller: self)
            return cell
        }
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
                    let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false)] as [String: Any]
                    let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: comment.created, numericDates: true))  •  ")

                    let boldString = NSMutableAttributedString(string: "\(comment.score)pts", attributes: attrs)
                    let subString = NSMutableAttributedString(string: "r/\(comment.subreddit)")
                    let color = ColorUtil.getColorForSub(sub: comment.subreddit)
                    if color != ColorUtil.baseColor {
                        subString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: subString.length))
                    }

                    let infoString = NSMutableAttributedString.init(string: "", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: false)])
                    infoString.append(boldString)
                    infoString.append(endString)
                    infoString.append(subString)

                    let titleString = NSMutableAttributedString.init(string: comment.submissionTitle, attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 18, submission: false)])
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
                        title = NSMutableAttributedString.init(string: message.linkTitle, attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 18, submission: true)])
                    } else {
                        title = NSMutableAttributedString.init(string: message.subject, attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 18, submission: true)])
                    }

                    let endString = NSMutableAttributedString(string: "\(DateFormatter().timeSince(from: message.created, numericDates: true))  •  from \(message.author)")

                    let subString = NSMutableAttributedString(string: "r/\(message.subreddit)")
                    let color = ColorUtil.getColorForSub(sub: message.subreddit)
                    if color != ColorUtil.baseColor {
                        subString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: subString.length))
                    }

                    let infoString = NSMutableAttributedString.init(string: "", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true)])
                    infoString.append(endString)
                    if !message.subreddit.isEmpty {
                        infoString.append(NSAttributedString.init(string: "  •  "))
                        infoString.append(subString)
                    }

                    let html = message.htmlBody
                    var content: NSMutableAttributedString?
                    if !html.isEmpty() {
                        do {
                            let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
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
        }
    }

    var refreshControl: UIRefreshControl!

    func refresh() {
        loading = true
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

    var loading: Bool = false

    func doneLoading(before: Int) {
        loading = false
        loaded = true
        DispatchQueue.main.async {
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
            self.refreshControl.endRefreshing()
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
        PostActions.showMoreMenu(cell: cell, parent: self, nav: self.navigationController!, mutableList: false, delegate: self)
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
        guard let link = cell.link else {
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
            BannerUtil.makeBanner(text: "Removed from Read Later", color: GMColor.red500Color(), seconds: 3, context: self, top: false) {
                ReadLater.addReadLater(id: cell.link!.getId(), subreddit: cell.link!.subreddit)
                self.baseData.content.insert(cell.link!, at: savedIndex)
                self.tableView.insertItems(at: [IndexPath.init(row: savedIndex, section: 0)])
            }
        }

        cell.refresh()
    }

}

public class NoContentCell: UICollectionViewCell {
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    var title = UILabel()
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func doText(controller: ContentListingViewController){
        let text: String
        if controller is ReadLaterViewController {
            text = "Nothing to see here!\nNo more posts to Read Later"
        } else {
            text = "Nothing to see here!\nNo content was found"
        }
        let textParts = text.components(separatedBy: "\n")
        
        let finalText: NSMutableAttributedString!
        if textParts.count > 1 {
            let firstPart = NSMutableAttributedString.init(string: textParts[0], attributes: [NSForegroundColorAttributeName: ColorUtil.fontColor.withAlphaComponent(0.8), NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
            let secondPart = NSMutableAttributedString.init(string: "\n" + textParts[1], attributes: [NSForegroundColorAttributeName: ColorUtil.fontColor.withAlphaComponent(0.5), NSFontAttributeName: UIFont.systemFont(ofSize: 12)])
            firstPart.append(secondPart)
            finalText = firstPart
        } else {
            finalText = NSMutableAttributedString.init(string: text, attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)])
        }
        title.attributedText = finalText
    }
    
    func setupView() {
        title = UILabel()
        title.backgroundColor = ColorUtil.foregroundColor
        title.textAlignment = .center
        
        title.numberOfLines = 0
        title.layer.cornerRadius = 15
        title.clipsToBounds = true
        let titleView = title.withPadding(padding: UIEdgeInsets(top: 8, left: 12, bottom: 0, right: 12))
        self.contentView.addSubview(titleView)
        
        titleView.heightAnchor == 90
        titleView.horizontalAnchors == self.contentView.horizontalAnchors
        titleView.topAnchor == self.contentView.topAnchor
    }
}
