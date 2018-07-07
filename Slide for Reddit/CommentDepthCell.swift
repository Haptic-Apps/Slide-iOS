//
//  CommentDepthCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/31/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import UIKit
import reddift
import TTTAttributedLabel
import RealmSwift
import AudioToolbox
import XLActionController
import RLBAlertsPickers

protocol TTTAttributedCellDelegate: class {
    func pushedMoreButton(_ cell: CommentDepthCell)
    func pushedSingleTap(_ cell: CommentDepthCell)
    func showCommentMenu(_ cell: CommentDepthCell)
    func hideCommentMenu(_ cell: CommentDepthCell)
    var menuShown: Bool { get set }
    var menuId: String { get set }
}

class CommentMenuCell: UITableViewCell {
    var upvote = UIButton()
    var downvote = UIButton()
    var reply = UIButton()
    var more = UIButton()
    var edit = UIButton()
    var delete = UIButton()
    var mod = UIButton()

    var editShown = false
    var archived = false
    var modShown = false

    var comment: RComment?
    var commentView: CommentDepthCell?
    var parent: CommentViewController?

    func setComment(comment: RComment, cell: CommentDepthCell, parent: CommentViewController) {
        self.comment = comment
        self.parent = parent
        self.commentView = cell
        editShown = AccountController.isLoggedIn && comment.author == AccountController.currentName
        modShown = comment.canMod
        archived = comment.archived
        self.contentView.backgroundColor = ColorUtil.getColorForSub(sub: comment.subreddit)
        updateConstraints()
    }

    func edit(_ s: AnyObject) {
        self.parent!.editComment()
    }

    func doDelete(_ s: AnyObject) {
        self.parent!.deleteComment(cell: commentView!)
    }

    func showModMenu(_ s: AnyObject) {
        parent!.modMenu(commentView!)

    }

    func upvote(_ s: AnyObject) {
        parent!.vote(comment: comment!, dir: .up)
        commentView!.refresh(comment: comment!, submissionAuthor: (parent!.submission?.author)!, text: commentView!.cellContent!)
        parent!.hideCommentMenu(commentView!)
    }

    func downvote(_ s: AnyObject) {
        parent!.vote(comment: comment!, dir: .down)
        commentView!.refresh(comment: comment!, submissionAuthor: (parent!.submission?.author)!, text: commentView!.cellContent!)
        parent!.hideCommentMenu(commentView!)
    }

    func more(_ s: AnyObject) {
        parent!.moreComment(commentView!)
    }

    func reply(_ s: AnyObject) {
        self.parent!.doReply(commentView!)
    }

    var sideConstraint: [NSLayoutConstraint] = []

