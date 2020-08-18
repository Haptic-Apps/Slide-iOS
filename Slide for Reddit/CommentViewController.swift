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
import SDCAlertView
import UIKit
import YYText

class CommentViewController: MediaViewController, UITableViewDelegate, UITableViewDataSource, TTTAttributedCellDelegate, LinkCellViewDelegate, UISearchBarDelegate, SubmissionMoreDelegate, ReplyDelegate, UIScrollViewDelegate {
    
    var version = 0
    var swipeBackAdded = false
    var fullWidthBackGestureRecognizer: UIPanGestureRecognizer!
    var cellGestureRecognizer: UIPanGestureRecognizer!
    var liveView: UILabel?
    var liveNewCount = 0

    func hide(index: Int) {
        if index >= 0 {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func subscribe(link: RSubmission) {
        let sub = link.subreddit
        let alrController = UIAlertController.init(title: "Follow r/\(sub)", message: nil, preferredStyle: .alert)
        if AccountController.isLoggedIn {
            let somethingAction = UIAlertAction(title: "Subscribe", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) in
                Subscriptions.subscribe(sub, true, session: self.session!)
                self.subChanged = true
                BannerUtil.makeBanner(text: "Subscribed to r/\(sub)", color: ColorUtil.accentColorForSub(sub: sub), seconds: 3, context: self, top: true)
            })
            alrController.addAction(somethingAction)
        }
        
        let somethingAction = UIAlertAction(title: "Casually subscribe", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) in
            Subscriptions.subscribe(sub, false, session: self.session!)
            self.subChanged = true
            BannerUtil.makeBanner(text: "r/\(sub) added to your subreddit list", color: ColorUtil.accentColorForSub(sub: sub), seconds: 3, context: self, top: true)
        })
        alrController.addAction(somethingAction)
        
        alrController.addCancelButton()
        
        alrController.modalPresentationStyle = .fullScreen
        self.present(alrController, animated: true, completion: {})
    }

    override var prefersStatusBarHidden: Bool {
        return SettingValues.fullyHideNavbar
    }

    override var keyCommands: [UIKeyCommand]? {
        if isReply {
            return []
        } else {
            return [
                UIKeyCommand(input: " ", modifierFlags: [], action: #selector(spacePressed)),
                UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(spacePressed)),
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(spacePressedUp)),
                UIKeyCommand(input: "l", modifierFlags: .command, action: #selector(upvote(_:)), discoverabilityTitle: "Like post"),
                UIKeyCommand(input: "r", modifierFlags: .command, action: #selector(reply(_:)), discoverabilityTitle: "Reply to post"),
                UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(save(_:)), discoverabilityTitle: "Save post"),
            ]
        }
    }

    var menuCell: CommentDepthCell?
    var menuId: String?
    public var inHeadView = UIView()
    
    var commentDepthColors = [UIColor]()

    var panGesture: UIPanGestureRecognizer!
    var translatingCell: CommentDepthCell?
    var didDisappearCompletely = false
    var live = false
    var liveTimer = Timer()
    var refreshControl: UIRefreshControl!
    var tableView: UITableView!
    
    var sortButton = UIButton()

    var jump: UIView!

    func isMenuShown() -> Bool {
        return menuCell != nil
    }

    func getMenuShown() -> String? {
        return menuId
    }
    
    func createJumpButton(_ forced: Bool = false) {
        if SettingValues.commentJumpButton == .DISABLED {
            return
        }
        if self.navigationController?.view != nil {
            let view = self.navigationController!.view!
            if jump != nil && forced {
                jump.removeFromSuperview()
                jump = nil
            }
            if jump == nil {
                jump = UIView.init(frame: CGRect.init(x: 70, y: 70, width: 0, height: 0)).then {
                    $0.clipsToBounds = true
                    $0.backgroundColor = ColorUtil.theme.backgroundColor
                    $0.layer.cornerRadius = 20
                }
                
                let image = UIImageView.init(frame: CGRect.init(x: 50, y: 50, width: 0, height: 0)).then {
                    $0.image = UIImage(sfString: SFSymbol.chevronDown, overrideString: "down")?.getCopy(withSize: CGSize.square(size: 30), withColor: ColorUtil.theme.navIconColor)
                    $0.contentMode = .center
                }
                jump.addSubview(image)
                image.edgeAnchors == jump.edgeAnchors
                jump.addTapGestureRecognizer {
                    self.goDown(self.jump)
                }
                jump.addLongTapGestureRecognizer {
                    self.goUp(self.jump)
                }
            }
            
            view.addSubview(jump)
            jump.bottomAnchor == view.bottomAnchor - 24
            if SettingValues.commentJumpButton == .RIGHT {
                jump.rightAnchor == view.rightAnchor - 24
            } else {
                jump.leftAnchor == view.leftAnchor + 24
            }
            jump.widthAnchor == 40
            jump.heightAnchor == 40
            jump.transform = CGAffineTransform(translationX: 0, y: 70)
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.jump?.transform = .identity
            }, completion: nil)

        }
    }
    
    func removeJumpButton() {
        if SettingValues.commentJumpButton == .DISABLED {
            return
        }
        if self.jump != nil {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.jump?.transform = CGAffineTransform(translationX: 0, y: 70)
            }, completion: { _ in
                self.jump?.removeFromSuperview()
            })
        }
    }
    
    override func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        self.setAlphaOfBackgroundViews(alpha: 0.25)
       // self.setBackgroundView()
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        self.setAlphaOfBackgroundViews(alpha: 1)
        return true
    }

    func showFilterMenu(_ cell: LinkCellView) {
        //Not implemented
    }
    
    func setLive() {
        self.sort = .new
        self.live = true
        self.reset = true
        self.activityIndicator.removeFromSuperview()
        let barButton = UIBarButtonItem(customView: self.activityIndicator)
        self.navigationItem.rightBarButtonItems = [barButton]
        self.activityIndicator.startAnimating()
        
        self.refresh(self)
    }
    
    var progressDot = UIView()
    
    func startPulse() {
        self.progressDot = UIView()
        progressDot.alpha = 0.7
        progressDot.backgroundColor = .clear
        
        let startAngle = -CGFloat.pi / 2
        
        let center = CGPoint(x: 20 / 2, y: 20 / 2)
        let radius = CGFloat(20 / 2)
        let arc = CGFloat.pi * CGFloat(2) * 1
        
        let cPath = UIBezierPath()
        cPath.move(to: center)
        cPath.addLine(to: CGPoint(x: center.x + radius * cos(startAngle), y: center.y + radius * sin(startAngle)))
        cPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: arc + startAngle, clockwise: true)
        cPath.addLine(to: CGPoint(x: center.x, y: center.y))
        
        let circleShape = CAShapeLayer()
        circleShape.path = cPath.cgPath
        circleShape.strokeColor = GMColor.red500Color().cgColor
        circleShape.fillColor = GMColor.red500Color().cgColor
        circleShape.lineWidth = 1.5
        // add sublayer
        for layer in progressDot.layer.sublayers ?? [CALayer]() {
            layer.removeFromSuperlayer()
        }
        progressDot.layer.removeAllAnimations()
        progressDot.layer.addSublayer(circleShape)

        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.5
        pulseAnimation.toValue = 1.2
        pulseAnimation.fromValue = 0.2
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        pulseAnimation.autoreverses = false
        pulseAnimation.repeatCount = Float.greatestFiniteMagnitude
        
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.duration = 0.5
        fadeAnimation.toValue = 0
        fadeAnimation.fromValue = 2.5
        fadeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        fadeAnimation.autoreverses = false
        fadeAnimation.repeatCount = Float.greatestFiniteMagnitude
        
        progressDot.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        liveB = UIBarButtonItem.init(customView: progressDot)

        self.navigationItem.rightBarButtonItems = [self.sortB, self.searchB, self.liveB]
        
        progressDot.layer.add(pulseAnimation, forKey: "scale")
        progressDot.layer.add(fadeAnimation, forKey: "fade")
    }
    
    @objc func loadNewComments() {
        var name = submission!.name
        if name.contains("t3_") {
            name = name.replacingOccurrences(of: "t3_", with: "")
        }
        do {
            try session?.getArticles(name, sort: .new, limit: SettingValues.commentLimit, completion: { (result) in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let tuple):
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        var queue: [Object] = []
                        let startDepth = 1
                        let listing = tuple.1
                        
                        for child in listing.children {
                            let incoming = self.extendKeepMore(in: child, current: startDepth)
                            for i in incoming {
                                if i.1 == 1 {
                                    let item = RealmDataWrapper.commentToRealm(comment: i.0, depth: i.1)
                                    if self.content[item.getIdentifier()] == nil {
                                        self.content[item.getIdentifier()] = item
                                        self.cDepth[item.getIdentifier()] = i.1
                                        queue.append(item)
                                        self.updateStrings([i])
                                    }
                                }
                            }
                        }

                        let datasetPosition = 0
                        let realPosition = 0
                        var ids: [String] = []
                        for item in queue {
                            let id = item.getIdentifier()
                            ids.append(id)
                            self.content[id] = item
                        }

                        if queue.count != 0 {
                            self.dataArray.insert(contentsOf: ids, at: datasetPosition)
                            self.comments.insert(contentsOf: ids, at: realPosition)
                            self.doArrays()
                            var paths: [IndexPath] = []
                            for i in stride(from: datasetPosition, to: datasetPosition + queue.count, by: 1) {
                                self.liveNewCount += 1
                                paths.append(IndexPath.init(row: i, section: 0))
                            }
                            let contentHeight = self.tableView.contentSize.height
                            let offsetY = self.tableView.contentOffset.y
                            let bottomOffset = contentHeight - offsetY
                            if #available(iOS 11.0, *) {
                                CATransaction.begin()
                                CATransaction.setDisableActions(true)
                                self.isHiding = true
                                self.tableView.performBatchUpdates({
                                    self.tableView.insertRows(at: paths, with: .fade)
                                }, completion: { (_) in
                                    self.lastY = self.tableView.contentOffset.y
                                    self.olderY = self.tableView.contentOffset.y
                                    self.isHiding = false
                                    if self.tableView.contentOffset.y > (self.tableView.tableHeaderView?.frame.size.height ?? 60) + 64 + 10 {
                                        if self.liveView == nil {
                                            self.liveView = UILabel().then {
                                                $0.textColor = .white
                                                $0.font = UIFont.boldSystemFont(ofSize: 10)
                                                $0.backgroundColor = ColorUtil.getColorForSub(sub: self.subreddit)
                                                $0.layer.cornerRadius = 20
                                                $0.clipsToBounds = true
                                                $0.textAlignment = .center
                                                $0.addTapGestureRecognizer {
                                                    UIView.animate(withDuration: 0.3, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                                                        self.tableView.contentOffset.y = (self.tableView.tableHeaderView?.frame.size.height ?? 60) + 64
                                                    }, completion: { (_) in
                                                        self.lastY = self.tableView.contentOffset.y
                                                        self.olderY = self.tableView.contentOffset.y
                                                    })
                                                }
                                            }
                                            self.view.addSubview(self.liveView!)
                                            self.liveView!.topAnchor == self.view.safeTopAnchor + 20
                                            self.liveView!.centerXAnchor == self.view.centerXAnchor
                                            self.liveView!.heightAnchor == 40
                                            self.liveView!.widthAnchor == 130
                                        }
                                        self.liveView!.text = "\(self.liveNewCount) NEW COMMENT\((self.liveNewCount > 1) ? "S" : "")"
                                        self.liveView!.setNeedsLayout()
                                    }
                                    //self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentSize.height - bottomOffset)
                                    CATransaction.commit()
                                })
                            } else {
                                self.tableView.insertRows(at: paths, with: .fade)
                            }
                        }
                    })
                }
            })

        } catch {
            
        }
    }
    
    func applyFilters() {
        if PostFilter.filter([submission!], previous: nil, baseSubreddit: "all").isEmpty {
            self.navigationController?.popViewController(animated: true)
        }
    }

    init(submission: RSubmission, single: Bool) {
        self.submission = submission
        self.sort = SettingValues.getCommentSorting(forSubreddit: submission.subreddit)
        self.single = single
        self.text = [:]
        super.init(nibName: nil, bundle: nil)
        setBarColors(color: ColorUtil.getColorForSub(sub: submission.subreddit))
    }

    init(submission: RSubmission) {
        self.submission = submission
        self.sort = SettingValues.getCommentSorting(forSubreddit: submission.subreddit)
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
            self.sort = SettingValues.getCommentSorting(forSubreddit: self.subreddit)
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
        self.sort = SettingValues.getCommentSorting(forSubreddit: self.submission!.subreddit)
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

    var authorColor: UIColor = ColorUtil.theme.fontColor

    func replySent(comment: Comment?, cell: CommentDepthCell?) {
        if comment != nil && cell != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                let startDepth = (self.cDepth[cell!.comment!.getIdentifier()] ?? 0) + 1

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
                self.isEditing = false
                self.tableView.reloadData()

            })
        } else if comment != nil && cell == nil {
            DispatchQueue.main.async(execute: { () -> Void in
                let startDepth = 1

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
                self.isEditing = false
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

                comment = RealmDataWrapper.commentToRComment(comment: cr!, depth: self.cDepth[comment.getIdentifier()] ?? 1)
                self.dataArray.remove(at: insertIndex)
                self.dataArray.insert(comment.getIdentifier(), at: insertIndex)
                self.comments.remove(at: realPosition)
                self.comments.insert(comment.getIdentifier(), at: realPosition)
                self.content[comment.getIdentifier()] = comment
                self.updateStringsSingle([comment])
                self.doArrays()
                self.isEditing = false
                self.isReply = false
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

    @objc func save(_ cell: LinkCellView) {
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
            History.addSeen(s: cell.link!, skipDuplicates: true)
            cell.refresh()
            if parent is PagingCommentViewController {
                (parent as! PagingCommentViewController).reloadCallback?()
            }
        } catch {
        }
    }

    func doHeadView(_ size: CGSize) {
        inHeadView.removeFromSuperview()
        inHeadView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: max(self.view.frame.size.width, self.view.frame.size.height), height: (UIApplication.shared.statusBarUIView?.frame.size.height ?? 20)))
        if submission != nil {
            self.inHeadView.backgroundColor = SettingValues.fullyHideNavbar ? .clear : (!SettingValues.reduceColor ? ColorUtil.getColorForSub(sub: submission!.subreddit) : ColorUtil.theme.foregroundColor)
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
    
    func reloadHeightsNone() {
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
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

    @objc func reply(_ cell: LinkCellView) {
        if !offline {
            VCPresenter.presentAlert(TapBehindModalViewController.init(rootViewController: ReplyViewController.init(submission: cell.link!, sub: cell.link!.subreddit, delegate: self)), parentVC: self)
        }
    }

    @objc func upvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up, name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .up ? .none : .up)
            History.addSeen(s: cell.link!, skipDuplicates: true)
            cell.refresh()
            if parent is PagingCommentViewController {
                _ = (parent as! PagingCommentViewController).reloadCallback?()
            }
            _ = CachedTitle.getTitle(submission: cell.link!, full: false, true, gallery: false)
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
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if scrollView.contentOffset.y > oldPosition.y {
            oldPosition = scrollView.contentOffset
            return true
        } else {
            tableView.setContentOffset(oldPosition, animated: true)
            oldPosition = CGPoint.zero
        }
        return false
    }
    
    var shouldAnimateLoad = false
    
    func downvote(_ cell: LinkCellView) {
        do {
            try session?.setVote(ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down, name: (cell.link?.id)!, completion: { (_) in

            })
            ActionStates.setVoteDirection(s: cell.link!, direction: ActionStates.getVoteDirection(s: cell.link!) == .down ? .none : .down)
            History.addSeen(s: cell.link!, skipDuplicates: true)
            cell.refresh()
            if parent is PagingCommentViewController {
                (parent as! PagingCommentViewController).reloadCallback?()
            }
        } catch {

        }
    }

    func more(_ cell: LinkCellView) {
        if !offline {
            PostActions.showMoreMenu(cell: cell, parent: self, nav: self.navigationController!, mutableList: false, delegate: self, index: 0)
        }
    }

    func readLater(_ cell: LinkCellView) {
        guard let link = cell.link else {
            return
        }

        ReadLater.toggleReadLater(link: link)
        if parent is PagingCommentViewController {
            (parent as! PagingCommentViewController).reloadCallback?()
        }
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
                        if !self.offline {
                            self.lastSeen = (self.context.isEmpty ? History.getSeenTime(s: self.submission!) : Double(0))
                        }
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.refreshControl?.endRefreshing()
                        self.indicator.stopAnimating()
                        
                        if !self.comments.isEmpty {
                            var time = timeval(tv_sec: 0, tv_usec: 0)
                            gettimeofday(&time, nil)
                            
                            self.tableView.reloadData()
                        }
                        if self.comments.isEmpty {
                            BannerUtil.makeBanner(text: "No cached comments found!", color: ColorUtil.accentColorForSub(sub: self.subreddit), seconds: 3, context: self)
                        } else {
                           // BannerUtil.makeBanner(text: "Showing cached comments", color: ColorUtil.accentColorForSub(sub: self.subreddit), seconds: 5, context: self)
                        }
                        
                    })
                }
            } catch {
                BannerUtil.makeBanner(text: "No cached comments found!", color: ColorUtil.accentColorForSub(sub: self.subreddit), seconds: 3, context: self)
            }
        }

    }
    
    @objc func refresh(_ sender: AnyObject) {
        self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - (self.refreshControl!.frame.size.height)), animated: true)
        session = (UIApplication.shared.delegate as! AppDelegate).session
        approved.removeAll()
        removed.removeAll()
        self.shouldAnimateLoad = false
        content.removeAll()
        self.liveTimer.invalidate()
        text.removeAll()
        dataArray.removeAll()
        cDepth.removeAll()
        comments.removeAll()
        hidden.removeAll()
        tableView.reloadData()
        if let link = self.submission {
            sub = link.subreddit
            
            self.setupTitleView(link.subreddit, icon: link.subreddit_icon)

            reset = false
            do {
                var name = link.name
                if name.contains("t3_") {
                    name = name.replacingOccurrences(of: "t3_", with: "")
                }
                if offline {
                    self.loadOffline()
                } else {
                    try session?.getArticles(name, sort: sort == .suggested ? nil : sort, comments: (context.isEmpty ? nil : [context]), context: 3, limit: SettingValues.commentLimit, completion: { (result) -> Void in
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
                                    let realm = try Realm()
                                   // TODO: - insert
                                    realm.beginWrite()
                                    for comment in self.comments {
                                        if let content = self.content[comment] {
                                            if content is RComment {
                                                realm.create(RComment.self, value: content, update: .all)
                                            } else {
                                                realm.create(RMore.self, value: content, update: .all)
                                            }
                                            if content is RComment {
                                                self.submission!.comments.append(content as! RComment)
                                            }
                                        }
                                    }
                                    realm.create(type(of: self.submission!), value: self.submission!, update: .all)
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
                            History.addSeen(s: link, skipDuplicates: false)
                            DispatchQueue.main.async(execute: { () -> Void in
                                if !self.hasSubmission {
                                    self.headerCell = FullLinkCellView()
                                    self.headerCell?.del = self
                                    self.headerCell?.parentViewController = self
                                    self.hasDone = true
                                    self.headerCell?.aspectWidth = self.tableView.bounds.size.width
                                    self.headerCell?.configure(submission: self.submission!, parent: self, nav: self.navigationController, baseSub: self.submission!.subreddit, parentWidth: self.view.frame.size.width, np: self.np)
                                    if self.submission!.isSelf {
                                        self.headerCell?.showBody(width: self.view.frame.size.width - 24)
                                    }
                                    self.tableView.tableHeaderView = UIView(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.width, height: 0.01))
                                    if let tableHeaderView = self.headerCell {
                                        var frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: tableHeaderView.estimateHeight(true, np: self.np))
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
                                    
                                    self.setupTitleView(self.submission!.subreddit, icon: self.submission!.subreddit_icon)
                                    
                                    self.navigationItem.backBarButtonItem?.title = ""
                                    self.setBarColors(color: ColorUtil.getColorForSub(sub: self.submission!.subreddit))
                                } else {
                                    self.headerCell?.aspectWidth = self.tableView.bounds.size.width
                                    self.headerCell?.refreshLink(self.submission!, np: self.np)
                                    if self.submission!.isSelf {
                                        self.headerCell?.showBody(width: self.view.frame.size.width - 24)
                                    }

                                    var frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.headerCell!.estimateHeight(true, true, np: self.np))
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
                                self.activityIndicator.stopAnimating()
                                if self.live {
                                    self.liveTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.loadNewComments), userInfo: nil, repeats: true)
                                    self.startPulse()
                                } else {
                                    if self.sortB != nil && self.searchB != nil {
                                        self.navigationItem.rightBarButtonItems = [self.sortB, self.searchB]
                                    }
                                }
                                self.indicator.stopAnimating()
                                self.indicator.isHidden = true
                                
                                var index = 0
                                var loaded = true
                                
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
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
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
                                    if self.finishedPush {
                                        self.reloadTableViewAnimated()
                                    } else {
                                        self.shouldAnimateLoad = true
                                    }
                                }
                                self.loaded = true
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
    
    func setupTitleView(_ sub: String, icon: String) {
        let label = UILabel()
        label.text = "   \(SettingValues.reduceColor ? "      " : "")\(sub)"
        label.textColor = SettingValues.reduceColor ? ColorUtil.theme.fontColor : .white
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.boldSystemFont(ofSize: 20)
        
        if SettingValues.reduceColor {
            let sideView = UIImageView(frame: CGRect(x: 5, y: 5, width: 30, height: 30))
            let subreddit = sub
            sideView.backgroundColor = ColorUtil.getColorForSub(sub: subreddit)
            
            if let icon = Subscriptions.icon(for: subreddit) {
                sideView.contentMode = .scaleAspectFill
                sideView.image = UIImage()
                sideView.sd_setImage(with: URL(string: icon.unescapeHTML), completed: nil)
            } else {
                sideView.contentMode = .center
                if subreddit.contains("m/") {
                    sideView.image = SubredditCellView.defaultIconMulti
                } else if subreddit.lowercased() == "all" {
                    sideView.image = SubredditCellView.allIcon
                    sideView.backgroundColor = GMColor.blue500Color()
                } else if subreddit.lowercased() == "frontpage" {
                    sideView.image = SubredditCellView.frontpageIcon
                    sideView.backgroundColor = GMColor.green500Color()
                } else if subreddit.lowercased() == "popular" {
                    sideView.image = SubredditCellView.popularIcon
                    sideView.backgroundColor = GMColor.purple500Color()
                } else {
                    sideView.image = SubredditCellView.defaultIcon
                }
            }
            
            label.addSubview(sideView)
            sideView.sizeAnchors == CGSize.square(size: 30)
            sideView.centerYAnchor == label.centerYAnchor
            sideView.leftAnchor == label.leftAnchor

            sideView.layer.cornerRadius = 15
            sideView.clipsToBounds = true
        }
        
        label.sizeToFit()
        self.navigationItem.titleView = label

        label.accessibilityHint = "Opens the sub red it r \(sub)"
        label.accessibilityLabel = "Sub red it: r \(sub)"

        label.addTapGestureRecognizer(action: {
            VCPresenter.openRedditLink("/r/\(sub)", self.navigationController, self)
        })
    }
    
    var savedBack: UIBarButtonItem?

    func showSearchBar() {
        searchBar.alpha = 0
        
        let cancelButtonAttributes = [NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes, for: .normal)

        isSearch = true
        savedHeaderView = tableView.tableHeaderView
        tableView.tableHeaderView = UIView()
        savedTitleView = navigationItem.titleView
        navigationItem.titleView = searchBar
        savedBack = navigationItem.leftBarButtonItem
        navigationItem.setRightBarButtonItems(nil, animated: true)
        navigationItem.setLeftBarButtonItems(nil, animated: true)
        self.navigationItem.setHidesBackButton(true, animated: false)
        
        // Add cancel button (iPad doesn't show standard one)
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let cancelButton = UIBarButtonItem(title: cancelButtonTitle, style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.setRightBarButton(cancelButton, animated: false)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.searchBar.alpha = 1
        }, completion: { _ in
            if !ColorUtil.theme.isLight {
                self.searchBar.keyboardAppearance = .dark
            }
            self.searchBar.becomeFirstResponder()
        })
    }

    var moreB = UIBarButtonItem()
    var modB = UIBarButtonItem()

    func hideSearchBar() {
        if let header = savedHeaderView {
            navigationController?.setNavigationBarHidden(false, animated: true)
            tableView.tableHeaderView = header
        }
        isSearch = false
        
        searchBar.tintColor = ColorUtil.theme.fontColor
        sortButton = UIButton.init(type: .custom)
        sortButton.addTarget(self, action: #selector(self.sort(_:)), for: UIControl.Event.touchUpInside)
        sortButton.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let sortB = UIBarButtonItem.init(customView: sortButton)

        doSortImage(sortButton)
        
        let search = UIButton.init(type: .custom)
        search.setImage(UIImage.init(sfString: SFSymbol.magnifyingglass, overrideString: "search")?.navIcon(), for: UIControl.State.normal)
        search.addTarget(self, action: #selector(self.search(_:)), for: UIControl.Event.touchUpInside)
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

    @objc func sort(_ selector: UIButton?) {
        if !offline {
            let isDefault = UISwitch()
            isDefault.onTintColor = ColorUtil.accentColorForSub(sub: self.sub)
            let defaultLabel = UILabel()
            defaultLabel.text = "Default for sub"
            let group = UIView()
            group.isUserInteractionEnabled = true
            group.addSubviews(isDefault, defaultLabel)
            defaultLabel.textColor = ColorUtil.accentColorForSub(sub: self.sub)
            defaultLabel.centerYAnchor == group.centerYAnchor
            isDefault.leftAnchor == group.leftAnchor
            isDefault.centerYAnchor == group.centerYAnchor
            defaultLabel.leftAnchor == isDefault.rightAnchor + 10
            defaultLabel.rightAnchor == group.rightAnchor

            let actionSheetController = DragDownAlertMenu(title: "Comment sorting", subtitle: "", icon: nil, extraView: group, themeColor: ColorUtil.accentColorForSub(sub: submission?.subreddit ?? ""), full: true)
            
            for c in CommentSort.cases {
                if c == .suggested {
                    continue
                }
                var sortIcon = UIImage()
                
                if c == .controversial {
                    actionSheetController.addAction(title: "Sort by Live", icon: UIImage(sfString: SFSymbol.playFill, overrideString: "ic_sort_white")?.navIcon() ?? UIImage(), primary: live) {
                        self.setLive()
                    }
                }
                
                switch c {
                case .suggested, .confidence:
                    sortIcon = UIImage(sfString: SFSymbol.handThumbsupFill, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
                case .hot:
                    sortIcon = UIImage(sfString: SFSymbol.flameFill, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
                case .controversial:
                    sortIcon = UIImage(sfString: SFSymbol.boltFill, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
                case .new:
                    sortIcon = UIImage(sfString: SFSymbol.tagFill, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
                case .old:
                    sortIcon = UIImage(sfString: SFSymbol.clockFill, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
                case .top:
                    sortIcon = UIImage(sfString: SFSymbol.arrowUp, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
                default:
                    sortIcon = UIImage(sfString: SFSymbol.questionmark, overrideString: "ic_sort_white")?.navIcon() ?? UIImage()
                }
                
                actionSheetController.addAction(title: c.description, icon: sortIcon, primary: sort == c) {
                    self.sort = c
                    self.reset = true
                    self.live = false
                    if isDefault.isOn {
                        SettingValues.setCommentSorting(forSubreddit: self.sub, commentSorting: c)
                    }
                    self.activityIndicator.removeFromSuperview()
                    let barButton = UIBarButtonItem(customView: self.activityIndicator)
                    self.navigationItem.rightBarButtonItems = [barButton]
                    self.activityIndicator.startAnimating()
                    
                    self.doSortImage(self.sortButton)

                    self.refresh(self)
                }
            }

            actionSheetController.addAction(title: "Q&A", icon: UIImage(sfString: SFSymbol.questionmark, overrideString: "ic_sort_white")?.navIcon() ?? UIImage(), primary: sort == .qa) {
                self.sort = .qa
                self.reset = true
                self.live = false
                if isDefault.isOn {
                    SettingValues.setCommentSorting(forSubreddit: self.sub, commentSorting: .qa)
                }
                self.activityIndicator.removeFromSuperview()
                let barButton = UIBarButtonItem(customView: self.activityIndicator)
                self.navigationItem.rightBarButtonItems = [barButton]
                self.activityIndicator.startAnimating()
                
                self.doSortImage(self.sortButton)

                self.refresh(self)
            }
            
            actionSheetController.show(self)
        }
    }
    
    var indicator: MDCActivityIndicator = MDCActivityIndicator()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView = UITableView(frame: CGRect.zero, style: UITableView.Style.plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.view = UIView.init(frame: CGRect.zero)
        self.view.addSubview(tableView)

        tableView.verticalAnchors == view.verticalAnchors
        tableView.horizontalAnchors == view.safeHorizontalAnchors

        self.automaticallyAdjustsScrollViewInsets = false
        self.registerForPreviewing(with: self, sourceView: self.tableView)

        self.tableView.allowsSelection = false
        //self.tableView.layer.speed = 1.5
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        self.tableView.backgroundColor = ColorUtil.theme.backgroundColor
        self.navigationController?.view.backgroundColor = ColorUtil.theme.foregroundColor
        refreshControl = UIRefreshControl()
        refreshControl?.tintColor = ColorUtil.theme.fontColor
        refreshControl?.attributedTitle = NSAttributedString(string: "")
        refreshControl?.addTarget(self, action: #selector(CommentViewController.refresh(_:)), for: UIControl.Event.valueChanged)
        var top = CGFloat(64)
        let bottom = CGFloat(45)
        if #available(iOS 11.0, *) {
            top = 0
        }
        tableView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        tableView.addSubview(refreshControl!)

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: nil, action: nil)

        searchBar.delegate = self
        searchBar.searchBarStyle = UISearchBar.Style.minimal
        searchBar.textColor = SettingValues.reduceColor && ColorUtil.theme.isLight ? ColorUtil.theme.fontColor : .white
        searchBar.showsCancelButton = false
        if !ColorUtil.theme.isLight {
            searchBar.keyboardAppearance = .dark
        }

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.white

        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension

        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "Cell\(version)")
        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "MoreCell\(version)")

        tableView.separatorStyle = .none
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillShow(_:)),
                name: UIResponder.keyboardWillShowNotification,
                object: nil
        )
        NotificationCenter.default.addObserver(
                self,
                selector: #selector(keyboardWillHide(_:)),
                name: UIResponder.keyboardWillHideNotification,
                object: nil)

        headerCell = FullLinkCellView()
        headerCell!.del = self
        headerCell!.parentViewController = self
        headerCell!.aspectWidth = self.tableView.bounds.size.width

        if SettingValues.commentActionLeftLeft != .NONE || SettingValues.commentActionLeftRight != .NONE {
            setupGestures()
        }
        
        self.presentationController?.delegate = self

        if !loaded && (single || forceLoad) {
            refresh(self)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(onThemeChanged), name: .onThemeChanged, object: nil)
    }

    @objc func onThemeChanged() {
        version += 1
        
        self.headerCell = FullLinkCellView()
        self.headerCell?.del = self
        self.headerCell?.parentViewController = self
        self.hasDone = true
        self.headerCell?.aspectWidth = self.tableView.bounds.size.width
        self.headerCell?.configure(submission: self.submission!, parent: self, nav: self.navigationController, baseSub: self.submission!.subreddit, parentWidth: self.view.frame.size.width, np: self.np)
        if self.submission!.isSelf {
            self.headerCell?.showBody(width: self.view.frame.size.width - 24)
        }
        self.tableView.tableHeaderView = UIView(frame: CGRect.init(x: 0, y: 0, width: self.tableView.frame.width, height: 0.01))
        if let tableHeaderView = self.headerCell {
            var frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: tableHeaderView.estimateHeight(true, np: self.np))
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
        
        self.setupTitleView(self.submission!.subreddit, icon: self.submission!.subreddit_icon)
        
        self.navigationItem.backBarButtonItem?.title = ""
        self.setBarColors(color: ColorUtil.getColorForSub(sub: self.submission!.subreddit))
        
        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "Cell\(version)")
        self.tableView.register(CommentDepthCell.classForCoder(), forCellReuseIdentifier: "MoreCell\(version)")
        updateStringsTheme(self.content.map { (k, v) in v} )

        self.tableView.reloadData()
        
        sortButton = UIButton.init(type: .custom)
        sortButton.addTarget(self, action: #selector(self.sort(_:)), for: UIControl.Event.touchUpInside)
        sortButton.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let sortB = UIBarButtonItem.init(customView: sortButton)

        doSortImage(sortButton)
        
        let search = UIButton.init(type: .custom)
        search.setImage(UIImage.init(sfString: SFSymbol.magnifyingglass, overrideString: "search")?.navIcon(), for: UIControl.State.normal)
        search.addTarget(self, action: #selector(self.search(_:)), for: UIControl.Event.touchUpInside)
        search.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
        let searchB = UIBarButtonItem.init(customView: search)

        navigationItem.rightBarButtonItems = [sortB, searchB]
        doHeadView(self.view.frame.size)
        
        self.createJumpButton(true)
        if let submission = self.submission {
            self.setupTitleView(submission.subreddit, icon: submission.subreddit_icon)
        }
        self.updateToolbar()
        self.view.backgroundColor = ColorUtil.theme.backgroundColor
        self.tableView.backgroundColor = ColorUtil.theme.backgroundColor
        self.navigationController?.view.backgroundColor = ColorUtil.theme.foregroundColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if let themeChanged = previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) {
                if themeChanged {
                    ColorUtil.matchTraitCollection()
                }
            }
        }
    }

    @objc func cancelTapped() {
        hideSearchBar()
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

    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            if keyboardHeight != 0 {
                var top = CGFloat(64)
                let bottom = CGFloat(45)
                if #available(iOS 11.0, *) {
                    top = 0
                }
                tableView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom + keyboardHeight, right: 0)
            }
        }
    }

    var normalInsets = UIEdgeInsets(top: 0, left: 0, bottom: 45, right: 0)

    @objc func keyboardWillHide(_ notification: Notification) {
        var top = CGFloat(64)
        let bottom = CGFloat(45)
        if #available(iOS 11.0, *) {
            top = 0
        }
        tableView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
    }

    var single = true
    var hasDone = false
    var configuredOnce = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if hasSubmission && self.view.frame.size.width != 0 {

            guard let headerCell = headerCell else {
                return
            }
            if !configuredOnce {
                headerCell.aspectWidth = self.view.frame.size.width
                headerCell.configure(submission: submission!, parent: self, nav: self.navigationController, baseSub: submission!.subreddit, parentWidth: self.navigationController?.view.bounds.size.width ?? self.tableView.frame.size.width, np: np)
                if submission!.isSelf {
                    headerCell.showBody(width: self.view.frame.size.width - 24)
                }
                configuredOnce = true
            }

            var frame = CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: headerCell.estimateHeight(true, np: self.np))
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
            
            self.setupTitleView(submission == nil ? subreddit : submission!.subreddit, icon: submission!.subreddit_icon)
            
            self.navigationItem.backBarButtonItem?.title = ""
            
            if submission != nil {
                self.setBarColors(color: ColorUtil.getColorForSub(sub: submission == nil ? subreddit : submission!.subreddit))
            }
            
            self.authorColor = ColorUtil.getCommentNameColor(submission == nil ? subreddit : submission!.subreddit)
            
            navigationController?.setToolbarHidden(false, animated: true)
            self.isToolbarHidden = false
        }
    }
    
    var sortB: UIBarButtonItem!
    var searchB: UIBarButtonItem!
    var liveB: UIBarButtonItem!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.isHiding = true
        
        if navigationController != nil {
            sortButton = UIButton.init(type: .custom)
            sortButton.accessibilityLabel = "Change sort type"
            sortButton.addTarget(self, action: #selector(self.sort(_:)), for: UIControl.Event.touchUpInside)
            sortButton.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            sortB = UIBarButtonItem.init(customView: sortButton)
            
            doSortImage(sortButton)

            let search = UIButton.init(type: .custom)
            search.accessibilityLabel = "Search"
            search.setImage(UIImage.init(sfString: SFSymbol.magnifyingglass, overrideString: "search")?.navIcon(), for: UIControl.State.normal)
            search.addTarget(self, action: #selector(self.search(_:)), for: UIControl.Event.touchUpInside)
            search.frame = CGRect.init(x: 0, y: 0, width: 25, height: 25)
            searchB = UIBarButtonItem.init(customView: search)
            
            navigationItem.rightBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -20)
            if !loaded {
                activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                activityIndicator.color = SettingValues.reduceColor && ColorUtil.theme.isLight ? ColorUtil.theme.fontColor : .white
                if self.navigationController == nil {
                    self.view.addSubview(activityIndicator)
                    activityIndicator.centerAnchors == self.view.centerAnchors
                } else {
                    let barButton = UIBarButtonItem(customView: activityIndicator)
                    navigationItem.rightBarButtonItems = [barButton]
                }
                activityIndicator.startAnimating()
            } else {
                navigationItem.rightBarButtonItems = [sortB, searchB]
            }
        } else {
            if !loaded {
                activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                activityIndicator.color = ColorUtil.theme.navIconColor
                self.view.addSubview(activityIndicator)
                activityIndicator.centerAnchors == self.view.centerAnchors
                activityIndicator.startAnimating()
            }
        }
        
        doStartupItems()

        if headerCell.videoView != nil && !(headerCell?.videoView?.isHidden ?? true) {
            headerCell.videoView?.player?.play()
        }
        
        if isSearching {
            isSearching = false
            tableView.reloadData()
        }
        
        setNeedsStatusBarAppearanceUpdate()
        if navigationController != nil && (didDisappearCompletely || !loaded) {
            self.setupTitleView(submission == nil ? subreddit : submission!.subreddit, icon: submission!.subreddit_icon)
            self.updateToolbar()
        }
    }
    
    var activityIndicator = UIActivityIndicatorView()

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad && Int(round(self.view.bounds.width / CGFloat(320))) > 1 && false {
            self.navigationController!.view.backgroundColor = .clear
        }
        self.isHiding = false
        didDisappearCompletely = false
        let isModal = navigationController?.presentingViewController != nil || self.modalPresentationStyle == .fullScreen

        if isModal && self.navigationController is TapBehindModalViewController {
            self.navigationController?.delegate = self
            (self.navigationController as! TapBehindModalViewController).del = self
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.finishedPush = true
    }
 
    var duringAnimation = false
    var finishedPush = false
    
    func reloadTableViewAnimated() {
        self.tableView.reloadData()

        let cells = self.tableView.visibleCells
        for cell in cells {
            cell.alpha = 0
        }
        var row = Double(0)
        for cell in cells {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                cell.alpha = 1
            }, completion: nil)
            row += 1
        }
    }

    @objc func close(_ sender: AnyObject) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func showMod(_ sender: AnyObject) {
        if !modLink.isEmpty() {
            VCPresenter.openRedditLink(self.modLink, self.navigationController, self)
        }
    }
    
    @objc func showMenu(_ sender: AnyObject) {
        if !offline {
            let link = submission!

            let alertController = DragDownAlertMenu(title: "Comment actions", subtitle: self.submission?.title ?? "", icon: self.submission?.thumbnailUrl)

            alertController.addAction(title: "Refresh comments", icon: UIImage(sfString: SFSymbol.arrowClockwise, overrideString: "sync")!.menuIcon()) {
                self.reset = true
                self.refresh(self)
            }

            alertController.addAction(title: "Reply to submission", icon: UIImage(sfString: SFSymbol.arrowshapeTurnUpLeftFill, overrideString: "reply")!.menuIcon()) {
                self.reply(self.headerCell)
            }

            alertController.addAction(title: "Go to r/\(link.subreddit)", icon: UIImage(sfString: .rCircleFill, overrideString: "subs")!.menuIcon()) {
                VCPresenter.openRedditLink("www.reddit.com/r/\(link.subreddit)", self.navigationController, self)
            }

            alertController.addAction(title: "View related submissions", icon: UIImage(sfString: SFSymbol.squareStackFill, overrideString: "size")!.menuIcon()) {
                let related = RelatedViewController.init(thing: self.submission!)
                VCPresenter.showVC(viewController: related, popupIfPossible: false, parentNavigationController: self.navigationController, parentViewController: self)
            }

            alertController.addAction(title: "View r/\(link.subreddit)'s sidebar", icon: UIImage(sfString: SFSymbol.infoCircle, overrideString: "info")!.menuIcon()) {
                Sidebar.init(parent: self, subname: self.submission!.subreddit).displaySidebar()
            }

            alertController.addAction(title: allCollapsed ? "Expand child comments" : "Collapse child comments", icon: UIImage(sfString: SFSymbol.bubbleLeftAndBubbleRightFill, overrideString: "comments")!.menuIcon()) {
                if self.allCollapsed {
                    self.expandAll()
                } else {
                    self.collapseAll()
                }
            }
            
            alertController.show(self)
        }
    }

    var sub: String = ""
    var allCollapsed = false

    var subInfo: Subreddit?

    @objc func search(_ sender: AnyObject) {
        if !dataArray.isEmpty {
            expandAll()
            showSearchBar()
        }
        // Todo future loadAllMore()
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
    
    private var blurView: UIVisualEffectView?
    private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
    private var blackView = UIView()
    
    func setBackgroundView() {
        blackView.backgroundColor = .black
        blackView.alpha = 0
        blurView = UIVisualEffectView(frame: self.navigationController!.view!.bounds)
        self.blurView!.effect = self.blurEffect
        self.blurEffect.setValue(10, forKeyPath: "blurRadius")
        self.navigationController!.view!.insertSubview(blackView, at: self.navigationController!.view!.subviews.count)
        self.navigationController!.view!.insertSubview(blurView!, at: self.navigationController!.view!.subviews.count)
        blurView!.edgeAnchors == self.navigationController!.view!.edgeAnchors
        blackView.edgeAnchors == self.navigationController!.view!.edgeAnchors
        
        UIView.animate(withDuration: 0.2, delay: 1, options: .curveEaseInOut, animations: {
            self.blackView.alpha = 0.2
        })
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
                self.text[comment.getId()] = TextDisplayStackView.createAttributedChunk(baseHTML: comment.bodyHtml, fontSize: 16, submission: false, accentColor: color, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
            } else {
                let attr = NSMutableAttributedString(string: "more")
                self.text[(thing.0 as! More).getId()] = LinkParser.parse(attr, color, font: UIFont.systemFont(ofSize: 16), fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
            }
        }
    }
    
    func updateStringsTheme(_ comments: [AnyObject]) {
        var color = UIColor.black
        var first = true
        for thing in comments {
            if let comment = thing as? RComment, first {
                color = ColorUtil.accentColorForSub(sub: comment.subreddit)
                first = false
            }
            if let comment = thing as? RComment {
                self.text[comment.getId()] = TextDisplayStackView.createAttributedChunk(baseHTML: comment.htmlText, fontSize: 16, submission: false, accentColor: color, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
            } else if let more = thing as? RMore {
                let attr = NSMutableAttributedString(string: "more")
                self.text[more.getId()] = LinkParser.parse(attr, color, font: UIFont.systemFont(ofSize: 16), fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
            }
        }
    }

    var text: [String: NSAttributedString]

    func updateStringsSingle(_ newComments: [Object]) {
        let color = ColorUtil.accentColorForSub(sub: ((newComments[0] as! RComment).subreddit))
        for thing in newComments {
            if let comment = thing as? RComment {
                let html = comment.htmlText
                self.text[comment.getIdentifier()] = TextDisplayStackView.createAttributedChunk(baseHTML: html, fontSize: 16, submission: false, accentColor: color, fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
            } else {
                let attr = NSMutableAttributedString(string: "more")
                self.text[(thing as! RMore).getIdentifier()] = LinkParser.parse(attr, color, font: UIFont.systemFont(ofSize: 16), fontColor: ColorUtil.theme.fontColor, linksCallback: nil, indexCallback: nil)
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

    @objc func downVote(_ sender: AnyObject?) {
        vote(.down)
    }

    @objc func upVote(_ sender: AnyObject?) {
        vote(.up)
    }

    @objc func cancelVote(_ sender: AnyObject?) {
        vote(.none)
    }

    @objc func loadAll(_ sender: AnyObject) {
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
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    @objc func showNavTypes(_ sender: UIView) {
        if !loaded {
            return
        }
        let alertController = DragDownAlertMenu(title: "Comment navigation", subtitle: "Select a navigation type", icon: nil)

        let link = getCount(sort: .LINK)
        let parents = getCount(sort: .PARENTS)
        let op = getCount(sort: .OP)
        let gilded = getCount(sort: .GILDED)
        let you = getCount(sort: .YOU)

        alertController.addAction(title: "Top-level comments (\(parents))", icon: UIImage()) {
            self.currentSort = .PARENTS
        }
        alertController.addAction(title: "Submission OP (\(op))", icon: UIImage()) {
            self.currentSort = .OP
        }
        alertController.addAction(title: "Links in comment (\(link))", icon: UIImage()) {
            self.currentSort = .LINK
        }
        alertController.addAction(title: "Your comments (\(you))", icon: UIImage()) {
            self.currentSort = .YOU
        }
        alertController.addAction(title: "Gilded comments (\(gilded))", icon: UIImage()) {
            self.currentSort = .GILDED
        }
        alertController.show(self)
    }

    func goToCell(i: Int) {
        let indexPath = IndexPath(row: i, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    var goingToCell = false
    
    func goToCellTop(i: Int) {
        isGoingDown = true
        let indexPath = IndexPath(row: i, section: 0)
        goingToCell = true
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.goingToCell = false
        self.isGoingDown = false
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.goingToCell = false
        self.isGoingDown = false
    }
    
    @objc func goUp(_ sender: AnyObject) {
        if !loaded || content.isEmpty {
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
    var isGoingDown = false
    
    @objc func goDown(_ sender: AnyObject) {
        if !loaded || content.isEmpty {
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
            if (topCell + 1) > (dataArray.count - 1) {
                return
            }
            for i in (topCell + 1)..<(dataArray.count - 1) {
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
            up.setImage(UIImage(sfString: SFSymbol.chevronCompactUp, overrideString: "up")?.toolbarIcon(), for: UIControl.State.normal)
            up.addTarget(self, action: #selector(CommentViewController.goUp(_:)), for: UIControl.Event.touchUpInside)
            up.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            let upB = UIBarButtonItem(customView: up)

            let nav = UIButton(type: .custom)
            nav.accessibilityLabel = "Change criteria for comment thread navigation"
            nav.setImage(UIImage(sfString: SFSymbol.safariFill, overrideString: "nav")?.toolbarIcon(), for: UIControl.State.normal)
            nav.addTarget(self, action: #selector(CommentViewController.showNavTypes(_:)), for: UIControl.Event.touchUpInside)
            nav.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            let navB = UIBarButtonItem(customView: nav)

            let down = UIButton(type: .custom)
            down.accessibilityLabel = "Navigate down one comment thread"
            down.setImage(UIImage(sfString: SFSymbol.chevronCompactDown, overrideString: "down")?.toolbarIcon(), for: UIControl.State.normal)
            down.addTarget(self, action: #selector(CommentViewController.goDown(_:)), for: UIControl.Event.touchUpInside)
            down.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            let downB = UIBarButtonItem(customView: down)

            let more = UIButton(type: .custom)
            more.accessibilityLabel = "Post options"
            more.setImage(UIImage(sfString: SFSymbol.ellipsis, overrideString: "moreh")?.toolbarIcon(), for: UIControl.State.normal)
            more.addTarget(self, action: #selector(self.showMenu(_:)), for: UIControl.Event.touchUpInside)
            more.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            moreB = UIBarButtonItem(customView: more)
            
            let mod = UIButton(type: .custom)
            mod.accessibilityLabel = "Moderator options"
            mod.setImage(UIImage(sfString: SFSymbol.shieldLefthalfFill, overrideString: "mod")?.toolbarIcon(), for: UIControl.State.normal)
            mod.addTarget(self, action: #selector(self.showMod(_:)), for: UIControl.Event.touchUpInside)
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
            parent?.navigationController?.toolbar.barTintColor = ColorUtil.theme.backgroundColor
            parent?.navigationController?.toolbar.tintColor = ColorUtil.theme.fontColor
        } else {
            toolbarItems = items
            navigationController?.toolbar.barTintColor = ColorUtil.theme.backgroundColor
            navigationController?.toolbar.tintColor = ColorUtil.theme.fontColor
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (isSearching ? self.filteredData.count : self.comments.count - self.hidden.count)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if SettingValues.collapseFully {
            let datasetPosition = (indexPath as NSIndexPath).row
            if dataArray.isEmpty {
                return UITableView.automaticDimension
            }
            let thing = isSearching ? filteredData[datasetPosition] : dataArray[datasetPosition]
            if !hiddenPersons.contains(thing) && thing != self.menuId {
                if let height = oldHeights[thing] {
                    return height
                }
            }
        }
        return UITableView.automaticDimension
    }

    var tagText: String?

    func tagUser(name: String) {
        let alert = DragDownAlertMenu(title: AccountController.formatUsername(input: name, small: true), subtitle: "Tag profile", icon: nil, full: true)
        
        alert.addTextInput(title: "Set tag", icon: UIImage(sfString: SFSymbol.tagFill, overrideString: "save-1")?.menuIcon(), action: {
            ColorUtil.setTagForUser(name: name, tag: alert.getText() ?? "")
            self.tableView.reloadData()
        }, inputPlaceholder: "Enter a tag...", inputValue: ColorUtil.getTagForUser(name: name), inputIcon: UIImage(sfString: SFSymbol.tagFill, overrideString: "subs")!.menuIcon(), textRequired: true, exitOnAction: true)

        if !(ColorUtil.getTagForUser(name: name) ?? "").isEmpty {
            alert.addAction(title: "Remove tag", icon: UIImage(sfString: SFSymbol.trashFill, overrideString: "delete")?.menuIcon(), enabled: true) {
                ColorUtil.removeTagForUser(name: name)
                self.tableView.reloadData()
            }
        }
        
        alert.show(self)
    }

    func blockUser(name: String) {
        let alert = AlertController(title: "", message: nil, preferredStyle: .alert)
        let confirmAction = AlertAction(title: "Block", style: .preferred, handler: {(_) in
            PostFilter.profiles.append(name as NSString)
            PostFilter.saveAndUpdate()
            BannerUtil.makeBanner(text: "User blocked", color: GMColor.red500Color(), seconds: 3, context: self, top: true, callback: nil)
            if AccountController.isLoggedIn {
                do {
                    try (UIApplication.shared.delegate as! AppDelegate).session?.blockViaUsername(name, completion: { (result) in
                        print(result)
                    })
                } catch {
                    print(error)
                }
            }
        })
            
        alert.setupTheme()
        
        alert.attributedTitle = NSAttributedString(string: "Are you sure you want to block u/\(name)?", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: ColorUtil.theme.fontColor])
        
        alert.addAction(confirmAction)
        alert.addCancelButton()
        
        alert.addBlurView()
        self.present(alert, animated: true, completion: nil)
    }

    var isCurrentlyChanging = false
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        inHeadView.removeFromSuperview()
        headerCell.endVideos()
        self.didDisappearCompletely = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isHiding = true
        self.liveTimer.invalidate()
        self.removeJumpButton()
    }

    func collapseAll() {
        self.allCollapsed = true
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
    
    func expandAll() {
        self.allCollapsed = false
        if dataArray.count > 0 {
            for i in 0...dataArray.count - 1 {
                if content[dataArray[i]] is RComment && matches(comment: content[dataArray[i]] as! RComment, sort: .PARENTS) {
                    _ = unhideNumber(n: dataArray[i], iB: i)
                    let t = content[dataArray[i]]
                    let id = (t is RComment) ? (t as! RComment).getIdentifier() : (t as! RMore).getIdentifier()
                    if hiddenPersons.contains(id) {
                        hiddenPersons.remove(id)
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
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let strongSelf = self else { return }
                let counter = strongSelf.hideNumber(n: comment, iB: i) - 1
                strongSelf.doArrays()
                DispatchQueue.main.async {
                    strongSelf.tableView.beginUpdates()

                    var indexPaths: [IndexPath] = []
                    for row in i...counter {
                        indexPaths.append(IndexPath(row: row, section: 0))
                    }
                    strongSelf.tableView.deleteRows(at: indexPaths, with: .fade)
                    strongSelf.tableView.endUpdates()
                    strongSelf.isCurrentlyChanging = false
                }
            }
        }
    }

    func doSortImage(_ sortButton: UIButton) {
        switch sort {
        case .suggested, .confidence:
            sortButton.setImage(UIImage(sfString: SFSymbol.arrowUpArrowDown, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        case .hot:
            sortButton.setImage(UIImage(sfString: SFSymbol.flameFill, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        case .controversial:
            sortButton.setImage(UIImage(sfString: SFSymbol.boltFill, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        case .new:
            sortButton.setImage(UIImage(sfString: SFSymbol.tagFill, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        case .old:
            sortButton.setImage(UIImage(sfString: SFSymbol.clockFill, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        case .top:
            sortButton.setImage(UIImage(sfString: SFSymbol.arrowUp, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        default:
            sortButton.setImage(UIImage(sfString: SFSymbol.questionmark, overrideString: "ic_sort_white")?.navIcon(), for: UIControl.State.normal)
        }
    }

    func unhideAll(comment: String, i: Int) {
        if !isCurrentlyChanging {
            isCurrentlyChanging = true
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let strongSelf = self else { return }

                let counter = strongSelf.unhideNumber(n: comment, iB: i)
                strongSelf.doArrays()
                DispatchQueue.main.async {
                    strongSelf.tableView.beginUpdates()

                    var indexPaths: [IndexPath] = []
                    for row in (i + 1)...counter {
                        indexPaths.append(IndexPath(row: row, section: 0))
                    }
                    strongSelf.tableView.insertRows(at: indexPaths, with: .fade)
                    strongSelf.tableView.endUpdates()
                    strongSelf.isCurrentlyChanging = false
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
            let bounds = comments.firstIndex(where: { ($0 == n) })! + 1
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
            let bounds = comments.firstIndex(where: { ($0 == n) })! + 1
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
            let bounds = comments.firstIndex(where: { $0 == n })! + 1
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
        if !isReply {
            UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                self.tableView.contentOffset.y = min(self.tableView.contentOffset.y + 350, self.tableView.contentSize.height - self.tableView.frame.size.height)
            }, completion: nil)
        }
    }
    
    @objc func spacePressedUp() {
        if !isReply {
            UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                self.tableView.contentOffset.y = max(self.tableView.contentOffset.y - 350, -64)
            }, completion: nil)
        }
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
                    frame.size.height = self.headerCell!.estimateHeight(true, true, np: self.np)

                    self.headerCell!.contentView.frame = frame
                    self.tableView.tableHeaderView!.frame = frame
                    //self.tableView.reloadData(with: .none)
                    self.doHeadView(size)
                    self.view.setNeedsLayout()
                }
            }, completion: nil)
    }
    
    var isToolbarHidden = false
    var isHiding = false
    var lastY = CGFloat(0)
    var olderY = CGFloat(0)
    
    var isSearch = false

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var currentY = scrollView.contentOffset.y
        
        //Sometimes the ScrollView will jump one time in the wrong direction. Unsure why this is happening, but this
        //will check for that case and ignore it
        if currentY > lastY && lastY < olderY {
            currentY = lastY
        }
        
        if !SettingValues.pinToolbar && !isReply && !isSearch {
            if currentY <= (tableView.tableHeaderView?.frame.size.height ?? 20) + 64 + 10 {
                liveView?.removeFromSuperview()
                liveView = nil
                liveNewCount = 0
            }
            if currentY > lastY && currentY > 60 {
                if navigationController != nil && !isHiding && !isToolbarHidden && !(scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
                    hideUI(inHeader: true)
                }
            } else if (currentY < lastY - 15 || currentY < 100) && !isHiding && navigationController != nil && (isToolbarHidden) {
                showUI()
            }
        }
        olderY = lastY
        lastY = currentY
    }

    func hideUI(inHeader: Bool) {
        isHiding = true
        //self.tableView.endEditing(true)
        if inHeadView.superview == nil {
            doHeadView(self.view.frame.size)
        }
        
        if !isGoingDown {
            (navigationController)?.setNavigationBarHidden(true, animated: true)
            
            (self.navigationController)?.setToolbarHidden(true, animated: true)
        }
        self.isToolbarHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.createJumpButton()
            strongSelf.isHiding = false
        }
    }

    func showUI() {
        (navigationController)?.setNavigationBarHidden(false, animated: true)
        (navigationController)?.setToolbarHidden(false, animated: true)
        if live {
            progressDot.layer.removeAllAnimations()
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = 0.5
            pulseAnimation.toValue = 1.2
            pulseAnimation.fromValue = 0.2
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            pulseAnimation.autoreverses = false
            pulseAnimation.repeatCount = Float.greatestFiniteMagnitude
            
            let fadeAnimation = CABasicAnimation(keyPath: "opacity")
            fadeAnimation.duration = 0.5
            fadeAnimation.toValue = 0
            fadeAnimation.fromValue = 2.5
            fadeAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            fadeAnimation.autoreverses = false
            fadeAnimation.repeatCount = Float.greatestFiniteMagnitude
            
            progressDot.layer.add(pulseAnimation, forKey: "scale")
            progressDot.layer.add(fadeAnimation, forKey: "fade")
        }
        self.isToolbarHidden = false
        self.removeJumpButton()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = nil

        let datasetPosition = (indexPath as NSIndexPath).row

        cell = tableView.dequeueReusableCell(withIdentifier: "Cell\(version)", for: indexPath) as UITableViewCell
        if content.isEmpty || text.isEmpty || cDepth.isEmpty || dataArray.isEmpty {
            self.refresh(self)
            return cell
        }
        let thing = isSearching ? filteredData[datasetPosition] : dataArray[datasetPosition]
        let parentOP = parents[thing]
        if let cell = cell as? CommentDepthCell {
            let innerContent = content[thing]
            if innerContent is RComment {
                var count = 0
                let hiddenP = hiddenPersons.contains(thing)
                if hiddenP {
                    count = getChildNumber(n: innerContent!.getIdentifier())
                }
                var t = text[thing]!
                if isSearching {
                    t = highlight(t)
                }

                cell.setComment(comment: innerContent as! RComment, depth: cDepth[thing]!, parent: self, hiddenCount: count, date: lastSeen, author: submission?.author, text: t, isCollapsed: hiddenP, parentOP: parentOP ?? "", depthColors: commentDepthColors, indexPath: indexPath, width: self.tableView.frame.size.width)
            } else {
                cell.setMore(more: (innerContent as! RMore), depth: cDepth[thing]!, depthColors: commentDepthColors, parent: self)
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
//                action.image = UIImage(named: SettingValues.commentActionRightRight.getPhoto())?.navIcon()
//
//                actions.append(action)
//            }
//            if SettingValues.commentActionRightLeft != .NONE {
//                let action = UIContextualAction.init(style: .normal, title: "", handler: { (action, _, b) in
//                    b(true)
//                    self.doAction(cell: cell as! CommentDepthCell, action: SettingValues.commentActionRightLeft, indexPath: indexPath)
//                })
//                action.backgroundColor = SettingValues.commentActionRightLeft.getColor()
//                action.image = UIImage(named: SettingValues.commentActionRightLeft.getPhoto())?.navIcon()
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
//                action.image = UIImage(named: SettingValues.commentActionLeftLeft.getPhoto())?.navIcon()
//
//                actions.append(action)
//            }
//            if SettingValues.commentActionLeftRight != .NONE {
//                let action = UIContextualAction.init(style: .normal, title: "", handler: { (action, _, b) in
//                    b(true)
//                    self.doAction(cell: cell as! CommentDepthCell, action: SettingValues.commentActionLeftRight, indexPath: indexPath)
//                })
//                action.backgroundColor = SettingValues.commentActionLeftRight.getColor()
//                action.image = UIImage(named: SettingValues.commentActionLeftRight.getPhoto())?.navIcon()
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
            cell.save(cell)
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
        case .PARENT_PREVIEW:
            break
        }
    }

    func collapseParent(_ indexPath: IndexPath, baseCell: CommentDepthCell) {
        var topCell = indexPath.row
        var contents = content[dataArray[topCell]]
        var id = ""
        if contents is RComment && (contents as! RComment).depth == 1 {
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
                                           at: UITableView.ScrollPosition.none, animated: false)
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
    
    func loadAllMore() {
        expandAll()
        
        loadMoreWithCallback(0)
    }
    
    func loadMoreWithCallback(_ datasetPosition: Int) {
        if datasetPosition > dataArray.count {
            return
        }
        if let more = content[dataArray[datasetPosition]] as? RMore, let link = self.submission {
           if more.children.isEmpty {
               loadMoreWithCallback(datasetPosition + 1)
           } else {
               do {
                   var strings: [String] = []
                   for c in more.children {
                       strings.append(c.value)
                   }
                   try session?.getMoreChildren(strings, name: link.id, sort: .top, id: more.id, completion: { (result) -> Void in
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

                               if self.comments.count > realPosition && self.comments[realPosition] != nil {
                                   self.comments.remove(at: realPosition)
                               } else {
                                   return
                               }
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
                                self.loadMoreWithCallback(datasetPosition + 1)

                               } else {
                                   self.doArrays()
                                   self.tableView.reloadData()
                                self.loadMoreWithCallback(datasetPosition + 1)
                               }
                           })

                       }

                   })

               } catch {
                    loadMoreWithCallback(datasetPosition + 1)
                   print(error)
               }
           }
        } else {
            loadMoreWithCallback(datasetPosition + 1)
        }
    }

    func highlight(_ cc: NSAttributedString) -> NSAttributedString {
        let base = NSMutableAttributedString.init(attributedString: cc)
        let r = base.mutableString.range(of: "\(searchBar.text!)", options: .caseInsensitive, range: NSRange(location: 0, length: base.string.length))
        if r.length > 0 {
            base.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorUtil.accentColorForSub(sub: subreddit), range: r)
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
                            if hiddenPersons.contains((id)) {
                                hiddenPersons.remove(at: hiddenPersons.firstIndex(of: id)!)
                            }
                            if let oldHeight = oldHeights[id] {
                                UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                                    cell.contentView.frame = CGRect(x: 0, y: 0, width: cell.contentView.frame.size.width, height: oldHeight)
                                }, completion: { (_) in
                                    cell.expandSingle()
                                    self.oldHeights.removeValue(forKey: id)
                                })
                                tableView.beginUpdates()
                                tableView.endUpdates()
                            } else {
                                cell.expandSingle()
                                tableView.beginUpdates()
                                tableView.endUpdates()
                            }
                        } else {
                            oldHeights[id] = cell.contentView.frame.size.height
                            if !hiddenPersons.contains(id) {
                                hiddenPersons.insert(id)
                            }
                            
                            self.tableView.beginUpdates()
                            cell.collapse(childNumber: 0)
                            self.tableView.endUpdates()
                            /* disable for now
                            if SettingValues.collapseFully, let path = tableView.indexPath(for: cell) {
                                self.tableView.scrollToRow(at: path,
                                                           at: UITableView.ScrollPosition.none, animated: true)
                            }*/
                        }
                    } else {
                        if hiddenPersons.contains((id)) && childNumber > 0 {
                            hiddenPersons.remove(at: hiddenPersons.firstIndex(of: id)!)
                            if let oldHeight = oldHeights[id] {
                                UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                                    cell.contentView.frame = CGRect(x: 0, y: 0, width: cell.contentView.frame.size.width, height: oldHeight)
                                }, completion: { (_) in
                                    cell.expand()
                                    self.oldHeights.removeValue(forKey: id)
                                })
                            } else {
                                cell.expand()
                                tableView.beginUpdates()
                                tableView.endUpdates()
                            }
                            unhideAll(comment: comment.getId(), i: row!)
                           // TODO: - hide child number
                        } else {
                            if childNumber > 0 {
                                if childNumber > 0 {
                                    oldHeights[id] = cell.contentView.frame.size.height
                                    cell.collapse(childNumber: childNumber)
                                    /* disable for now
                                    if SettingValues.collapseFully, let path = tableView.indexPath(for: cell) {
                                        self.tableView.scrollToRow(at: path,
                                                                   at: UITableView.ScrollPosition.none, animated: false)
                                    }*/
                                }
                                if row != nil {
                                    hideAll(comment: comment.getIdentifier(), i: row! + 1)
                                }
                                if !hiddenPersons.contains(id) {
                                    hiddenPersons.insert(id)
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
                                try session?.getMoreChildren(strings, name: link.id, sort: .top, id: more.id, completion: { (result) -> Void in
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

                                            if self.comments.count > realPosition && self.comments[realPosition] != nil {
                                                self.comments.remove(at: realPosition)
                                            } else {
                                                return
                                            }
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
    
    func setupGestures() {
        cellGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panCell(_:)))
        cellGestureRecognizer.delegate = self
        cellGestureRecognizer.maximumNumberOfTouches = 1
        tableView.addGestureRecognizer(cellGestureRecognizer)
        cellGestureRecognizer.require(toFail: tableView.panGestureRecognizer)
        if let parent = parent as? ColorMuxPagingViewController {
            parent.requireFailureOf(cellGestureRecognizer)
        }
        if let nav = self.navigationController as? SwipeForwardNavigationController {
            nav.fullWidthBackGestureRecognizer.require(toFail: cellGestureRecognizer)
            if let interactivePop = nav.interactivePopGestureRecognizer {
                cellGestureRecognizer.require(toFail: interactivePop)
            }
        }
    }
    
    func setupSwipeGesture() {
        if swipeBackAdded {
            return
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            if #available(iOS 14, *) {
                return
            }
        }
        if SettingValues.commentGesturesMode == .FULL {
            return
        }
        fullWidthBackGestureRecognizer = UIPanGestureRecognizer()
        if let interactivePopGestureRecognizer = parent?.navigationController?.interactivePopGestureRecognizer, let targets = interactivePopGestureRecognizer.value(forKey: "targets"), parent is ColorMuxPagingViewController, !swipeBackAdded {
            swipeBackAdded = true
            fullWidthBackGestureRecognizer.require(toFail: tableView.panGestureRecognizer)
            if let navGesture = self.navigationController?.interactivePopGestureRecognizer {
                fullWidthBackGestureRecognizer.require(toFail: navGesture)
            }
            fullWidthBackGestureRecognizer.setValue(targets, forKey: "targets")
            fullWidthBackGestureRecognizer.delegate = self
            //parent.requireFailureOf(fullWidthBackGestureRecognizer)
            tableView.addGestureRecognizer(fullWidthBackGestureRecognizer)
            if #available(iOS 13.4, *) {
                fullWidthBackGestureRecognizer.allowedScrollTypesMask = .continuous
            }
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translation(in: tableView)
            if panGestureRecognizer == cellGestureRecognizer {
                if abs(translation.y) >= abs(translation.x) {
                    return false
                }
                if translation.x < 0 {
                    if gestureRecognizer.location(in: tableView).x > tableView.frame.width * 0.5 || SettingValues.commentGesturesMode == .FULL {
                        return true
                    }
                } else if SettingValues.commentGesturesMode == .FULL && abs(translation.x) > abs(translation.y) {
                    return gestureRecognizer.location(in: tableView).x > tableView.frame.width * 0.1
                }
                return false
            }
            if panGestureRecognizer == fullWidthBackGestureRecognizer && translation.x >= 0 {
                return true
            }
            return false
        }
        return false
    }

    @objc func panCell(_ recognizer: UIPanGestureRecognizer) {
        
        if recognizer.view != nil {
            let velocity = recognizer.velocity(in: recognizer.view!)

            if (velocity.x < 0 && (SettingValues.commentActionLeftLeft == .NONE && SettingValues.commentActionLeftRight == .NONE) && translatingCell == nil) || (velocity.x > 0 && (SettingValues.commentGesturesMode == .HALF ||  (SettingValues.commentActionRightLeft == .NONE && SettingValues.commentActionRightRight == .NONE)) && translatingCell == nil) {
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
            for view in cell.commentBody.subviews {
                let cellPoint = recognizer.location(in: view)
                if (view is UIScrollView || view is CodeDisplayView || view is TableDisplayView) && view.bounds.contains(cellPoint) {
                    return
                }
            }
            translatingCell = cell
        }
        
        translatingCell?.handlePan(recognizer)
        if recognizer.state == .ended {
            translatingCell = nil
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value) })
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

class ParentCommentViewController: UIViewController {
    var childView = UIView()
    var scrollView = UIScrollView()
    var estimatedSize: CGSize
    var parentContext: String = ""
    var dismissHandler: (() -> Void)?
    init(view: UIView, size: CGSize) {
        self.estimatedSize = size
        super.init(nibName: nil, bundle: nil)
        self.childView = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView = UIScrollView().then {
            $0.backgroundColor = ColorUtil.theme.foregroundColor
            $0.isUserInteractionEnabled = true
        }
        self.view.addSubview(scrollView)
        scrollView.edgeAnchors == self.view.edgeAnchors
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.addSubview(childView)
        childView.widthAnchor == estimatedSize.width
        childView.heightAnchor == estimatedSize.height
        childView.topAnchor == scrollView.topAnchor
        scrollView.contentSize = estimatedSize
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissHandler?()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CommentViewController: UIViewControllerPreviewingDelegate {
        
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else {
            return nil
        }
        
        guard let cell = self.tableView.cellForRow(at: indexPath) as? CommentDepthCell else {
            return nil
        }
        
        if SettingValues.commentActionForceTouch != .PARENT_PREVIEW {
           // TODO: - maybe
            /*let textView =
            let locationInTextView = textView.convert(location, to: textView)
            
            if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
                previewingContext.sourceRect = textView.convert(rect, from: textView)
                if let controller = parentViewController?.getControllerForUrl(baseUrl: url) {
                    return controller
                }
            }*/
            return nil
        }
        
        if cell.depth == 1 {
            return nil
        }
        self.setAlphaOfBackgroundViews(alpha: 0.5)

        var topCell = (indexPath as NSIndexPath).row
        
        var contents = content[dataArray[topCell]]
        
        while (contents is RComment ? (contents as! RComment).depth >= cell.depth : true) && dataArray.count > topCell && topCell - 1 >= 0 {
            topCell -= 1
            contents = content[dataArray[topCell]]
        }

        let parentCell = CommentDepthCell(style: .default, reuseIdentifier: "test")
        if let comment = contents as? RComment {
            parentCell.contentView.layer.cornerRadius = 10
            parentCell.contentView.clipsToBounds = true
            parentCell.commentBody.ignoreHeight = false
            parentCell.commentBody.estimatedWidth = UIScreen.main.bounds.size.width * 0.85 - 36
            if contents is RComment {
                var count = 0
                let hiddenP = hiddenPersons.contains(comment.getIdentifier())
                if hiddenP {
                    count = getChildNumber(n: comment.getIdentifier())
                }
                var t = text[comment.getIdentifier()]!
                if isSearching {
                    t = highlight(t)
                }
                
                parentCell.setComment(comment: contents as! RComment, depth: 0, parent: self, hiddenCount: count, date: lastSeen, author: submission?.author, text: t, isCollapsed: hiddenP, parentOP: "", depthColors: commentDepthColors, indexPath: indexPath, width: UIScreen.main.bounds.size.width * 0.85)
            } else {
                parentCell.setMore(more: (contents as! RMore), depth: cDepth[comment.getIdentifier()]!, depthColors: commentDepthColors, parent: self)
            }
            parentCell.content = comment
            parentCell.contentView.isUserInteractionEnabled = false

            var size = CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: CGFloat.greatestFiniteMagnitude)
            let layout = YYTextLayout(containerSize: size, text: parentCell.title.attributedText!)!
            let textSize = layout.textBoundingSize

            size = CGSize(width: UIScreen.main.bounds.size.width * 0.85, height: parentCell.commentBody.estimatedHeight + 24 + textSize.height)// TODO: - fix height
            let detailViewController = ParentCommentViewController(view: parentCell.contentView, size: size)
            detailViewController.preferredContentSize = CGSize(width: size.width, height: min(size.height, 300))

            previewingContext.sourceRect = cell.frame
            detailViewController.dismissHandler = {() in
                self.setAlphaOfBackgroundViews(alpha: 1)
            }
            return detailViewController
        }
        return nil
    }
        
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewControllerToCommit.modalPresentationStyle = .popover
        if let popover = viewControllerToCommit.popoverPresentationController {
            popover.sourceView = self.tableView
            popover.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            popover.backgroundColor = ColorUtil.theme.foregroundColor
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            //detailViewController.frame = CGRect(x: (self.view.frame.bounds.width / 2 - (UIScreen.main.bounds.size.width * 0.85)), y: (self.view.frame.bounds.height / 2 - (cell2.title.estimatedHeight + 12)), width: UIScreen.main.bounds.size.width * 0.85, height: cell2.title.estimatedHeight + 12)
            popover.delegate = self
            viewControllerToCommit.preferredContentSize = (viewControllerToCommit as! ParentCommentViewController).estimatedSize
        }

        self.present(viewControllerToCommit, animated: true, completion: {
        })
    }
}

extension CommentViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // Fixes bug with corrupt nav stack
        // https://stackoverflow.com/a/39457751/7138792
        navigationController.interactivePopGestureRecognizer?.isEnabled = navigationController.viewControllers.count > 1
        if navigationController.viewControllers.count == 1 {
            self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

extension CommentViewController: TapBehindModalViewControllerDelegate {
    func shouldDismiss() -> Bool {
        return false
    }
}
