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
import XLActionController

class ContentListingViewController: MediaViewController, UICollectionViewDelegate, WrappingFlowLayoutDelegate, UICollectionViewDataSource, SubmissionMoreDelegate {
    
    func showFilterMenu(_ cell: LinkCellView) {
        //Not implemented
    }

    var baseData: ContributionLoader
    var session: Session? = nil
    var tableView: UICollectionView!

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
    }

    func drefresh(_ sender: AnyObject) {
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.automaticallyAdjustsScrollViewInsets = false
        self.edgesForExtendedLayout = UIRectEdge.all
        self.extendedLayoutIncludesOpaqueBars = true
        self.navigationController?.setToolbarHidden(true, animated: false)
    }

    var flowLayout: WrappingFlowLayout = WrappingFlowLayout.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        flowLayout.delegate = self
        let frame = self.view.bounds
        self.tableView = UICollectionView(frame: frame, collectionViewLayout: flowLayout)
        self.view = UIView.init(frame: CGRect.zero)
        
        self.view.addSubview(tableView)

        self.tableView.delegate = self
        self.tableView.dataSource = self

        refreshControl = UIRefreshControl()
        self.tableView.contentOffset = CGPoint.init(x: 0, y: -self.refreshControl.frame.size.height)
        refreshControl.tintColor = ColorUtil.fontColor
        refreshControl.attributedTitle = NSAttributedString(string: "")
        refreshControl.addTarget(self, action: #selector(self.drefresh(_:)), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController

        self.tableView.register(BannerLinkCellView.classForCoder(), forCellWithReuseIdentifier: "banner")
        self.tableView.register(ThumbnailLinkCellView.classForCoder(), forCellWithReuseIdentifier: "thumb")
        self.tableView.register(TextLinkCellView.classForCoder(), forCellWithReuseIdentifier: "text")
        self.tableView.register(CommentCellView.classForCoder(), forCellWithReuseIdentifier: "comment")
        self.tableView.register(MessageCellView.classForCoder(), forCellWithReuseIdentifier: "message")
        tableView.backgroundColor = ColorUtil.backgroundColor

        if (baseData is ProfileContributionLoader || baseData is InboxContributionLoader || baseData is ModQueueContributionLoader || baseData is ModMailContributionLoader) {
            self.tableView.contentInset = UIEdgeInsets.init(top: 45, left: 0, bottom: 0, right: 0)
        }
        session = (UIApplication.shared.delegate as! AppDelegate).session

        refresh()
    }
    
    var oldsize = CGFloat(0)

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.frame = self.view.bounds
        if (self.view.bounds.width != oldsize) {
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
        return baseData.content.count
    }

    func collectionView(_ tableView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let thing = baseData.content[indexPath.row]
        var cell: UICollectionViewCell?
        if (thing is RSubmission) {
            var target = CurrentType.none
            let submission = thing as! RSubmission

            var thumb = submission.thumbnail
            var big = submission.banner
            let height = submission.height

            var type = ContentType.getContentType(baseUrl: submission.url)
            if (submission.isSelf) {
                type = .SELF
            }

            if (SettingValues.postImageMode == .THUMBNAIL) {
                big = false
                thumb = true
            }

            let fullImage = ContentType.fullImage(t: type)

            if (!fullImage && height < 50) {
                big = false
                thumb = true
            }

            if (type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big) {
                big = false
                thumb = false
            }

            if (height < 50) {
                thumb = true
                big = false
            }

            if (type == ContentType.CType.SELF && SettingValues.hideImageSelftext
                    || SettingValues.noImages && submission.isSelf) {
                big = false
                thumb = false
            }

            if (big || !submission.thumbnail) {
                thumb = false
            }


            if (!big && !thumb && submission.type != .SELF && submission.type != .NONE) { //If a submission has a link but no images, still show the web thumbnail
                thumb = true
            }

            if (submission.nsfw && (!SettingValues.nsfwPreviews || SettingValues.hideNSFWCollection)) {
                big = false
                thumb = true
            }

            if (SettingValues.noImages) {
                big = false
                thumb = false
            }
            if (thumb && type == .SELF) {
                thumb = false
            }

            if (thumb && !big) {
                target = .thumb
            } else if (big) {
                target = .banner
            } else {
                target = .text
            }

            var c: LinkCellView?
            if (target == .thumb) {
                c = tableView.dequeueReusableCell(withReuseIdentifier: "thumb", for: indexPath) as! ThumbnailLinkCellView
            } else if (target == .banner) {
                c = tableView.dequeueReusableCell(withReuseIdentifier: "banner", for: indexPath) as! BannerLinkCellView
            } else {
                c = tableView.dequeueReusableCell(withReuseIdentifier: "text", for: indexPath) as! TextLinkCellView
            }

            c?.preservesSuperviewLayoutMargins = false
            c?.del = self

            (c)!.configure(submission: submission, parent: self, nav: self.navigationController, baseSub: "")

            c?.layer.shouldRasterize = true
            c?.layer.rasterizationScale = UIScreen.main.scale
            cell = c
        } else if thing is RComment {
            let c = tableView.dequeueReusableCell(withReuseIdentifier: "comment", for: indexPath) as! CommentCellView
            c.setComment(comment: (thing as! RComment), parent: self, nav: self.navigationController, width: self.view.frame.size.width)
            cell = c
        } else {
            let c = tableView.dequeueReusableCell(withReuseIdentifier: "message", for: indexPath) as! MessageCellView
            c.setMessage(message: (thing as! RMessage), parent: self, nav: self.navigationController, width: self.view.frame.size.width)
            cell = c
        }

        if indexPath.row == baseData.content.count - 2 && !loading && baseData.canGetMore {
            self.loadMore()
        }

        return cell!
    }


    func collectionView(_ collectionView: UICollectionView, width: CGFloat, indexPath: IndexPath) -> CGSize {
        var itemWidth = width

        if (indexPath.row < baseData.content.count) {
            let thing = baseData.content[indexPath.row]

            if (thing is RSubmission) {
                let submission = thing as! RSubmission
                if (estimatedHeights[submission.id] == nil) {
                    var thumb = submission.thumbnail
                    var big = submission.banner

                    var type = ContentType.getContentType(baseUrl: submission.url)
                    if (submission.isSelf) {
                        type = .SELF
                    }

                    if (SettingValues.postImageMode == .THUMBNAIL) {
                        big = false
                        thumb = true
                    }

                    let fullImage = ContentType.fullImage(t: type)
                    var submissionHeight = submission.height

                    if (!fullImage && submissionHeight < 50) {
                        big = false
                        thumb = true
                    } else if (big && (SettingValues.postImageMode == .CROPPED_IMAGE)) {
                        submissionHeight = 200
                    } else if (big) {
                        let ratio = Double(submissionHeight) / Double(submission.width)
                        let width = Double(itemWidth);

                        let h = width * ratio
                        if (h == 0) {
                            submissionHeight = 200
                        } else {
                            submissionHeight = Int(h)
                        }
                    }


                    if (type == .SELF && SettingValues.hideImageSelftext || SettingValues.hideImageSelftext && !big) {
                        big = false
                        thumb = false
                    }

                    if (submissionHeight < 50) {
                        thumb = true
                        big = false
                    }


                    if (big || !submission.thumbnail) {
                        thumb = false
                    }


                    if (!big && !thumb && submission.type != .SELF && submission.type != .NONE) { //If a submission has a link but no images, still show the web thumbnail
                        thumb = true
                    }

                    if (submission.nsfw && !SettingValues.nsfwPreviews) {
                        big = false
                        thumb = true
                    }

                    if (submission.nsfw && SettingValues.hideNSFWCollection) {
                        big = false
                        thumb = true
                    }


                    if (SettingValues.noImages) {
                        big = false
                        thumb = false
                    }
                    if (thumb && type == .SELF) {
                        thumb = false
                    }

                    var paddingTop = CGFloat(0)
                    var paddingBottom = CGFloat(2)
                    var paddingLeft = CGFloat(0)
                    var paddingRight = CGFloat(0)
                    var innerPadding = CGFloat(0)
                    if (SettingValues.postViewMode == .CARD || SettingValues.postViewMode == .CENTER) {
                        paddingTop = 5
                        paddingBottom = 5
                        paddingLeft = 5
                        paddingRight = 5
                    }
                    
                    let actionbar = CGFloat(SettingValues.actionBarMode != .FULL ? 0 : 24)
                    
                    var imageHeight = big && !thumb ? CGFloat(submissionHeight) : CGFloat(0)
                    let thumbheight = (SettingValues.largerThumbnail ? CGFloat(75) : CGFloat(50)) - (SettingValues.postViewMode == .COMPACT ? 15 : 0)
                    let textHeight = CGFloat(submission.isSelf ? 5 : 0)
                    
                    if (thumb) {
                        imageHeight = thumbheight
                        innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between top and thumbnail
                        innerPadding += 18 - (SettingValues.postViewMode == .COMPACT ? 4 : 0) //between label and bottom box
                        innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
                    } else if (big) {
                        if (SettingValues.postViewMode == .CENTER) {
                            innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 16) //between label
                            innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between banner and box
                        } else {
                            innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between banner and label
                            innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between label and box
                        }
                        
                        innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
                    } else {
                        innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8)
                        innerPadding += 5 //between label and body
                        innerPadding += (SettingValues.postViewMode == .COMPACT ? 8 : 12) //between body and box
                        innerPadding += (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between box and end
                    }
                    
                    var estimatedUsableWidth = itemWidth - paddingLeft - paddingRight
                    if (thumb) {
                        estimatedUsableWidth -= thumbheight //is the same as the width
                        estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 16 : 24) //between edge and thumb
                        estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 4 : 8) //between thumb and label
                    } else {
                        estimatedUsableWidth -= (SettingValues.postViewMode == .COMPACT ? 16 : 24) //12 padding on either side
                    }
                    
                    let framesetter = CTFramesetterCreateWithAttributedString(CachedTitle.getTitle(submission: submission, full: false, false))
                    let textSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(), nil, CGSize.init(width: estimatedUsableWidth, height: CGFloat.greatestFiniteMagnitude), nil)
                    
                    let totalHeight = paddingTop + paddingBottom + (thumb ? max(ceil(textSize.height), imageHeight) : ceil(textSize.height) + imageHeight) + innerPadding + actionbar + textHeight

                    estimatedHeights[submission.id] = totalHeight
                }
                return CGSize(width: itemWidth, height: estimatedHeights[submission.id]!)
            } else if (thing is RComment) {
                let comment = thing as! RComment
                if (estimatedHeights[comment.id] == nil) {
                    let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false)] as [String: Any]
                    let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: comment.created, numericDates: true))  •  ")

                    let boldString = NSMutableAttributedString(string: "\(comment.score)pts", attributes: attrs)
                    let subString = NSMutableAttributedString(string: "r/\(comment.subreddit)")
                    let color = ColorUtil.getColorForSub(sub: comment.subreddit)
                    if (color != ColorUtil.baseColor) {
                        subString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: subString.length))
                    }

                    let infoString = NSMutableAttributedString.init(string: "", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: false)])
                    infoString.append(boldString)
                    infoString.append(endString)
                    infoString.append(subString)

                    let titleString = NSMutableAttributedString.init(string: comment.submissionTitle, attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 18, submission: false)])

                    var content: CellContent?
                    if (!comment.body.isEmpty()) {
                        var html = comment.htmlText
                        do {
                            html = WrapSpoilers.addSpoilers(html)
                            html = WrapSpoilers.addTables(html)
                            let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                            let font = FontGenerator.fontOfSize(size: 16, submission: false)
                            let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: .white)
                            content = CellContent.init(string: LinkParser.parse(attr2, .white), width: (width - 16))
                        } catch {
                        }
                    }
                    let framesetterT = CTFramesetterCreateWithAttributedString(titleString)
                    let textSizeT = CTFramesetterSuggestFrameSizeWithConstraints(framesetterT, CFRange(), nil, CGSize.init(width: itemWidth - 16, height: CGFloat.greatestFiniteMagnitude), nil)
                    let framesetterI = CTFramesetterCreateWithAttributedString(infoString)
                    let textSizeI = CTFramesetterSuggestFrameSizeWithConstraints(framesetterI, CFRange(), nil, CGSize.init(width: itemWidth - 16, height: CGFloat.greatestFiniteMagnitude), nil)
                    if (content != nil) {
                        let framesetterB = CTFramesetterCreateWithAttributedString(content!.attributedString)
                        let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: itemWidth - 16, height: CGFloat.greatestFiniteMagnitude), nil)

                        estimatedHeights[comment.id] = CGFloat(24 + textSizeT.height + textSizeI.height + textSizeB.height)
                    } else {
                        estimatedHeights[comment.id] = CGFloat(24 + textSizeT.height + textSizeI.height)
                    }
                }
                return CGSize(width: itemWidth, height: estimatedHeights[comment.id]!)
            } else {
                let message = thing as! RMessage
                if (estimatedHeights[message.id] == nil) {
                    var title: NSMutableAttributedString = NSMutableAttributedString()
                    if (message.wasComment) {
                        title = NSMutableAttributedString.init(string: message.linkTitle, attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 18, submission: true)])
                    } else {
                        title = NSMutableAttributedString.init(string: message.subject, attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 18, submission: true)])
                    }

                    let endString = NSMutableAttributedString(string: "\(DateFormatter().timeSince(from: message.created, numericDates: true))  •  from \(message.author)")

                    let subString = NSMutableAttributedString(string: "r/\(message.subreddit)")
                    let color = ColorUtil.getColorForSub(sub: message.subreddit)
                    if (color != ColorUtil.baseColor) {
                        subString.addAttribute(NSForegroundColorAttributeName, value: color, range: NSRange.init(location: 0, length: subString.length))
                    }

                    let infoString = NSMutableAttributedString.init(string: "", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: true)])
                    infoString.append(endString)
                    if (!message.subreddit.isEmpty) {
                        infoString.append(NSAttributedString.init(string: "  •  "))
                        infoString.append(subString)
                    }

                    let html = message.htmlBody
                    var content: CellContent?
                    if (!html.isEmpty()) {
                        do {
                            let attr = try NSMutableAttributedString(data: (html.data(using: .unicode)!), options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                            let font = FontGenerator.fontOfSize(size: 16, submission: false)
                            let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: .white)
                            content = CellContent.init(string: LinkParser.parse(attr2, .white), width: (width - 16 - (message.subject.hasPrefix("re:") ? 30 : 0)))
                        } catch {
                        }
                    }
                    
                    let framesetterT = CTFramesetterCreateWithAttributedString(title)
                    let textSizeT = CTFramesetterSuggestFrameSizeWithConstraints(framesetterT, CFRange(), nil, CGSize.init(width: itemWidth - 16 - (message.subject.hasPrefix("re:") ? 22 : 0), height: CGFloat.greatestFiniteMagnitude), nil)
                    let framesetterI = CTFramesetterCreateWithAttributedString(infoString)
                    let textSizeI = CTFramesetterSuggestFrameSizeWithConstraints(framesetterI, CFRange(), nil, CGSize.init(width: itemWidth - 16 - (message.subject.hasPrefix("re:") ? 22 : 0), height: CGFloat.greatestFiniteMagnitude), nil)
                    if (content != nil) {
                        let framesetterB = CTFramesetterCreateWithAttributedString(content!.attributedString)
                        let textSizeB = CTFramesetterSuggestFrameSizeWithConstraints(framesetterB, CFRange(), nil, CGSize.init(width: itemWidth - 16 - (message.subject.hasPrefix("re:") ? 22 : 0), height: CGFloat.greatestFiniteMagnitude), nil)

                        estimatedHeights[message.id] = CGFloat(24 + textSizeT.height + textSizeI.height + textSizeB.height)
                    } else {
                        estimatedHeights[message.id] = CGFloat(24 + textSizeT.height + textSizeI.height)
                    }
                }
                return CGSize(width: itemWidth, height: estimatedHeights[message.id]!)
            }
        }
        return CGSize(width: itemWidth, height: 0)
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

        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            print("Cancel")
        }
        actionSheetController.addAction(cancelActionButton)

        for link in LinkSortType.cases {
            let saveActionButton: UIAlertAction = UIAlertAction(title: link.description, style: .default) { action -> Void in
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
        if (s == .hot || s == .new) {
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
                let saveActionButton: UIAlertAction = UIAlertAction(title: t.param, style: .default) { action -> Void in
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

    func refresh() {
        baseData.reset()
        tableView.reloadData()
        flowLayout.reset()
        flowLayout.invalidateLayout()
        refreshControl.beginRefreshing()
        loading = true
        baseData.getData(reload: true)
    }

    func loadMore() {
        if (!showing) {
            showLoader()
        }
        loading = true
        baseData.getData(reload: false)
    }


    var loading: Bool = false

    func doneLoading() {
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
            self.flowLayout.reset()
            self.loading = false
            if (self.baseData.content.count == 0) {
                BannerUtil.makeBanner(text: "No content found!", seconds: 5, context: self)
            }
        }
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
        PostActions.showMoreMenu(cell: cell, parent: parent!, nav: parent!.navigationController!, mutableList: false, delegate: self)
    }

    func upvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.getId())!, completion: { (result) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.getId())!, completion: { (result) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!)
            cell.refresh()
        } catch {

        }
    }

    func save(_ cell: LinkCellView) {
        do {
            try session?.setSave(!ActionStates.isSaved(s: cell.link!), name: (cell.link?.getId())!, completion: { (result) in

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
}