    override func updateConstraints() {
        super.updateConstraints()
        var width = min(375, UIScreen.main.bounds.size.width)
        width = width / ((archived || !AccountController.isLoggedIn) ? 1 : (editShown ? (modShown ? 7 : 6) : (modShown ? 5 : 4)))

        

        if (editShown) {
            edit.isHidden = false
            delete.isHidden = false
        } else {
            edit.isHidden = true
            delete.isHidden = true
        }

        if (archived || !AccountController.isLoggedIn) {
            edit.isHidden = true
            delete.isHidden = true
            upvote.isHidden = true
            downvote.isHidden = true
            reply.isHidden = true
        }
        
        if (comment != nil){
            if(modShown){
                mod.isHidden = false
                if(!comment!.reports.isEmpty){
                    mod.setImage(UIImage.init(named: "mod")?.getCopy(withSize: .square(size: 20), withColor: GMColor.red500Color()), for: .normal)
                } else {
                    mod.setImage(UIImage.init(named: "mod")?.getCopy(withSize: .square(size: 20), withColor: .white), for: .normal)
                }
            } else {
                mod.isHidden = true
            }

            switch(ActionStates.getVoteDirection(s: comment!)){
            case .down:
                downvote.setImage(UIImage.init(named: "downvote")?.getCopy(withSize: .square(size: 20), withColor: ColorUtil.downvoteColor), for: .normal)
                upvote.setImage(UIImage.init(named: "upvote")?.getCopy(withSize: .square(size: 20), withColor: .white), for: .normal)
            case .up:
                upvote.setImage(UIImage.init(named: "upvote")?.getCopy(withSize: .square(size: 20), withColor: ColorUtil.upvoteColor), for: .normal)
                downvote.setImage(UIImage.init(named: "downvote")?.getCopy(withSize: .square(size: 20), withColor: .white), for: .normal)
            case .none:
                upvote.setImage(UIImage.init(named: "upvote")?.getCopy(withSize: .square(size: 20), withColor: .white), for: .normal)
                downvote.setImage(UIImage.init(named: "downvote")?.getCopy(withSize: .square(size: 20), withColor: .white), for: .normal)
            }
        }

        let metrics: [String: Int] = ["width": Int(width), "full": Int(self.contentView.frame.size.width)]
        let views = ["upvote": upvote, "downvote": downvote, "edit": edit, "delete": delete, "mod": mod, "view": contentView, "more": more, "reply": reply] as [String: Any]

        let replyStuff = !archived && AccountController.isLoggedIn ? "[upvote(width)]-0-[downvote(width)]-0-[reply(width)]-0-" : ""
        let editStuff = (!archived && editShown) ? "[edit(width)]-0-[delete(width)]-0-" : ""
        let modStuff = (modShown) ? "[mod(width)]-0-" : ""

        self.contentView.removeConstraints(sideConstraint)
        sideConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:\(editStuff)\(replyStuff)[more(width)]-0-\(modStuff)|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views)
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[more(45)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[edit(45)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[mod(45)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))

        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[delete(45)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[reply(45)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[downvote(45)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[upvote(45)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))
        sideConstraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:[view(45)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: views))

        self.contentView.addConstraints(sideConstraint)
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.upvote = UIButton.init(type: .custom)
        self.downvote = UIButton.init(type: .custom)
        self.reply = UIButton.init(type: .custom)
        self.more = UIButton.init(type: .custom)
        self.edit = UIButton.init(type: .custom)
        self.delete = UIButton.init(type: .custom)
        self.mod = UIButton.init(type: .custom)

        upvote.setImage(UIImage.init(named: "upvote")?.navIcon(), for: .normal)
        downvote.setImage(UIImage.init(named: "downvote")?.navIcon(), for: .normal)
        reply.setImage(UIImage.init(named: "reply")?.navIcon(), for: .normal)
        more.setImage(UIImage.init(named: "ic_more_vert_white")?.navIcon(), for: .normal)
        edit.setImage(UIImage.init(named: "edit")?.navIcon(), for: .normal)
        delete.setImage(UIImage.init(named: "delete")?.navIcon(), for: .normal)
        mod.setImage(UIImage.init(named: "mod")?.navIcon(), for: .normal)

        upvote.translatesAutoresizingMaskIntoConstraints = false
        downvote.translatesAutoresizingMaskIntoConstraints = false
        more.translatesAutoresizingMaskIntoConstraints = false
        reply.translatesAutoresizingMaskIntoConstraints = false
        edit.translatesAutoresizingMaskIntoConstraints = false
        delete.translatesAutoresizingMaskIntoConstraints = false
        mod.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(upvote)
        self.contentView.addSubview(more)
        self.contentView.addSubview(downvote)
        self.contentView.addSubview(reply)
        self.contentView.addSubview(edit)
        self.contentView.addSubview(delete)
        self.contentView.addSubview(mod)

        upvote.addTarget(self, action: #selector(CommentMenuCell.upvote(_:)), for: UIControlEvents.touchUpInside)
        downvote.addTarget(self, action: #selector(CommentMenuCell.downvote(_:)), for: UIControlEvents.touchUpInside)
        more.addTarget(self, action: #selector(CommentMenuCell.more(_:)), for: UIControlEvents.touchUpInside)
        reply.addTarget(self, action: #selector(CommentMenuCell.reply(_:)), for: UIControlEvents.touchUpInside)
        edit.addTarget(self, action: #selector(CommentMenuCell.edit(_:)), for: UIControlEvents.touchUpInside)
        delete.addTarget(self, action: #selector(CommentMenuCell.doDelete(_:)), for: UIControlEvents.touchUpInside)
        mod.addTarget(self, action: #selector(CommentMenuCell.showModMenu(_:)), for: UIControlEvents.touchUpInside)

        updateConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CommentDepthCell: MarginedTableViewCell, TTTAttributedLabelDelegate, UIViewControllerPreviewingDelegate {
    var moreButton: UIButton = UIButton()
    var sideView: UIView = UIView()
    var sideViewSpace: UIView = UIView()
    var topViewSpace: UIView = UIView()
    var title: TTTAttributedLabel = TTTAttributedLabel.init(frame: CGRect.zero)
    var c: UIView = UIView()
    var children: UILabel = UILabel()
    var comment: RComment?
    var depth: Int = 0

    func attributedLabel(_ label: TTTAttributedLabel!, didLongPressLinkWith url: URL!, at point: CGPoint) {
        if parent != nil {
            let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
            sheet.addAction(
                    UIAlertAction(title: "Close", style: .cancel) { (action) in
                        sheet.dismiss(animated: true, completion: nil)
                    }
            )
            let open = OpenInChromeController.init()
            if (open.isChromeInstalled()) {
                sheet.addAction(
                        UIAlertAction(title: "Open in Chrome", style: .default) { (action) in
                            _ = open.openInChrome(url, callbackURL: nil, createNewTab: true)
                        }
                )
            }
            sheet.addAction(
                    UIAlertAction(title: "Open in Safari", style: .default) { (action) in
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                        sheet.dismiss(animated: true, completion: nil)
                    }
            )
            sheet.addAction(
                    UIAlertAction(title: "Open", style: .default) { (action) in
                        /* let controller = WebViewController(nibName: nil, bundle: nil)
                         controller.url = url
                         let nav = UINavigationController(rootViewController: controller)
                         self.present(nav, animated: true, completion: nil)*/
                    }
            )
            sheet.addAction(
                    UIAlertAction(title: "Copy URL", style: .default) { (action) in
                        UIPasteboard.general.setValue(url, forPasteboardType: "public.url")
                        sheet.dismiss(animated: true, completion: nil)
                    }
            )
            sheet.modalPresentationStyle = .popover
            if let presenter = sheet.popoverPresentationController {
                presenter.sourceView = label
                presenter.sourceRect = label.bounds
            }

            parent?.present(sheet, animated: true, completion: nil)
        }
    }

    var parent: CommentViewController?

    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith result: NSTextCheckingResult!) {
        var textClicked = label.attributedText.attributedSubstring(from: result.range).string
        if (textClicked.contains("[[s[")) {
            parent?.showSpoiler(textClicked)
        } else {
            var urlClicked = result.url!
            parent?.doShow(url: urlClicked)
        }
    }

    func upvote() {
        parent!.vote(comment: comment!, dir: .up)
        self.refresh(comment: comment!, submissionAuthor: (parent!.submission?.author)!, text: self.cellContent!)
    }
    
    func downvote() {
        parent!.vote(comment: comment!, dir: .down)
        self.refresh(comment: comment!, submissionAuthor: (parent!.submission?.author)!, text: self.cellContent!)
    }

    func save() {
        parent!.saveComment(self.comment!)
    }

    func menu() {
        more(parent!)
    }

    var delegate: TTTAttributedCellDelegate? = nil
    var content: Object? = nil

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = ColorUtil.backgroundColor

        self.title = TTTAttributedLabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        title.numberOfLines = 0
        title.font = FontGenerator.fontOfSize(size: 16, submission: false)
        title.isUserInteractionEnabled = true
        title.delegate = self
        title.textColor = ColorUtil.fontColor

        self.children = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 15))
        children.numberOfLines = 1
        children.font = FontGenerator.boldFontOfSize(size: 12, submission: false)
        children.textColor = UIColor.white
        children.layer.shadowOffset = CGSize(width: 0, height: 0)
        children.layer.shadowOpacity = 0.4
        children.layer.shadowRadius = 4
        let padding = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)


        self.moreButton = UIButton(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))

        self.sideView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        self.sideViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        self.topViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 4))

        self.c = children.withPadding(padding: padding)
        c.alpha = 0
        c.backgroundColor = ColorUtil.accentColorForSub(sub: "")
        c.layer.cornerRadius = 4
        c.clipsToBounds = true

        moreButton.translatesAutoresizingMaskIntoConstraints = false
        sideView.translatesAutoresizingMaskIntoConstraints = false
        sideViewSpace.translatesAutoresizingMaskIntoConstraints = false
        topViewSpace.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        children.translatesAutoresizingMaskIntoConstraints = false
        c.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(moreButton)
        self.contentView.addSubview(sideView)
        self.contentView.addSubview(sideViewSpace)
        self.contentView.addSubview(topViewSpace)
        self.contentView.addSubview(title)
        self.contentView.addSubview(c)

        if(dtap == nil && SettingValues.commentActionDoubleTap != .NONE){
            dtap = UIShortTapGestureRecognizer.init(target: self, action: #selector(self.doDTap(_:)))
            dtap!.numberOfTapsRequired = 2
            self.contentView.addGestureRecognizer(dtap!)
        }

        moreButton.addTarget(self, action: #selector(CommentDepthCell.pushedMoreButton(_:)), for: UIControlEvents.touchUpInside)

        let tapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(self.handleShortPress(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        if(dtap != nil){
            tapGestureRecognizer.require(toFail: dtap!)
        }
        self.title.addGestureRecognizer(tapGestureRecognizer)

        long = UILongPressGestureRecognizer.init(target: self, action: #selector(self.handleLongPress(_:)))
        long.minimumPressDuration = 0.25
        long.delegate = self
        self.addGestureRecognizer(long)

        self.contentView.backgroundColor = ColorUtil.foregroundColor
        sideViewSpace.backgroundColor = ColorUtil.backgroundColor
        topViewSpace.backgroundColor = ColorUtil.backgroundColor

        self.clipsToBounds = true
    }

    func doLongClick() {
        timer!.invalidate()
        AudioServicesPlaySystemSound(1519)
        if (!self.cancelled) {
            if (SettingValues.swapLongPress) {
                if (self.delegate!.menuShown) { //todo check if comment id is the same as this comment id
                    self.showMenu(nil)
                } else {
                    self.pushedSingleTap(nil)
                }
            } else {
                self.showMenu(nil)
            }
        }
    }

    var timer: Timer?
    var cancelled = false

    func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.began) {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.25,
                    target: self,
                    selector: #selector(self.doLongClick),
                    userInfo: nil,
                    repeats: false)
        }
        if (sender.state == UIGestureRecognizerState.ended) {
            timer!.invalidate()
            cancelled = true
        }
    }

    func handleShortPress(_ sender: UIGestureRecognizer) {
        if (SettingValues.swapLongPress || (self.delegate!.menuShown && delegate!.menuId == (content as! RComment).getId())) {
            self.showMenu(sender)
        } else {
            self.pushedSingleTap(sender)
        }
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (gestureRecognizer.view == self.title) {
            return self.title.link(at: touch.location(in: self.title)) == nil
        }
        return true
    }

    var long = UILongPressGestureRecognizer.init(target: self, action: nil)

    func showMenu(_ sender: AnyObject?) {
        if let del = self.delegate {
            if (del.menuShown && del.menuId == (content as! RComment).getId()) {
                del.hideCommentMenu(self)
            } else {
                del.showCommentMenu(self)
            }
        }
    }

    func vote() {
        if (content is RComment) {
            let current = ActionStates.getVoteDirection(s: comment!)
            let dir = (current == VoteDirection.none) ? VoteDirection.up : VoteDirection.none
            var direction = dir
            switch (ActionStates.getVoteDirection(s: comment!)) {
            case .up:
                if (dir == .up) {
                    direction = .none
                }
                break
            case .down:
                if (dir == .down) {
                    direction = .none
                }
                break
            default:
                break
            }
            do {
                try parent?.session?.setVote(direction, name: (comment!.name), completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                    case .success(_): break
                    }
                })
            } catch {
                print(error)
            }
            ActionStates.setVoteDirection(s: comment!, direction: direction)
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modApprove() {
        if (content is RComment) {
            do {
                try parent?.session?.approve(comment!.id, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Approving comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    case .success(_):
                        self.parent!.approved.append(self.comment!.id)
                        if(self.parent!.removed.contains(self.comment!.id)){
                            self.parent!.removed.remove(at: self.parent!.removed.index(of: self.comment!.id)!)
                        }
                        DispatchQueue.main.async {
                            self.parent!.tableView.reloadData()
                            BannerUtil.makeBanner(text: "Comment approved!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func modDistinguish() {
        if (content is RComment) {
            do {
                try parent?.session?.distinguish(comment!.id, how: "yes", completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Distinguishing comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    case .success(_):
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Comment distinguished!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modSticky(sticky: Bool) {
        if (content is RComment) {
            do {
                try parent?.session?.distinguish(comment!.id, how: "yes", sticky: sticky, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Couldn't \(sticky ? "" : "un-")pin comment!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    case .success(_):
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Comment \(sticky ? "" : "un-")pinned!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func modRemove(_ spam: Bool = false) {
        if (content is RComment) {
            do {
                try parent?.session?.remove(comment!.id, spam: spam, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Removing comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    case .success(_):
                        self.parent!.removed.append(self.comment!.id)
                        if(self.parent!.approved.contains(self.comment!.id)){
                            self.parent!.approved.remove(at: self.parent!.approved.index(of: self.comment!.id)!)
                        }
                        DispatchQueue.main.async {
                            self.parent!.tableView.reloadData()
                            BannerUtil.makeBanner(text: "Comment removed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                }
            })
            
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modBan(why: String, duration: Int?) {
        if (content is RComment) {
            do {
                try parent?.session?.ban(comment!.author, banReason: why, duration: duration == nil ? 999 /*forever*/ : duration!, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Banning user failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    case .success(_):
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "u/\(self.comment!.author) banned!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit) ,seconds: 3, context: self.parent!)
                        }
                        break
                    }

                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }


    func more(_ par: CommentViewController) {

        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Comment by u/\(comment!.author)"


        alertController.addAction(Action(ActionData(title: "\(AccountController.formatUsernamePosessive(input: comment!.author, small: false)) profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in

            let prof = ProfileViewController.init(name: self.comment!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: nil, parentViewController: par);
        }))
        alertController.addAction(Action(ActionData(title: "Share comment permalink", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { action in
            let activityViewController = UIActivityViewController(activityItems: [self.comment!.permalink], applicationActivities: nil)
            par.present(activityViewController, animated: true, completion: {})
        }))
        if (AccountController.isLoggedIn) {
            alertController.addAction(Action(ActionData(title: "Save", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { action in
                par.saveComment(self.comment!)
            }))
        }
        alertController.addAction(Action(ActionData(title: "Report", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
            PostActions.report(self.comment!, parent: par)
        }))
        
        alertController.addAction(Action(ActionData(title: "Tag user", image: UIImage(named: "subs")!.menuIcon()), style: .default, handler: { action in
            par.tagUser(name: self.comment!.author)
        }))

        alertController.addAction(Action(ActionData(title: "Copy text", image: UIImage(named: "copy")!.menuIcon()), style: .default, handler: { action in
            let alert = UIAlertController.init(title: "Copy text", message: "", preferredStyle: .alert)
            alert.addTextViewer(text: .text(self.comment!.body))
            alert.addAction(UIAlertAction.init(title: "Copy all", style: .default, handler: { (action) in
                UIPasteboard.general.string = self.comment!.body
            }))
            alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: { (action) in
                
            }))
            par.present(alert, animated: true)
        }))

        VCPresenter.presentAlert(alertController, parentVC: par.parent!)
    }

    func mod(_ par: CommentViewController) {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Comment by u/\(comment!.author)"


        alertController.addAction(Action(ActionData(title: "\(comment!.reports.count) reports", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { action in
            var reports = ""
            for report in self.comment!.reports {
                reports = reports + report + "\n"
            }
            let alert = UIAlertController(title: "Reports",
                                          message: reports,
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            self.parent?.present(alert, animated: true, completion: nil)

        }))
        alertController.addAction(Action(ActionData(title: "Approve", image: UIImage(named: "approve")!.menuIcon()), style: .default, handler: { action in
            self.modApprove()
        }))

        alertController.addAction(Action(ActionData(title: "Ban user", image: UIImage(named: "ban")!.menuIcon()), style: .default, handler: { action in
            //todo show dialog for this
        }))
        
        if(comment!.author == AccountController.currentName){
            alertController.addAction(Action(ActionData(title: "Distinguish", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { action in
                self.modDistinguish()
            }))
        }

        if(comment!.author == AccountController.currentName && comment!.depth == 1){
            if(comment!.sticky){
                alertController.addAction(Action(ActionData(title: "Un-pin", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
                    self.modSticky(sticky: false)
                }))
            } else {
                alertController.addAction(Action(ActionData(title: "Pin and distinguish", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
                    self.modSticky(sticky: true)
                }))
            }
        }

        alertController.addAction(Action(ActionData(title: "Remove", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { action in
            self.modRemove()
        }))

        alertController.addAction(Action(ActionData(title: "Mark as spam", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { action in
            self.modRemove(true)
        }))

        alertController.addAction(Action(ActionData(title: "User profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { action in
            let prof = ProfileViewController.init(name: self.comment!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: nil, parentViewController: par);
        }))

        VCPresenter.presentAlert(alertController, parentVC: par.parent!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sideConstraint: [NSLayoutConstraint]?

    func collapse(childNumber: Int) {
        if(childNumber != 0){
            children.text = "+\(childNumber)"
            UIView.animate(withDuration: 0.4, delay: 0.0, options:
                UIViewAnimationOptions.curveEaseOut, animations: {
                    self.c.alpha = 1
            }, completion: { finished in
            })
        }
        isCollapsed = true
        if (SettingValues.collapseFully) {
            refresh(comment: comment!, submissionAuthor: parent!.submission!.author, text: cellContent!)
        }
    }

    func expandSingle() {
        isCollapsed = false
        refresh(comment: comment!, submissionAuthor: parent!.submission!.author, text: cellContent!)
    }

    func expand() {
        UIView.animate(withDuration: 0.4, delay: 0.0, options:
        UIViewAnimationOptions.curveEaseOut, animations: {
            self.c.alpha = 0
        }, completion: { finished in
        })
        isCollapsed = false
        if (SettingValues.collapseFully) {
            refresh(comment: comment!, submissionAuthor: parent!.submission!.author, text: cellContent!)
        }
    }

    var oldDepth = 0

    func updateDepthConstraints() {
        if (sideConstraint != nil) {
            self.contentView.removeConstraints(sideConstraint!)
        }
        let metrics = ["marginTop": marginTop, "nmarginTop": -marginTop, "horizontalMargin": 75, "top": 0, "bottom": 0, "separationBetweenLabels": 0, "labelMinHeight": 75, "sidewidth": (SettingValues.wideIndicators ? 8 : 4) * (depth), "width": sideWidth]
        let views = ["title": title, "topviewspace": topViewSpace, "more": moreButton, "side": sideView, "cell": self.contentView, "sideviewspace": sideViewSpace] as [String: Any]

        
        if (!menuC.isEmpty) {
            self.contentView.removeConstraints(menuC)
        }
        menuC = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topviewspace(marginTop)]-8-[title]-8-|",
                                               options: NSLayoutFormatOptions(rawValue: 0),
                                               metrics: metrics,
                                               views: views)
        self.contentView.addConstraints(menuC)
        sideConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-8)-[sideviewspace(sidewidth)]-0-[side(width)]",
                                                        options: NSLayoutFormatOptions(rawValue: 0),
                                                        metrics: metrics,
                                                        views: views)



        sideConstraint!.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-8)-[sideviewspace(sidewidth)]-0-[side(width)]-12-[title]-4-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        self.contentView.addConstraints(sideConstraint!)

    }

    var menuC: [NSLayoutConstraint] = []

    func doHighlight() {
        oldDepth = depth
        if (depth == 1) {
            depth = 1
        } else {
            depth = 2
        }
        updateDepthConstraints()
        self.contentView.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.getColorForSub(sub: ((comment)!.subreddit)).withAlphaComponent(0.25))
    }

    func doUnHighlight() {
        depth = oldDepth
        updateDepthConstraints()
        self.contentView.backgroundColor = ColorUtil.foregroundColor
    }

    override func updateConstraints() {
        super.updateConstraints()

        let metrics = ["marginTop": marginTop, "nmarginTop": -marginTop, "horizontalMargin": 75, "top": 0, "bottom": 0, "separationBetweenLabels": 0, "labelMinHeight": 75, "sidewidth": (SettingValues.wideIndicators ? 8 : 4)  * (depth), "width": sideWidth]
        let views = ["title": title, "topviewspace": topViewSpace, "children": c, "more": moreButton, "side": sideView, "cell": self.contentView, "sideviewspace": sideViewSpace] as [String: Any]


        var constraint: [NSLayoutConstraint] = []

        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-(-8)-[sideviewspace]-0-[side]-12-[title]-4-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[topviewspace]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[more]",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-2-[more]-2-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))


        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-4-[children]",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:[children]-4-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))

        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topviewspace]-(nmarginTop)-[side]-(-1)-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))
        constraint.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[topviewspace]-(nmarginTop)-[sideviewspace]-0-|",
                options: NSLayoutFormatOptions(rawValue: 0),
                metrics: metrics,
                views: views))


        self.contentView.addConstraints(constraint)

        updateDepthConstraints()
    }

    var sideWidth: Int = 0
    var marginTop: Int = 0

    func setMore(more: RMore, depth: Int) {
        self.depth = depth
        self.comment = nil
        loading = false
        c.alpha = 0
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        if (depth - 1 > 0) {
            sideWidth = 3
            marginTop = 1
            let i22 = depth - 2;
            if (SettingValues.disableColor) {
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.grey100Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.grey200Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.grey300Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.grey400Color()
                } else {
                    sideView.backgroundColor = GMColor.grey500Color()
                }
            } else {
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.blue500Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.green500Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.yellow500Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.orange500Color()
                } else {
                    sideView.backgroundColor = GMColor.red500Color()
                }
            }
        } else {
            marginTop = 8
            sideWidth = 0
        }
        
        if(depth == 1){
            marginTop = 8
        }
        let font = FontGenerator.fontOfSize(size: 14, submission: false)

        var attr = NSMutableAttributedString()
        if (more.children.isEmpty) {
            attr = NSMutableAttributedString(string: "Continue this thread", attributes: [NSFontAttributeName: font])
        } else {
            attr = NSMutableAttributedString(string: "Load \(more.count) more", attributes: [NSFontAttributeName: font])
        }
        let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: .white)
        
        title.setText(attr2)
        updateDepthConstraints()
    }

    var numberOfDots = 3
    var loading = false

    func animateMore() {
        loading = true
        let attr = NSMutableAttributedString(string: "Loading...")
        let font = FontGenerator.fontOfSize(size: 16, submission: false)
        let attr2 = NSMutableAttributedString(attributedString: attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: UIColor.blue))


        title.setText(attr2)

        /* possibly todo var timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
         print("Firing")
         let range = NSMakeRange(attr2.length - self.numberOfDots, self.numberOfDots)
         attr2.addAttribute(NSForegroundColorAttributeName, value: UIColor.clear, range: range)
         
         self.textView.attributedString = attr2
         self.numberOfDots -= 1
         if self.numberOfDots < 0 {
         self.numberOfDots = 3
         }
         if(self.loading == false){
         timer.invalidate()
         }
         }*/
    }

    public var isCollapsed = false
    var dtap : UIShortTapGestureRecognizer?

    func setComment(comment: RComment, depth: Int, parent: CommentViewController, hiddenCount: Int, date: Double, author: String?, text: NSAttributedString, isCollapsed: Bool, parentOP: String) {
        self.comment = comment
        self.cellContent = text
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        loading = false
        if (self.parent == nil) {
            self.parent = parent
        }

        self.isCollapsed = isCollapsed

        if (date != 0 && date < Double(comment.created.timeIntervalSince1970)) {
            setIsNew(sub: comment.subreddit)
        }
        
        if (hiddenCount > 0) {
            c.alpha = 1
            children.text = "+\(hiddenCount)"
        } else {
            c.alpha = 0
        }

        self.depth = depth
        if (depth - 1 > 0) {
            sideWidth = SettingValues.wideIndicators ? 8 : 4 
            marginTop = 1
            let i22 = depth - 2;
            if (SettingValues.disableColor) {
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.grey100Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.grey200Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.grey300Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.grey400Color()
                } else {
                    sideView.backgroundColor = GMColor.grey500Color()
                }
            } else {
                if (i22 % 5 == 0) {
                    sideView.backgroundColor = GMColor.blue500Color()
                } else if (i22 % 4 == 0) {
                    sideView.backgroundColor = GMColor.green500Color()
                } else if (i22 % 3 == 0) {
                    sideView.backgroundColor = GMColor.yellow500Color()
                } else if (i22 % 2 == 0) {
                    sideView.backgroundColor = GMColor.orange500Color()
                } else {
                    sideView.backgroundColor = GMColor.red500Color()
                }
            }
            if (SettingValues.highlightOp && parentOP == comment.author) {
                sideView.backgroundColor = GMColor.purple500Color()
            }
        } else {
            marginTop = 8
            sideWidth = 0
        }
        
        if(depth == 1){
            marginTop = 8
        }

        refresh(comment: comment, submissionAuthor: author, text: text)

        if (!registered) {
            parent.registerForPreviewing(with: self, sourceView: title)
            registered = true
        }
        updateDepthConstraints()
    }
    
    func doDTap(_ sender: AnyObject){
        switch(SettingValues.commentActionDoubleTap){
        case .UPVOTE:
            self.upvote()
            break
        case .DOWNVOTE:
            self.downvote()
            break
        case .SAVE:
            self.save()
            break
        case .MENU:
            self.menu()
            break
        default:
            break
        }
    }

    var cellContent: NSAttributedString?

    var savedAuthor: String = ""

    func refresh(comment: RComment, submissionAuthor: String?, text: NSAttributedString) {
        var color: UIColor

        savedAuthor = submissionAuthor!

        switch (ActionStates.getVoteDirection(s: comment)) {
        case .down:
            color = ColorUtil.downvoteColor
            break
        case .up:
            color = ColorUtil.upvoteColor
            break
        default:
            color = ColorUtil.fontColor
            break
        }

        let scoreString = NSMutableAttributedString(string: ((comment.scoreHidden ? "[score hidden]" : "\(getScoreText(comment: comment))") + (comment.controversiality > 0 ? "†" : "")), attributes: [NSForegroundColorAttributeName: color])

        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: comment.created, numericDates: true))" + (comment.isEdited ? ("(edit \(DateFormatter().timeSince(from: comment.edited, numericDates: true)))") : ""), attributes: [NSForegroundColorAttributeName: ColorUtil.fontColor])


        let authorString = NSMutableAttributedString(string: "\u{00A0}\(AccountController.formatUsername(input: comment.author, small: true))\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])
        let authorStringNoFlair = NSMutableAttributedString(string: "\(AccountController.formatUsername(input: comment.author, small: true))\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])

        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(comment.flair)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(comment.gilded) ", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false)])

        let spacer = NSMutableAttributedString.init(string: "  ")
        let userColor = ColorUtil.getColorForUser(name: comment.author)
        var authorSmall = false
        if (comment.distinguished == "admin") {
          authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#E57373"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (comment.distinguished == "special") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#F44336"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (comment.distinguished == "moderator") {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#81C784"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (AccountController.currentName == comment.author) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (submissionAuthor != nil && comment.author == submissionAuthor) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#64B5F6"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else if (userColor != ColorUtil.baseColor) {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: userColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: authorString.length))
        } else {
            authorSmall = true
        }

        let infoString = NSMutableAttributedString(string: "")
        if(authorSmall){
            infoString.append(authorStringNoFlair)
        } else {
            infoString.append(authorString)
        }

        let tag = ColorUtil.getTagForUser(name: comment.author)
        if (!tag.isEmpty) {
            let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])
            tagString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: tagString.length))
            infoString.append(spacer)
            infoString.append(tagString)
        }

        infoString.append(NSAttributedString(string: "  •  ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor]))
        infoString.append(scoreString)
        infoString.append(endString)

        if (!comment.flair.isEmpty) {
            infoString.append(spacer)
            infoString.append(flairTitle)
        }

        if (comment.sticky) {
            infoString.append(spacer)
            infoString.append(pinned)
        }
        if (comment.gilded > 0) {
            infoString.append(spacer)
            let gild = NSMutableAttributedString.init(string: "G", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
            infoString.append(gild)
            if (comment.gilded > 1) {
                infoString.append(gilded)
            }
        }
        
        if(parent!.removed.contains(comment.id) || (!comment.removedBy.isEmpty() && !parent!.approved.contains(comment.id))){
            let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: GMColor.red500Color()] as [String: Any]
            infoString.append(spacer)
            if(comment.removedBy == "true"){
                infoString.append(NSMutableAttributedString.init(string: "Removed by Reddit\(!comment.removalReason.isEmpty() ? ":\(comment.removalReason)" : "")", attributes: attrs))
            } else {
                infoString.append(NSMutableAttributedString.init(string: "Removed\(!comment.removedBy.isEmpty() ? " by \(comment.removedBy)":"")\(!comment.removalReason.isEmpty() ? " for \(comment.removalReason)" : "")\(!comment.removalNote.isEmpty() ? " \(comment.removalNote)" : "")", attributes: attrs))
            }
        } else if(parent!.approved.contains(comment.id) || (!comment.approvedBy.isEmpty() && !parent!.removed.contains(comment.id))){
            let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: GMColor.green500Color()] as [String: Any]
            infoString.append(spacer)
            infoString.append(NSMutableAttributedString.init(string: "Approved\(!comment.approvedBy.isEmpty() ? " by \(comment.approvedBy)":"")", attributes: attrs))
        }


        infoString.append(NSAttributedString.init(string: "\n\n", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 5)]))
        if (!isCollapsed || !SettingValues.collapseFully) {
            infoString.append(text)
        }

        if (!setLinkAttrs) {
            let activeLinkAttributes = NSMutableDictionary(dictionary: title.activeLinkAttributes)
            activeLinkAttributes[NSForegroundColorAttributeName] = ColorUtil.accentColorForSub(sub: comment.subreddit)
            title.linkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            title.activeLinkAttributes = activeLinkAttributes as NSDictionary as! [AnyHashable: Any]
            setLinkAttrs = true
        }
        title.attributedText = (infoString)

    }

    var setLinkAttrs = false

    func setIsContext() {
        self.contentView.backgroundColor = GMColor.yellow500Color().withAlphaComponent(0.5)
    }

    func setIsNew(sub: String) {
        self.contentView.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.getColorForSub(sub: sub).withAlphaComponent(0.25))
    }


    func getScoreText(comment: RComment) -> Int {
        var submissionScore = comment.score
        switch (ActionStates.getVoteDirection(s: comment)) {
        case .up:
            if (comment.likes != .up) {
                if (comment.likes == .down) {
                    submissionScore += 1
                }
                submissionScore += 1
            }
            break
        case .down:
            if (comment.likes != .down) {
                if (comment.likes == .up) {
                    submissionScore -= 1
                }
                submissionScore -= 1
            }
            break
        case .none:
            if (comment.likes == .up && comment.author == AccountController.currentName) {
                submissionScore -= 1
            }
        }
        return submissionScore
    }

    var registered: Bool = false

    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {

        let locationInTextView = title.convert(location, to: title)

        if let (url, rect) = getInfo(locationInTextView: locationInTextView) {
            previewingContext.sourceRect = title.convert(rect, from: title)
            if let controller = parent?.getControllerForUrl(baseUrl: url) {
                return controller
            }
        }

        return nil
    }

    func getInfo(locationInTextView: CGPoint) -> (URL, CGRect)? {
        if let attr = title.link(at: locationInTextView) {
            if let url = attr.result.url {
                return (url, title.bounds)
            }

        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        parent?.show(viewControllerToCommit, sender: parent)
    }

    func pushedMoreButton(_ sender: AnyObject?) {
        if let delegate = self.delegate {
            delegate.pushedMoreButton(self)
        }
    }

    func longPressed(_ sender: AnyObject?) {
        if self.delegate != nil {
        }
    }

    func pushedSingleTap(_ sender: AnyObject?) {
        if let delegate = self.delegate {
            delegate.pushedSingleTap(self)
        }
    }

    class func margin() -> UIEdgeInsets {
        return UIEdgeInsetsMake(4, 0, 2, 0)
    }
}

extension UIColor {
    func add(overlay: UIColor) -> UIColor {
        var bgR: CGFloat = 0
        var bgG: CGFloat = 0
        var bgB: CGFloat = 0
        var bgA: CGFloat = 0

        var fgR: CGFloat = 0
        var fgG: CGFloat = 0
        var fgB: CGFloat = 0
        var fgA: CGFloat = 0

        self.getRed(&bgR, green: &bgG, blue: &bgB, alpha: &bgA)
        overlay.getRed(&fgR, green: &fgG, blue: &fgB, alpha: &fgA)

        let r = fgA * fgR + (1 - fgA) * bgR
        let g = fgA * fgG + (1 - fgA) * bgG
        let b = fgA * fgB + (1 - fgA) * bgB

        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

//from https://stackoverflow.com/a/48847585/3697225
class UIShortTapGestureRecognizer: UITapGestureRecognizer {
    let tapMaxDelay: Double = 0.3 //anything below 0.3 may cause doubleTap to be inaccessible by many users
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + tapMaxDelay) { [weak self] in
            if self?.state != UIGestureRecognizerState.recognized {
                self?.state = UIGestureRecognizerState.failed
            }
        }
    }
}
