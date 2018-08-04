//
//  CommentDepthCell.swift
//  Slide for Reddit
//
//  Created by Carlos Crane on 12/31/16.
//  Copyright © 2016 Haptic Apps. All rights reserved.
//

import Anchorage
import AudioToolbox
import RealmSwift
import reddift
import RLBAlertsPickers
import TTTAttributedLabel
import UIKit
import XLActionController

protocol TTTAttributedCellDelegate: class {
    func pushedSingleTap(_ cell: CommentDepthCell)
    func isMenuShown() -> Bool
    func getMenuShown() -> String?
}

protocol ReplyDelegate {
    func replySent(comment: Comment?, cell: CommentDepthCell?)
    func updateHeight(textView: UITextView)
    func discard()
    func editSent(cr: Comment?, cell: CommentDepthCell)
}

class CommentDepthCell: MarginedTableViewCell, UIViewControllerPreviewingDelegate, UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        textView.sizeToFitHeight()
        parent!.reloadHeights()
    }
    
    var sideView: UIView!
    var menu: UIStackView!
    var menuBack: UIView!
    var reply: UIView!
    
    var sideViewSpace: UIView!
    var topViewSpace: UIView!
    var title : TextDisplayStackView!
    
    //Buttons for comment menu
    var upvoteButton: UIButton!
    var downvoteButton: UIButton!
    var replyButton: UIButton!
    var moreButton: UIButton!
    var editButton: UIButton!
    var deleteButton: UIButton!
    var modButton: UIButton!
    var editShown = false
    var archived = false
    var modShown = false
    
    //Buttons for reply
    var body: UITextView!
    var sendB: UIButton!
    var discardB: UIButton!
    var edit = false
    var toolbar: ToolbarTextView?

    var childrenCount: UIView!
    var childrenCountLabel: UILabel!
    var comment: RComment?
    var depth: Int = 0
    
    var delegate: TTTAttributedCellDelegate?
    var content: Object?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.backgroundColor = ColorUtil.backgroundColor
        self.title = TextDisplayStackView(fontSize: 16, submission: false, color: .blue, delegate: self, width: contentView.frame.size.width).then({
            $0.isUserInteractionEnabled = true
            $0.accessibilityIdentifier = "Comment body"
        })

        self.childrenCountLabel = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 15)).then({
            $0.numberOfLines = 1
            $0.font = FontGenerator.boldFontOfSize(size: 12, submission: false)
            $0.textColor = UIColor.white
            $0.layer.shadowOffset = CGSize(width: 0, height: 0)
            $0.layer.shadowOpacity = 0.4
            $0.layer.shadowRadius = 4
        })
        
        let padding = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)

        self.sideView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        self.sideViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: CGFloat.greatestFiniteMagnitude))
        self.topViewSpace = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 4))
        self.topViewSpace.accessibilityIdentifier = "Top view margin"

        self.childrenCount = childrenCountLabel.withPadding(padding: padding).then({
            $0.alpha = 0
            $0.backgroundColor = ColorUtil.accentColorForSub(sub: "")
            $0.layer.cornerRadius = 4
            $0.clipsToBounds = true
        })

        self.contentView.addSubviews(sideView, sideViewSpace, topViewSpace, title, childrenCount)
        
        if dtap == nil && SettingValues.commentActionDoubleTap != .NONE {
            dtap = UIShortTapGestureRecognizer.init(target: self, action: #selector(self.doDTap(_:)))
            dtap!.numberOfTapsRequired = 2
            self.contentView.addGestureRecognizer(dtap!)
        }

        let tapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(self.handleShortPress(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        if dtap != nil {
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
        
        self.menu = UIStackView().then {
            $0.accessibilityIdentifier = "Comment menu"
            $0.axis = .horizontal
            $0.alignment = .center
            $0.distribution = .fillEqually
            $0.isHidden = true
        }
        
        menuBack = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        menuBack.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        menu.addSubview(menuBack)

        self.contentView.addSubview(menu)
        
        self.reply = UIView().then {
            $0.accessibilityIdentifier = "Reply menu"
            $0.isHidden = true
        }
        
        self.body = UITextView.init(frame: CGRect.init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 60)).then({
            $0.isEditable = true
            $0.textColor = .white
            $0.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            $0.layer.masksToBounds = false
            $0.layer.cornerRadius = 10
            $0.font = UIFont.systemFont(ofSize: 16)
            $0.isScrollEnabled = false
        })
        sendB = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 60))
        discardB = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 60))
        
        self.sendB.setTitle("Send", for: .normal)
        self.discardB.setTitle("Discard", for: .normal)

        sendB.addTarget(self, action: #selector(self.send(_:)), for: UIControlEvents.touchUpInside)
        discardB.addTarget(self, action: #selector(self.discard(_:)), for: UIControlEvents.touchUpInside)

        self.reply.addSubviews(body, sendB, discardB)
        contentView.addSubview(reply)
        
        configureLayout()
    }

    func doLongClick() {
        timer!.invalidate()
        AudioServicesPlaySystemSound(1519)
        if !self.cancelled {
            if SettingValues.swapLongPress {
                //todo this is probably wrong
                if comment != nil && self.delegate!.isMenuShown() && self.delegate!.getMenuShown() != comment!.getIdentifier() {
                    self.showMenu(nil)
                } else {
                    self.pushedSingleTap(nil)
                }
            } else {
                if comment != nil {
                    self.showMenu(nil)
                } else {
                    self.pushedSingleTap(nil)
                }
            }
        }
    }

    var timer: Timer?
    var cancelled = false

    func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            cancelled = false
            timer = Timer.scheduledTimer(timeInterval: 0.25,
                    target: self,
                    selector: #selector(self.doLongClick),
                    userInfo: nil,
                    repeats: false)
        }
        if sender.state == UIGestureRecognizerState.ended {
            timer!.invalidate()
            cancelled = true
        }
    }

    func handleShortPress(_ sender: UIGestureRecognizer) {
        if SettingValues.swapLongPress || (self.delegate!.isMenuShown() && delegate!.getMenuShown() == (content as! RComment).getId()) {
            self.showMenu(sender)
        } else {
            self.pushedSingleTap(sender)
        }
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.view == self.title {
            let link = self.title.link(at: touch.location(in: self.title), withTouch: touch)
            return link == nil
        }
        return true
    }

    var long = UILongPressGestureRecognizer.init(target: self, action: nil)

    func showMenu(_ sender: AnyObject?) {
        if let del = self.delegate {
            if del.isMenuShown() && del.getMenuShown() == (content as! RComment).getId() {
                hideMenuAnimated()
            } else {
                showMenuAnimated()
            }
        }
    }
    
    func hideMenuAnimated() {
        parent!.menuCell = nil
        parent!.menuId = nil
        self.hideCommentMenu()
        parent!.reloadHeights()
    }
    
    func showMenuAnimated() {
        if parent!.menuCell != nil {
            parent!.menuCell!.hideCommentMenu()
            parent!.reloadHeights()
        }
        self.showCommentMenu()
        parent!.menuId = comment!.getIdentifier()
        parent!.reloadHeights()
    }
    
    func showCommentMenu() {
        upvoteButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "upvote")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.upvote(_:)), for: UIControlEvents.touchUpInside)
        })
        downvoteButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "downvote")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.downvote(_:)), for: UIControlEvents.touchUpInside)
        })
        replyButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "reply")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.reply(_:)), for: UIControlEvents.touchUpInside)
        })
        moreButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "ic_more_vert_white")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.menu(_:)), for: UIControlEvents.touchUpInside)
        })
        editButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "edit")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.edit(_:)), for: UIControlEvents.touchUpInside)
        })
        deleteButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "delete")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.doDelete(_:)), for: UIControlEvents.touchUpInside)
        })
        modButton = UIButton.init(type: .custom).then({
            $0.setImage(UIImage.init(named: "mod")?.navIcon(), for: .normal)
            $0.addTarget(self, action: #selector(self.showModMenu(_:)), for: UIControlEvents.touchUpInside)
        })
        
        let removedSubviews = menu.arrangedSubviews.reduce([]) { (allSubviews, subview) -> [UIView] in
            menu.removeArrangedSubview(subview)
            return allSubviews + [subview]
        }
        
        NSLayoutConstraint.deactivate(removedSubviews.flatMap({ $0.constraints }))
        
        removedSubviews.forEach({ $0.removeFromSuperview() })
        
        if UIDevice.current.userInterfaceIdiom == .pad && !UIApplication.shared.isSplitOrSlideOver {
            menu.addArrangedSubviews(flexSpace(), flexSpace(), flexSpace(), editButton, deleteButton, upvoteButton, downvoteButton, replyButton, moreButton, modButton)
        } else {
            menu.addArrangedSubviews(editButton, deleteButton, upvoteButton, downvoteButton, replyButton, moreButton, modButton)
        }
        if !AccountController.isLoggedIn || comment!.archived || parent!.np {
            upvoteButton.isHidden = true
            downvoteButton.isHidden = true
            replyButton.isHidden = true
        }
        if !comment!.canMod {
            modButton.isHidden = true
        }
        if comment!.author != AccountController.currentName {
            editButton.isHidden = true
            deleteButton.isHidden = true
        }
        parent!.menuCell = self
        menu.isHidden = false
        reply.isHidden = true
        if depth == 1 {
            depth = 1
        } else {
            depth = 2
        }
        NSLayoutConstraint.deactivate(menuHeight)
        menuHeight = batch {
            menu.heightAnchor == CGFloat(45)
            menu.horizontalAnchors == contentView.horizontalAnchors
            menu.bottomAnchor == contentView.bottomAnchor
            title.bottomAnchor == menu.topAnchor - CGFloat(8)
            menu.topAnchor == title.bottomAnchor + CGFloat(8)
            body.heightAnchor == CGFloat(0)
            reply.heightAnchor == CGFloat(0)
        }
        updateDepth()
        self.contentView.backgroundColor = ColorUtil.foregroundColor.add(overlay: ColorUtil.getColorForSub(sub: ((comment)!.subreddit)).withAlphaComponent(0.25))
        menuBack.backgroundColor = ColorUtil.getColorForSub(sub: comment!.subreddit)
    }
    
    func hideCommentMenu() {
        depth = oldDepth
        menu.isHidden = true
        reply.isHidden = true
        NSLayoutConstraint.deactivate(menuHeight)
        menuHeight = batch {
            title.bottomAnchor == contentView.bottomAnchor - CGFloat(8)
            menu.heightAnchor == CGFloat(0)
            body.heightAnchor == CGFloat(0)
            reply.heightAnchor == CGFloat(0)
        }
        updateDepth()
        self.contentView.backgroundColor = ColorUtil.foregroundColor
    }

    var parent: CommentViewController?
    
    func upvote(_ s: AnyObject) {
        parent!.vote(comment: comment!, dir: .up)
        self.refresh(comment: comment!, submissionAuthor: (parent!.submission?.author)!, text: self.cellContent!)
        self.hideMenuAnimated()
    }
    
    func discard(_ sender: AnyObject) {
        self.endEditing(true)
        replyDelegate!.discard()
        showCommentMenu()
        parent!.reloadHeights()
    }
    
    var alertController: UIAlertController?
    
    func getCommentEdited(_ name: String) {
        let session = (UIApplication.shared.delegate as! AppDelegate).session
        do {
            try session?.getInfo([name], completion: { (res) in
                switch res {
                case .failure:
                    DispatchQueue.main.async {
                        self.toolbar?.saveDraft(self)
                        self.alertController?.dismiss(animated: false, completion: {
                            let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been edited (but has been saved as a draft), please try again", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self.parent!.present(alert, animated: true, completion: nil)
                        })
                        self.replyDelegate!.editSent(cr: nil, cell: self)
                    }
                case .success(let listing):
                    if listing.children.count == 1 {
                        if let comment = listing.children[0] as? Comment {
                            DispatchQueue.main.async {
                                self.alertController?.dismiss(animated: false, completion: {
                                    self.parent!.dismiss(animated: true, completion: nil)
                                })
                                self.replyDelegate!.editSent(cr: comment, cell: self)
                            }
                        }
                    }
                }
                
            })
        } catch {
            DispatchQueue.main.async {
                self.toolbar?.saveDraft(self)
                self.alertController?.dismiss(animated: false, completion: {
                    let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your message has not been edited (but has been saved as a draft), please try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.parent!.present(alert, animated: true, completion: nil)
                })
                self.replyDelegate!.editSent(cr: nil, cell: self)
            }
        }
    }
    
    func doEdit(_ sender: AnyObject) {
        alertController = UIAlertController(title: nil, message: "Editing comment...\n\n", preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()
        
        alertController?.view.addSubview(spinnerIndicator)
        parent!.present(alertController!, animated: true, completion: nil)
        
        let session = (UIApplication.shared.delegate as! AppDelegate).session
        
        do {
            let name = comment!.getIdentifier()
            try session?.editCommentOrLink(name, newBody: body.text!, completion: { (_) in
                self.getCommentEdited(name)
            })
        } catch {
            print((error as NSError).description)
        }
    }
    
    func send(_ sender: AnyObject) {
        self.endEditing(true)
        
        if edit {
            doEdit(sender)
            return
        }
        
        let session = (UIApplication.shared.delegate as! AppDelegate).session
        alertController = UIAlertController(title: nil, message: "Sending reply...\n\n", preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135.0, y: 65.5)
        spinnerIndicator.color = UIColor.black
        spinnerIndicator.startAnimating()
        
        alertController?.view.addSubview(spinnerIndicator)
        parent!.present(alertController!, animated: true, completion: nil)
        
        do {
            let name = comment!.getIdentifier()
            try session?.postComment(body.text!, parentName: name, completion: { (result) -> Void in
                switch result {
                case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        self.toolbar?.saveDraft(self)
                        self.alertController?.dismiss(animated: false, completion: {
                            let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your comment has not been sent (but has been saved as a draft), please try again.\n\nError: \(error.localizedDescription)", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                            self.parent!.present(alert, animated: true, completion: nil)
                        })
                        self.replyDelegate!.replySent(comment: nil, cell: self)
                    }
                case .success(let postedComment):
                    DispatchQueue.main.async {
                        self.alertController?.dismiss(animated: false, completion: {
                            self.parent!.dismiss(animated: true, completion: nil)
                        })
                        self.replyDelegate!.replySent(comment: postedComment, cell: self)
                    }
                }
            })
        } catch {
            DispatchQueue.main.async {
                self.toolbar?.saveDraft(self)
                self.alertController?.dismiss(animated: false, completion: {
                    let alert = UIAlertController(title: "Uh oh, something went wrong", message: "Your comment has not been sent (but has been saved as a draft), please try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    self.parent!.present(alert, animated: true, completion: nil)
                })
                self.replyDelegate!.replySent(comment: nil, cell: self)
            }
        }
    }

    func edit(_ sender: AnyObject) {
        edit = true
        self.reply(sender)
    }
    
    var replyDelegate: ReplyDelegate?
    func reply(_ s: AnyObject) {
        menu.isHidden = true
        reply.isHidden = false
        NSLayoutConstraint.deactivate(menuHeight)
        menuHeight = batch {
            title.bottomAnchor == reply.topAnchor - CGFloat(8)
            reply.topAnchor == title.bottomAnchor + CGFloat(8)
            reply.bottomAnchor == contentView.bottomAnchor
            reply.horizontalAnchors == contentView.horizontalAnchors
            body.horizontalAnchors == reply.horizontalAnchors + CGFloat(8)
            body.topAnchor == reply.topAnchor + CGFloat(8)
            discardB.leftAnchor == reply.leftAnchor + CGFloat(8)
            sendB.rightAnchor == reply.rightAnchor - CGFloat(8)
            discardB.topAnchor == body.bottomAnchor + CGFloat(8)
            sendB.topAnchor == body.bottomAnchor + CGFloat(8)
            discardB.bottomAnchor == reply.bottomAnchor - CGFloat(8)
            sendB.bottomAnchor == reply.bottomAnchor - CGFloat(8)
            sendB.heightAnchor == CGFloat(45)
            discardB.heightAnchor == CGFloat(45)
        }
        updateDepth()

        reply.backgroundColor = menuBack.backgroundColor
        
        body.text = ""
        body.delegate = self
        self.replyDelegate = parent!

        if edit {
            body.text = comment!.body
        }

        body.sizeToFitHeight()
        parent!.prepareReply()
        toolbar = ToolbarTextView.init(textView: body, parent: parent!)
        body.becomeFirstResponder()
    }

    func menu(_ s: AnyObject) {
        more(parent!)
    }
    
    func downvote(_ s: AnyObject) {
        parent!.vote(comment: comment!, dir: .down)
        self.refresh(comment: comment!, submissionAuthor: (parent!.submission?.author)!, text: self.cellContent!)
        self.hideMenuAnimated()
    }
    
    func save() {
        parent!.saveComment(self.comment!)
    }
    
    func doDelete(_ s: AnyObject) {
        self.parent!.deleteComment(cell: self)
    }
    
    func showModMenu(_ s: AnyObject) {
        parent!.modMenu(self)
    }
    
    func vote() {
        if content is RComment {
            let current = ActionStates.getVoteDirection(s: comment!)
            let dir = (current == VoteDirection.none) ? VoteDirection.up : VoteDirection.none
            var direction = dir
            switch ActionStates.getVoteDirection(s: comment!) {
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
                try parent?.session?.setVote(direction, name: (comment!.name), completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                    case .success: break
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
        if content is RComment {
            do {
                try parent?.session?.approve(comment!.id, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Approving comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    case .success:
                        self.parent!.approved.append(self.comment!.id)
                        if self.parent!.removed.contains(self.comment!.id) {
                            self.parent!.removed.remove(at: self.parent!.removed.index(of: self.comment!.id)!)
                        }
                        DispatchQueue.main.async {
                            self.parent!.tableView.reloadData()
                            BannerUtil.makeBanner(text: "Comment approved!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func modDistinguish() {
        if content is RComment {
            do {
                try parent?.session?.distinguish(comment!.id, how: "yes", completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Distinguishing comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    case .success:
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Comment distinguished!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modSticky(sticky: Bool) {
        if content is RComment {
            do {
                try parent?.session?.distinguish(comment!.id, how: "yes", sticky: sticky, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Couldn't \(sticky ? "" : "un-")pin comment!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    case .success:
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Comment \(sticky ? "" : "un-")pinned!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    }
                })
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }
    
    func modRemove(_ spam: Bool = false) {
        if content is RComment {
            do {
                try parent?.session?.remove(comment!.id, spam: spam, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                    print(error.description)
                    DispatchQueue.main.async {
                        BannerUtil.makeBanner(text: "Removing comment failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    case .success:
                        self.parent!.removed.append(self.comment!.id)
                        if self.parent!.approved.contains(self.comment!.id) {
                            self.parent!.approved.remove(at: self.parent!.approved.index(of: self.comment!.id)!)
                        }
                        DispatchQueue.main.async {
                            self.parent!.tableView.reloadData()
                            BannerUtil.makeBanner(text: "Comment removed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                }
            })
            
            } catch {
                print(error)
            }
            refresh(comment: content as! RComment, submissionAuthor: savedAuthor, text: cellContent!)
        }
    }

    func modBan(why: String, duration: Int?) {
        if content is RComment {
            do {
                try parent?.session?.ban(comment!.author, banReason: why, duration: duration == nil ? 999 /*forever*/ : duration!, completion: { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        print(error.description)
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "Banning user failed!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
                    case .success:
                        DispatchQueue.main.async {
                            BannerUtil.makeBanner(text: "u/\(self.comment!.author) banned!", color: ColorUtil.accentColorForSub(sub: self.comment!.subreddit), seconds: 3, context: self.parent!)
                        }
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

        alertController.addAction(Action(ActionData(title: "\(AccountController.formatUsernamePosessive(input: comment!.author, small: false)) profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { _ in

            let prof = ProfileViewController.init(name: self.comment!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: nil, parentViewController: par)
        }))
        alertController.addAction(Action(ActionData(title: "Share comment permalink", image: UIImage(named: "link")!.menuIcon()), style: .default, handler: { _ in
            let activityViewController = UIActivityViewController(activityItems: [self.comment!.permalink], applicationActivities: nil)
            par.present(activityViewController, animated: true, completion: {})
        }))
        if AccountController.isLoggedIn {
            alertController.addAction(Action(ActionData(title: ActionStates.isSaved(s: comment!) ? "Unsave" : "Save", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { _ in
                par.saveComment(self.comment!)
            }))
        }
        alertController.addAction(Action(ActionData(title: "Report", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
            PostActions.report(self.comment!, parent: par)
        }))
        
        alertController.addAction(Action(ActionData(title: "Tag user", image: UIImage(named: "subs")!.menuIcon()), style: .default, handler: { _ in
            par.tagUser(name: self.comment!.author)
        }))

        alertController.addAction(Action(ActionData(title: "Copy text", image: UIImage(named: "copy")!.menuIcon()), style: .default, handler: { _ in
            let alert = UIAlertController.init(title: "Copy text", message: "", preferredStyle: .alert)
            alert.addTextViewer(text: .text(self.comment!.body))
            alert.addAction(UIAlertAction.init(title: "Copy all", style: .default, handler: { (_) in
                UIPasteboard.general.string = self.comment!.body
            }))
            alert.addAction(UIAlertAction.init(title: "Close", style: .cancel, handler: { (_) in
                
            }))
            par.present(alert, animated: true)
        }))

        VCPresenter.presentAlert(alertController, parentVC: par.parent!)
    }

    func mod(_ par: CommentViewController) {
        let alertController: BottomSheetActionController = BottomSheetActionController()
        alertController.headerData = "Comment by u/\(comment!.author)"

        alertController.addAction(Action(ActionData(title: "\(comment!.reports.count) reports", image: UIImage(named: "reports")!.menuIcon()), style: .default, handler: { _ in
            var reports = ""
            for report in self.comment!.reports {
                reports += report + "\n"
            }
            let alert = UIAlertController(title: "Reports",
                                          message: reports,
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            self.parent?.present(alert, animated: true, completion: nil)

        }))
        alertController.addAction(Action(ActionData(title: "Approve", image: UIImage(named: "approve")!.menuIcon()), style: .default, handler: { _ in
            self.modApprove()
        }))

        alertController.addAction(Action(ActionData(title: "Ban user", image: UIImage(named: "ban")!.menuIcon()), style: .default, handler: { _ in
            //todo show dialog for this
        }))
        
        if comment!.author == AccountController.currentName {
            alertController.addAction(Action(ActionData(title: "Distinguish", image: UIImage(named: "save")!.menuIcon()), style: .default, handler: { _ in
                self.modDistinguish()
            }))
        }

        if comment!.author == AccountController.currentName && comment!.depth == 1 {
            if comment!.sticky {
                alertController.addAction(Action(ActionData(title: "Un-pin", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
                    self.modSticky(sticky: false)
                }))
            } else {
                alertController.addAction(Action(ActionData(title: "Pin and distinguish", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
                    self.modSticky(sticky: true)
                }))
            }
        }

        alertController.addAction(Action(ActionData(title: "Remove", image: UIImage(named: "close")!.menuIcon()), style: .default, handler: { _ in
            self.modRemove()
        }))

        alertController.addAction(Action(ActionData(title: "Mark as spam", image: UIImage(named: "flag")!.menuIcon()), style: .default, handler: { _ in
            self.modRemove(true)
        }))

        alertController.addAction(Action(ActionData(title: "User profile", image: UIImage(named: "profile")!.menuIcon()), style: .default, handler: { _ in
            let prof = ProfileViewController.init(name: self.comment!.author)
            VCPresenter.showVC(viewController: prof, popupIfPossible: true, parentNavigationController: nil, parentViewController: par)
        }))

        VCPresenter.presentAlert(alertController, parentVC: par.parent!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sideConstraints: [NSLayoutConstraint] = []

    func collapse(childNumber: Int) {
        if childNumber != 0 {
            childrenCountLabel.text = "+\(childNumber)"
            UIView.animate(withDuration: 0.4, delay: 0.0, options:
                UIViewAnimationOptions.curveEaseOut, animations: {
                    self.childrenCount.alpha = 1
            }, completion: { _ in
            })
        }
        isCollapsed = true
        if SettingValues.collapseFully {
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
            self.childrenCount.alpha = 0
        }, completion: { _ in
        })
        isCollapsed = false
        if SettingValues.collapseFully {
            refresh(comment: comment!, submissionAuthor: parent!.submission!.author, text: cellContent!)
        }
    }

    var oldDepth = 0

    func configureLayout() {
        topViewSpace.horizontalAnchors == contentView.horizontalAnchors
        topViewSpace.topAnchor == contentView.topAnchor
        title.topAnchor == topViewSpace.bottomAnchor + CGFloat(8)

        title.leftAnchor == sideView.rightAnchor + CGFloat(12)
        title.rightAnchor == contentView.rightAnchor - CGFloat(4)
        
        childrenCount.topAnchor == topViewSpace.bottomAnchor + CGFloat(4)
        childrenCount.rightAnchor == contentView.rightAnchor - CGFloat(4)
        sideView.verticalAnchors == contentView.verticalAnchors
        sideViewSpace.verticalAnchors == contentView.verticalAnchors
        
        updateDepth()
        menu.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        title.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        reply.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        body.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        sendB.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)
        discardB.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .vertical)

    }
    
    func updateDepth() {
        NSLayoutConstraint.deactivate(sideConstraints)
        sideConstraints = batch {
            sideViewSpace.leftAnchor == contentView.leftAnchor - CGFloat(8)
            sideViewSpace.widthAnchor == CGFloat((SettingValues.wideIndicators ? 8 : 4) * (depth))
            sideView.leftAnchor == sideViewSpace.rightAnchor
            sideView.widthAnchor == CGFloat(sideWidth)
        }
    }

    var sideWidth: Int = 0
    var marginTop: Int = 0
    var menuHeight: [NSLayoutConstraint] = []
    var topMargin: [NSLayoutConstraint] = []

    func setMore(more: RMore, depth: Int) {
        self.depth = depth
        self.comment = nil
        loading = false
        childrenCount.alpha = 0
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        if depth - 1 > 0 {
            sideWidth = (SettingValues.wideIndicators ? 8 : 4)
            marginTop = 1
            let i22 = depth - 2
            if SettingValues.disableColor {
                if i22 % 5 == 0 {
                    sideView.backgroundColor = GMColor.grey100Color()
                } else if i22 % 4 == 0 {
                    sideView.backgroundColor = GMColor.grey200Color()
                } else if i22 % 3 == 0 {
                    sideView.backgroundColor = GMColor.grey300Color()
                } else if i22 % 2 == 0 {
                    sideView.backgroundColor = GMColor.grey400Color()
                } else {
                    sideView.backgroundColor = GMColor.grey500Color()
                }
            } else {
                if i22 % 5 == 0 {
                    sideView.backgroundColor = GMColor.blue500Color()
                } else if i22 % 4 == 0 {
                    sideView.backgroundColor = GMColor.green500Color()
                } else if i22 % 3 == 0 {
                    sideView.backgroundColor = GMColor.yellow500Color()
                } else if i22 % 2 == 0 {
                    sideView.backgroundColor = GMColor.orange500Color()
                } else {
                    sideView.backgroundColor = GMColor.red500Color()
                }
            }
        } else {
            marginTop = 8
            sideWidth = 0
        }
        
        if depth == 1 {
            marginTop = 8
        }

        let font = FontGenerator.fontOfSize(size: 14, submission: false)
        
        var attr = NSMutableAttributedString()
        if more.children.isEmpty {
            attr = NSMutableAttributedString(string: "Continue this thread", attributes: [NSFontAttributeName: font])
        } else {
            attr = NSMutableAttributedString(string: "Load \(more.count) more", attributes: [NSFontAttributeName: font])
        }
        let attr2 = attr.reconstruct(with: font, color: ColorUtil.fontColor, linkColor: .white)
        
        title.setTextWithTitleHTML(attr2, htmlString: "")
        NSLayoutConstraint.deactivate(menuHeight)
        menuHeight = batch {
            title.bottomAnchor == contentView.bottomAnchor - CGFloat(8)
            menu.heightAnchor == CGFloat(0)
            body.heightAnchor == CGFloat(0)
            reply.heightAnchor == CGFloat(0)
        }
        updateDepth()
        NSLayoutConstraint.deactivate(topMargin)
        topMargin = batch {
            topViewSpace.heightAnchor == CGFloat(marginTop)
        }
    }

    var numberOfDots = 3
    var loading = false

    func animateMore() {
        loading = true
        
        title.setData(htmlString: "Loading...")
        //todo possibly animate?
    }

    public var isCollapsed = false
    var dtap: UIShortTapGestureRecognizer?

    func setComment(comment: RComment, depth: Int, parent: CommentViewController, hiddenCount: Int, date: Double, author: String?, text: NSAttributedString, isCollapsed: Bool, parentOP: String) {
        self.comment = comment
        self.cellContent = text
        self.contentView.backgroundColor = ColorUtil.foregroundColor
        loading = false
        if self.parent == nil {
            self.parent = parent
        }

        self.isCollapsed = isCollapsed

        if date != 0 && date < Double(comment.created.timeIntervalSince1970) {
            setIsNew(sub: comment.subreddit)
        }
        
        if hiddenCount > 0 {
            childrenCount.alpha = 1
            childrenCountLabel.text = "+\(hiddenCount)"
        } else {
            childrenCount.alpha = 0
        }

        self.depth = depth
        self.oldDepth = depth
        if depth - 1 > 0 {
            sideWidth = SettingValues.wideIndicators ? 8 : 4 
            marginTop = 1
            let i22 = depth - 2
            if SettingValues.disableColor {
                if i22 % 5 == 0 {
                    sideView.backgroundColor = GMColor.grey100Color()
                } else if i22 % 4 == 0 {
                    sideView.backgroundColor = GMColor.grey200Color()
                } else if i22 % 3 == 0 {
                    sideView.backgroundColor = GMColor.grey300Color()
                } else if i22 % 2 == 0 {
                    sideView.backgroundColor = GMColor.grey400Color()
                } else {
                    sideView.backgroundColor = GMColor.grey500Color()
                }
            } else {
                if i22 % 5 == 0 {
                    sideView.backgroundColor = GMColor.blue500Color()
                } else if i22 % 4 == 0 {
                    sideView.backgroundColor = GMColor.green500Color()
                } else if i22 % 3 == 0 {
                    sideView.backgroundColor = GMColor.yellow500Color()
                } else if i22 % 2 == 0 {
                    sideView.backgroundColor = GMColor.orange500Color()
                } else {
                    sideView.backgroundColor = GMColor.red500Color()
                }
            }
            if SettingValues.highlightOp && parentOP == comment.author {
                sideView.backgroundColor = GMColor.purple500Color()
            }
        } else {
            marginTop = 8
            sideWidth = 0
        }
        
        if depth == 1 {
            marginTop = 8
        }

        refresh(comment: comment, submissionAuthor: author, text: text)

        if !registered {
            parent.registerForPreviewing(with: self, sourceView: title)
            registered = true
        }
        if parent.getMenuShown() ?? "" == comment.getIdentifier() {
            showCommentMenu()
        } else {
            hideCommentMenu()
        }
        
        NSLayoutConstraint.deactivate(topMargin)
        topMargin = batch {
            topViewSpace.heightAnchor == CGFloat(marginTop)
        }
    }
    
    func doDTap(_ sender: AnyObject) {
        switch SettingValues.commentActionDoubleTap {
        case .UPVOTE:
            self.upvote(self)
        case .DOWNVOTE:
            self.downvote(self)
        case .SAVE:
            self.save()
        case .MENU:
            self.menu(self)
        default:
            break
        }
    }

    var cellContent: NSAttributedString?

    var savedAuthor: String = ""

    func refresh(comment: RComment, submissionAuthor: String?, text: NSAttributedString) {
        var color: UIColor

        savedAuthor = submissionAuthor!

        switch ActionStates.getVoteDirection(s: comment) {
        case .down:
            color = ColorUtil.downvoteColor
        case .up:
            color = ColorUtil.upvoteColor
        default:
            color = ColorUtil.fontColor
        }

        let scoreString = NSMutableAttributedString(string: ((comment.scoreHidden ? "[score hidden]" : "\(getScoreText(comment: comment))") + (comment.controversiality > 0 ? "†" : "")), attributes: [NSForegroundColorAttributeName: color])

        let endString = NSMutableAttributedString(string: "  •  \(DateFormatter().timeSince(from: comment.created, numericDates: true))" + (comment.isEdited ? ("(edit \(DateFormatter().timeSince(from: comment.edited, numericDates: true)))") : ""), attributes: [NSForegroundColorAttributeName: ColorUtil.fontColor])

        let authorString = NSMutableAttributedString(string: "\u{00A0}\u{00A0}\(AccountController.formatUsername(input: comment.author, small: true))\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])
        let authorStringNoFlair = NSMutableAttributedString(string: "\(AccountController.formatUsername(input: comment.author, small: true))\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: parent?.authorColor ?? ColorUtil.fontColor])

        let flairTitle = NSMutableAttributedString.init(string: "\u{00A0}\(comment.flair)\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: ColorUtil.backgroundColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let pinned = NSMutableAttributedString.init(string: "\u{00A0}PINNED\u{00A0}", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.green500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
        let gilded = NSMutableAttributedString.init(string: "\u{00A0}x\(comment.gilded) ", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false)])

        let spacer = NSMutableAttributedString.init(string: "  ")
        let userColor = ColorUtil.getColorForUser(name: comment.author)
        var authorSmall = false
        if comment.distinguished == "admin" {
          authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#E57373"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 1, length: authorString.length - 1))
        } else if comment.distinguished == "special" {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#F44336"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 1, length: authorString.length - 1))
        } else if comment.distinguished == "moderator" {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#81C784"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 1, length: authorString.length - 1))
        } else if AccountController.currentName == comment.author {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#FFB74D"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 1, length: authorString.length - 1))
        } else if submissionAuthor != nil && comment.author == submissionAuthor {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor.init(hexString: "#64B5F6"), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 1, length: authorString.length - 1))
        } else if userColor != ColorUtil.baseColor {
            authorString.addAttributes([kTTTBackgroundFillColorAttributeName: userColor, NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 3, length: authorString.length))
        } else {
            authorSmall = true
        }

        let infoString = NSMutableAttributedString(string: "")
        if authorSmall {
            infoString.append(authorStringNoFlair)
        } else {
            infoString.append(authorString)
        }

        let tag = ColorUtil.getTagForUser(name: comment.author)
        if !tag.isEmpty {
            let tagString = NSMutableAttributedString(string: "\u{00A0}\(tag)\u{00A0}", attributes: [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor])
            tagString.addAttributes([kTTTBackgroundFillColorAttributeName: UIColor(rgb: 0x2196f3), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3], range: NSRange.init(location: 0, length: tagString.length))
            infoString.append(spacer)
            infoString.append(tagString)
        }

        infoString.append(NSAttributedString(string: "  •  ", attributes: [NSFontAttributeName: FontGenerator.fontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: ColorUtil.fontColor]))
        infoString.append(scoreString)
        infoString.append(endString)

        if !comment.flair.isEmpty {
            infoString.append(spacer)
            infoString.append(flairTitle)
        }

        if comment.sticky {
            infoString.append(spacer)
            infoString.append(pinned)
        }
        if comment.gilded > 0 {
            infoString.append(spacer)
            let gild = NSMutableAttributedString.init(string: "G", attributes: [kTTTBackgroundFillColorAttributeName: GMColor.amber500Color(), NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: false), NSForegroundColorAttributeName: UIColor.white, kTTTBackgroundFillPaddingAttributeName: UIEdgeInsets.init(top: 1, left: 1, bottom: 1, right: 1), kTTTBackgroundCornerRadiusAttributeName: 3])
            infoString.append(gild)
            if comment.gilded > 1 {
                infoString.append(gilded)
            }
        }
        
        if parent!.removed.contains(comment.id) || (!comment.removedBy.isEmpty() && !parent!.approved.contains(comment.id)) {
            let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: GMColor.red500Color()] as [String: Any]
            infoString.append(spacer)
            if comment.removedBy == "true" {
                infoString.append(NSMutableAttributedString.init(string: "Removed by Reddit\(!comment.removalReason.isEmpty() ? ":\(comment.removalReason)" : "")", attributes: attrs))
            } else {
                infoString.append(NSMutableAttributedString.init(string: "Removed\(!comment.removedBy.isEmpty() ? " by \(comment.removedBy)":"")\(!comment.removalReason.isEmpty() ? " for \(comment.removalReason)" : "")\(!comment.removalNote.isEmpty() ? " \(comment.removalNote)" : "")", attributes: attrs))
            }
        } else if parent!.approved.contains(comment.id) || (!comment.approvedBy.isEmpty() && !parent!.removed.contains(comment.id)) {
            let attrs = [NSFontAttributeName: FontGenerator.boldFontOfSize(size: 12, submission: true), NSForegroundColorAttributeName: GMColor.green500Color()] as [String: Any]
            infoString.append(spacer)
            infoString.append(NSMutableAttributedString.init(string: "Approved\(!comment.approvedBy.isEmpty() ? " by \(comment.approvedBy)":"")", attributes: attrs))
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.5
        infoString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSRange(location: 0, length: infoString.length))

        title.tColor = ColorUtil.accentColorForSub(sub: comment.subreddit)
        if !isCollapsed || !SettingValues.collapseFully {
            title.setTextWithTitleHTML(infoString, text, htmlString: comment.htmlText)
        } else {
            title.setAttributedString(infoString)
        }
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
        switch ActionStates.getVoteDirection(s: comment) {
        case .up:
            if comment.likes != .up {
                if comment.likes == .down {
                    submissionScore += 1
                }
                submissionScore += 1
            }
        case .down:
            if comment.likes != .down {
                if comment.likes == .up {
                    submissionScore -= 1
                }
                submissionScore -= 1
            }
        case .none:
            if comment.likes == .up && comment.author == AccountController.currentName {
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
        if let attr = title.firstTextView.link(at: locationInTextView) {
            if let url = attr.result.url {
                return (url, title.bounds)
            }

        }
        return nil
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if viewControllerToCommit is AlbumViewController {
            viewControllerToCommit.modalPresentationStyle = .overFullScreen
            parent?.present(viewControllerToCommit, animated: true, completion: nil)
        } else if viewControllerToCommit is ModalMediaViewController {
            viewControllerToCommit.modalPresentationStyle = .overFullScreen
            parent?.present(viewControllerToCommit, animated: true, completion: nil)
        } else {
            VCPresenter.showVC(viewController: viewControllerToCommit, popupIfPossible: true, parentNavigationController: parent?.navigationController, parentViewController: parent)
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
        return UIEdgeInsets(top: 4, left: 0, bottom: 2, right: 0)
    }
}

extension CommentDepthCell: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didLongPressLinkWith url: URL!, at point: CGPoint) {
        if parent != nil {
            let sheet = UIAlertController(title: url.absoluteString, message: nil, preferredStyle: .actionSheet)
            sheet.addAction(
                UIAlertAction(title: "Close", style: .cancel) { (_) in
                    sheet.dismiss(animated: true, completion: nil)
                }
            )
            let open = OpenInChromeController.init()
            if open.isChromeInstalled() {
                sheet.addAction(
                    UIAlertAction(title: "Open in Chrome", style: .default) { (_) in
                        _ = open.openInChrome(url, callbackURL: nil, createNewTab: true)
                    }
                )
            }
            sheet.addAction(
                UIAlertAction(title: "Open in Safari", style: .default) { (_) in
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                    sheet.dismiss(animated: true, completion: nil)
                }
            )
            sheet.addAction(
                UIAlertAction(title: "Open", style: .default) { (_) in
                    /* let controller = WebViewController(nibName: nil, bundle: nil)
                     controller.url = url
                     let nav = UINavigationController(rootViewController: controller)
                     self.present(nav, animated: true, completion: nil)*/
                }
            )
            sheet.addAction(
                UIAlertAction(title: "Copy URL", style: .default) { (_) in
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
    
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith result: NSTextCheckingResult!) {
        let textClicked = label.attributedText.attributedSubstring(from: result.range).string
        if textClicked.contains("[[s[") {
            parent?.showSpoiler(textClicked)
        } else {
            let urlClicked = result.url!
            parent?.doShow(url: urlClicked, heroView: nil, heroVC: nil)
        }
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

extension UITextView {
    func sizeToFitHeight() {
        let size: CGSize = self.sizeThatFits(CGSize.init(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        var frame: CGRect = self.frame
        frame.size.height = size.height
        self.frame = frame
    }
}
